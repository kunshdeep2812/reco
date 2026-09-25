#!/usr/bin/env ruby
# Runs a built command either on the dashboard host itself (Open3) or on a
# remote worker over SSH (Net::SSH), streaming output lines back live.
require 'open3'
require 'net/ssh'
require 'shellwords'
require_relative 'crypto'

module Executor
  REPO_ROOT = File.expand_path('../..', __dir__)

  # host: a Hosts row, or nil/local for the dashboard's own machine.
  # Yields each output line as it is produced. Returns the exit status
  # (Integer), or nil if the command could not be started at all.
  def self.run(host, command, extra_env: {})
    reco_home = (host.nil? || host.auth_method == 'local') ? REPO_ROOT : (host.remote_path.to_s.empty? ? '~/reco' : host.remote_path)
    env = { 'RECO_HOME' => reco_home }.merge(extra_env.reject { |_, v| v.nil? })
    env_prefix = env.map { |k, v| "export #{k}=#{Shellwords.escape(v.to_s)};" }.join(' ')
    full_command = "#{env_prefix} #{command}"

    if host.nil? || host.auth_method == 'local'
      run_local(full_command) { |line| yield line if block_given? }
    else
      run_remote(host, full_command) { |line| yield line if block_given? }
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

  def self.run_local(command)
    Open3.popen2e('bash', '-lc', command) do |stdin, out, wait_thr|
      stdin.close
      out.each_line { |line| yield sanitize(line) }
      wait_thr.value.exitstatus
    end
  rescue => e
    yield "[executor] local run failed: #{e.message}"
    nil
  end

  # Subprocess/SSH output isn't guaranteed to be valid UTF-8 (or even tagged
  # that way) — scrub it so a stray byte can't crash a downstream regex match.
  def self.sanitize(str)
    str.to_s.dup.force_encoding(Encoding::UTF_8).scrub.chomp
  end

  def self.run_remote(host, command)
    exit_code = nil
    Net::SSH.start(host.address, host.ssh_user, ssh_options(host).merge(timeout: 10)) do |ssh|
      ssh.open_channel do |channel|
        channel.exec("bash -lc #{Shellwords.escape(command)}") do |_ch, success|
          unless success
            yield '[executor] failed to open remote command channel'
            next
          end
          buffer = +''
          drain = lambda do
            while (idx = buffer.index("\n"))
              yield sanitize(buffer.slice!(0..idx))
            end
          end
          channel.on_data { |_, data| buffer << data; drain.call }
          channel.on_extended_data { |_, _type, data| buffer << data; drain.call }
          channel.on_request('exit-status') { |_, data| exit_code = data.read_long }
        end
      end
      ssh.loop
    end
    exit_code
  rescue => e
    yield "[executor] SSH to #{host.name} (#{host.address}) failed: #{e.message}"
    nil
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
