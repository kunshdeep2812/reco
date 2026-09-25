#!/usr/bin/env ruby
# Background loop that launches scans for due ScheduledScan rows. One
# instance per dashboard process — this is not a distributed job queue.
require_relative 'models'
require_relative 'dispatcher'

module Scheduler
  TICK_SECONDS = 30

  def self.start!
    Thread.new { loop_forever }
  end

  def self.loop_forever
    loop do
      begin
        tick
      rescue StandardError => e
        warn "[scheduler] error: #{e.message}"
      end
      sleep TICK_SECONDS
    end
  end

  def self.tick(now = Time.now)
    ScheduledScan.where(active: true).all.select { |s| s.due?(now) }.each do |s|
      run_due(s, now)
    end
  end

  def self.run_due(scheduled, now = Time.now)
    return nil unless scheduled.target && scheduled.engine
    scan = Scan.create(target_id: scheduled.target_id, engine_id: scheduled.engine_id, status: 'queued', created_at: now)
    Dispatcher.launch(scan)
    scheduled.update(last_run_at: now, next_run_at: scheduled.compute_next_run(now))
    scan
  end
end
