require File.dirname(__FILE__) + '/test_helper.rb'

class TestDay < MiniTest::Test #:nodoc:
  def setup
  end

  def test_creates_full_working_day
    myday = working_day
    assert_equal 1440, myday.working_minutes
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
     assert_equal 1440, myday.working_minutes
   end
 
   def test_total_minutes_resting_day
     myday = resting_day
     assert_equal 0, myday.working_minutes
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
     9.upto(23) do | hour |
       0.upto(59) do | minute |
         assert myday.working?(hour, minute), "Failed on #{hour}:#{minute}"
       end
     end
 
     assert_equal 900, myday.working_minutes
   end
 
   def test_add_rest_in_midday
     myday = working_day
 
     from_time = set_time(11,0)
     to_time = set_time(12,59)
     myday.set_resting(from_time, to_time)
     0.upto(10) do | hour |
       0.upto(59) do | minute |
         assert myday.working?(hour, minute), "Failed on #{hour}:#{minute}"
       end
     end    
     
     11.upto(12) do | hour |
       0.upto(59) do | minute |
         assert myday.resting?(hour, minute), "Failed on #{hour}:#{minute}"
       end
     end    
     13.upto(23) do | hour |
       0.upto(59) do | minute |
         assert myday.working?(hour, minute), "Failed on #{hour}:#{minute}"
       end
     end    
 
     assert_equal 1320, myday.working_minutes
   end
 
   def test_add_rest_at_end_of_day
     myday = working_day
     from_time = set_time(21,0)
     to_time = set_time(23,59)
     myday.set_resting(from_time, to_time)
     0.upto(20) do | hour |
       0.upto(59) do | minute |
         assert myday.working?(hour, minute), "Failed on #{hour}:#{minute}"
       end
     end    
     
     21.upto(23) do | hour |
       0.upto(59) do | minute |
         assert myday.resting?(hour, minute), "Failed on #{hour}:#{minute}"
       end
     end    
 
     assert_equal 1260, myday.working_minutes
   end
 
 
   def test_add_work_in_morning
     myday = resting_day
     from_time = set_time(0,0)
     to_time = set_time(8,59)
     myday.set_working(from_time, to_time)
     0.upto(8) do | hour |
       0.upto(59) do | minute |
         assert myday.working?(hour, minute), "Failed on #{hour}:#{minute}"
       end
     end    
     9.upto(23) do | hour |
       0.upto(59) do | minute |
         assert myday.resting?(hour, minute), "Failed on #{hour}:#{minute}"
       end
     end
 
     assert_equal 540, myday.working_minutes
   end
 
   def test_add_work_in_midday
     myday = resting_day
     from_time = set_time(11,0)
     to_time = set_time(12,59)
     myday.set_working(from_time, to_time)
     0.upto(10) do | hour |
       0.upto(59) do | minute |
         assert myday.resting?(hour, minute), "Failed on #{hour}:#{minute}"
       end
     end    
     
     11.upto(12) do | hour |
       0.upto(59) do | minute |
         assert myday.working?(hour, minute), "Failed on #{hour}:#{minute}"
       end
     end    
     13.upto(23) do | hour |
       0.upto(59) do | minute |
         assert myday.resting?(hour, minute), "Failed on #{hour}:#{minute}"
       end
     end    
 
     assert_equal 120, myday.working_minutes
   end
 
   def test_add_work_at_end_of_day
     myday = resting_day
     from_time = set_time(21,0)
     to_time = set_time(23,59)
     myday.set_working(from_time, to_time)
     0.upto(20) do | hour |
       0.upto(59) do | minute |
         assert myday.resting?(hour, minute), "Failed on #{hour}:#{minute}"
       end
     end    
     
     21.upto(23) do | hour |
       0.upto(59) do | minute |
         assert myday.working?(hour, minute), "Failed on #{hour}:#{minute}"
       end
     end    
 
     assert_equal 180, myday.working_minutes
   end
 
   def test_minutes_in_part_of_day
     myday = working_day
     myday.set_resting(set_time(0,13), set_time(1,19))
     myday.set_resting(set_time(11,47), set_time(12,21))
     myday.set_resting(set_time(22,43), set_time(23,11))
 
     assert_equal 114, myday.working_minutes(set_time(0,0), set_time(3,0))
     assert_equal 146, myday.working_minutes(set_time(11,0), set_time(14,0))
     assert_equal 151, myday.working_minutes(set_time(21,0), set_time(23,59))
     assert_equal 1309, myday.working_minutes(set_time(0,0), set_time(23,59))
   end
 
   def test_must_diff_long_distances_within_patterned_week
 
     d_day =working_day 
     d_day.set_resting(Workpattern.clock(0,0),
                       Workpattern.clock(8, 59))
     d_day.set_resting(Workpattern.clock(12,0),
                       Workpattern.clock(12,59))
     d_day.set_resting(Workpattern.clock(18,0),
                       Workpattern.clock(23,59))
 
     s_date = Workpattern.clock(17,0)
     f_date = Workpattern.clock(10,0)
 
     d_minutes = d_day.working_minutes()
     start_minutes = d_day.working_minutes(s_date)
     finish_minutes = d_day.working_minutes(Workpattern::FIRST_TIME_IN_DAY,f_date)
 
     assert_equal 61, finish_minutes, "finish_minutes"
     assert_equal 60, start_minutes,"start_minutes"
     assert_equal 480, d_minutes, "d_minutes"
   end

   def test_add_durations_to_working_day

     a_day = working_day
     a_date = Time.gm(1963,6,10,22,58)

     r_time, r_duration, r_offset = a_day.calc(a_date,30)
     
     assert_equal 23, r_time.hour, "should be 23 hours"
     assert_equal 28, r_time.min,  "should be 28 minutes"
     assert_equal 0, r_duration, "should be 0 duration"
     assert_equal Workpattern::SAME_DAY, r_offset, "should be SAME_DAY"

     
     r_time, r_duration, r_offset = a_day.calc(a_date,100)
     
     assert_equal 22, r_time.hour, "should be 23 hours"
     assert_equal 58, r_time.min,  "should be 28 minutes"
     assert_equal 38, r_duration, "should be 0 duration"
     assert_equal Workpattern::NEXT_DAY, r_offset, "should be SAME_DAY"

     r_time, r_duration, r_offset = a_day.calc(a_date,62)
     
     assert_equal 22, r_time.hour, "should be 23 hours"
     assert_equal 58, r_time.min,  "should be 28 minutes"
     assert_equal 0, r_duration, "should be 0 duration"
     assert_equal Workpattern::NEXT_DAY, r_offset, "should be SAME_DAY"

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
