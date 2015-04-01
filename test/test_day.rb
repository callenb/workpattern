require File.dirname(__FILE__) + '/test_helper.rb'

class TestDay < MiniTest::Unit::TestCase #:nodoc:

  def setup
    @working = Workpattern::Day.new(1)
  end

  def test_must_create_a_default_day_as_working
    working_day = Workpattern::Day.new()
    assert_equal (24*60), working_day.total
  end

  def test_must_create_a_working_day
    working_day = Workpattern::Day.new(1)
    assert_equal (24*60), working_day.total
  end

  def test_must_create_a_resting_day
    resting_day = Workpattern::Day.new(0)
    assert_equal 0, resting_day.total
  end

  def test_must_be_161_minutes_after_21_19
    assert_equal 161, @working.minutes_remaining(clock(21,19))
  end 

  def test_must_be_1_minute_after_23_59
    assert_equal 1, @working.minutes_remaining(clock(23,59))
  end 

  def test_must_be_1440_minutes_after_00_00
    assert_equal 1440, @working.minutes_remaining(clock(0,0))
  end 

  def clock(hours,minutes)
    DateTime.new(2000,1,1,hours,minutes)
  end
end
