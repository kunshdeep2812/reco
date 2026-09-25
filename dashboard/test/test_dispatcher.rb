require_relative 'test_helper'
require 'dispatcher'

class DispatcherTest < Minitest::Test
  def setup
    TestDB.reset!
    Host.create(name: 'local', address: '127.0.0.1', auth_method: 'local', status: 'online', created_at: Time.now)
    @target = Target.create(name: 'example.com', created_at: Time.now)
  end

  STUBBED_METHODS = %i[available? binary_for command_for parse_line].freeze

  def with_stub_tool(build_command)
    originals = STUBBED_METHODS.to_h { |m| [m, Tools.singleton_class.instance_method(m)] }
    Tools.define_singleton_method(:available?) { |_k| true }
    Tools.define_singleton_method(:binary_for) { |_k| 'bash' }
    Tools.define_singleton_method(:command_for) { |_k, _t, _o| build_command }
    Tools.define_singleton_method(:parse_line) { |_k, line| line.start_with?('FOUND:') ? { kind: 'subdomain', value: line.sub('FOUND:', ''), raw: line } : nil }
    yield
  ensure
    originals.each { |m, impl| Tools.singleton_class.send(:define_method, m, impl) }
  end

  def test_chained_stage_fans_out_over_parent_findings
    engine = Engine.create(name: 'chain-test', created_at: Time.now, definition: <<~YAML)
      name: chain-test
      stages:
        - name: enum
          tool: fake_enum
        - name: probe
          tool: fake_probe
          chain_from: enum
          chain_kind: subdomain
          chain_limit: 10
    YAML

    call_count = 0
    with_stub_tool("echo done") do
      # first stage produces two subdomains, second stage is a no-op per target
      Tools.define_singleton_method(:command_for) do |key, target, _opts|
        call_count += 1
        key == 'fake_enum' ? 'echo FOUND:a.example.com; echo FOUND:b.example.com' : 'echo done'
      end

      scan = Scan.create(target_id: @target.id, engine_id: engine.id, status: 'queued', created_at: Time.now)
      Dispatcher.launch(scan).join
      scan.refresh

      assert_equal 'completed', scan.status
      probe_tasks = ScanTask.where(scan_id: scan.id, stage_name: 'probe').all
      assert_equal 2, probe_tasks.length
      assert_equal %w[a.example.com b.example.com], probe_tasks.map(&:target_value).sort
    end
  end

  def test_chained_stage_with_no_parent_findings_is_skipped_not_failed
    engine = Engine.create(name: 'empty-chain', created_at: Time.now, definition: <<~YAML)
      name: empty-chain
      stages:
        - name: enum
          tool: fake_enum
        - name: probe
          tool: fake_probe
          chain_from: enum
    YAML

    with_stub_tool('echo nothing_here') do
      scan = Scan.create(target_id: @target.id, engine_id: engine.id, status: 'queued', created_at: Time.now)
      Dispatcher.launch(scan).join
      scan.refresh

      assert_equal 'completed', scan.status
      probe_task = ScanTask.where(scan_id: scan.id, stage_name: 'probe').first
      assert_equal 'skipped', probe_task.status
      assert_match(/No 'subdomain' findings/, probe_task.output)
    end
  end

  def test_cancel_requested_stops_a_running_scan
    engine = Engine.create(name: 'slow', created_at: Time.now, definition: <<~YAML)
      name: slow
      stages:
        - name: slow_stage
          tool: fake_slow
    YAML

    with_stub_tool('sleep 20') do
      scan = Scan.create(target_id: @target.id, engine_id: engine.id, status: 'queued', created_at: Time.now)
      thread = Dispatcher.launch(scan)
      sleep 0.5
      scan.update(cancel_requested: true)
      thread.join

      scan.refresh
      assert_equal 'cancelled', scan.status
      task = ScanTask.where(scan_id: scan.id).first
      assert_equal 'cancelled', task.status
    end
  end

  def test_stage_timeout_marks_task_timeout_and_scan_failed
    engine = Engine.create(name: 'timeout-test', created_at: Time.now, definition: <<~YAML)
      name: timeout-test
      stages:
        - name: slow_stage
          tool: fake_slow
          timeout: 1
    YAML

    with_stub_tool('sleep 20') do
      scan = Scan.create(target_id: @target.id, engine_id: engine.id, status: 'queued', created_at: Time.now)
      Dispatcher.launch(scan).join
      scan.refresh

      assert_equal 'failed', scan.status
      task = ScanTask.where(scan_id: scan.id).first
      assert_equal 'timeout', task.status
    end
  end

  def test_unknown_tool_fails_the_task_without_crashing_the_scan
    engine = Engine.create(name: 'bad-tool', created_at: Time.now, definition: <<~YAML)
      name: bad-tool
      stages:
        - name: bogus
          tool: does_not_exist_in_registry
    YAML
    scan = Scan.create(target_id: @target.id, engine_id: engine.id, status: 'queued', created_at: Time.now)
    Dispatcher.launch(scan).join
    scan.refresh
    assert_equal 'failed', scan.status
    task = ScanTask.where(scan_id: scan.id).first
    assert_equal 'failed', task.status
    assert_match(/Unknown tool/, task.output)
  end
end
