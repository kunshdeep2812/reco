#!/usr/bin/env ruby
# Minimal in-memory pub/sub used to push live scan output to SSE clients.
# Per-process only: fine for a single dashboard instance (the intended
# deployment for this tool), not a multi-node broadcast bus.
require 'thread'

module Broadcaster
  @mutex = Mutex.new
  @subscribers = Hash.new { |h, k| h[k] = [] }

  class << self
    attr_reader :mutex, :subscribers
  end

  def self.subscribe(scan_id)
    q = Queue.new
    mutex.synchronize { subscribers[scan_id] << q }
    q
  end

  def self.unsubscribe(scan_id, q)
    mutex.synchronize { subscribers[scan_id]&.delete(q) }
  end

  def self.publish(scan_id, event)
    mutex.synchronize do
      (subscribers[scan_id] || []).each { |q| q << event }
    end
  end
end
