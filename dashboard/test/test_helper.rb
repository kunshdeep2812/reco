#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'tmpdir'
require 'securerandom'

# Point every test run at its own throwaway SQLite file so the real
# dashboard/data/reco.sqlite3 (or a developer's live data) is never touched.
ENV['RECO_DB_PATH'] = File.join(Dir.mktmpdir('reco-test'), "test-#{SecureRandom.hex(4)}.sqlite3")
ENV['RECO_SECRET_KEY'] = 'test-secret-key-not-for-production'

require 'minitest/autorun'
require 'models'

module TestDB
  # Deletes in FK-safe order (children before parents) so this works
  # regardless of which other test classes ran first in the same process -
  # every test file shares one sqlite database for the whole `rake test` run.
  def self.reset!
    DB[:findings].delete
    DB[:scan_tasks].delete
    DB[:scans].delete
    DB[:scheduled_scans].delete
    DB[:engines].delete
    DB[:targets].delete
    DB[:hosts].delete
  end
end
