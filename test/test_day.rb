require File.dirname(__FILE__) + '/test_helper.rb'

class TestDay < MiniTest::Test #:nodoc:
  def setup
  end

  def test_creates_full_working_day
    myday = working_day
    assert_equal myday.total_minutes, 1440
  end

  def test_creates_non_working_day
    myday = resting_day
    assert_equal myday.total_minutes, 0
  end

  def test_when_working_minute
    myday = working_day
    assert myday.working?(0,0)
    assert myday.working?(9,0)
  end  
  
  def test_when_not_working_minute
    myday = resting_day
    assert !myday.working?(0,0)
    assert !myday.working?(9,0)
  end

  def test_when_resting_minute
    myday = resting_day
    assert myday.resting?(0,0)
    assert myday.resting?(9,0)
  end

  def test_when_not_resting_minute
    myday = working_day
    assert !myday.resting?(0,0)
    assert !myday.resting?(9,0)
  end

  def test_total_minutes_working_day
    myday = working_day
    assert myday.total_minutes, 1440
  end

  def test_total_minutes_resting_day
    myday = resting_day
    assert myday.total_minutes, 0
  end

  def test_add_rest_in_morning
    myday = working_day
    from_time = set_time(0,0)
    to_time = set_time(8,59)
    myday.set_resting(from_time, to_time)
    0.upto(8) do | hour |
      0.upto(59) do | minute |
        assert myday.resting?(hour, minute), "Failed on #{hour}:#{minute}"
      end
    end    
  end

  private

  def working_day
    Workpattern::Day.new()
  end
  def resting_day
    Workpattern::Day.new(Workpattern::HOURS_IN_DAY, Workpattern::REST_TYPE)
  end

  def set_time(hour,minute)
    Time.gm(2000,12,31,hour, minute)
  end
end
