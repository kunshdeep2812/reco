#!/usr/bin/env ruby
# Expands a scan engine's YAML stages into scan_tasks for a target, hands
# each stage to one host from the pool (round-robin, Axiom-style spread),
# and runs them concurrently, streaming output + findings live.
require_relative 'models'
require_relative 'tools'
require_relative 'executor'
require_relative 'broadcaster'

module Dispatcher
  def self.launch(scan)
    Thread.new { run(scan) }
  end

  def self.run(scan)
    scan.update(status: 'running', started_at: Time.now)
    Broadcaster.publish(scan.id, { type: 'scan_status', status: 'running' })

    stages = scan.engine.stages
    hosts = Host.all
    hosts = [nil] if hosts.empty?

    if stages.empty?
      scan.update(status: 'failed', finished_at: Time.now)
      Broadcaster.publish(scan.id, { type: 'scan_status', status: 'failed', message: 'Engine has no stages' })
      return
    end

    threads = stages.each_with_index.map do |stage, i|
      host = hosts[i % hosts.length]
      Thread.new { run_stage(scan, stage, host) }
    end
    threads.each(&:join)

    failed = ScanTask.where(scan_id: scan.id, status: 'failed').count
    final_status = failed.zero? ? 'completed' : 'failed'
    scan.update(status: final_status, finished_at: Time.now)
    Broadcaster.publish(scan.id, { type: 'scan_status', status: final_status })
  rescue => e
    scan.update(status: 'failed', finished_at: Time.now)
    Broadcaster.publish(scan.id, { type: 'scan_status', status: 'failed', message: e.message })
  end

  def self.run_stage(scan, stage, host)
    tool_key = stage['tool'].to_s
    task = ScanTask.create(
      scan_id: scan.id, stage_name: (stage['name'] || tool_key), tool: tool_key,
      host_id: host&.id, status: 'queued', created_at: Time.now
    )
    Broadcaster.publish(scan.id, { type: 'task', task: task_json(task) })

    unless Tools.available?(tool_key)
      return finish_task(scan, task, 'failed', "Unknown tool '#{tool_key}'", nil)
    end

    binary = Tools.binary_for(tool_key)
    unless Executor.which(host, binary)
      where = host ? "host '#{host.name}'" : 'the local dashboard host'
      return finish_task(scan, task, 'skipped', "Tool '#{tool_key}' (binary: #{binary}) not found on #{where}", nil)
    end

    command = Tools.command_for(tool_key, scan.target.name, stage)
    task.update(status: 'running', command: command, started_at: Time.now)
    Broadcaster.publish(scan.id, { type: 'task_update', task: task_json(task) })

    lines = []
    extra_env = { 'BURP_API_URL' => ENV['BURP_API_URL'], 'BURP_API_KEY' => ENV['BURP_API_KEY'] }
    exit_status = Executor.run(host, command, extra_env: extra_env) do |line|
      lines << line
      Broadcaster.publish(scan.id, { type: 'output', task_id: task.id, line: line })
      finding = Tools.parse_line(tool_key, line)
      next unless finding
      f = Finding.create(scan_task_id: task.id, scan_id: scan.id, kind: finding[:kind],
                          value: finding[:value], raw: finding[:raw], created_at: Time.now)
      Broadcaster.publish(scan.id, { type: 'finding', finding: { id: f.id, kind: f.kind, value: f.value, task_id: task.id } })
    end

    status = (exit_status == 0) ? 'completed' : 'failed'
    finish_task(scan, task, status, lines.join("\n")[0, 200_000], exit_status)
  rescue => e
    finish_task(scan, task, 'failed', "[dispatcher] #{e.message}", nil)
  end

  def self.finish_task(scan, task, status, output, exit_status)
    task.update(status: status, output: output.to_s, exit_status: exit_status, finished_at: Time.now)
    Broadcaster.publish(scan.id, { type: 'task_update', task: task_json(task) })
  end

  def self.task_json(task)
    {
      id: task.id, stage_name: task.stage_name, tool: task.tool, host_id: task.host_id,
      status: task.status, command: task.command, exit_status: task.exit_status
    }
  end
end
