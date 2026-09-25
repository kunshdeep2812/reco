require_relative 'test_helper'
require 'executor'

class ExecutorTest < Minitest::Test
  def test_normal_run_captures_output_and_exit_status
    lines = []
    result = Executor.run(nil, 'echo hi; echo bye; exit 7') { |l| lines << l }
    assert_equal %w[hi bye], lines
    assert_equal 7, result.exit_status
    refute result.timed_out
    refute result.cancelled
  end

  def test_timeout_kills_the_whole_process_tree
    result = Executor.run(nil, 'sleep 20 & CHILD=$!; wait $CHILD', timeout: 1) { |_l| }
    assert result.timed_out
    refute result.cancelled
    assert_nil result.exit_status
  end

  def test_cancellation_stops_the_command
    cancel_after = Time.now + 0.5
    result = Executor.run(nil, 'sleep 20', cancel_check: -> { Time.now > cancel_after }) { |_l| }
    assert result.cancelled
    refute result.timed_out
  end

  def test_which_finds_a_known_binary_and_rejects_a_fake_one
    assert Executor.which(nil, 'ruby')
    refute Executor.which(nil, 'this-binary-should-not-exist-xyz')
  end

  def test_which_binary_nil_is_always_true
    assert Executor.which(nil, nil)
  end

  def test_env_burp_binary_check_reflects_env_vars
    orig_url, orig_key = ENV['BURP_API_URL'], ENV['BURP_API_KEY']
    ENV.delete('BURP_API_URL')
    ENV.delete('BURP_API_KEY')
    refute Executor.which(nil, :env_burp)
    ENV['BURP_API_URL'] = 'http://example.com'
    ENV['BURP_API_KEY'] = 'key'
    assert Executor.which(nil, :env_burp)
  ensure
    ENV['BURP_API_URL'] = orig_url
    ENV['BURP_API_KEY'] = orig_key
  end

  def test_sanitize_scrubs_invalid_byte_sequences
    bad = "hello \xFF\xFE world".dup.force_encoding('ASCII-8BIT')
    cleaned = Executor.sanitize(bad)
    assert cleaned.valid_encoding?
  end
end
