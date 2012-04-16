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

  must "follow the example in workpattern" do
    mywp=Workpattern.new('My Workpattern',2011,10)
    mywp.resting(:days => :weekend)
    mywp.resting(:days =>:weekday, :from_time=>Workpattern.clock(0,0),:to_time=>Workpattern.clock(8,59))
    mywp.resting(:days =>:weekday, :from_time=>Workpattern.clock(12,0),:to_time=>Workpattern.clock(12,59))
    mywp.resting(:days =>:weekday, :from_time=>Workpattern.clock(18,0),:to_time=>Workpattern.clock(23,59))
    mydate=DateTime.civil(2011,9,1,9,0)
    result_date = mywp.calc(mydate,1920) # => 6/9/11@18:00
    assert_equal DateTime.civil(2011,9,6,18,0), result_date, 'example in workpattern'
  end
  
  must "calculate across week patterns" do
    name='mypattern'
    base=2011
    span=11
    wp=Workpattern.new(name,base,span)
    start=DateTime.new(2012,9,24,0,0)
    finish=DateTime.new(2012,10,14,0,0)
    wp.resting(:days =>:all,:start=> start, :finish=>finish)    
    wp.working(:days =>:mon,:start=> start, :finish=>finish, :from_time=>Workpattern.clock(1,0),:to_time=>Workpattern.clock(1,59))        
    wp.working(:days =>:tue,:start=> start, :finish=>finish, :from_time=>Workpattern.clock(2,0),:to_time=>Workpattern.clock(2,59))        
    wp.working(:days =>:wed,:start=> start, :finish=>finish, :from_time=>Workpattern.clock(3,0),:to_time=>Workpattern.clock(3,59))        
    wp.working(:days =>:thu,:start=> start, :finish=>finish, :from_time=>Workpattern.clock(4,0),:to_time=>Workpattern.clock(4,59))        
    wp.working(:days =>:fri,:start=> start, :finish=>finish, :from_time=>Workpattern.clock(5,0),:to_time=>Workpattern.clock(5,59))        
    wp.working(:days =>:sat,:start=> start, :finish=>finish, :from_time=>Workpattern.clock(6,0),:to_time=>Workpattern.clock(6,59))        
    wp.working(:days =>:sun,:start=> start, :finish=>finish, :from_time=>Workpattern.clock(0,0),:to_time=>Workpattern.clock(23,59))        

    # Mon Tue Wed Thu Fri Sat Sun
    #  24  25  26  27  28  29  30
    #   1   2   3   4   5   6   7
    #   8   9  10  11  12  13  14
    # Mon 01:00 - 01:59
    # Tue 02:00 - 02:59
    # Wed 03:00 - 03:59
    # Thu 04:00 - 04:59
    # Fri 05:00 - 05:59
    # Sat 06:00 - 06:59
    # Sun 00:00 - 23:59
    #
    tests=[[2012,10,1,1,0,1,2012,10,1,1,1],
     [2012,10,14,23,59,1,2012,10,15,0,0],
     [2012,10,1,1,0,60*60+1,2012,10,15,0,1],
     [2012,10,1,2,0,-1,2012,10,1,1,59],
     [2012,10,2,3,0,-61,2012,10,1,1,59],
     [2012,9,24,1,1,-2,2012,9,23,23,59],
     [2012,10,1,1,59,61,2012,10,2,3,0],
     [2012,10,1,1,1,-1,2012,10,1,1,0],
     [2012,10,1,1,0,-1,2012,9,30,23,59]          
    ]
    clue="calculate across week patterns"
    calc_test(wp,tests,clue)
  end
  
  must "know whether a time is working or resting" do
    name='working?'
    base=2011
    span=11
    wp=Workpattern.new(name,base,span)
    wp.resting(:to_time=>Workpattern.clock(8,59))
    assert wp.working?(DateTime.new(2012,1,1,9,0))
    assert !wp.working?(DateTime.new(2012,1,1,8,59))    
  end
  
  
  private
  
  def get_week(ss)
    ss.each {|obj|  return obj}
  end  
  

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
