require_relative 'test_helper'
require 'scheduler'

class SchedulerTest < Minitest::Test
  def setup
    TestDB.reset!
    Host.create(name: 'local', address: '127.0.0.1', auth_method: 'local', status: 'online', created_at: Time.now)
    @target = Target.create(name: 'example.com', created_at: Time.now)
    @engine = Engine.create(name: 'quick', definition: "name: quick\nstages:\n  - name: dns\n    tool: reco_dnsrecon\n", created_at: Time.now)
  end

  def test_interval_schedule_due_on_creation_then_not_until_interval_passes
    sched = ScheduledScan.create(target_id: @target.id, engine_id: @engine.id, schedule_type: 'interval',
                                  interval_minutes: 60, active: true, created_at: Time.now)
    assert sched.due?

    now = Time.now
    with_stubbed_dispatch { Scheduler.run_due(sched, now) }
    sched.refresh
    assert_equal now.to_i, sched.last_run_at.to_i
    assert_equal (now + 3600).to_i, sched.next_run_at.to_i
    refute sched.due?(now + 60)
    assert sched.due?(now + 3601)
  end

  def test_inactive_schedule_is_never_due
    sched = ScheduledScan.create(target_id: @target.id, engine_id: @engine.id, schedule_type: 'interval',
                                  interval_minutes: 5, active: false, created_at: Time.now)
    refute sched.due?
  end

  def test_daily_schedule_rolls_to_next_day_once_past
    sched = ScheduledScan.new(schedule_type: 'daily', daily_at: '03:00')
    evening = Time.new(2026, 1, 1, 20, 0, 0)
    next_run = sched.compute_next_run(evening)
    assert_equal Time.new(2026, 1, 2, 3, 0, 0), next_run
  end

  # Scheduler's own job is deciding *when* to launch a scan, not running
  # one - Dispatcher's actual execution is covered in test_dispatcher.rb.
  # Stub the launch so this doesn't spawn a real, unsupervised background
  # recon run that could still be alive when a later test wipes the DB.
  def with_stubbed_dispatch
    original = Dispatcher.singleton_class.instance_method(:launch)
    launched = []
    Dispatcher.define_singleton_method(:launch) { |scan| launched << scan; Thread.new {} }
    yield launched
  ensure
    Dispatcher.singleton_class.send(:define_method, :launch, original)
  end

  def test_tick_launches_a_scan_for_each_due_schedule
    ScheduledScan.create(target_id: @target.id, engine_id: @engine.id, schedule_type: 'interval',
                          interval_minutes: 60, active: true, created_at: Time.now)
    assert_equal 0, Scan.count
    with_stubbed_dispatch { |launched| Scheduler.tick; assert_equal 1, launched.length }
    assert_equal 1, Scan.count
  end

  def test_tick_skips_a_schedule_with_no_target
    sched = ScheduledScan.create(target_id: nil, engine_id: @engine.id, schedule_type: 'interval',
                                  interval_minutes: 60, active: true, created_at: Time.now)
    with_stubbed_dispatch { |launched| Scheduler.tick; assert_empty launched }
    assert_equal 0, Scan.count
    sched.refresh
    assert_nil sched.last_run_at
  end
end
