require File.dirname(__FILE__) + '/test_helper.rb'

class TestWeek < Test::Unit::TestCase #:nodoc:

  def setup
    
  end
  
  must "create a working week" do
    start=DateTime.new(2000,1,1,11,3)
    finish=DateTime.new(2005,12,31,16,41)
    working_week=week(start,finish,1)
    assert_equal DateTime.new(start.year,start.month,start.day), working_week.start
    assert_equal DateTime.new(finish.year,finish.month,finish.day), working_week.finish
    assert_equal 3156480, working_week.total#2192
  end
    
  must "create a resting week" do
    start=DateTime.new(2000,1,1,11,3)
    finish=DateTime.new(2005,12,31,16,41)
    resting_week=week(start,finish,0)
    assert_equal DateTime.new(start.year,start.month,start.day), resting_week.start
    assert_equal DateTime.new(finish.year,finish.month,finish.day), resting_week.finish
    assert_equal 0, resting_week.total#2192
    assert_equal 0,resting_week.week_total
  end
  
  must 'duplicate all of a week' do
    start=DateTime.new(2000,1,1,11,3)
    finish=DateTime.new(2005,12,31,16,41)
    week=week(start,finish,1)
    new_week=week.duplicate
    assert_equal DateTime.new(start.year,start.month,start.day), new_week.start
    assert_equal DateTime.new(finish.year,finish.month,finish.day), new_week.finish
    assert_equal 3156480, new_week.total#2192
    
  end
  
  must "set patterns correctly" do
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
  
  must 'add minutes in a working week' do
    start=DateTime.new(2000,1,1,0,0)
    finish=DateTime.new(2005,12,31,8,59)
    working_week=week(start,finish,1)
    result_date, result_duration= working_week.calc(start,0)
    assert_equal start,result_date, "#{start} + #{0}"
    result_date,result_duration=working_week.calc(finish,0)
    assert_equal finish,result_date, "#{finish} + #{0}"
    result_date,result_duration=working_week.calc(finish,10)
    assert_equal DateTime.new(2005,12,31,9,9),result_date, "#{finish} + #{10}"
  end
  
  must 'add minutes in a resting week' do
    assert true
  end
  
  must 'add minutes in a patterned week' do
    assert true
  end
  
  must 'subtract minutes in a working week' do
    start=DateTime.new(2000,1,1,0,0)
    finish=DateTime.new(2005,12,31,8,59)
    working_week=week(start,finish,1)
    result_date, result_duration= working_week.calc(start,0)
    assert_equal start,result_date, "#{start} + #{0}"
    result_date,result_duration=working_week.calc(finish,0)
    assert_equal finish,result_date, "#{finish} + #{0}"
    result_date,result_duration=working_week.calc(finish,-10)
    assert_equal DateTime.new(2005,12,31,8,49),result_date, "#{finish} - #{10}"
    result_date,result_duration=working_week.calc(DateTime.new(2005,12,31,0,0),-10)
    assert_equal DateTime.new(2005,12,30,23,50),result_date, "#{DateTime.new(2005,12,31,0,0)} - #{10}"
  end
  
  must 'subtract minutes in a resting week' do
    assert true
  end
  
  must 'subtract minutes in a patterned week' do
    assert true
  end
  
  
  must 'create complex patterns' do
    assert true
  end

  must "calculate difference between minutes in working week" do
    assert true
  end

  must "calculate difference between minutes in resting week" do
    assert true
  end

  must "calculate difference between minutes in pattern week" do
    assert true 
  end
  
  private
  
  def week(start,finish,type)
    return Workpattern::Week.new(start,finish,type)
  end 
  
  def clock(hour,min)
    return Workpattern.clock(hour,min)
  end 
end

