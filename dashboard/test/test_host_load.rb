require_relative 'test_helper'
require 'host_load'

class HostLoadTest < Minitest::Test
  FakeHost = Struct.new(:id)

  def setup
    HostLoad.reset!
  end

  def test_spreads_evenly_across_idle_hosts
    hosts = [FakeHost.new(1), FakeHost.new(2), FakeHost.new(3)]
    picks = 6.times.map { HostLoad.acquire(hosts) }
    counts = picks.group_by(&:id).transform_values(&:count)
    assert_equal({ 1 => 2, 2 => 2, 3 => 2 }, counts)
  end

  def test_prefers_the_host_with_fewer_active_tasks
    a = FakeHost.new(1)
    b = FakeHost.new(2)
    HostLoad.acquire([b]) # b now has 2 active tasks, a has 0
    HostLoad.acquire([b])
    HostLoad.acquire([a]) # a now has 1 active task
    picked = HostLoad.acquire([a, b]) # a: 1 < b: 2, unambiguous
    assert_equal a.id, picked.id
  end

  def test_acquire_on_empty_pool_returns_nil
    assert_nil HostLoad.acquire([])
  end

  def test_release_never_goes_negative
    host = FakeHost.new(1)
    HostLoad.release(host)
    HostLoad.release(host)
    assert_equal 0, HostLoad.current_load(host)
  end

  def test_nil_host_tracked_as_local
    picked = HostLoad.acquire([nil])
    assert_nil picked
    assert_equal 1, HostLoad.current_load(nil)
  end
end
