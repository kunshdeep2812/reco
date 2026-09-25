#!/usr/bin/env ruby
require 'sequel'
require 'fileutils'

DB_PATH = File.expand_path('../data/reco.sqlite3', __dir__)
FileUtils.mkdir_p(File.dirname(DB_PATH))

DB = Sequel.sqlite(DB_PATH, timeout: 5000)

DB.create_table?(:hosts) do
  primary_key :id
  String :name, unique: true, null: false
  String :address, null: false
  Integer :port, default: 22
  String :ssh_user, default: 'root'
  String :auth_method, default: 'key' # key | password | local
  String :key_path
  String :encrypted_password
  String :remote_path, default: '~/reco' # where the reco checkout lives on this host
  String :status, default: 'unknown' # unknown | online | offline
  DateTime :last_checked_at
  DateTime :created_at
end

DB.create_table?(:targets) do
  primary_key :id
  String :name, unique: true, null: false
  String :notes, text: true
  DateTime :created_at
end

DB.create_table?(:engines) do
  primary_key :id
  String :name, unique: true, null: false
  String :definition, text: true, null: false
  DateTime :created_at
end

DB.create_table?(:scans) do
  primary_key :id
  foreign_key :target_id, :targets
  foreign_key :engine_id, :engines
  String :status, default: 'queued' # queued | running | completed | failed | cancelled
  DateTime :started_at
  DateTime :finished_at
  DateTime :created_at
end

DB.create_table?(:scan_tasks) do
  primary_key :id
  foreign_key :scan_id, :scans
  String :stage_name, null: false
  String :tool, null: false
  foreign_key :host_id, :hosts
  String :status, default: 'queued' # queued | running | completed | failed | skipped
  String :command, text: true
  String :output, text: true, default: ''
  Integer :exit_status
  DateTime :started_at
  DateTime :finished_at
  DateTime :created_at
end

DB.create_table?(:findings) do
  primary_key :id
  foreign_key :scan_task_id, :scan_tasks
  foreign_key :scan_id, :scans
  String :kind, null: false # subdomain | ip | port | directory | vulnerability | osint | dns | other
  String :value, text: true, null: false
  String :raw, text: true
  DateTime :created_at
end
