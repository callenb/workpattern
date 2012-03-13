require File.dirname(__FILE__) + '/test_helper.rb'

class TestWorkpattern < Test::Unit::TestCase #:nodoc:

  def setup
    
  end
  
  must "create a working workpattern" do
    name='mywp'
    base=2001
    span=11
    wp=Workpattern::Workpattern.new(name,base,span)
    assert_equal name, wp.name
    assert_equal base, wp.base
    assert_equal span, wp.span
    assert_equal DateTime.new(base), wp.from
    assert_equal DateTime.new(base+span-1,12,31,23,59), wp.to
  end
  
  must "set patterns correctly" do
    name='mypattern'
    base=2000
    span=11
    wp=Workpattern::Workpattern.new(name,base,span)
 
    start=DateTime.new(2000,1,1,0,0)
    finish=DateTime.new(2005,12,31,8,59)
    assert_equal 10080, get_week(wp.weeks).week_total
    wp.workpattern(:days=>:all,:from_time=>start,:to_time=>finish,:work_type=>0)
    assert_equal 6300, get_week(wp.weeks).week_total
    wp.workpattern(:days=>:sun,:from_time=>start,:to_time=>finish,:work_type=>1)
    assert_equal 6840, get_week(wp.weeks).week_total
    wp.workpattern(:days=>:mon,:from_time=>start,:to_time=>finish,:work_type=>1)
    assert_equal 7380, get_week(wp.weeks).week_total
    wp.workpattern(:days=>:all,:from_time=>DateTime.new(2000,1,1,18,0),:to_time=>DateTime.new(2000,1,1,18,19),:work_type=>0)
    assert_equal 7240, get_week(wp.weeks).week_total
    wp.workpattern(:days=>:all,:from_time=>DateTime.new(2000,1,1,0,0),:to_time=>DateTime.new(2000,1,1,23,59),:work_type=>0)
    assert_equal 0, get_week(wp.weeks).week_total
    wp.workpattern(:days=>:all,:from_time=>DateTime.new(2000,1,1,0,0),:to_time=>DateTime.new(2000,1,1,0,0),:work_type=>1)
    assert_equal 7, get_week(wp.weeks).week_total
    wp.workpattern(:days=>:all,:from_time=>DateTime.new(2000,1,1,23,59),:to_time=>DateTime.new(2000,1,1,23,59),:work_type=>1)
    assert_equal 14, get_week(wp.weeks).week_total
    wp.workpattern(:days=>:all,:from_time=>DateTime.new(2000,1,1,0,0),:to_time=>DateTime.new(2000,1,1,23,59),:work_type=>1)
    assert_equal 10080, get_week(wp.weeks).week_total
    wp.workpattern(:days=>:weekend,:from_time=>DateTime.new(2000,1,1,0,0),:to_time=>DateTime.new(2000,1,1,23,59),:work_type=>0)
    assert_equal 7200, get_week(wp.weeks).week_total
    
  end
  
  must 'add minutes in a working week' do
    start=DateTime.new(2000,1,1,0,0)
    finish=DateTime.new(2005,12,31,8,59)
    working_week=Workpattern::Week.new(start,finish,1)
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
    working_week=Workpattern::Week.new(start,finish,1)
    result_date, result_duration= working_week.calc(start,0)
    assert_equal start,result_date, "#{start} + #{0}"
    result_date,result_duration=working_week.calc(finish,0)
    assert_equal finish,result_date, "#{finish} + #{0}"
    result_date,result_duration=working_week.calc(finish,-10)
    assert_equal DateTime.new(2005,12,31,8,49),result_date, "#{finish} + #{10}"
    result_date,result_duration=working_week.calc(DateTime.new(2005,12,31,0,0),-10)
    assert_equal DateTime.new(2005,12,30,23,50),result_date, "#{finish} - #{10}"
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
  
  def get_week(ss)
    ss.each {|obj|  return obj}
  end  
end

