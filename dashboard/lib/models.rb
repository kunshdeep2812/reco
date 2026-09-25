#!/usr/bin/env ruby
require 'yaml'
require_relative 'db'

class Host < Sequel::Model(:hosts)
  def local?
    auth_method == 'local'
  end
end

class Target < Sequel::Model(:targets)
  one_to_many :scans
end

class Engine < Sequel::Model(:engines)
  def parsed
    YAML.safe_load(definition) || {}
  end

  def stages
    parsed['stages'] || []
  end
end

class Scan < Sequel::Model(:scans)
  many_to_one :target
  many_to_one :engine
  one_to_many :scan_tasks
  one_to_many :findings
end

class ScanTask < Sequel::Model(:scan_tasks)
  many_to_one :scan
  many_to_one :host
  many_to_one :parent_task, class: :ScanTask, key: :parent_task_id
end

class Finding < Sequel::Model(:findings)
  many_to_one :scan
  many_to_one :scan_task
end

class ScheduledScan < Sequel::Model(:scheduled_scans)
  many_to_one :target
  many_to_one :engine

  def due?(now = Time.now)
    return false unless active
    return true if next_run_at.nil?
    now >= next_run_at
  end

  def compute_next_run(from = Time.now)
    if schedule_type == 'daily'
      hh, mm = daily_at.to_s.split(':').map(&:to_i)
      candidate = Time.new(from.year, from.month, from.day, hh, mm, 0)
      candidate += 86_400 if candidate <= from
      candidate
    else
      from + (interval_minutes.to_i.positive? ? interval_minutes.to_i : 60) * 60
    end
  end
end
