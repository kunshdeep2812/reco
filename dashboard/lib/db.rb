#!/usr/bin/env ruby
require 'sequel'
require 'fileutils'

DB_PATH = ENV['RECO_DB_PATH'] || File.expand_path('../data/reco.sqlite3', __dir__)
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
  TrueClass :cancel_requested, default: false
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
  foreign_key :parent_task_id, :scan_tasks # set when this task was fanned out via chain_from
  String :target_value, text: true # the actual target this task ran against
  String :status, default: 'queued' # queued | running | completed | failed | skipped | cancelled | timeout
  String :command, text: true
  String :output, text: true, default: ''
  Integer :exit_status
  Integer :pid # local child process id, used to kill on cancel/timeout
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

DB.create_table?(:scheduled_scans) do
  primary_key :id
  foreign_key :target_id, :targets
  foreign_key :engine_id, :engines
  String :schedule_type, default: 'interval' # interval | daily
  Integer :interval_minutes
  String :daily_at # "HH:MM", used when schedule_type == 'daily'
  TrueClass :active, default: true
  DateTime :last_run_at
  DateTime :next_run_at
  DateTime :created_at
end

# Additive migrations for databases created before these columns/tables
# existed - safe to run every boot.
existing_scan_columns = DB[:scans].columns
DB.alter_table(:scans) { add_column :cancel_requested, TrueClass, default: false } unless existing_scan_columns.include?(:cancel_requested)

existing_task_columns = DB[:scan_tasks].columns
DB.alter_table(:scan_tasks) do
  add_foreign_key :parent_task_id, :scan_tasks unless existing_task_columns.include?(:parent_task_id)
  add_column :target_value, String, text: true unless existing_task_columns.include?(:target_value)
  add_column :pid, Integer unless existing_task_columns.include?(:pid)
end
