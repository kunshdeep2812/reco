#!/usr/bin/env ruby
# Resolves the dashboard's basic-auth credentials: explicit env vars win;
# otherwise a random password is generated once and persisted locally so
# restarts don't invalidate it. Auth is always on - there is no "run with
# no password" mode, since this dashboard can execute commands across
# every host in its pool.
require 'securerandom'
require 'fileutils'

module Credentials
  CREDENTIALS_FILE = File.expand_path('../data/admin_credentials.txt', __dir__)

  def self.resolve
    if ENV['RECO_DASHBOARD_USER'] && ENV['RECO_DASHBOARD_PASS']
      return { user: ENV['RECO_DASHBOARD_USER'], pass: ENV['RECO_DASHBOARD_PASS'], source: :env }
    end

    if File.exist?(CREDENTIALS_FILE)
      user, pass = File.read(CREDENTIALS_FILE).strip.split(':', 2)
      return { user: user, pass: pass, source: :persisted } if user && pass
    end

    user = 'admin'
    pass = SecureRandom.hex(12)
    FileUtils.mkdir_p(File.dirname(CREDENTIALS_FILE))
    File.write(CREDENTIALS_FILE, "#{user}:#{pass}\n")
    File.chmod(0600, CREDENTIALS_FILE)
    { user: user, pass: pass, source: :generated }
  end
end
