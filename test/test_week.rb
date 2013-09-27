require File.dirname(__FILE__) + '/test_helper.rb'

class TestWeek < MiniTest::Unit::TestCase #:nodoc:

  def setup
    
  end

  def test_must_diff_from_last_day_of_patterned_week
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


######################################################
######################################################
######################################################
  
  def test_must_create_a_working_week
    start=DateTime.new(2000,1,1,11,3)
    finish=DateTime.new(2005,12,31,16,41)
    working_week=week(start,finish,1)
    assert_equal DateTime.new(start.year,start.month,start.day), working_week.start
    assert_equal DateTime.new(finish.year,finish.month,finish.day), working_week.finish
    assert_equal 3156480, working_week.total#2192
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
  
  def test_must_add_minutes_in_a_working_week
    start=DateTime.new(2000,1,1,0,0)
    finish=DateTime.new(2005,12,31,8,59)
    working_week=week(start,finish,1)
      
    [# yyyy,mm,dd,hh,mn,durtn,ryyyy,rmm,rdd,rhh,rmn,rdurtn
     [ 2000, 1, 1, 0, 0,    0, 2000,  1,  1,  0,  0,     0],
     [ 2005,12,31, 8,59,   10, 2005, 12, 31,  9,  9,     0],
     [ 2005,12,31,23,59,    1, 2006,  1,  1,  0,  0,     0],
     [ 2005,12,31,23,59,    2, 2006,  1,  1,  0,  0,     1],
     [ 2005,11,30,23,59,    2, 2005, 12,  1,  0,  1,     0]
    ].each {|yyyy,mm,dd,hh,mn,durtn,ryyyy,rmm,rdd,rhh,rmn,rdurtn|
      start=DateTime.new(yyyy,mm,dd,hh,mn)
      result_date, result_duration= working_week.calc(start,durtn)
      assert_equal DateTime.new(ryyyy,rmm,rdd,rhh,rmn), result_date, "result_date for working_week.calc(#{start},#{durtn})"
      assert_equal rdurtn, result_duration,"result_duration for working_week.calc(#{start},#{durtn})"
    }
  end
  
  def test_must_add_minutes_in_a_resting_week
    start=DateTime.new(2000,1,1,0,0)
    finish=DateTime.new(2005,12,31,8,59)
    resting_week=week(start,finish,0)
      
    [# yyyy,mm,dd,hh,mn,durtn,midnight,ryyyy,rmm,rdd,rhh,rmn,rdurtn,rmidnight
     [ 2000, 1, 1, 0, 0,    0,   false, 2000,  1,  1,  0,  0,     0,   false],
     [ 2005,12,31, 8,59,   10,   false, 2006,  1,  1,  0,  0,    10,   false],
     [ 2005,12,31,23,59,    1,   false, 2006,  1,  1,  0,  0,     1,   false],
     [ 2005,12,31,23,59,    2,   false, 2006,  1,  1,  0,  0,     2,   false],
     [ 2005,11,30,23,59,    2,   false, 2006,  1,  1,  0,  0,     2,   false],
     [ 2000, 1, 1, 0, 0,    0,    true, 2000,  1,  1,  0,  0,     0,   false],
     [ 2005,12,31, 8,59,   10,    true, 2006,  1,  1,  0,  0,    10,   false],
     [ 2005,12,31,23,59,    1,    true, 2006,  1,  1,  0,  0,     1,   false],
     [ 2005,12,31,23,59,    2,    true, 2006,  1,  1,  0,  0,     2,   false],
     [ 2005,11,30,23,59,    2,    true, 2006,  1,  1,  0,  0,     2,   false]     
    ].each {|yyyy,mm,dd,hh,mn,durtn,midnight,ryyyy,rmm,rdd,rhh,rmn,rdurtn,rmidnight|
      start=DateTime.new(yyyy,mm,dd,hh,mn)
      result_date, result_duration,result_midnight= resting_week.calc(start,durtn,midnight)
      assert_equal DateTime.new(ryyyy,rmm,rdd,rhh,rmn), result_date, "result_date for resting_week.calc(#{start},#{durtn},#{midnight})"
      assert_equal rdurtn, result_duration,"result_duration for resting_week.calc(#{start},#{durtn},#{midnight})"
      assert_equal rmidnight, result_midnight,"result_midnight for resting_week.calc(#{start},#{durtn},#{midnight})"      
    }
  end
  
  def test_must_add_minutes_in_a_patterned_week
    start=DateTime.new(2000,1,1,0,0) #saturday
    finish=DateTime.new(2005,12,31,8,59) #saturday
    working_week=week(start,finish,0)
    working_week.workpattern(:sun,clock(9,0),clock(9,13),1) 
    
    working_week.workpattern(:weekday,clock(9,0),clock(11,59),1)
    working_week.workpattern(:weekday,clock(13,0),clock(17,59),1)
    
    working_week.workpattern(:mon,clock(0,0),clock(23,59),0) 
    working_week.workpattern(:mon,clock(9,0),clock(9,13),1)
    working_week.workpattern(:mon,clock(10,1),clock(10,1),1)        
    
    
    [# yyyy,mm,dd,hh,mn,durtn,midnight,ryyyy,rmm,rdd,rhh,rmn,rdurtn,rmidnight
     [ 2000, 1, 1, 0, 0,    0,   false, 2000,  1,  1,  0,  0,     0,   false],
     [ 2000, 1, 1, 0, 0,    1,   false, 2000,  1,  2,  9,  1,     0,   false],
     [ 2000, 1, 2, 9, 0,   14,   false, 2000,  1,  2,  9,  14,     0,   false], #Issue #9 - getting wrong time when hour had exactly the right number of minutes
     [ 2000, 1, 2, 9, 0,   15,   false, 2000,  1,  3,  9,  1,     0,   false],
     [ 2000, 1, 2, 9, 0,   29,   false, 2000,  1,  3,  10,  2,     0,   false],     
     [ 2000, 1, 2, 9, 0, 1950,   false, 2000,  1,  9,   9,  1,     0,   false],
     [ 2005,12,25, 9, 0, 1950,   false, 2006,  1,  1,   0,  0,     1,   false],
     [ 2005,12,25, 9, 0, 1949,   false, 2005, 12, 30,  18,  0,     0,   false]#,          
    ].each {|yyyy,mm,dd,hh,mn,durtn,midnight,ryyyy,rmm,rdd,rhh,rmn,rdurtn,rmidnight|
      start=DateTime.new(yyyy,mm,dd,hh,mn)   
      result_date, result_duration,result_midnight= working_week.calc(start,durtn,midnight)
      assert_equal DateTime.new(ryyyy,rmm,rdd,rhh,rmn), result_date, "result_date for working_week.calc(#{start},#{durtn},#{midnight})"
      assert_equal rdurtn, result_duration,"result_duration for working_week.calc(#{start},#{durtn},#{midnight})"
      assert_equal rmidnight, result_midnight,"result_midnight for working_week.calc(#{start},#{durtn},#{midnight})"      
    }
  end
  
  def test_must_subtract_minutes_in_a_working_week
    start=DateTime.new(2000,1,1,0,0)
    finish=DateTime.new(2005,12,31,8,59)
    working_week=week(start,finish,1)
    [# yyyy,mm,dd,hh,mn,durtn,midnight,ryyyy,rmm,rdd,rhh,rmn,rdurtn,rmidnight
     [ 2000, 1, 1, 0, 0,    0,   false, 2000,  1,  1,  0,  0,     0,   false],
     [ 2005,12,31, 0, 0,  -10,   false, 2005, 12, 30, 23, 50,     0,   false],
     [ 2005,12,31, 0, 0,   -1,   false, 2005, 12, 30, 23, 59,     0,   false],
     [ 2005,12,31, 0, 1,   -2,   false, 2005, 12, 30, 23, 59,     0,   false], #Issue 6 - available minutes not calculating correctly for a time of 00:01
     [ 2000, 1, 1, 0, 1,   -2,   false, 1999, 12, 31,  0,  0,     -1,   true], #Issue 6 - available minutes not calculating correctly for a time of 00:01
     [ 2000, 1, 1, 0, 0,    0,    true, 2000,  1,  1,  0,  0,     0,   false],
     [ 2005,12,31, 0, 0,  -10,    true, 2005, 12, 31, 23, 50,     0,   false],
     [ 2005,12,31, 0, 0,   -1,    true, 2005, 12, 31, 23, 59,     0,   false],
     [ 2005,12,31, 0, 1,   -2,    true, 2005, 12, 31, 23, 58,     0,   false],#Issue 7 - midnight flag should override hour and minutes     
     [ 2000, 1, 1, 0, 1,   -2,    true, 2000,  1,  1, 23, 58,     0,   false] #Issue 7 - midnight flag should override hour and minutes     
    ].each {|yyyy,mm,dd,hh,mn,durtn,midnight,ryyyy,rmm,rdd,rhh,rmn,rdurtn,rmidnight|
      start=DateTime.new(yyyy,mm,dd,hh,mn)
      result_date, result_duration,result_midnight= working_week.calc(start,durtn,midnight)
      assert_equal DateTime.new(ryyyy,rmm,rdd,rhh,rmn), result_date, "result_date for working_week.calc(#{start},#{durtn},#{midnight})"
      assert_equal rdurtn, result_duration,"result_duration for working_week.calc(#{start},#{durtn},#{midnight})"
      assert_equal rmidnight, result_midnight,"result_midnight for working_week.calc(#{start},#{durtn},#{midnight})"      
    }
  end
  
  def test_must_subtract_minutes_in_a_resting_week
    start=DateTime.new(2000,1,1,0,0)
    finish=DateTime.new(2005,12,31,8,59)
    resting_week=week(start,finish,0)
    [# yyyy,mm,dd,hh,mn,durtn,midnight,ryyyy,rmm,rdd,rhh,rmn,rdurtn,rmidnight
     [ 2000, 1, 1, 0, 0,    0,   false, 2000,  1,  1,  0,  0,     0,    false],
     [ 2005,12,31, 0, 0,  -10,   false, 1999, 12, 31,  0,  0,   -10,     true],
     [ 2005,12,31, 0, 0,   -1,   false, 1999, 12, 31,  0,  0,    -1,     true],
     [ 2005,12,31, 0, 1,   -2,   false, 1999, 12, 31,  0,  0,    -2,     true],
     [ 2000, 1, 1, 0, 1,   -2,   false, 1999, 12, 31,  0,  0,    -2,     true]
    ].each {|yyyy,mm,dd,hh,mn,durtn,midnight,ryyyy,rmm,rdd,rhh,rmn,rdurtn,rmidnight|
      start=DateTime.new(yyyy,mm,dd,hh,mn)
      result_date, result_duration, result_midnight= resting_week.calc(start,durtn,midnight)
      assert_equal DateTime.new(ryyyy,rmm,rdd,rhh,rmn), result_date, "result_date for resting_week.calc(#{start},#{durtn},#{midnight})"
      assert_equal rdurtn, result_duration,"result_duration for resting_week.calc(#{start},#{durtn},#{midnight})"
      assert_equal rmidnight, result_midnight,"result_midnight for resting_week.calc(#{start},#{durtn},#{midnight})"      
    }
  end
  
  def test_must_subtract_minutes_in_a_patterned_week
    start=DateTime.new(2000,1,1,0,0) #saturday
    finish=DateTime.new(2005,12,31,8,59) #saturday
    working_week=week(start,finish,0)
    working_week.workpattern(:sun,clock(9,0),clock(9,13),1) 
    
    working_week.workpattern(:weekday,clock(9,0),clock(11,59),1)
    working_week.workpattern(:weekday,clock(13,0),clock(17,59),1)
    
    working_week.workpattern(:mon,clock(0,0),clock(23,59),0) 
    working_week.workpattern(:mon,clock(9,0),clock(9,13),1)
    working_week.workpattern(:mon,clock(10,1),clock(10,1),1)        
    
    
    [# yyyy,mm,dd,hh,mn,durtn,midnight,ryyyy,rmm,rdd,rhh,rmn,rdurtn,rmidnight
     [ 2000, 1, 1, 0, 0,    0,   false, 2000,  1,  1,  0,  0,     0,   false],
     [ 2000, 1, 1, 0, 0,   -1,   false, 1999, 12, 31,  0,  0,     -1,   true],
     [ 2000, 1, 2, 9, 0,   14,   false, 2000,  1,  2,  9,  14,     0,   false], 
     [ 2000, 1, 2, 9, 0,   15,   false, 2000,  1,  3,  9,  1,     0,   false],
     [ 2000, 1, 2, 9, 0,   29,   false, 2000,  1,  3,  10,  2,     0,   false],     
     [ 2000, 1, 2, 9, 0, 1950,   false, 2000,  1,  9,   9,  1,     0,   false],
     [ 2005,12,25, 9, 0, 1950,   false, 2006,  1,  1,   0,  0,     1,   false],
     [ 2005,12,25, 9, 0, 1949,   false, 2005, 12, 30,  18,  0,     0,   false]#,          
    ].each {|yyyy,mm,dd,hh,mn,durtn,midnight,ryyyy,rmm,rdd,rhh,rmn,rdurtn,rmidnight|
      start=DateTime.new(yyyy,mm,dd,hh,mn)   
      result_date, result_duration,result_midnight= working_week.calc(start,durtn,midnight)
      assert_equal DateTime.new(ryyyy,rmm,rdd,rhh,rmn), result_date, "result_date for working_week.calc(#{start},#{durtn},#{midnight})"
      assert_equal rdurtn, result_duration,"result_duration for working_week.calc(#{start},#{durtn},#{midnight})"
      assert_equal rmidnight, result_midnight,"result_midnight for working_week.calc(#{start},#{durtn},#{midnight})"      
    }
  end
  
  def test_must_calculate_difference_between_dates_in_working_week
    start=DateTime.new(2012,10,1)
    finish=DateTime.new(2012,10,7)
    week=week(start,finish,1)
        
    [
     [ 2012,10, 1, 0, 0, 2012,10, 1, 0, 0,    0,2012,10, 1, 0, 0],
     [ 2012,10, 1, 0, 0, 2012,10, 1, 0, 1,    1,2012,10, 1, 0, 1],
     [ 2012,10, 1, 0,50, 2012,10, 1, 0,59,    9,2012,10, 1, 0,59],
     [ 2012,10, 1, 8,50, 2012,10, 1, 9, 0,   10,2012,10, 1, 9, 0],
     [ 2012,10, 1, 0, 0, 2012,10, 1,23,59, 1439,2012,10, 1,23,59],
     [ 2012,10, 1, 0, 0, 2012,10, 2, 0, 0, 1440,2012,10, 2, 0, 0],
     [ 2012,10, 1, 0, 0, 2012,10, 2, 0, 1, 1441,2012,10, 2, 0, 1],     
     [ 2012,10, 1, 0, 0, 2013, 3,22, 6,11,10080,2012,10, 8, 0, 0],
     [ 2012,10, 1, 0, 1, 2012,10, 1, 0, 0,    1,2012,10, 1, 0, 1],
     [ 2012,10, 1, 0,59, 2012,10, 1, 0,50,    9,2012,10, 1, 0,59],
     [ 2012,10, 1, 9, 0, 2012,10, 1, 8,50,   10,2012,10, 1, 9, 0],
     [ 2012,10, 1,23,59, 2012,10, 1, 0, 0, 1439,2012,10, 1,23,59],
     [ 2012,10, 2, 0, 0, 2012,10, 1, 0, 0, 1440,2012,10, 2, 0, 0],
     [ 2012,10, 2, 0, 1, 2012,10, 1, 0, 0, 1441,2012,10, 2, 0, 1],     
     [ 2013, 3,22, 6,11, 2012,10, 1, 0, 0,10080,2012,10, 8, 0, 0],
     [ 2012,10, 2, 6,11, 2012,10, 4, 8, 9, 2998,2012,10, 4, 8, 9]
    ].each {|start_year, start_month, start_day, start_hour,start_min,
             finish_year, finish_month, finish_day, finish_hour,finish_min,result,
             y,m,d,h,n|
      start=DateTime.new(start_year, start_month, start_day, start_hour,start_min)
      finish=DateTime.new(finish_year, finish_month, finish_day, finish_hour,finish_min)
      expected_date=DateTime.new(y,m,d,h,n)       
      duration, result_date=week.diff(start,finish)
      assert_equal result, duration,"duration diff(#{start}, #{finish})"
      assert_equal expected_date, result_date,"date diff(#{start}, #{finish})"
    }
  end

  def test_must_calculate_difference_between_dates_in_resting_week

    start=DateTime.new(2012,10,1)
    finish=DateTime.new(2012,10,7)
    week=week(start,finish,0)
  
    [
     [ 2012,10, 1, 0, 0, 2012,10, 1, 0, 0,   0,2012,10, 1, 0, 0],
     [ 2012,10, 1, 0, 0, 2012,10, 1, 0, 1,   0,2012,10, 1, 0, 1],
     [ 2012,10, 1, 0,50, 2012,10, 1, 0,59,   0,2012,10, 1, 0,59],
     [ 2012,10, 1, 8,50, 2012,10, 1, 9, 0,   0,2012,10, 1, 9, 0],
     [ 2012,10, 1, 0, 0, 2012,10, 1,23,59,   0,2012,10, 1,23,59],
     [ 2012,10, 1, 0, 0, 2012,10, 2, 0, 0,   0,2012,10, 2, 0, 0],
     [ 2012,10, 1, 0, 0, 2012,10, 2, 0, 1,   0,2012,10, 2, 0, 1],     
     [ 2012,10, 1, 0, 0, 2013, 3,22, 6,11,   0,2012,10, 8, 0, 0],
     [ 2012,10, 1, 0, 1, 2012,10, 1, 0, 0,   0,2012,10, 1, 0, 1],
     [ 2012,10, 1, 0,59, 2012,10, 1, 0,50,   0,2012,10, 1, 0,59],
     [ 2012,10, 1, 9, 0, 2012,10, 1, 8,50,   0,2012,10, 1, 9, 0],
     [ 2012,10, 1,23,59, 2012,10, 1, 0, 0,   0,2012,10, 1,23,59],
     [ 2012,10, 2, 0, 0, 2012,10, 1, 0, 0,   0,2012,10, 2, 0, 0],
     [ 2012,10, 2, 0, 1, 2012,10, 1, 0, 0,   0,2012,10, 2, 0, 1],     
     [ 2013, 3,22, 6,11, 2012,10, 1, 0, 0,   0,2012,10, 8, 0, 0]
    ].each {|start_year, start_month, start_day, start_hour,start_min,
             finish_year, finish_month, finish_day, finish_hour,finish_min,result,
             y,m,d,h,n|
      start=DateTime.new(start_year, start_month, start_day, start_hour,start_min)
      finish=DateTime.new(finish_year, finish_month, finish_day, finish_hour,finish_min)
      expected_date=DateTime.new(y,m,d,h,n)       
      duration, result_date=week.diff(start,finish)
      assert_equal result, duration,"duration diff(#{start}, #{finish})"
      assert_equal expected_date, result_date,"date diff(#{start}, #{finish})"
     }
  end

  def test_must_calculate_difference_between_dates_in_pattern_week
    start=DateTime.new(2000,1,1)
    finish=DateTime.new(2012,12,31)
    week=week(start,finish,1)
    return
    [[0,0,8,59],
     [12,0,12,59],
     [17,0,22,59]
    ].each {|start_hour,start_min,finish_hour,finish_min|
      week.workpattern(clock(start_hour, start_min),
                      clock(finish_hour, finish_min),
                      0)
    }
    assert_equal 480, day.total, "minutes in patterned day should be 480"
    assert_equal 1, day.minutes(16,59,16,59),"16:59 should be 1"
    assert_equal 0, day.minutes(17,0,17,0),"17:00 should be 0"
    assert_equal 0, day.minutes(22,59,22,59),"22:59 should be 0"
    assert_equal 1, day.minutes(23,0,23,0),"23:00 should be 1"
  
    [
     [ 2012,10, 1, 0, 0, 2012,10, 1, 0, 0,   0,2012,10, 1, 0, 0],
     [ 2012,10, 1, 0, 0, 2012,10, 1, 0, 1,   0,2012,10, 1, 0, 1],
     [ 2012,10, 1, 0,50, 2012,10, 1, 9,59,  59,2012,10, 1, 9,59],
     [ 2012,10, 1, 8,50, 2012,10, 1, 9,10,  10,2012,10, 1, 9,10],
     [ 2012,10, 1, 0, 0, 2012,10, 1,23,59, 479,2012,10, 1,23,59],
     [ 2012,10, 1, 0, 0, 2012,10, 2, 0, 0, 480,2012,10, 2, 0, 0],
     [ 2012,10, 1, 0, 0, 2012,10, 2, 0, 1, 480,2012,10, 2, 0, 0],     
     [ 2012,10, 1, 0, 0, 2013, 3,22, 6,11, 480,2012,10, 2, 0, 0],
     [ 2012,10, 1, 0, 1, 2012,10, 1, 0, 0,   0,2012,10, 1, 0, 1],
     [ 2012,10, 1, 9,59, 2012,10, 1, 0,50,  59,2012,10, 1, 9,59],
     [ 2012,10, 1, 9, 0, 2012,10, 1, 8,50,   0,2012,10, 1, 9, 0],
     [ 2012,10, 1,23,59, 2012,10, 1, 0, 0, 479,2012,10, 1,23,59],
     [ 2012,10, 2, 0, 0, 2012,10, 1, 0, 0, 480,2012,10, 2, 0, 0],
     [ 2012,10, 2, 0, 1, 2012,10, 1, 0, 0, 480,2012,10, 2, 0, 0],     
     [ 2013, 3,22, 6,11, 2012,10, 1, 0, 0, 480,2012,10, 2, 0, 0]
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
  
  def week(start,finish,type)
    return Workpattern::Week.new(start,finish,type)
  end 
  
  def clock(hour,min)
    return Workpattern.clock(hour,min)
  end 
end

