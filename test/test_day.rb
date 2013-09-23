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

############################################################################  
############################################################################  
############################################################################  
  
  def test_must_subtract_minutes_in_a_patterned_day
  
    day = Workpattern::Day.new(1)
    [[0,0,8,59],
     [12,0,12,59],
     [17,0,22,59]
    ].each {|start_hour,start_min,finish_hour,finish_min|
      day.workpattern(clock(start_hour, start_min),
                      clock(finish_hour, finish_min),
                      0)
    }
    assert_equal 480, day.total, "minutes in patterned day should be 480"
    assert_equal 1, day.minutes(16,59,16,59),"16:59 should be 1"
    assert_equal 0, day.minutes(17,0,17,0),"17:00 should be 0"
    assert_equal 0, day.minutes(22,59,22,59),"22:59 should be 0"
    assert_equal 1, day.minutes(23,0,23,0),"23:00 should be 1"
    # y   ,m ,d ,h ,n ,dur ,yr  ,mr,dr,hr,nr,rem ,midnight,midnightr         
    tests=[
     [2000,1 ,1 ,0 ,0 ,-3  ,1999,12,31,0 ,0 ,-3  ,false   ,true],
     [2000,1 ,1 ,0 ,0 ,0   ,2000,1 ,1 ,0 ,0 ,0   ,false   ,false],
     [2000,1 ,1 ,0 ,59,0   ,2000,1 ,1 ,0 ,59,0   ,false   ,false],
     [2000,1 ,1 ,9 ,4 ,-3  ,2000,1 ,1 ,9 ,1 ,0   ,false   ,false],
     [2000,1 ,1 ,0 ,0 ,-60 ,1999,12,31,0 ,0 ,-60 ,false   ,true],
     [2000,1 ,1 ,0 ,0 ,-61 ,1999,12,31,0 ,0 ,-61 ,false   ,true],
     [2000,1 ,1 ,9 ,30,-60 ,1999,12,31,0 ,0 ,-30 ,false   ,true],
     [2000,12,31,22,59,-1  ,2000,12,31,16,59,0   ,false   ,false],
     [2000,1 ,1 ,9 ,10,-33 ,1999,12,31,0 ,0 ,-23 ,false   ,true],
     [2000,1 ,1 ,9 ,10,-60 ,1999,12,31,0 ,0 ,-50 ,false   ,true],
     [2000,1 ,1 ,9 ,1 ,-931,1999,12,31,0 ,0 ,-930,false   ,true],
     [2000,1 ,1 ,12,0 ,-1  ,2000,1 ,1 ,11,59,0   ,false   ,false],
     [2000,1 ,1 ,12,59,-1  ,2000,1 ,1 ,11,59,0   ,false   ,false],
     [2000,1 ,1 ,0 ,0 ,-3  ,2000,1 ,1 ,23,57,0   ,true    ,false],
     [2000,1 ,1 ,0 ,0 ,0   ,2000,1 ,1 ,0 ,0 ,0   ,true    ,false],
     [2000,1 ,1 ,0 ,59,0   ,2000,1 ,1 ,0 ,59,0   ,true    ,false],
     [2000,1 ,1 ,9 ,4 ,-3  ,2000,1 ,1 ,9 ,1 ,0   ,true    ,false],
     [2000,1 ,1 ,0 ,0 ,-60 ,2000,1 ,1 ,23,0 ,0   ,true    ,false],
     [2000,1 ,1 ,0 ,0 ,-61 ,2000,1 ,1 ,16,59,0   ,true    ,false],
     [2000,1 ,1 ,0 ,0 ,-931,1999,12,31,0 ,0 ,-451,true    ,true],
     [2000,1 ,1 ,12,0 ,-1  ,2000,1 ,1 ,11,59,0   ,true    ,false]
    ]
    clue = "subtract minutes in a patterned day"
    calc_test(day,tests,clue)
 
  end
   
  
  def test_must_calculate_difference_between_times_in_working_day
    day = Workpattern::Day.new(1)
    
    [
     [ 2000, 1, 1, 0, 0, 2000, 1, 1, 0, 0,   0,2000, 1, 1, 0, 0],
     [ 2000, 1, 1, 0, 0, 2000, 1, 1, 0, 1,   1,2000, 1, 1, 0, 1],
     [ 2000, 1, 1, 0,50, 2000, 1, 1, 0,59,   9,2000, 1, 1, 0,59],
     [ 2000, 1, 1, 8,50, 2000, 1, 1, 9, 0,  10,2000, 1, 1, 9, 0],
     [ 2000, 1, 1, 0, 0, 2000, 1, 1,23,59,1439,2000, 1, 1,23,59],
     [ 2000, 1, 1, 0, 0, 2000, 1, 2, 0, 0,1440,2000, 1, 2, 0, 0],
     [ 2000, 1, 1, 0, 0, 2000, 1, 2, 0, 1,1440,2000, 1, 2, 0, 0],     
     [ 2000, 1, 1, 0, 0, 2010, 3,22, 6,11,1440,2000, 1, 2, 0, 0],
     [ 2000, 1, 1, 0, 1, 2000, 1, 1, 0, 0,   1,2000, 1, 1, 0, 1],
     [ 2000, 1, 1, 0,59, 2000, 1, 1, 0,50,   9,2000, 1, 1, 0,59],
     [ 2000, 1, 1, 9, 0, 2000, 1, 1, 8,50,  10,2000, 1, 1, 9, 0],
     [ 2000, 1, 1,23,59, 2000, 1, 1, 0, 0,1439,2000, 1, 1,23,59],
     [ 2000, 1, 2, 0, 0, 2000, 1, 1, 0, 0,1440,2000, 1, 2, 0, 0],
     [ 2000, 1, 2, 0, 1, 2000, 1, 1, 0, 0,1440,2000, 1, 2, 0, 0],     
     [ 2010, 3,22, 6,11, 2000, 1, 1, 0, 0,1440,2000, 1, 2, 0, 0]
    ].each {|start_year, start_month, start_day, start_hour,start_min,
             finish_year, finish_month, finish_day, finish_hour,finish_min,result,
             y,m,d,h,n|
      start=DateTime.new(start_year, start_month, start_day, start_hour,start_min)
      finish=DateTime.new(finish_year, finish_month, finish_day, finish_hour,finish_min)
      expected_date=DateTime.new(y,m,d,h,n)       
      duration, result_date=day.diff(start,finish)
      assert_equal result, duration,"duration diff(#{start}, #{finish})"
      assert_equal expected_date, result_date,"date diff(#{start}, #{finish})"
    }
  end

  def test_must_calculate_difference_between_times_in_resting_day
  day = Workpattern::Day.new(0)
  
    [
     [ 2000, 1, 1, 0, 0, 2000, 1, 1, 0, 0,   0,2000, 1, 1, 0, 0],
     [ 2000, 1, 1, 0, 0, 2000, 1, 1, 0, 1,   0,2000, 1, 1, 0, 1],
     [ 2000, 1, 1, 0,50, 2000, 1, 1, 0,59,   0,2000, 1, 1, 0,59],
     [ 2000, 1, 1, 8,50, 2000, 1, 1, 9, 0,   0,2000, 1, 1, 9, 0],
     [ 2000, 1, 1, 0, 0, 2000, 1, 1,23,59,   0,2000, 1, 1,23,59],
     [ 2000, 1, 1, 0, 0, 2000, 1, 2, 0, 0,   0,2000, 1, 2, 0, 0],
     [ 2000, 1, 1, 0, 0, 2000, 1, 2, 0, 1,   0,2000, 1, 2, 0, 0],     
     [ 2000, 1, 1, 0, 0, 2010, 3,22, 6,11,   0,2000, 1, 2, 0, 0],
     [ 2000, 1, 1, 0, 1, 2000, 1, 1, 0, 0,   0,2000, 1, 1, 0, 1],
     [ 2000, 1, 1, 0,59, 2000, 1, 1, 0,50,   0,2000, 1, 1, 0,59],
     [ 2000, 1, 1, 9, 0, 2000, 1, 1, 8,50,   0,2000, 1, 1, 9, 0],
     [ 2000, 1, 1,23,59, 2000, 1, 1, 0, 0,   0,2000, 1, 1,23,59],
     [ 2000, 1, 2, 0, 0, 2000, 1, 1, 0, 0,   0,2000, 1, 2, 0, 0],
     [ 2000, 1, 2, 0, 1, 2000, 1, 1, 0, 0,   0,2000, 1, 2, 0, 0],     
     [ 2010, 3,22, 6,11, 2000, 1, 1, 0, 0,   0,2000, 1, 2, 0, 0]
    ].each {|start_year, start_month, start_day, start_hour,start_min,
             finish_year, finish_month, finish_day, finish_hour,finish_min,result,
             y,m,d,h,n|
      start=DateTime.new(start_year, start_month, start_day, start_hour,start_min)
      finish=DateTime.new(finish_year, finish_month, finish_day, finish_hour,finish_min)
      expected_date=DateTime.new(y,m,d,h,n)       
      duration, result_date=day.diff(start,finish)
      assert_equal result, duration,"duration diff(#{start}, #{finish})"
      assert_equal expected_date, result_date,"date diff(#{start}, #{finish})"
     }
  end

  def test_must_calculate_difference_between_times_in_pattern_day

    day = Workpattern::Day.new(1)
    [[0,0,8,59],
     [12,0,12,59],
     [17,0,22,59]
    ].each {|start_hour,start_min,finish_hour,finish_min|
      day.workpattern(clock(start_hour, start_min),
                      clock(finish_hour, finish_min),
                      0)
    }
    assert_equal 480, day.total, "minutes in patterned day should be 480"
    assert_equal 1, day.minutes(16,59,16,59),"16:59 should be 1"
    assert_equal 0, day.minutes(17,0,17,0),"17:00 should be 0"
    assert_equal 0, day.minutes(22,59,22,59),"22:59 should be 0"
    assert_equal 1, day.minutes(23,0,23,0),"23:00 should be 1"
  
    [
     [ 2000, 1, 1, 0, 0, 2000, 1, 1, 0, 0,   0,2000, 1, 1, 0, 0],
     [ 2000, 1, 1, 0, 0, 2000, 1, 1, 0, 1,   0,2000, 1, 1, 0, 1],
     [ 2000, 1, 1, 0,50, 2000, 1, 1, 9,59,  59,2000, 1, 1, 9,59],
     [ 2000, 1, 1, 8,50, 2000, 1, 1, 9,10,  10,2000, 1, 1, 9,10],
     [ 2000, 1, 1, 0, 0, 2000, 1, 1,23,59, 479,2000, 1, 1,23,59],
     [ 2000, 1, 1, 0, 0, 2000, 1, 2, 0, 0, 480,2000, 1, 2, 0, 0],
     [ 2000, 1, 1, 0, 0, 2000, 1, 2, 0, 1, 480,2000, 1, 2, 0, 0],     
     [ 2000, 1, 1, 0, 0, 2010, 3,22, 6,11, 480,2000, 1, 2, 0, 0],
     [ 2000, 1, 1, 0, 1, 2000, 1, 1, 0, 0,   0,2000, 1, 1, 0, 1],
     [ 2000, 1, 1, 9,59, 2000, 1, 1, 0,50,  59,2000, 1, 1, 9,59],
     [ 2000, 1, 1, 9, 0, 2000, 1, 1, 8,50,   0,2000, 1, 1, 9, 0],
     [ 2000, 1, 1,23,59, 2000, 1, 1, 0, 0, 479,2000, 1, 1,23,59],
     [ 2000, 1, 2, 0, 0, 2000, 1, 1, 0, 0, 480,2000, 1, 2, 0, 0],
     [ 2000, 1, 2, 0, 1, 2000, 1, 1, 0, 0, 480,2000, 1, 2, 0, 0],     
     [ 2010, 3,22, 6,11, 2000, 1, 1, 0, 0, 480,2000, 1, 2, 0, 0]
    ].each {|start_year, start_month, start_day, start_hour,start_min,
             finish_year, finish_month, finish_day, finish_hour,finish_min,result,
             y,m,d,h,n|
      start=DateTime.new(start_year, start_month, start_day, start_hour,start_min)
      finish=DateTime.new(finish_year, finish_month, finish_day, finish_hour,finish_min)
      expected_date=DateTime.new(y,m,d,h,n)       
      duration, result_date=day.diff(start,finish)
      assert_equal result, duration,"duration diff(#{start}, #{finish})"
      assert_equal expected_date, result_date,"date diff(#{start}, #{finish})"
     }

  end
  
  private

  def calc_test(day,tests,clue)
    tests.each{|y,m,d,h,n,dur,yr,mr,dr,hr,nr,rem, midnight, midnightr|
      start_date=DateTime.new(y,m,d,h,n)
      result_date,remainder, result_midnight = day.calc(start_date,dur, midnight)
      assert_equal DateTime.new(yr,mr,dr,hr,nr), result_date, "result date calc(#{start_date},#{dur},#{midnight}) for #{clue}"
      assert_equal rem, remainder, "result remainder calc(#{start_date},#{dur},#{midnight}) for #{clue}"
      assert_equal midnightr,result_midnight, "result midnight calc(#{start_date},#{dur},#{midnight}) for #{clue}"
    }
  
  
  end
  
  def clock(hour,min)
    return Workpattern.clock(hour,min)
  end 
end

