#!/usr/bin/env ruby
# Expands a scan engine's YAML stages into scan_tasks for a target. A stage
# runs once against the scan's top-level target unless it declares
# `chain_from: <earlier stage name>`, in which case it waits for that
# stage to finish and fans out into one task per distinct finding value it
# produced (capped by `chain_limit`). Each task is handed to whichever
# host is currently least busy, executed with an optional per-stage
# timeout, and can be stopped mid-run by a scan-level cancel request.
require_relative 'models'
require_relative 'tools'
require_relative 'executor'
require_relative 'broadcaster'
require_relative 'host_load'
require_relative 'notifier'

module Dispatcher
  DEFAULT_CHAIN_LIMIT = 25

  def self.launch(scan)
    Thread.new { run(scan) }
  end

  def self.run(scan)
    scan.update(status: 'running', cancel_requested: false, started_at: Time.now)
    Broadcaster.publish(scan.id, { type: 'scan_status', status: 'running' })

    stages = scan.engine.stages
    hosts = Host.all
    hosts = [nil] if hosts.empty?

    if stages.empty?
      scan.update(status: 'failed', finished_at: Time.now)
      Broadcaster.publish(scan.id, { type: 'scan_status', status: 'failed', message: 'Engine has no stages' })
      return
    end

    stage_threads = {}
    stages.each do |stage|
      parent_name = stage['chain_from']
      stage_threads[stage['name']] = Thread.new do
        stage_threads[parent_name]&.join if parent_name
        if parent_name
          run_chained_stage(scan, stage, hosts, parent_name)
        else
          run_single_stage(scan, stage, hosts, scan.target.name)
        end
      end
    end
    stage_threads.each_value(&:join)

    final_status = determine_final_status(scan)
    scan.update(status: final_status, finished_at: Time.now)
    Broadcaster.publish(scan.id, { type: 'scan_status', status: final_status })
    Notifier.scan_finished(scan)
  rescue => e
    scan.update(status: 'failed', finished_at: Time.now)
    Broadcaster.publish(scan.id, { type: 'scan_status', status: 'failed', message: e.message })
    Notifier.scan_finished(scan)
  end

  def self.determine_final_status(scan)
    return 'cancelled' if scan.refresh.cancel_requested
    bad = ScanTask.where(scan_id: scan.id, status: %w[failed timeout]).count
    bad.zero? ? 'completed' : 'failed'
  end

  def self.cancelled?(scan_id)
    Scan[scan_id]&.cancel_requested || false
  end

  # A stage with no chain_from: one task against `target`.
  def self.run_single_stage(scan, stage, hosts, target)
    run_task(scan, stage, hosts, target, nil)
  end

  # A stage with chain_from: one task per distinct finding value the
  # parent stage produced (capped), each task's target_value set to that
  # finding.
  def self.run_chained_stage(scan, stage, hosts, parent_name)
    kind = stage['chain_kind'] || 'subdomain'
    limit = (stage['chain_limit'] || DEFAULT_CHAIN_LIMIT).to_i
    parent_task_ids = ScanTask.where(scan_id: scan.id, stage_name: parent_name).select_map(:id)
    values = Finding.where(scan_task_id: parent_task_ids, kind: kind).distinct.select_map(:value).compact.first(limit)

    if values.empty?
      task = ScanTask.create(
        scan_id: scan.id, stage_name: stage['name'], tool: stage['tool'].to_s,
        status: 'queued', target_value: nil, created_at: Time.now
      )
      Broadcaster.publish(scan.id, { type: 'task', task: task_json(task) })
      msg = "No '#{kind}' findings from stage '#{parent_name}' to chain into"
      finish_task(scan, task, 'skipped', msg, nil)
      return
    end

    threads = values.map do |value|
      Thread.new { run_task(scan, stage, hosts, value, parent_task_ids.first) }
    end
    threads.each(&:join)
  end

  def self.run_task(scan, stage, hosts, target, parent_task_id)
    tool_key = stage['tool'].to_s
    task = ScanTask.create(
      scan_id: scan.id, stage_name: (stage['name'] || tool_key), tool: tool_key,
      parent_task_id: parent_task_id, target_value: target, status: 'queued', created_at: Time.now
    )
    Broadcaster.publish(scan.id, { type: 'task', task: task_json(task) })

    if cancelled?(scan.id)
      return finish_task(scan, task, 'cancelled', 'Scan was cancelled before this stage started', nil)
    end

    unless Tools.available?(tool_key)
      return finish_task(scan, task, 'failed', "Unknown tool '#{tool_key}'", nil)
    end

    host = HostLoad.acquire(hosts)
    begin
      task.update(host_id: host&.id)

      binary = Tools.binary_for(tool_key)
      unless Executor.which(host, binary)
        where = host ? "host '#{host.name}'" : 'the local dashboard host'
        return finish_task(scan, task, 'skipped', "Tool '#{tool_key}' (binary: #{binary}) not found on #{where}", nil)
      end

      command = Tools.command_for(tool_key, target, stage)
      task.update(status: 'running', command: command, started_at: Time.now)
      Broadcaster.publish(scan.id, { type: 'task_update', task: task_json(task) })

      lines = []
      extra_env = { 'BURP_API_URL' => ENV['BURP_API_URL'], 'BURP_API_KEY' => ENV['BURP_API_KEY'] }
      timeout = stage['timeout']&.to_i
      result = Executor.run(
        host, command, extra_env: extra_env, timeout: (timeout&.positive? ? timeout : nil),
        cancel_check: -> { cancelled?(scan.id) }, pid_callback: ->(pid) { task.update(pid: pid) }
      ) do |line|
        lines << line
        Broadcaster.publish(scan.id, { type: 'output', task_id: task.id, line: line })
        finding = Tools.parse_line(tool_key, line)
        next unless finding
        f = Finding.create(scan_task_id: task.id, scan_id: scan.id, kind: finding[:kind],
                            value: finding[:value], raw: finding[:raw], created_at: Time.now)
        Broadcaster.publish(scan.id, { type: 'finding', finding: { id: f.id, kind: f.kind, value: f.value, task_id: task.id } })
      end

      status =
        if result.cancelled then 'cancelled'
        elsif result.timed_out then 'timeout'
        elsif result.exit_status == 0 then 'completed'
        else 'failed'
        end
      finish_task(scan, task, status, lines.join("\n")[0, 200_000], result.exit_status)
    ensure
      HostLoad.release(host)
    end
  rescue => e
    if task
      finish_task(scan, task, 'failed', "[dispatcher] #{e.message}", nil)
    else
      Broadcaster.publish(scan.id, { type: 'scan_status', status: 'running', message: "[dispatcher] #{e.message}" })
    end
  end

  def self.finish_task(scan, task, status, output, exit_status)
    task.update(status: status, output: output.to_s, exit_status: exit_status, finished_at: Time.now)
    Broadcaster.publish(scan.id, { type: 'task_update', task: task_json(task) })
  end

  def self.task_json(task)
    {
      id: task.id, stage_name: task.stage_name, tool: task.tool, host_id: task.host_id,
      target_value: task.target_value, status: task.status, command: task.command,
      exit_status: task.exit_status
    }
  end
end
