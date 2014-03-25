require File.dirname(__FILE__) + '/test_helper.rb'

class TestDay < MiniTest::Unit::TestCase #:nodoc:

  def setup
    @working_day = Workpattern::Day.new(1)
    @resting_day = Workpattern::Day.new(0)
    @pattern_day = Workpattern::Day.new(1)
    @pattern_day.workpattern(clock(0,0),clock(8,33),0)
    @pattern_day.workpattern(clock(12,0),clock(12,21),0)
    @pattern_day.workpattern(clock(12,30),clock(12,59),0)
    @pattern_day.workpattern(clock(17,0),clock(22,59),0)
  end
  
  def test_must_create_a_working_day
    assert_equal 1440, @working_day.total,"24 hour working total minutes"
  end
    
  def test_must_ceate_a_resting_day
    assert_equal 0, @resting_day.total,"24 hour resting total minutes"
  end
  
  def test_must_set_patterns_correctly
    mins=[0,0,0,0,0,0,0,0,26,60,60,60,8,60,60,60,60,0,0,0,0,0,0,60]
    mins.each_index {|index|
      assert_equal mins[index],@pattern_day.values[index].wp_total,"#{index} hour should be #{mins[index]} minutes"
    }
    assert_equal 514, @pattern_day.total, "total working minutes"
    assert_equal 8, @pattern_day.first_hour, "first hour of the day"
    assert_equal 34, @pattern_day.first_min, "first minute of the day"
    assert_equal 23, @pattern_day.last_hour, "last hour of the day"
    assert_equal 59, @pattern_day.last_min, "last minute of the day"
  end

  def test_must_duplicate_a_working_day
    dup_day = @working_day.duplicate
    assert_equal 1440, dup_day.total
    assert_equal 0, dup_day.first_hour
    assert_equal 0, dup_day.first_min
    assert_equal 23, dup_day.last_hour
    assert_equal 59, dup_day.last_min
    hour=Workpattern::WORKING_HOUR
    dup_day.values.each {|item|
      assert_equal hour, item
    }
  end

  def test_must_duplicate_a_resting_day
    dup_day = @resting_day.duplicate
    assert_equal 0, dup_day.total
    assert_nil dup_day.first_hour
    assert_nil dup_day.first_min
    assert_nil dup_day.last_hour
    assert_nil dup_day.last_min
    hour=Workpattern::RESTING_HOUR
    dup_day.values.each {|item|
      assert_equal hour, item
    }
  end

  def test_must_duplicate_a_patterned_day
    dup_day = @pattern_day.duplicate

    mins=[0,0,0,0,0,0,0,0,26,60,60,60,8,60,60,60,60,0,0,0,0,0,0,60]
    mins.each_index {|index|
      assert_equal mins[index],dup_day.values[index].wp_total,"#{index} hour should be #{mins[index]} minutes"
    }

    assert_equal 514, dup_day.total, "total working minutes"
    assert_equal 8, dup_day.first_hour, "first hour of the day"
    assert_equal 34, dup_day.first_min, "first minute of the day"
    assert_equal 23, dup_day.last_hour, "last hour of the day"
    assert_equal 59, dup_day.last_min, "last minute of the day"

  end

  def test_must_add_more_than_available_minutes_to_a_working_day
    start_date=DateTime.new(2013,1,1,8,15)
    result, remainder=@working_day.calc(start_date,946)
    assert_equal DateTime.new(2013,1,2,0,0), result
    assert_equal 1,remainder
  end

  def test_must_add_less_than_available_minutes_to_a_working_day
    start_date=DateTime.new(2013,1,1,8,15)
    result, remainder=@working_day.calc(start_date,944)
    assert_equal DateTime.new(2013,1,1,23,59), result
    assert_equal 0,remainder
  end

  def test_must_add_exactly_the_available_minutes_to_a_working_day
    start_date=DateTime.new(2013,1,1,8,15)
    result, remainder=@working_day.calc(start_date,945)
    assert_equal DateTime.new(2013,1,2,0,0), result
    assert_equal 0,remainder
  end

  def test_must_add_zero_minutes_to_a_working_day
    start_date=DateTime.new(2013,1,1,8,15)
    result, remainder=@working_day.calc(start_date,0)
    assert_equal start_date, result
    assert_equal 0,remainder
  end

  def test_must_add_1_minute_to_0_in_working_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder=@working_day.calc(start_date,1)
    assert_equal DateTime.new(2013,1,1,0,1), result
    assert_equal 0,remainder
  end

  def test_must_add_1_hour_to_0_in_working_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder=@working_day.calc(start_date,60)
    assert_equal DateTime.new(2013,1,1,1,0), result
    assert_equal 0,remainder
  end
  
  def test_must_add_1_hour_1_minute_to_0_in_working_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder=@working_day.calc(start_date,61)
    assert_equal DateTime.new(2013,1,1,1,1), result
    assert_equal 0,remainder
  end

  def test_must_add_1_day_to_0_in_working_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder=@working_day.calc(start_date,1440)
    assert_equal DateTime.new(2013,1,2,0,0), result
    assert_equal 0,remainder
  end
 
  def test_must_add_1_day_1_minute_to_0_in_working_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder=@working_day.calc(start_date,1441)
    assert_equal DateTime.new(2013,1,2,0,0), result
    assert_equal 1,remainder
  end

  def test_must_add_more_than_available_minutes_to_a_resting_day
    start_date=DateTime.new(2013,1,1,8,15)
    result, remainder=@resting_day.calc(start_date,946)
    assert_equal DateTime.new(2013,1,2,0,0), result
    assert_equal 946,remainder
  end

  def test_must_add_less_than_available_minutes_to_a_resting_day
    start_date=DateTime.new(2013,1,1,8,15)
    result, remainder=@resting_day.calc(start_date,944)
    assert_equal DateTime.new(2013,1,2,0,0), result
    assert_equal 944,remainder
  end

  def test_must_add_exactly_the_available_minutes_to_a_resting_day
    start_date=DateTime.new(2013,1,1,8,15)
    result, remainder=@resting_day.calc(start_date,945)
    assert_equal DateTime.new(2013,1,2,0,0), result
    assert_equal 945,remainder
  end

  def test_must_add_zero_minutes_to_a_resting_day
    start_date=DateTime.new(2013,1,1,8,15)
    result, remainder=@resting_day.calc(start_date,0)
    assert_equal start_date, result
    assert_equal 0,remainder
  end

  def test_must_add_1_minute_to_0_in_resting_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder=@resting_day.calc(start_date,1)
    assert_equal DateTime.new(2013,1,2,0,0), result
    assert_equal 1,remainder
  end

  def test_must_add_1_hour_to_0_in_resting_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder=@resting_day.calc(start_date,60)
    assert_equal DateTime.new(2013,1,2,0,0), result
    assert_equal 60,remainder
  end
  
  def test_must_add_1_hour_1_minute_to_0_in_resting_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder=@resting_day.calc(start_date,61)
    assert_equal DateTime.new(2013,1,2,0,0), result
    assert_equal 61,remainder
  end

  def test_must_add_1_day_to_0_in_resting_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder=@resting_day.calc(start_date,1440)
    assert_equal DateTime.new(2013,1,2,0,0), result
    assert_equal 1440,remainder
  end
 
  def test_must_add_1_day_1_minute_to_0_in_resting_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder=@resting_day.calc(start_date,1441)
    assert_equal DateTime.new(2013,1,2,0,0), result
    assert_equal 1441,remainder
  end

  def test_must_add_more_than_available_minutes_to_a_pattern_day
    start_date=DateTime.new(2013,1,1,8,15)
    result, remainder=@pattern_day.calc(start_date,515)
    assert_equal DateTime.new(2013,1,2,0,0), result
    assert_equal 1,remainder
  end

  def test_must_add_less_than_available_minutes_to_a_pattern_day
    start_date=DateTime.new(2013,1,1,8,15)
    result, remainder=@pattern_day.calc(start_date,513)
    assert_equal DateTime.new(2013,1,1,23,59), result
    assert_equal 0,remainder
  end

  def test_must_add_exactly_the_available_minutes_to_a_pattern_day
    start_date=DateTime.new(2013,1,1,8,15)
    result, remainder=@pattern_day.calc(start_date,514)
    assert_equal DateTime.new(2013,1,2,0,0), result
    assert_equal 0,remainder
  end

  def test_must_add_zero_minutes_to_a_pattern_day
    start_date=DateTime.new(2013,1,1,8,15)
    result, remainder=@pattern_day.calc(start_date,0)
    assert_equal start_date, result
    assert_equal 0,remainder
  end

  def test_must_add_1_minute_to_0_in_pattern_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder=@pattern_day.calc(start_date,1)
    assert_equal DateTime.new(2013,1,1,8,35), result
    assert_equal 0,remainder
  end

  def test_must_add_1_hour_to_0_in_pattern_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder=@pattern_day.calc(start_date,60)
    assert_equal DateTime.new(2013,1,1,9,34), result
    assert_equal 0,remainder
  end
  
  def test_must_add_1_hour_1_minute_to_0_in_pattern_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder=@pattern_day.calc(start_date,61)
    assert_equal DateTime.new(2013,1,1,9,35), result
    assert_equal 0,remainder
  end

  def test_must_add_1_day_to_0_in_pattern_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder=@pattern_day.calc(start_date,1440)
    assert_equal DateTime.new(2013,1,2,0,0), result
    assert_equal 926,remainder
  end
 
  def test_must_add_1_day_1_minute_to_0_in_pattern_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder=@pattern_day.calc(start_date,1441)
    assert_equal DateTime.new(2013,1,2,0,0), result
    assert_equal 927,remainder
  end

  def test_must_subtract_more_than_available_minutes_in_working_day
    start_date=DateTime.new(2013,1,1,12,23)
    result, remainder, midnight=@working_day.calc(start_date,-744)
    assert_equal DateTime.new(2012,12,31,0,0), result
    assert_equal -1,remainder
    assert midnight
  end  

  def test_must_subtract_less_than_available_minutes_in_working_day
    start_date=DateTime.new(2013,1,1,12,23)
    result, remainder, midnight=@working_day.calc(start_date,-742)
    assert_equal DateTime.new(2013,1,1,0,1), result
    assert_equal 0,remainder
    refute midnight
  end  

  def test_must_subtract_available_minutes_in_working_day
    start_date=DateTime.new(2013,1,1,12,23)
    result, remainder, midnight=@working_day.calc(start_date,-743)
    assert_equal DateTime.new(2013,1,1,0,0), result
    assert_equal 0,remainder
    refute midnight
  end  

  def test_must_subtract_1_minute_from_start_of_working_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder, midnight=@working_day.calc(start_date,-1)
    assert_equal DateTime.new(2012,12,31,0,0), result
    assert_equal -1,remainder
    assert midnight
  end  

  def test_must_subtract_1_minute_from_start_of_next_working_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder, midnight=@working_day.calc(start_date,-1,true)
    assert_equal DateTime.new(2013,1,1,23,59), result
    assert_equal 0,remainder
    refute midnight
  end  

  def test_must_subtract_1_day_from_start_of_next_working_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder, midnight=@working_day.calc(start_date,-1440,true)
    assert_equal DateTime.new(2013,1,1,0,0), result
    assert_equal 0,remainder
    refute midnight
  end  
   
  def test_must_subtract_1_from_zero_minutes_from_resting_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder, midnight=@resting_day.calc(start_date,-1,true)
    assert_equal DateTime.new(2012,12,31,0,0), result
    assert_equal -1,remainder
    assert midnight
  end

  def test_must_subtract_1_from_resting_day
    start_date=DateTime.new(2013,1,1,4,13)
    result, remainder, midnight=@resting_day.calc(start_date,-1,true)
    assert_equal DateTime.new(2012,12,31,0,0), result
    assert_equal -1,remainder
    assert midnight
  end

  def test_must_subtract_1_from_zero_minutes_from_resting_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder, midnight=@resting_day.calc(start_date,-1,false)
    assert_equal DateTime.new(2012,12,31,0,0), result
    assert_equal -1,remainder
    assert midnight
  end

  def test_must_subtract_1_from_somewhere_in_resting_day
    start_date=DateTime.new(2013,1,1,4,13)
    result, remainder, midnight=@resting_day.calc(start_date,-1,false)
    assert_equal DateTime.new(2012,12,31,0,0), result
    assert_equal -1,remainder
    assert midnight
  end

  def test_must_subtract_more_than_available_minutes_in_patterned_day
    start_date=DateTime.new(2013,1,1,12,23)
    result, remainder, midnight=@pattern_day.calc(start_date,-208)
    assert_equal DateTime.new(2012,12,31,0,0), result
    assert_equal -1,remainder
    assert midnight
  end  

  def test_must_subtract_less_than_available_minutes_in_patterned_day
    start_date=DateTime.new(2013,1,1,12,23)
    result, remainder, midnight=@pattern_day.calc(start_date,-206)
    assert_equal DateTime.new(2013,1,1,8,35), result
    assert_equal 0,remainder
    refute midnight
  end  

  def test_must_subtract_available_minutes_in_patterned_day
    start_date=DateTime.new(2013,1,1,12,23)
    result, remainder, midnight=@pattern_day.calc(start_date,-207)
    assert_equal DateTime.new(2013,1,1,8,34), result
    assert_equal 0,remainder
    refute midnight
  end  

  def test_must_subtract_1_minute_from_start_of_patterned_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder, midnight=@pattern_day.calc(start_date,-1)
    assert_equal DateTime.new(2012,12,31,0,0), result
    assert_equal -1,remainder
    assert midnight
  end  

  def test_must_subtract_1_minute_from_start_of_next_patterned_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder, midnight=@pattern_day.calc(start_date,-1,true)
    assert_equal DateTime.new(2013,1,1,23,59), result
    assert_equal 0,remainder
    refute midnight
  end  

  def test_must_subtract_1_day_from_start_of_next_patterned_day
    start_date=DateTime.new(2013,1,1,0,0)
    result, remainder, midnight=@pattern_day.calc(start_date,-514,true)
    assert_equal DateTime.new(2013,1,1,8,34), result
    assert_equal 0,remainder
    refute midnight
  end  

  def test_must_return_0_difference_between_same_time_in_working_day
    start_date=DateTime.new(2013,1,1,8,32)
    difference,result_date=@working_day.diff(start_date,start_date)
    assert_equal 0, difference
    assert_equal start_date, result_date
  end

  def test_must_return_difference_to_end_of_day_using_different_days_in_working_day
    start_date=DateTime.new(2013,1,1,23,30)
    finish_date=DateTime.new(2013,1,2,8,1)
    difference,result_date=@working_day.diff(start_date,finish_date)
    assert_equal 30, difference
    assert_equal DateTime.new(2013,1,2,0,0), result_date
  end

  def test_must_return_difference_to_from_start_of_day_to_end_of_day_using_different_days_in_working_day
    start_date=DateTime.new(2013,1,1,0,0)
    finish_date=DateTime.new(2013,1,2,8,1)
    difference,result_date=@working_day.diff(start_date,finish_date)
    assert_equal 1440, difference
    assert_equal DateTime.new(2013,1,2,0,0), result_date
  end

  def test_must_return_difference_from_start_of_day_in_working_day
    start_date=DateTime.new(2013,1,1,0,0)
    finish_date=DateTime.new(2013,1,1,3,1)
    difference,result_date=@working_day.diff(start_date,finish_date)
    assert_equal 181, difference
    assert_equal finish_date, result_date
  end

  def test_must_return_difference_between_two_times_in_working_day
    start_date=DateTime.new(2013,1,1,2,11)
    finish_date=DateTime.new(2013,1,1,9,15)
    difference,result_date=@working_day.diff(start_date,finish_date)
    assert_equal 424, difference
    assert_equal finish_date, result_date
  end

  def test_must_return_0_difference_between_same_time_in_resting_day
    start_date=DateTime.new(2013,1,1,8,32)
    difference,result_date=@resting_day.diff(start_date,start_date)
    assert_equal 0, difference
    assert_equal start_date, result_date
  end

  def test_must_return_difference_to_end_of_day_using_different_days_in_resting_day
    start_date=DateTime.new(2013,1,1,23,30)
    finish_date=DateTime.new(2013,1,2,8,1)
    difference,result_date=@resting_day.diff(start_date,finish_date)
    assert_equal 0, difference
    assert_equal DateTime.new(2013,1,2,0,0), result_date
  end

  def test_must_return_difference_to_from_start_of_day_to_end_of_day_using_different_days_in_resting_day
    start_date=DateTime.new(2013,1,1,0,0)
    finish_date=DateTime.new(2013,1,2,8,1)
    difference,result_date=@resting_day.diff(start_date,finish_date)
    assert_equal 0, difference
    assert_equal DateTime.new(2013,1,2,0,0), result_date
  end

  def test_must_return_difference_from_start_of_day_in_resting_day
    start_date=DateTime.new(2013,1,1,0,0)
    finish_date=DateTime.new(2013,1,1,3,1)
    difference,result_date=@resting_day.diff(start_date,finish_date)
    assert_equal 0, difference
    assert_equal finish_date, result_date
  end

  def test_must_return_difference_between_two_times_in_resting_day
    start_date=DateTime.new(2013,1,1,2,11)
    finish_date=DateTime.new(2013,1,1,9,15)
    difference,result_date=@resting_day.diff(start_date,finish_date)
    assert_equal 0, difference
    assert_equal finish_date, result_date
  end
  
####

  def test_must_return_0_difference_between_same_working_time_in_patterned_day
    start_date=DateTime.new(2013,1,1,8,34)
    difference,result_date=@pattern_day.diff(start_date,start_date)
    assert_equal 0, difference
    assert_equal start_date, result_date
  end

  def test_must_return_0_difference_between_same_resting_time_in_patterned_day
    start_date=DateTime.new(2013,1,1,8,32)
    difference,result_date=@pattern_day.diff(start_date,start_date)
    assert_equal 0, difference
    assert_equal start_date, result_date
  end

  def test_must_return_difference_to_end_of_day_from_working_time_using_different_days_in_patterned_day
    start_date=DateTime.new(2013,1,1,12,23)
    finish_date=DateTime.new(2013,1,2,8,1)
    difference,result_date=@pattern_day.diff(start_date,finish_date)
    assert_equal 307, difference
    assert_equal DateTime.new(2013,1,2,0,0), result_date
  end

  def test_must_return_difference_to_end_of_day_from_resting_time_using_different_days_in_patterned_day
    start_date=DateTime.new(2013,1,1,12,10)
    finish_date=DateTime.new(2013,1,2,8,1)
    difference,result_date=@pattern_day.diff(start_date,finish_date)
    assert_equal 308, difference
    assert_equal DateTime.new(2013,1,2,0,0), result_date
  end

  def test_must_return_difference_to_from_start_of_day_to_end_of_day_using_different_days_in_pattern_day
    start_date=DateTime.new(2013,1,1,0,0)
    finish_date=DateTime.new(2013,1,2,8,1)
    difference,result_date=@pattern_day.diff(start_date,finish_date)
    assert_equal 514, difference
    assert_equal DateTime.new(2013,1,2,0,0), result_date
  end

  def test_must_return_difference_from_start_of_day_in_pattern_day
    start_date=DateTime.new(2013,1,1,0,0)
    finish_date=DateTime.new(2013,1,1,11,1)
    difference,result_date=@pattern_day.diff(start_date,finish_date)
    assert_equal 147, difference
    assert_equal finish_date, result_date
  end

  def test_must_return_difference_between_two_working_times_in_pattern_day
    start_date=DateTime.new(2013,1,1,8,45)
    finish_date=DateTime.new(2013,1,1,12,26)
    difference,result_date=@pattern_day.diff(start_date,finish_date)
    assert_equal 199, difference
    assert_equal finish_date, result_date
  end

  def test_must_return_difference_between_two_resting_times_in_pattern_day
    start_date=DateTime.new(2013,1,1,8,20)
    finish_date=DateTime.new(2013,1,1,12,40)
    difference,result_date=@pattern_day.diff(start_date,finish_date)
    assert_equal 214, difference
    assert_equal finish_date, result_date
  end

  def test_must_return_difference_between_working_and_resting_times_in_pattern_day
    start_date=DateTime.new(2013,1,1,8,45)
    finish_date=DateTime.new(2013,1,1,12,40)
    difference,result_date=@pattern_day.diff(start_date,finish_date)
    assert_equal 203, difference
    assert_equal finish_date, result_date
  end

  def test_must_return_difference_between_resting_and_working_times_in_pattern_day
    start_date=DateTime.new(2013,1,1,12,15)
    finish_date=DateTime.new(2013,1,1,23,30)
    difference,result_date=@pattern_day.diff(start_date,finish_date)
    assert_equal 278, difference
    assert_equal finish_date, result_date
  end
  
  private
  
  def clock(hour,min)
    return Workpattern.clock(hour,min)
  end 
end

