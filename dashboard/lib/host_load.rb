#!/usr/bin/env ruby
# Tracks in-process "how many tasks are currently running on this host"
# so the dispatcher can hand each new stage to whichever host is least
# busy right now, instead of blind round-robin. Round-robins among ties
# (most commonly: every host idle) so a single host doesn't get every
# stage of a fresh scan just because it sorts first.
require 'thread'

module HostLoad
  @mutex = Mutex.new
  @counts = Hash.new(0)
  @rr_index = 0

  class << self
    attr_reader :mutex
  end

  # Picks and reserves a host from `hosts` (an Array of Host rows, or
  # containing nil entries meaning "run locally"). Returns the chosen host
  # (or nil for local). Call `release` with the same value once the task
  # that used it is done.
  def self.acquire(hosts)
    mutex.synchronize do
      return nil if hosts.empty?
      key = ->(h) { h&.id || :local }
      min_count = hosts.map { |h| @counts[key.call(h)] }.min
      candidates = hosts.select { |h| @counts[key.call(h)] == min_count }
      chosen = candidates[@rr_index % candidates.length]
      @rr_index += 1
      @counts[key.call(chosen)] += 1
      chosen
    end
  end

  def self.release(host)
    key = host&.id || :local
    mutex.synchronize { @counts[key] = [@counts[key] - 1, 0].max }
  end

  def self.current_load(host)
    key = host&.id || :local
    mutex.synchronize { @counts[key] }
  end

  # Test/inspection helper.
  def self.reset!
    mutex.synchronize { @counts.clear; @rr_index = 0 }
  end
end
