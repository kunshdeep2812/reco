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
end

class Finding < Sequel::Model(:findings)
  many_to_one :scan
  many_to_one :scan_task
end
