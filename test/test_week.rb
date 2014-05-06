require File.dirname(__FILE__) + '/test_helper.rb'

class TestWeek < MiniTest::Unit::TestCase #:nodoc:

  def setup
    start=DateTime.new(2000,1,3)
    finish=DateTime.new(2000,1,9)

    @working_week=Workpattern::Week.new(start,finish,1)

    @resting_week=Workpattern::Week.new(start,finish,0)

    @pattern_week=Workpattern::Week.new(start,finish,1)
    @pattern_week.workpattern(:weekend,Workpattern.clock(0,0),Workpattern.clock(23,59),0)
    @pattern_week.workpattern(:weekday,Workpattern.clock(0,0),Workpattern.clock(8,59),0)
    @pattern_week.workpattern(:weekday,Workpattern.clock(12,30),Workpattern.clock(13,0),0)
    @pattern_week.workpattern(:weekday,Workpattern.clock(17,0),Workpattern.clock(23,59),0)

  end

  def no_test_must_diff_from_last_day_of_patterned_week
    #issue 15
    start=DateTime.new(2013,9,23,0,0)
    finish=DateTime.new(2013,9,26,23,59)
    working_week=week(start,finish,1)
    working_week.workpattern :all, Workpattern.clock(0,0),Workpattern.clock(8,59),0
    working_week.workpattern :all, Workpattern.clock(12,0),Workpattern.clock(12,59),0
    working_week.workpattern :all, Workpattern.clock(18,0),Workpattern.clock(23,59),0

    duration, start =working_week.diff(DateTime.civil(2013,9,26,17,0),DateTime.civil(2013,9,27,10,0))

    assert_equal 60, duration
    assert_equal DateTime.civil(2013,9,27,0,0), start
  end

  def test_must_create_a_working_week
    start=DateTime.new(2000,1,1,11,3)
    finish=DateTime.new(2005,12,31,16,41)
    working_week=week(start,finish,1)
    assert_equal DateTime.new(start.year,start.month,start.day), working_week.start
    assert_equal DateTime.new(finish.year,finish.month,finish.day), working_week.finish
    assert_equal 3156480, working_week.total #2192 days
  end

  def test_create_working_week_of_3_concecutive_days
    start=DateTime.new(2000,1,2,11,3) # Sunday
    finish=DateTime.new(2000,1,4,16,41) # Tuesday
    working_week=week(start,finish,1)
    assert_equal DateTime.new(start.year,start.month,start.day), working_week.start
    assert_equal DateTime.new(finish.year,finish.month,finish.day), working_week.finish
    assert_equal 1440 * 3, working_week.total #3 days
  end

  def test_create_working_week_f_to_Su
    start=DateTime.new(2000,1,7,11,3) # Friday
    finish=DateTime.new(2000,1,9,16,41) # Sunday
    working_week=week(start,finish,1)
    assert_equal DateTime.new(start.year,start.month,start.day), working_week.start
    assert_equal DateTime.new(finish.year,finish.month,finish.day), working_week.finish
    assert_equal 1440 * 3, working_week.total #3 days
  end

  def test_create_working_week_Th_to_Su
    start=DateTime.new(2000,1,6,11,3) # Thursday
    finish=DateTime.new(2000,1,8,16,41) # Sunday
    working_week=week(start,finish,1)
    assert_equal DateTime.new(start.year,start.month,start.day), working_week.start
    assert_equal DateTime.new(finish.year,finish.month,finish.day), working_week.finish
    assert_equal 1440 * 3, working_week.total #3 days
  end

  def test_must_create_a_resting_week
    start=DateTime.new(2000,1,1,11,3)
    finish=DateTime.new(2005,12,31,16,41)
    resting_week=week(start,finish,0)
    assert_equal DateTime.new(start.year,start.month,start.day), resting_week.start
    assert_equal DateTime.new(finish.year,finish.month,finish.day), resting_week.finish
    assert_equal 0, resting_week.total#2192
    assert_equal 0,resting_week.week_total
  end

  def test_must_duplicate_all_of_a_week
    start=DateTime.new(2000,1,1,11,3)
    finish=DateTime.new(2005,12,31,16,41)
    week=week(start,finish,1)
    new_week=week.duplicate
    assert_equal DateTime.new(start.year,start.month,start.day), new_week.start
    assert_equal DateTime.new(finish.year,finish.month,finish.day), new_week.finish
    assert_equal 3156480, new_week.total#2192
    week.workpattern(:weekend,Workpattern.clock(0,0),Workpattern.clock(23,59),0)
    assert_equal 3156480, new_week.total#2192
  end

  def test_must_set_week_pattern_correctly
    start=DateTime.new(2000,1,3)
    finish=DateTime.new(2000,1,9)

    pattern_week=Workpattern::Week.new(start,finish,1)
    assert_equal start, pattern_week.start
    assert_equal finish, pattern_week.finish
    assert_equal 10080, pattern_week.week_total
    pattern_week.workpattern(:weekend,Workpattern.clock(0,0),Workpattern.clock(23,59),0)
    assert_equal 7200, pattern_week.week_total
    pattern_week.workpattern(:weekday,Workpattern.clock(0,0),Workpattern.clock(8,59),0)
    assert_equal 4500, pattern_week.week_total
    pattern_week.workpattern(:weekday,Workpattern.clock(12,30),Workpattern.clock(13,0),0)
    assert_equal 4345, pattern_week.week_total
    pattern_week.workpattern(:weekday,Workpattern.clock(17,0),Workpattern.clock(23,59),0)
    assert_equal 2245, pattern_week.week_total
  end

  def test_must_set_patterns_correctly
    start=DateTime.new(2000,1,1,0,0)
    finish=DateTime.new(2005,12,31,8,59)
    working_week=week(start,finish,1)
    assert_equal 10080, working_week.week_total
    working_week.workpattern(:all,start,finish,0)
    assert_equal 6300, working_week.week_total
    working_week.workpattern(:sun,start,finish,1)
    assert_equal 6840, working_week.week_total 
    working_week.workpattern(:mon,start,finish,1)
    assert_equal 7380, working_week.week_total 
    working_week.workpattern(:all,clock(18,0),clock(18,19),0)
    assert_equal 7240, working_week.week_total 
    working_week.workpattern(:all,clock(0,0),clock(23,59),0)
    assert_equal 0, working_week.week_total
    working_week.workpattern(:all,clock(0,0),clock(0,0),1)
    assert_equal 7, working_week.week_total
    working_week.workpattern(:all,clock(23,59),clock(23,59),1)
    assert_equal 14, working_week.week_total
    working_week.workpattern(:all,clock(0,0),clock(23,59),1)
    assert_equal 10080, working_week.week_total
    working_week.workpattern(:weekend,clock(0,0),clock(23,59),0)
    assert_equal 7200, working_week.week_total    
  end

  def test_must_add_minutes_in_a_working_week_result_in_same_day
    result_date, result_duration, midnight_flag = @working_week.calc(DateTime.new(2000,1,3,7,31),29)
    assert_equal DateTime.new(2000,1,3,8,0), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def test_must_add_minutes_in_a_working_week_result_in_next_day
    result_date, result_duration, midnight_flag = @working_week.calc(DateTime.new(2000,1,3,7,31),990)
    assert_equal DateTime.new(2000,1,4,0,1), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def test_must_add_minutes_in_a_working_week_result_in_later_day
    result_date, result_duration, midnight_flag = @working_week.calc(DateTime.new(2000,1,3,7,31),2430)
    assert_equal DateTime.new(2000,1,5,0,1), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def test_must_add_minutes_in_a_working_week_result_in_start_next_day
    result_date, result_duration, midnight_flag = @working_week.calc(DateTime.new(2000,1,3,7,31),989)
    assert_equal DateTime.new(2000,1,4,0,0), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def test_must_add_0_minutes_in_a_working_week
    result_date, result_duration, midnight_flag = @working_week.calc(DateTime.new(2000,1,3,7,31),0)
    assert_equal DateTime.new(2000,1,3,7,31), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def test_must_add_too_many_minutes_in_a_working_week
    result_date, result_duration, midnight_flag = @working_week.calc(DateTime.new(2000,1,3,7,31),9630)
    assert_equal DateTime.new(2000,1,10,0,0), result_date
    refute midnight_flag
    assert_equal 1, result_duration
  end

  def test_must_add_minutes_in_a_resting_week
    result_date, result_duration, midnight_flag = @resting_week.calc(DateTime.new(2000,1,3,7,31),29)
    assert_equal DateTime.new(2000,1,10,0,0), result_date
    refute midnight_flag
    assert_equal 29, result_duration
  end

  def test_must_add_minutes_from_start_of_resting_week
    result_date, result_duration, midnight_flag = @resting_week.calc(DateTime.new(2000,1,3,0,0),990)
    assert_equal DateTime.new(2000,1,10,0,0), result_date
    refute midnight_flag
    assert_equal 990, result_duration
  end

  def test_must_add_minutes_to_last_minute_of_a_resting_week
    result_date, result_duration, midnight_flag = @resting_week.calc(DateTime.new(2000,1,9,23,59),2430)
    assert_equal DateTime.new(2000,1,10,0,0), result_date
    refute midnight_flag
    assert_equal 2430, result_duration
  end

  def test_must_add_zero_minutes_in_a_resting_week
    result_date, result_duration, midnight_flag = @resting_week.calc(DateTime.new(2000,1,3,7,31),0)
    assert_equal DateTime.new(2000,1,3,7,31), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def test_must_add_minutes_from_working_in_a_pattern_week_result_in_same_day
    result_date, result_duration, midnight_flag = @pattern_week.calc(DateTime.new(2000,1,3,10,11),110)
    assert_equal DateTime.new(2000,1,3,12,1), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def no_test_must_add_minutes_from_resting_in_a_pattern_week_result_in_same_day
    result_date, result_duration, midnight_flag = @pattern_week.calc(DateTime.new(2000,1,3,12,45),126)
    assert_equal DateTime.new(2000,1,3,15,7), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def no_test_must_add_minutes_from_working_in_a_pattern_week_result_in_next_day
    result_date, result_duration, midnight_flag = @pattern_week.calc(DateTime.new(2000,1,3,10,11),379)
    assert_equal DateTime.new(2000,1,4,9,1), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def no_test_must_add_minutes_from_resting_in_a_pattern_week_result_in_next_day
    result_date, result_duration, midnight_flag = @pattern_week.calc(DateTime.new(2000,1,3,12,45),240)
    assert_equal DateTime.new(2000,1,4,9,1), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def no_test_must_add_minutes_from_working_in_a_working_week_result_in_later_day
    result_date, result_duration, midnight_flag = @pattern_week.calc(DateTime.new(2000,1,3,10,11),828)
    assert_equal DateTime.new(2000,1,5,9,1), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def no_test_must_add_minutes_from_resting_in_a_working_week_result_in_later_day
    result_date, result_duration, midnight_flag = @pattern_week.calc(DateTime.new(2000,1,3,12,45),689)
    assert_equal DateTime.new(2000,1,5,9,1), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end
### infinity bug  
  def no_test_must_add_0_minutes_from_working_in_a_resting_week
    result_date, result_duration, midnight_flag = @pattern_week.calc(DateTime.new(2000,1,3,10,11),0)
    assert_equal DateTime.new(2000,1,3,10,11), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end
### infinity bug  
  def no_test_must_add_0_minutes_from_resting_in_a_resting_week
    result_date, result_duration, midnight_flag = @pattern_week.calc(DateTime.new(2000,1,3,12,45),0)
    assert_equal DateTime.new(2000,1,3,12,45), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def no_test_must_add_too_many_minutes_in_a_pattern__week
    result_date, result_duration, midnight_flag = @pattern_week.calc(DateTime.new(2000,1,3,10,11),2175)
    assert_equal DateTime.new(2000,1,10,0,0), result_date
    refute midnight_flag
    assert_equal 1, result_duration
  end

  def no_test_must_subtract_minutes_in_a_working_week_result_in_same_day
    result_date, result_duration, midnight_flag = @working_week.calc(DateTime.new(2000,1,8,7,31),-29)
    assert_equal DateTime.new(2000,1,8,7,2), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def no_test_must_subtract_minutes_in_a_working_week_result_in_previous_day
    result_date, result_duration, midnight_flag = @working_week.calc(DateTime.new(2000,1,8,7,31),-452)
    assert_equal DateTime.new(2000,1,7,23,59), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def no_test_must_subtract_minutes_in_a_working_week_result_in_earlier_day
    result_date, result_duration, midnight_flag = @working_week.calc(DateTime.new(2000,1,8,7,31),-1892)
    assert_equal DateTime.new(2000,1,6,23,59), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def no_test_must_subtract_minutes_in_a_working_week_result_at_start_of_day
    result_date, result_duration, midnight_flag = @working_week.calc(DateTime.new(2000,1,8,7,31),-451)
    assert_equal DateTime.new(2000,1,8,0,0), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def no_test_must_subtract_minutes_in_a_working_week_result_at_start_of_previous_day
    result_date, result_duration, midnight_flag = @working_week.calc(DateTime.new(2000,1,8,7,31),-1891)
    assert_equal DateTime.new(2000,1,7,0,0), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def no_test_must_subtract_too_many_minutes_from_a_working_week
    result_date, result_duration, midnight_flag = @working_week.calc(DateTime.new(2000,1,8,7,31),-7652)
    assert_equal DateTime.new(2000,1,2,0,0), result_date
    assert midnight_flag
    assert_equal -1, result_duration
  end

  def no_test_must_subtract_1_minute_from_start_of_next_day_after_working_week
    result_date, result_duration, midnight_flag = @working_week.calc(DateTime.new(2000,1,9,0,0),-1,true)
    assert_equal DateTime.new(2000,1,9,23,59), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def no_test_must_subtract_2_minutes_from_start_of_next_day_after_working_week
    result_date, result_duration, midnight_flag = @working_week.calc(DateTime.new(2000,1,9,0,0),-2,true)
    assert_equal DateTime.new(2000,1,9,23,58), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def no_test_must_subtract_minutes_from_last_day_in_a_resting_week
    result_date, result_duration, midnight_flag = @resting_week.calc(DateTime.new(2000,1,10,7,31),-29)
    assert_equal DateTime.new(2000,1,2,0,0), result_date
    assert midnight_flag
    assert_equal -29, result_duration
  end

  def no_test_must_subtract_minutes_from_middle_day_in_a_resting_week
    result_date, result_duration, midnight_flag = @resting_week.calc(DateTime.new(2000,1,8,7,31),-452)
    assert_equal DateTime.new(2000,1,2,0,0), result_date
    assert midnight_flag
    assert_equal -452, result_duration
  end

  def no_test_must_subtract_minutes_from_start_of_resting_week
    result_date, result_duration, midnight_flag = @resting_week.calc(DateTime.new(2000,1,3,0,0),-1892)
    assert_equal DateTime.new(2000,1,2,0,0), result_date
    assert midnight_flag
    assert_equal -1892, result_duration
  end

  def no_test_must_subtract_minutes_from_start_of_next_day_after_resting_week
    result_date, result_duration, midnight_flag = @resting_week.calc(DateTime.new(2000,1,9,0,0),-1,true)
    assert_equal DateTime.new(2000,1,2,0,0), result_date
    assert midnight_flag
    assert_equal -1, result_duration
  end
  
  def no_test_must_subtract_minutes_from_resting_day_in_a_pattern_week
    result_date, result_duration, midnight_flag = @pattern_week.calc(DateTime.new(2000,1,8,13,29),-29)
    assert_equal DateTime.new(2000,1,7,16,31), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def no_test_must_subtract_minutes_from_working_day_in_a_pattern_week
    result_date, result_duration, midnight_flag = @pattern_week.calc(DateTime.new(2000,1,7,13,29),-29)
    assert_equal DateTime.new(2000,1,7,12,29), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def no_test_must_subtract_minutes_in_a_pattern_week_result_in_previous_day
    result_date, result_duration, midnight_flag = @pattern_week.calc(DateTime.new(2000,1,7,9,1),-2)
    assert_equal DateTime.new(2000,1,6,16,59), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def no_test_must_subtract_minutes_in_a_pattern_week_result_in_earlier_day
    result_date, result_duration, midnight_flag = @pattern_week.calc(DateTime.new(2000,1,7,13,29),-240)
    assert_equal DateTime.new(2000,1,6,16,58), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def no_test_must_subtract_minutes_in_a_pattern_week_result_at_start_of_day
    result_date, result_duration, midnight_flag = @pattern_week.calc(DateTime.new(2000,1,7,13,29),-238)
    assert_equal DateTime.new(2000,1,7,9,0), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def no_test_must_subtract_minutes_in_a_pattern_week_result_at_start_of_previous_day
    result_date, result_duration, midnight_flag = @pattern_week.calc(DateTime.new(2000,1,7,13,29),-687)
    assert_equal DateTime.new(2000,1,6,9,0), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def no_test_must_subtract_too_many_minutes_from_a_pattern_week
    result_date, result_duration, midnight_flag = @pattern_week.calc(DateTime.new(2000,1,7,9,0),-1797)
    assert_equal DateTime.new(2000,1,2,0,0), result_date
    assert midnight_flag
    assert_equal -1, result_duration
  end

  def no_test_must_subtract_1_minute_from_start_of_next_day_after_pattern_week
    result_date, result_duration, midnight_flag = @pattern_week.calc(DateTime.new(2000,1,9,0,0),-1,true)
    assert_equal DateTime.new(2000,1,7,16,59), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

  def no_test_must_subtract_2_minutes_from_start_of_next_day_after_pattern_week
    result_date, result_duration, midnight_flag = @pattern_week.calc(DateTime.new(2000,1,9,0,0),-2,true)
    assert_equal DateTime.new(2000,1,7,16,58), result_date
    refute midnight_flag
    assert_equal 0, result_duration
  end

######################################################
#    start=DateTime.new(2000,1,3)
#    finish=DateTime.new(2000,1,9)
#
#    @pattern_week=Workpattern::Week.new(start,finish,1)
#    @pattern_week.workpattern(:weekend,Workpattern.clock(0,0),Workpattern.clock(23,59),0)
#    @pattern_week.workpattern(:weekday,Workpattern.clock(0,0),Workpattern.clock(8,59),0)
#    @pattern_week.workpattern(:weekday,Workpattern.clock(12,30),Workpattern.clock(13,0),0)
#    @pattern_week.workpattern(:weekday,Workpattern.clock(17,0),Workpattern.clock(23,59),0)

### @pattern_week centric

  
  def no_test_must_calculate_difference_between_dates_in_working_week
    late_date=DateTime.new(2000,1,6,9,32)
    early_date=DateTime.new(2000,1,6,8,20)
    result_dur, result_date = @working_week.diff(early_date,late_date)
    assert_equal 72, result_dur
    assert_equal late_date, result_date
  end

  def no_test_must_calculate_difference_between_dates_in_resting_week
    late_date=DateTime.new(2000,1,6,9,32)
    early_date=DateTime.new(2000,1,6,8,20)
    result_dur, result_date = @resting_week.diff(early_date,late_date)
    assert_equal 0, result_dur
    assert_equal late_date, result_date
  end

  def no_test_must_calculate_difference_between_dates_in_pattern_week
    late_date=DateTime.new(2000,1,6,13,1)
    early_date=DateTime.new(2000,1,6,12,29)
    result_dur, result_date = @pattern_week.diff(early_date,late_date)
    assert_equal 1, result_dur
    assert_equal late_date, result_date
  end
  
  private
  
  def week(start,finish,type)
    return Workpattern::Week.new(start,finish,type)
  end 
  
  def clock(hour,min)
    return Workpattern.clock(hour,min)
  end 
end
