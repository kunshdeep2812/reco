#!/usr/bin/env ruby
# Runs a built command either on the dashboard host itself (Open3) or on a
# remote worker over SSH (Net::SSH), streaming output lines back live.
# Supports a per-command deadline and a cooperative cancellation check,
# killing the whole process tree (local) or the remote process (SSH) when
# either fires.
require 'open3'
require 'net/ssh'
require 'shellwords'
require_relative 'crypto'

module Executor
  REPO_ROOT = File.expand_path('../..', __dir__)
  POLL_INTERVAL = 0.5

  Result = Struct.new(:exit_status, :timed_out, :cancelled, keyword_init: true)

  # host: a Hosts row, or nil/local for the dashboard's own machine.
  # command: shell command string (already built by Tools.command_for).
  # timeout: seconds, or nil for no deadline.
  # cancel_check: a callable returning true once the run should stop.
  # pid_callback: called with the (local or remote) process id once known.
  # Yields each output line as it is produced. Returns a Result.
  def self.run(host, command, extra_env: {}, timeout: nil, cancel_check: nil, pid_callback: nil, &block)
    reco_home = (host.nil? || host.auth_method == 'local') ? REPO_ROOT : (host.remote_path.to_s.empty? ? '~/reco' : host.remote_path)
    env = { 'RECO_HOME' => reco_home }.merge(extra_env.reject { |_, v| v.nil? })
    env_prefix = env.map { |k, v| "export #{k}=#{Shellwords.escape(v.to_s)};" }.join(' ')
    full_command = "#{env_prefix} #{command}"

    if host.nil? || host.auth_method == 'local'
      run_local(full_command, timeout: timeout, cancel_check: cancel_check, pid_callback: pid_callback, &block)
    else
      run_remote(host, full_command, timeout: timeout, cancel_check: cancel_check, pid_callback: pid_callback, &block)
    end
  end

  # Checks whether `binary` exists in $PATH on the given host (or locally).
  def self.which(host, binary)
    return true if binary.nil?
    if binary == :env_burp
      return !ENV['BURP_API_URL'].to_s.empty? && !ENV['BURP_API_KEY'].to_s.empty?
    end
    check = "command -v #{Shellwords.escape(binary.to_s)} >/dev/null 2>&1 && echo __FOUND__ || echo __MISSING__"
    found = false
    if host.nil? || host.auth_method == 'local'
      run_local(check) { |l| found = true if l.include?('__FOUND__') }
    else
      run_remote(host, check) { |l| found = true if l.include?('__FOUND__') }
    end
    found
  rescue
    false
  end

  def self.test_connection(host)
    return { ok: true, message: 'Runs locally on the dashboard host' } if host.auth_method == 'local'
    Net::SSH.start(host.address, host.ssh_user, ssh_options(host).merge(timeout: 8)) do |ssh|
      ssh.exec!('echo ok')
    end
    { ok: true, message: 'SSH connection succeeded' }
  rescue => e
    { ok: false, message: e.message }
  end

  def self.run_local(command, timeout: nil, cancel_check: nil, pid_callback: nil)
    exit_status = nil
    timed_out = false
    cancelled = false
    deadline = timeout ? (Time.now + timeout) : nil
    buffer = +''

    Open3.popen2e('bash', '-lc', command, pgroup: true) do |stdin, out, wait_thr|
      stdin.close
      pid_callback.call(wait_thr.pid) if pid_callback

      loop do
        if deadline && Time.now > deadline
          timed_out = true
          kill_process_tree(wait_thr.pid)
          break
        end
        if cancel_check && cancel_check.call
          cancelled = true
          kill_process_tree(wait_thr.pid)
          break
        end
        begin
          ready = IO.select([out], nil, nil, POLL_INTERVAL)
          next unless ready
          chunk = out.read_nonblock(65_536)
          buffer << chunk
          while (idx = buffer.index("\n"))
            yield sanitize(buffer.slice!(0..idx))
          end
        rescue IO::WaitReadable
          next
        rescue EOFError
          break
        end
      end

      yield sanitize(buffer) unless buffer.empty?
      exit_status = (wait_thr.value.exitstatus rescue nil) unless timed_out || cancelled
    end

    Result.new(exit_status: exit_status, timed_out: timed_out, cancelled: cancelled)
  rescue => e
    yield "[executor] local run failed: #{e.message}"
    Result.new(exit_status: nil, timed_out: false, cancelled: false)
  end

  def self.run_remote(host, command, timeout: nil, cancel_check: nil, pid_callback: nil)
    exit_code = nil
    remote_pid = nil
    timed_out = false
    cancelled = false
    deadline = timeout ? (Time.now + timeout) : nil

    Net::SSH.start(host.address, host.ssh_user, ssh_options(host).merge(timeout: 10)) do |ssh|
      wrapped = "#{command} & __RECO_CHILD__=$!; echo __PID__:$__RECO_CHILD__; wait $__RECO_CHILD__"
      ssh.open_channel do |channel|
        channel.exec("bash -lc #{Shellwords.escape(wrapped)}") do |_ch, success|
          unless success
            yield '[executor] failed to open remote command channel'
            next
          end
          buffer = +''
          drain = lambda do
            while (idx = buffer.index("\n"))
              line = sanitize(buffer.slice!(0..idx))
              if line.start_with?('__PID__:')
                remote_pid = line.split(':', 2)[1].to_i
                pid_callback.call(remote_pid) if pid_callback
              else
                yield line
              end
            end
          end
          channel.on_data { |_, data| buffer << data; drain.call }
          channel.on_extended_data { |_, _type, data| buffer << data; drain.call }
          channel.on_request('exit-status') { |_, data| exit_code = data.read_long }
        end
      end

      ssh.loop(POLL_INTERVAL) do
        if deadline && Time.now > deadline
          timed_out = true
          false
        elsif cancel_check && cancel_check.call
          cancelled = true
          false
        else
          true
        end
      end

      if (timed_out || cancelled) && remote_pid
        begin
          ssh.exec!("kill -TERM #{remote_pid} 2>/dev/null; sleep 1; kill -KILL #{remote_pid} 2>/dev/null")
        rescue StandardError
        end
      end
    end

    yield '[executor] command timed out' if timed_out
    yield '[executor] command cancelled' if cancelled
    Result.new(exit_status: exit_code, timed_out: timed_out, cancelled: cancelled)
  rescue => e
    yield "[executor] SSH to #{host.name} (#{host.address}) failed: #{e.message}"
    Result.new(exit_status: nil, timed_out: false, cancelled: false)
  end

  def self.kill_process_tree(pid)
    Process.kill('TERM', -pid)
    sleep 1
    Process.kill('KILL', -pid) if process_alive?(pid)
  rescue Errno::ESRCH, Errno::EPERM
  end

  def self.process_alive?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  rescue Errno::EPERM
    true
  end

  # Subprocess/SSH output isn't guaranteed to be valid UTF-8 (or even tagged
  # that way) — scrub it so a stray byte can't crash a downstream regex match.
  def self.sanitize(str)
    str.to_s.dup.force_encoding(Encoding::UTF_8).scrub.chomp
  end

  def self.ssh_options(host)
    opts = { port: (host.port || 22), non_interactive: true, verify_host_key: :never, use_agent: true }
    case host.auth_method
    when 'key'
      if host.key_path && !host.key_path.to_s.empty?
        opts[:keys] = [host.key_path]
        opts[:keys_only] = true
      end
    when 'password'
      pw = Crypto.decrypt(host.encrypted_password)
      opts[:password] = pw if pw
      opts[:auth_methods] = ['password']
    end
    opts
  end
end
