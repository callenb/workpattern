require File.dirname(__FILE__) + '/test_helper.rb'

class TestDay < MiniTest::Unit::TestCase #:nodoc:

  def setup
  end
  
  def test_must_create_a_working_day
  
    working_day = Workpattern::Day.new(1)
    assert_equal 1440, working_day.total,"24 hour working total minutes"
  end
    
  def test_must_ceate_a_resting_day

    resting_day = Workpattern::Day.new(0)
    assert_equal 0, resting_day.total,"24 hour resting total minutes"
  end
  
  def test_must_set_patterns_correctly

    times=Array.new()
    [[0,0,8,59],
     [12,0,12,59],
     [17,0,22,59]
    ].each {|start_hour,start_min,finish_hour,finish_min|
      times<<[clock(start_hour,start_min),clock(finish_hour,finish_min)]
    }
    
    [[24,480,clock(9,0),clock(23,59)]
    ].each{|hours_in_day,total,first_time,last_time|
      working_day=Workpattern::Day.new(1)
      times.each{|start_time,finish_time| 
        working_day.workpattern(start_time,finish_time,0)
      } 
      assert_equal total,working_day.total, "#{hours_in_day} hour total working minutes"
      assert_equal first_time.hour, working_day.first_hour, "#{hours_in_day} hour first hour of the day"
      assert_equal first_time.min, working_day.first_min, "#{hours_in_day} hour first minute of the day"
      assert_equal last_time.hour, working_day.last_hour, "#{hours_in_day} hour last hour of the day"
      assert_equal last_time.min, working_day.last_min, "#{hours_in_day} hour last minute of the day"
    }
  end
  
  def test_must_duplicate_all_of_day
    day=Workpattern::Day.new(1)
    new_day = day.duplicate
    assert_equal 1440, new_day.total,"24 hour duplicate working total minutes"
    # y    m ,d ,h ,n ,dur ,yr  ,mr,dr,hr,nr,rem ,midnight, midnightr
    tests=[
     [2000,1 ,1 ,0 , 0,3   ,2000,1 ,1 ,0 ,3 ,0   ,false   ,false],
     [2000,1 ,1 ,23,59,0   ,2000,1 ,1 ,23,59,0   ,false   ,false],
     [2000,1 ,1 ,23,59,1   ,2000,1 ,2 ,0 ,0 ,0   ,false   ,false],
     [2000,1 ,1 ,23,59,2   ,2000,1 ,2 ,0 ,0 ,1   ,false   ,false],
     [2000,1 ,1 ,9 ,10,33  ,2000,1 ,1 ,9 ,43,0   ,false   ,false],
     [2000,1 ,1 ,9 ,10,60  ,2000,1 ,1 ,10,10,0   ,false   ,false],
     [2000,1 ,1 ,9 , 0,931 ,2000,1 ,2 ,0 ,0 ,31  ,false   ,false]
    ]
    clue="duplicate working pattern"
    calc_test(new_day,tests,clue)
    
    day = Workpattern::Day.new(0)
    new_day=day.duplicate
    assert_equal 0, new_day.total,"24 hour resting total minutes"
    # y    m ,d ,h ,n ,dur ,yr  ,mr,dr,hr,nr,rem ,midnight, midnightr
    tests=[
     [2000,1,1,0,0,3,2000,1,2,0,0,3,false,false],
     [2000,1,1,23,59,0,2000,1,1,23,59,0,false,false],
     [2000,1,1,23,59,1,2000,1,2,0,0,1,false,false],
     [2000,1,1,23,59,2,2000,1,2,0,0,2,false,false],
     [2000,1,1,9,10,33,2000,1,2,0,0,33,false,false],
     [2000,1,1,9,10,60,2000,1,2,0,0,60,false,false],
     [2000,1,1,9,0,931,2000,1,2,0,0,931,false,false]
    ]
    clue="duplicate resting pattern"
    calc_test(new_day,tests,clue)
    
    
    times=Array.new()
    [[0,0,8,59],
     [12,0,12,59],
     [17,0,22,59]
    ].each {|start_hour,start_min,finish_hour,finish_min|
      times<<[Workpattern::Clock.new(start_hour,start_min),Workpattern::Clock.new(finish_hour,finish_min)]
    }
    
    [[24,480,clock(9,0),clock(23,59)]
    ].each{|hours_in_day,total,first_time,last_time|
      day=Workpattern::Day.new(1)
      times.each{|start_time,finish_time| 
        day.workpattern(start_time,finish_time,0)
      } 
      new_day=day.duplicate
      
      assert_equal total,new_day.total, "#{hours_in_day} hour total working minutes"
      assert_equal first_time.hour, new_day.first_hour, "#{hours_in_day} hour first hour of the day"
      assert_equal first_time.min, new_day.first_min, "#{hours_in_day} hour first minute of the day"
      assert_equal last_time.hour, new_day.last_hour, "#{hours_in_day} hour last hour of the day"
      assert_equal last_time.min, new_day.last_min, "#{hours_in_day} hour last minute of the day"
      
      new_day.workpattern(clock(13,0),clock(13,0),0)
      
      assert_equal total,day.total, "#{hours_in_day} hour total original working minutes"
      
      assert_equal total-1,new_day.total, "#{hours_in_day} hour total new working minutes"
      
    }
    
  end
  
  def test_must_add_minutes_in_a_working_day
  
    day = Workpattern::Day.new(1)
    # y    m ,d ,h ,n ,dur ,yr  ,mr,dr,hr,nr,rem ,midnight, midnightr
    tests=[
     [2000,1,1,0,0,3,2000,1,1,0,3,0,false,false],
     [2000,1,1,0,0,0,2000,1,1,0,0,0,false,false],
     [2000,1,1,0,59,0,2000,1,1,0,59,0,false,false],
     [2000,1,1,0,11,3,2000,1,1,0,14,0,false,false],
     [2000,1,1,0,0,60,2000,1,1,1,0,0,false,false],
     [2000,1,1,0,0,61,2000,1,1,1,1,0,false,false],
     [2000,1,1,0,30,60,2000,1,1,1,30,0,false,false],
     [2000,12,31,23,59,1,2001,1,1,0,0,0,false,false],
     [2000,1,1,9,10,33,2000,1,1,9,43,0,false,false],
     [2000,1,1,9,10,60,2000,1,1,10,10,0,false,false],
     [2000,1,1,9,0,931,2000,1,2,0,0,31,false,false]
    ]
    clue = "add minutes in a working day"
    calc_test(day,tests,clue)
    
  end
  
  def test_must_add_minutes_in_a_resting_day

    day = Workpattern::Day.new(0)
    # y    m ,d ,h ,n ,dur ,yr  ,mr,dr,hr,nr,rem ,midnight, midnightr
    tests=[
     [2000,1,1,0,0,3,2000,1,2,0,0,3,false,false],
     [2000,1,1,23,59,0,2000,1,1,23,59,0,false,false],
     [2000,1,1,23,59,1,2000,1,2,0,0,1,false,false],
     [2000,1,1,23,59,2,2000,1,2,0,0,2,false,false],
     [2000,1,1,9,10,33,2000,1,2,0,0,33,false,false],
     [2000,1,1,9,10,60,2000,1,2,0,0,60,false,false],
     [2000,1,1,9,0,931,2000,1,2,0,0,931,false,false]
    ]
    clue="add minutes in a resting day"
    calc_test(day,tests,clue)
  end
  
  def test_must_add_minutes_in_a_patterned_day
 
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
    # y    m ,d ,h ,n ,dur ,yr  ,mr,dr,hr,nr,rem ,midnight, midnightr
    tests=[
     [2000,1,1,0,0,3,2000,1,1,9,3,0,false,false],
     [2000,1,1,0,0,0,2000,1,1,0,0,0,false,false],
     [2000,1,1,0,59,0,2000,1,1,0,59,0,false,false],
     [2000,1,1,0,11,3,2000,1,1,9,3,0,false,false],
     [2000,1,1,0,0,60,2000,1,1,10,0,0,false,false],
     [2000,1,1,0,0,61,2000,1,1,10,1,0,false,false],
     [2000,1,1,9,30,60,2000,1,1,10,30,0,false,false],
     [2000,12,31,22,59,1,2000,12,31,23,1,0,false,false],
     [2000,1,1,9,10,33,2000,1,1,9,43,0,false,false],
     [2000,1,1,9,10,60,2000,1,1,10,10,0,false,false],
     [2000,1,1,9,0,931,2000,1,2,0,0,451,false,false],
     [2000,1,1,12,0,1,2000,1,1,13,1,0,false,false],
     [2000,1,1,12,59,1,2000,1,1,13,1,0,false,false]
    ]
    clue = "add minutes in a patterned day"
    calc_test(day,tests,clue)  
  end
  
  def test_must_subtract_minutes_in_a_working_day

    day = Workpattern::Day.new(1)
    # y   ,m ,d ,h ,n ,dur ,yr  ,mr,dr,hr,nr,rem ,midnight,midnightr    
    tests=[
     [2000,1 ,1 ,0 ,0 ,-3  ,1999,12,31,0 ,0 ,-3  ,false   ,true],
     [2000,1 ,1 ,0 ,1 ,-2  ,1999,12,31,0 ,0 ,-1  ,false   ,true], #Issue 6 - available minutes not calculating correctly for a time of 00:01
     [2000,1 ,1 ,23,59,0   ,2000,1 ,1 ,23,59,0   ,false   ,false],
     [2000,1 ,1 ,23,59,-1  ,2000,1 ,1 ,23,58,0   ,false   ,false],
     [2000,1 ,1 ,23,59,-2  ,2000,1 ,1 ,23,57,0   ,false   ,false],
     [2000,1 ,1 ,9 ,10,-33 ,2000,1 ,1 ,8 ,37,0   ,false   ,false],
     [2000,1 ,1 ,9 ,10,-60 ,2000,1 ,1 ,8 ,10,0   ,false   ,false],
     [2000,1 ,1 ,9 ,4 ,-3  ,2000,1 ,1 ,9 ,1 ,0   ,false   ,false],
     [2000,1 ,1 ,9 ,0 ,-931,1999,12,31,0 ,0 ,-391,false   ,true],
     [2000,1 ,1 ,0 ,0 ,-3  ,2000,1 ,1 ,23,57,0   ,true    ,false],
     [2000,1 ,1 ,23,59,0   ,2000,1 ,1 ,23,59,0   ,true    ,false],
     [2000,1 ,1 ,23,59,-1  ,2000,1 ,1 ,23,58,0   ,true    ,false],
     [2000,1 ,1 ,0 ,0 ,-2  ,2000,1 ,1 ,23,58,0   ,true    ,false],
     [2000,1 ,1 ,0 ,0 ,-33 ,2000,1 ,1 ,23,27,0   ,true    ,false],
     [2000,1 ,1 ,0 ,0 ,-60 ,2000,1 ,1 ,23,0 ,0   ,true    ,false],
     [2000,1 ,1 ,0 ,0 ,-931,2000,1 ,1 ,8 ,29,0   ,true    ,false]     
    ]
    clue="subtract minutes in a working day"
    calc_test(day,tests,clue)
  end
  
  def test_must_subtract_minutes_in_a_resting_day
    
    day = Workpattern::Day.new(0)
    # y   ,m ,d ,h ,n ,dur ,yr  ,mr,dr,hr,nr,rem ,midnight,midnightr     
    tests=[
     [2000,1 ,1 ,0 ,0 ,-3  ,1999,12,31,0 ,0 ,-3  ,false   ,true],
     [2000,1 ,1 ,23,59,0   ,2000,1 ,1 ,23,59,0   ,false   ,false],
     [2000,1 ,1 ,23,59,-1  ,1999,12,31,0 ,0 ,-1  ,false   ,true],
     [2000,1 ,1 ,23,59,-2  ,1999,12,31,0 ,0 ,-2  ,false   ,true],
     [2000,1 ,1 ,9 ,10,-33 ,1999,12,31,0 ,0 ,-33 ,false   ,true],
     [2000,1 ,1 ,9 ,10,-60 ,1999,12,31,0 ,0 ,-60 ,false   ,true],
     [2000,1 ,1 ,9 ,0 ,-931,1999,12,31,0 ,0 ,-931,false   ,true],
     [2000,1 ,1 ,0 ,0 ,-3  ,1999,12,31,0 ,0 ,-3  ,true   ,true],
     [2000,1 ,1 ,23,59,0   ,2000,1 ,1 ,23,59,0   ,true   ,false],
     [2000,1 ,1 ,23,59,-1  ,1999,12,31,0 ,0 ,-1  ,true   ,true],
     [2000,1 ,1 ,23,59,-2  ,1999,12,31,0 ,0 ,-2  ,true   ,true],
     [2000,1 ,1 ,9 ,10,-33 ,1999,12,31,0 ,0 ,-33 ,true   ,true],
     [2000,1 ,1 ,9 ,10,-60 ,1999,12,31,0 ,0 ,-60 ,true   ,true],
     [2000,1 ,1 ,9 ,0 ,-931,1999,12,31,0 ,0 ,-931,true   ,true]
    ]
    clue="subtract minutes in a resting day"
    calc_test(day,tests,clue)  
  end
  
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

