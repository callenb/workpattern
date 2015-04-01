require File.dirname(__FILE__) + '/test_helper.rb'

class TestDay < MiniTest::Unit::TestCase #:nodoc:

  def setup
    @working = Workpattern::Day.new(1)
    @resting = Workpattern::Day.new(0)
  end


### creating day

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

  def test_must_be_0_minutes_after_21_19_in_rest
    assert_equal 0, @resting.minutes_remaining(clock(21,19))
  end 

  def test_must_be_0_minute_after_23_59_in_rest
    assert_equal 0, @resting.minutes_remaining(clock(23,59))
  end 

  def test_must_be_0_minutes_after_00_00_in_rest
    assert_equal 0, @resting.minutes_remaining(clock(0,0))
  end 

### rest patterns

  def test_must_rest_11_21_to_13_42
    @working.rest clock(11,21), clock(13,42)
    assert_equal 1299, @working.total, 'total minutes'
    assert_equal 618, @working.minutes_remaining(clock(11,22))
  end

  def test_must_rest_23_59
    @working.rest clock(23,59), clock(23,59)
    assert_equal 1439, @working.total, 'total minutes'
    assert_equal 1, @working.minutes_remaining(clock(23,58))
  end

### helper  
  def clock(hours,minutes)
    DateTime.new(2000,1,1,hours,minutes)
  end
end
