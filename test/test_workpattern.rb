require File.dirname(__FILE__) + '/test_helper.rb'

class TestWorkpattern < Test::Unit::TestCase #:nodoc:

  def setup
    Workpattern.clear()    
  end
  
  must "create a working workpattern" do
    name='mywp'
    base=2001
    span=11
    wp=Workpattern.new(name,base,span)
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
    wp=Workpattern.new(name,base,span)
 
    start=clock(0,0)
    finish=clock(8,59)    
    assert_equal 10080, get_week(wp.weeks).week_total
    wp.workpattern(:days=>:all,:from_time=>start,:to_time=>finish,:work_type=>0)
    assert_equal 6300, get_week(wp.weeks).week_total
    wp.workpattern(:days=>:sun,:from_time=>start,:to_time=>finish,:work_type=>1)
    assert_equal 6840, get_week(wp.weeks).week_total
    wp.workpattern(:days=>:mon,:from_time=>start,:to_time=>finish,:work_type=>1)
    assert_equal 7380, get_week(wp.weeks).week_total
    wp.workpattern(:days=>:all,:from_time=>clock(18,0),:to_time=>clock(18,19),:work_type=>0)
    assert_equal 7240, get_week(wp.weeks).week_total
    wp.workpattern(:days=>:all,:from_time=>clock(0,0),:to_time=>clock(23,59),:work_type=>0)
    assert_equal 0, get_week(wp.weeks).week_total
    wp.workpattern(:days=>:all,:from_time=>clock(0,0),:to_time=>clock(0,0),:work_type=>1)
    assert_equal 7, get_week(wp.weeks).week_total
    wp.workpattern(:days=>:all,:from_time=>clock(23,59),:to_time=>clock(23,59),:work_type=>1)
    assert_equal 14, get_week(wp.weeks).week_total
    wp.workpattern(:days=>:all,:from_time=>clock(0,0),:to_time=>clock(23,59),:work_type=>1)
    assert_equal 10080, get_week(wp.weeks).week_total
    wp.workpattern(:days=>:weekend,:from_time=>clock(0,0),:to_time=>clock(23,59),:work_type=>0)
    assert_equal 7200, get_week(wp.weeks).week_total
    
  end
  
  must 'add minutes in a working workpattern' do
    name='mypattern'
    base=1999
    span=11
    wp=Workpattern.new(name,base,span)
    tests=[[2000,1,1,0,0,3,2000,1,1,0,3],
     [2000,1,1,23,59,0,2000,1,1,23,59],
     [2000,1,1,23,59,1,2000,1,2,0,0],
     [2000,1,1,23,59,2,2000,1,2,0,1],
     [2000,1,1,9,10,33,2000,1,1,9,43],
     [2000,1,1,9,10,60,2000,1,1,10,10],
     [2000,1,1,9,0,931,2000,1,2,0,31],
     [2000,1,1,0,0,3,2000,1,1,0,3]
    ]
    clue="add minutes in a working workpattern"
    calc_test(wp,tests,clue) 
  end
  
  must 'add minutes in a resting workpattern' do
    name='mypattern'
    base=1999
    span=11
    wp=Workpattern.new(name,base,span)
    start=DateTime.new(1999,6,11,0,0)
    finish=DateTime.new(2003,6,8,0,0)
    wp.workpattern(:days=>:all,:start=> start, :finish=>finish, :work_type=>0 )
    tests=[[2000,1,1,0,0,3,2003,6,9,0,3],
     [2000,1,1,23,59,0,2000,1,1,23,59],
     [2000,1,1,23,59,1,2003,6,9,0,1],
     [2000,1,1,23,59,2,2003,6,9,0,2],
     [2000,1,1,9,10,33,2003,6,9,0,33],
     [2000,1,1,9,10,60,2003,6,9,1,0],
     [2000,1,1,9,0,931,2003,6,9,15,31],
     [2000,1,1,0,0,3,2003,6,9,0,3]
    ]
    clue="add minutes in a resting workpattern"
    calc_test(wp,tests,clue) 
  end
  
  must 'add minutes in a patterned workpattern' do
    assert true
  end
  
  must 'subtract minutes in a working workpattern' do
    name='mypattern'
    base=1999
    span=11
    wp=Workpattern.new(name,base,span)
    tests=[[2000,1,1,0,0,-3,1999,12,31,23,57],
     [2000,1,1,23,59,0,2000,1,1,23,59],
     [2000,1,1,23,59,-1,2000,1,1,23,58],
     [2000,1,1,23,59,-2,2000,1,1,23,57],
     [2000,1,1,9,10,-33,2000,1,1,8,37],
     [2000,1,1,9,10,-60,2000,1,1,8,10],
     [2000,1,1,9,0,-931,1999,12,31,17,29],
     [2000,1,1,0,0,-3,1999,12,31,23,57]
    ]
    clue="subtract minutes in a working workpattern"
    calc_test(wp,tests,clue) 
  end
  
  must 'subtract minutes in a resting workpattern' do
    name='mypattern'
    base=1999
    span=11
    wp=Workpattern.new(name,base,span)
    start=DateTime.new(1999,6,11,0,0)
    finish=DateTime.new(2003,6,8,0,0)
    wp.workpattern(:days=>:all,:start=> start, :finish=>finish, :work_type=>0 )
    tests=[[2000,1,1,0,0,-3,1999,6,10,23,57],
     [2000,1,1,23,59,0,2000,1,1,23,59],
     [2000,1,1,23,59,-1,1999,6,10,23,59],
     [2000,1,1,23,59,-2,1999,6,10,23,58],
     [2000,1,1,9,10,-33,1999,6,10,23,27],
     [2000,1,1,9,10,-60,1999,6,10,23,0],
     [2000,1,1,9,0,-931,1999,6,10,8,29],
     [2000,1,1,0,0,-3,1999,6,10,23,57]
    ]
    clue="subtract minutes in a resting workpattern"
    calc_test(wp,tests,clue)
  end
  
  must 'subtract minutes in a patterned workpattern' do
    assert true
  end
  
  
  must "calculate difference between minutes in workpattern" do
    assert true
  end

  must "calculate difference between minutes in resting workpattern" do
    assert true
  end

  must "calculate difference between minutes in pattern workpattern" do
    assert true 
  end

  private
  
  def get_week(ss)
    ss.each {|obj|  return obj}
  end  
  
  private

  def calc_test(wp,tests,clue)
    
    tests.each{|y,m,d,h,n,add,yr,mr,dr,hr,nr|
      start_date=DateTime.new(y,m,d,h,n)
      result_date = wp.calc(start_date,add)
      assert_equal DateTime.new(yr,mr,dr,hr,nr), result_date, "result date calc(#{start_date},#{add}) for #{clue}"
    }
  end
  def clock(hour,min)
    return Workpattern.clock(hour,min)
  end
end
