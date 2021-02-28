require File.dirname(__FILE__) + '/test_helper.rb'

class TestClock < WorkpatternTest #:nodoc:
  def setup
  end

  def test_must_create_midnight_default
    clock = Workpattern::Clock.new

    assert_equal 0, clock.minutes, 'total default minutes'
    assert_equal 0, clock.hour, 'default hour is zero'
    assert_equal 0, clock.min, 'default minute is zero'
    time = clock.time
    assert time.is_a?(DateTime), 'must return a DateTime object'
    assert_equal 0, time.hour, 'hour in the day must be zero'
    assert_equal 0, time.min, 'minute in the day must be zero'
  end

  def test_must_account_for_out_of_range_values
    clock = Workpattern::Clock.new(27, 80)

    assert_equal 1700, clock.minutes, 'total minutes'
    assert_equal 4, clock.hour, 'hour is 4'
    assert_equal 20, clock.min, 'minute is 20'
    time = clock.time
    assert time.is_a?(DateTime), 'must return a DateTime object'
    assert_equal DateTime.new(1963, 6, 10, 4, 20), time
  end
end
