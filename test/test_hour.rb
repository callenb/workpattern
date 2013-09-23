require File.dirname(__FILE__) + '/test_helper.rb'

class TestHour < MiniTest::Unit::TestCase #:nodoc:

  def setup
    @working_hour = Workpattern::WORKING_HOUR
    @resting_hour = Workpattern::RESTING_HOUR
    @pattern_hour = @working_hour
    @pattern_hour = @pattern_hour.wp_workpattern(0,0,0)
    @pattern_hour = @pattern_hour.wp_workpattern(59,59,0)
    @pattern_hour = @pattern_hour.wp_workpattern(11,30,0)

  end
  
  def test_for_default_working_hour_of_60_minutes
    assert_equal 60, @working_hour.wp_total,"working total minutes"
    assert_equal 0, @working_hour.wp_first,"first minute of the working hour"
    assert_equal 59, @working_hour.wp_last, "last minute of the working hour"
  end

  def test_for_default_resting_hour_of_0_minutes
    assert_equal 0, @resting_hour.wp_total,"resting total minutes"
    assert_equal nil, @resting_hour.wp_first,"first minute of the resting hour"
    assert_equal nil, @resting_hour.wp_last, "last minute of the resting hour"
  end

  def test_for_creating_a_workpattern_in_an_hour
    assert_equal 38,@pattern_hour.wp_total, "total working minutes in pattern"
    assert_equal 1, @pattern_hour.wp_first, "first minute of the pattern hour"
    assert_equal 58, @pattern_hour.wp_last, "last minute of the pattern hour"
    refute @pattern_hour.wp_working?(0)
    assert @pattern_hour.wp_working?(1)
  end
 
  def test_for_creating_8_33_that_failed_in_test_day
    test_hour=@working_hour.wp_workpattern(0,33,0)
    assert_equal 26, test_hour.wp_total
  end 

  def test_can_add_more_than_the_available_minutes_in_a_working_hour
    start_date=DateTime.new(2013,1,1,1,8)
    result, remainder=@working_hour.wp_calc(start_date,53)
    assert_equal DateTime.new(2013,1,1,2,0), result
    assert_equal 1,remainder
  end

  def test_can_add_exact_amount_of_available_minutes_in_working_hour
    start_date=DateTime.new(2013,1,1,1,8)
    result, remainder=@working_hour.wp_calc(start_date,52)
    assert_equal DateTime.new(2013,1,1,2,0), result
    assert_equal 0,remainder
  end

  def test_can_add_when_more_available_minutes_in_working_hour
    start_date=DateTime.new(2013,1,1,1,8)
    result, remainder=@working_hour.wp_calc(start_date,51)
    assert_equal DateTime.new(2013,1,1,1,59), result
    assert_equal 0,remainder
  end
  
  def test_can_add_1_minute_to_59_seconds_in_working_hour
    start_date=DateTime.new(2013,1,1,1,59)
    result, remainder=@working_hour.wp_calc(start_date,1)
    assert_equal DateTime.new(2013,1,1,2,0), result
    assert_equal 0,remainder
  end

  def test_can_add_2_minute_to_59_seconds_in_working_hour
    start_date=DateTime.new(2013,1,1,1,59)
    result, remainder=@working_hour.wp_calc(start_date,2)
    assert_equal DateTime.new(2013,1,1,2,0), result
    assert_equal 1,remainder
  end

  def test_can_subtract_more_than_the_available_minutes_in_a_working_hour
    start_date=DateTime.new(2013,1,1,1,31)
    result, remainder=@working_hour.wp_calc(start_date,-32)
    assert_equal DateTime.new(2013,1,1,1,0), result
    assert_equal -1,remainder
  end

  def test_can_subtract_exact_amount_of_available_minutes_in_working_hour
    start_date=DateTime.new(2013,1,1,1,31)
    result, remainder=@working_hour.wp_calc(start_date,-31)
    assert_equal DateTime.new(2013,1,1,1,0), result
    assert_equal 0,remainder
  end

  def test_can_subtract_1_second_less_than_available_minutes_in_working_hour
    start_date=DateTime.new(2013,1,1,1,31)
    result, remainder=@working_hour.wp_calc(start_date,-30)
    assert_equal DateTime.new(2013,1,1,1,1), result
    assert_equal 0,remainder
  end

  def test_can_subtract_when_more_available_minutes_in_working_hour
    start_date=DateTime.new(2013,1,1,1,31)
    result, remainder=@working_hour.wp_calc(start_date,-30)
    assert_equal DateTime.new(2013,1,1,1,1), result
    assert_equal 0,remainder
  end

  def test_can_subtract_1_minute_from_0_seconds_in_working_hour
    start_date=DateTime.new(2013,1,1,1,0)
    result, remainder=@working_hour.wp_calc(start_date,-1)
    assert_equal DateTime.new(2013,1,1,1,0), result
    assert_equal -1,remainder
  end

  def test_can_subtract_2_minute_to_0_seconds_in_working_hour
    start_date=DateTime.new(2013,1,1,1,0)
    result, remainder=@working_hour.wp_calc(start_date,-2)
    assert_equal DateTime.new(2013,1,1,1,0), result
    assert_equal -2,remainder
  end

  def test_can_subtract_exact_minutes_from_start_of_a_working_hour
    start_date=DateTime.new(2013,1,1,1,0)
    result, remainder=@working_hour.wp_calc(start_date,-60,true)
    assert_equal DateTime.new(2013,1,1,1,0), result
    assert_equal 0,remainder
  end

  def test_can_subtract_less_than_available_minutes_from_start_of_a_working_hour
    start_date=DateTime.new(2013,1,1,1,0)
    result, remainder=@working_hour.wp_calc(start_date,-59,true)
    assert_equal DateTime.new(2013,1,1,1,1), result
    assert_equal 0,remainder
  end
  
  def test_can_subtract_more_than_available_minutes_from_start_of_a_working_hour
    start_date=DateTime.new(2013,1,1,1,0)
    result, remainder=@working_hour.wp_calc(start_date,-61,true)
    assert_equal DateTime.new(2013,1,1,1,0), result
    assert_equal -1,remainder
  end
  
  def test_can_subtract_1_minute_from_end_of_a_working_hour
    start_date=DateTime.new(2013,1,1,1,0)
    result, remainder=@working_hour.wp_calc(start_date,-1,true)
    assert_equal DateTime.new(2013,1,1,1,59), result
    assert_equal 0,remainder
  end
  
  def test_can_zero_minutes_in_a_working_hour
    start_date=DateTime.new(2013,1,1,1,8)
    result, remainder=@working_hour.wp_calc(start_date,0)
    assert_equal DateTime.new(2013,1,1,1,8), result
    assert_equal 0,remainder
  end

  def test_can_add_1_minute_to_a_resting_hour
    start_date=DateTime.new(2013,1,1,1,30)
    result, remainder=@resting_hour.wp_calc(start_date,1)
    assert_equal DateTime.new(2013,1,1,2,0), result
    assert_equal 1,remainder
  end

  def test_can_add_1_minute_to_59_seconds_of_resting_hour
    start_date=DateTime.new(2013,1,1,1,59)
    result, remainder=@resting_hour.wp_calc(start_date,1)
    assert_equal DateTime.new(2013,1,1,2,0), result
    assert_equal 1,remainder
  end

  def test_can_add_1_minute_to_0_seconds_of_resting_hour
    start_date=DateTime.new(2013,1,1,1,0)
    result, remainder=@resting_hour.wp_calc(start_date,1)
    assert_equal DateTime.new(2013,1,1,2,0), result
    assert_equal 1,remainder
  end

  def test_can_subtract_0_minutes_from_start_of_a_resting_hour
    start_date=DateTime.new(2013,1,1,1,0)
    result, remainder=@resting_hour.wp_calc(start_date,0,true)
    assert_equal DateTime.new(2013,1,1,1,0), result
    assert_equal 0,remainder
  end
 
  def test_can_subtract_1_minute_from_end_of_a_resting_hour
    start_date=DateTime.new(2013,1,1,1,0)
    result, remainder=@resting_hour.wp_calc(start_date,-1,true)
    assert_equal DateTime.new(2013,1,1,1,0), result
    assert_equal -1,remainder
  end

  def test_can_zero_minutes_in_a_resting_hour
    start_date=DateTime.new(2013,1,1,1,8)
    result, remainder=@resting_hour.wp_calc(start_date,0)
    assert_equal DateTime.new(2013,1,1,1,8), result
    assert_equal 0,remainder
  end

  def test_can_add_more_than_the_available_minutes_in_a_patterned_hour
    start_date=DateTime.new(2013,1,1,1,8)
    result, remainder=@pattern_hour.wp_calc(start_date,32)
    assert_equal DateTime.new(2013,1,1,2,0), result
    assert_equal 1,remainder
  end

  def test_can_add_exact_amount_of_available_minutes_in_patterned_hour
    start_date=DateTime.new(2013,1,1,1,8)
    result, remainder=@pattern_hour.wp_calc(start_date,31)
    assert_equal DateTime.new(2013,1,1,1,59), result
    assert_equal 0,remainder
  end

  def test_can_add_when_more_available_minutes_in_patterned_hour
    start_date=DateTime.new(2013,1,1,1,8)
    result, remainder=@pattern_hour.wp_calc(start_date,30)
    assert_equal DateTime.new(2013,1,1,1,58), result
    assert_equal 0,remainder
  end

  def test_can_add_from_resting_period_in_patterned_hour
    start_date=DateTime.new(2013,1,1,1,15)
    result, remainder=@pattern_hour.wp_calc(start_date,1)
    assert_equal DateTime.new(2013,1,1,1,32), result
    assert_equal 0,remainder
  end

  def test_can_add_1_subtract_1_to_find_next_working_period_in_patterned_hour
    start_date=DateTime.new(2013,1,1,1,15)
    start_date, remainder=@pattern_hour.wp_calc(start_date,1)
    result, remainder=@pattern_hour.wp_calc(start_date,-1)
    assert_equal DateTime.new(2013,1,1,1,31), result
    assert_equal 0,remainder
  end  

  def test_can_add_zero_minutes_in_a_working_period_patterned_hour
    start_date=DateTime.new(2013,1,1,1,8)
    result, remainder=@pattern_hour.wp_calc(start_date,0)
    assert_equal DateTime.new(2013,1,1,1,8), result
    assert_equal 0,remainder
  end

  def test_can_zero_minutes_in_a_resting_period_patterned_hour
    start_date=DateTime.new(2013,1,1,1,15)
    result, remainder=@pattern_hour.wp_calc(start_date,0)
    assert_equal DateTime.new(2013,1,1,1,15), result
    assert_equal 0,remainder
  end

  def test_minutes_in_slice_of_working_hour
    assert_equal 8,@working_hour.wp_minutes(8,15)
  end

  def test_minutes_in_slice_of_resting_hour
    assert_equal 0,@resting_hour.wp_minutes(8,15)
  end

  def test_minutes_in_slice_of_working_hour
    assert_equal 3,@pattern_hour.wp_minutes(8,15)
    assert_equal 4,@pattern_hour.wp_minutes(8,31)
  end

  def test_can_subtract_more_than_the_available_minutes_in_a_pattern_hour
    start_date=DateTime.new(2013,1,1,1,31)
    result, remainder=@pattern_hour.wp_calc(start_date,-11)
    assert_equal DateTime.new(2013,1,1,1,0), result
    assert_equal -1,remainder
  end

  def test_can_subtract_exact_amount_of_available_minutes_in_pattern_hour
    start_date=DateTime.new(2013,1,1,1,31)
    result, remainder=@pattern_hour.wp_calc(start_date,-10)
    assert_equal DateTime.new(2013,1,1,1,1), result
    assert_equal 0,remainder
  end

  def test_can_subtract_1_second_less_than_available_minutes_in_pattern_hour
    start_date=DateTime.new(2013,1,1,1,31)
    result, remainder=@pattern_hour.wp_calc(start_date,-9)
    assert_equal DateTime.new(2013,1,1,1,2), result
    assert_equal 0,remainder
  end

  def test_can_change_working_to_resting
    new_hour=@working_hour.wp_workpattern(0,59,0)
    assert_equal 0,new_hour.wp_total
    assert_nil new_hour.wp_first
    assert_nil new_hour.wp_last
  end

  def test_must_create_complex_patterns
    new_hour=@working_hour.wp_workpattern(0,0,0)
    new_hour=new_hour.wp_workpattern(8,23,0)
    new_hour=new_hour.wp_workpattern(12,12,1)
    new_hour=new_hour.wp_workpattern(58,58,0)
    new_hour=new_hour.wp_workpattern(6,8,1)
    assert_equal 44, new_hour.wp_total
    assert_equal 1, new_hour.wp_first
    assert_equal 59, new_hour.wp_last
  end

  def test_difference_between_first_and_last_minute_in_working_hour
    assert_equal 59, @working_hour.wp_diff(0,59)
  end

  def test_difference_between_first_and_first_minute_in_working_hour
    assert_equal 0, @working_hour.wp_diff(0,0)
  end

  def test_difference_between_last_and_last_minute_in_working_hour
    assert_equal 0, @working_hour.wp_diff(59,59)
  end

  def test_difference_between_two_minutes_in_working_hour
    assert_equal 13, @working_hour.wp_diff(3,16)
  end

  def test_difference_between_first_minute_and_first_minute_in_next_hour_in_working_hour
    assert_equal 60, @working_hour.wp_diff(0,60)
  end

  def test_difference_between_a_minute_and_last_minute_in_working_hour
    assert_equal 43, @working_hour.wp_diff(16,59)
  end

  def test_differences_work_in_reverse_for_working_hour
    assert_equal 59, @working_hour.wp_diff(59,0)
    assert_equal 13, @working_hour.wp_diff(16,3)
    assert_equal 60, @working_hour.wp_diff(60,0)
    assert_equal 43, @working_hour.wp_diff(59,16)
  end

  def test_difference_between_first_and_last_minute_in_resting_hour
    assert_equal 0, @resting_hour.wp_diff(0,59)
  end

  def test_difference_between_first_and_first_minute_in_resting_hour
    assert_equal 0, @resting_hour.wp_diff(0,0)
  end

  def test_difference_between_last_and_last_minute_in_resting_hour
    assert_equal 0, @resting_hour.wp_diff(59,59)
  end

  def test_difference_between_two_minutes_in_resting_hour
    assert_equal 0, @resting_hour.wp_diff(3,16)
  end

  def test_difference_between_first_minute_and_first_minute_in_next_hour_in_resting_hour
    assert_equal 0, @resting_hour.wp_diff(0,60)
  end

  def test_difference_between_a_minute_and_last_minute_in_resting_hour
    assert_equal 0, @resting_hour.wp_diff(16,59)
  end

  def test_differences_work_in_reverse_for_resting_hour
    assert_equal 0, @resting_hour.wp_diff(59,0)
    assert_equal 0, @resting_hour.wp_diff(16,3)
    assert_equal 0, @resting_hour.wp_diff(60,0)
    assert_equal 0, @resting_hour.wp_diff(59,16)
  end

  def test_difference_between_first_and_last_minute_in_pattern_hour
    assert_equal 38, @pattern_hour.wp_diff(0,59)
  end

  def test_difference_between_first_and_first_minute_in_pattern_hour
    assert_equal 0, @pattern_hour.wp_diff(0,0)
  end

  def test_difference_between_last_and_last_minute_in_pattern_hour
    assert_equal 0, @pattern_hour.wp_diff(59,59)
  end

  def test_difference_between_two_minutes_in_pattern_hour
    assert_equal 8, @pattern_hour.wp_diff(3,16)
  end

  def test_difference_between_first_minute_and_first_minute_in_next_hour_in_pattern_hour
    assert_equal 38, @pattern_hour.wp_diff(0,60)
  end

  def test_difference_between_a_minute_and_last_minute_in_pattern_hour
    assert_equal 28, @pattern_hour.wp_diff(16,59)
  end

  def test_differences_work_in_reverse_for_pattern_hour
    assert_equal 38, @pattern_hour.wp_diff(59,0)
    assert_equal 8, @pattern_hour.wp_diff(16,3)
    assert_equal 38, @pattern_hour.wp_diff(60,0)
    assert_equal 28, @pattern_hour.wp_diff(59,16)
  end

end
