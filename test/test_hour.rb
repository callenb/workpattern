require File.dirname(__FILE__) + '/test_helper.rb'

class TestHour < Test::Unit::TestCase #:nodoc:

  def setup
    @working_hour = Workpattern::WORKING_HOUR
    @resting_hour = Workpattern::RESTING_HOUR
  end
  
  must "ceate a working hour" do
    working_hour = Workpattern::WORKING_HOUR
    assert_equal 60, working_hour.total,"working total minutes"
  end
    
  must "ceate a resting hour" do
    resting_hour = Workpattern::RESTING_HOUR
    assert_equal 0, resting_hour.total,"resting total minutes"
  end
  
  must "set patterns correctly" do
    working_hour = Workpattern::WORKING_HOUR
    working_hour = working_hour.workpattern(0,0,0)
    working_hour = working_hour.workpattern(59,59,0)
    working_hour = working_hour.workpattern(11,30,0)
    assert_equal 38,working_hour.total, "total working minutes"
    assert_equal 1, working_hour.first, "first minute of the day"
    assert_equal 58, working_hour.last, "last minute of the day"
    assert !working_hour.working?(0)
    assert working_hour.working?(1)
  end
  
  must 'add minutes in a working hour' do
    
    working_hour = Workpattern::WORKING_HOUR
    [
     [2000,1,1,0,0,3,2000,1,1,0,3,0],
     [2000,1,1,0,0,0,2000,1,1,0,0,0],
     [2000,1,1,0,59,0,2000,1,1,0,59,0],
     [2000,1,1,0,11,3,2000,1,1,0,14,0],
     [2000,1,1,0,0,60,2000,1,1,1,0,0],
     [2000,1,1,0,0,61,2000,1,1,1,0,1],
     [2000,1,1,0,30,60,2000,1,1,1,0,30],
     [2000,12,31,23,59,1,2001,1,1,0,0,0]
    ].each{|y,m,d,h,n,add,yr,mr,dr,hr,nr,rem|
      start=DateTime.new(y,m,d,h,n)
      result,remainder = working_hour.calc(start,add)
      assert_equal DateTime.new(yr,mr,dr,hr,nr), result, "result calc(#{start},#{add})"
      assert_equal rem, remainder, "remainder calc(#{start},#{add})"  
    }
    
  end
  
  must 'add minutes in a resting hour' do
    resting_hour = Workpattern::RESTING_HOUR
    [
     [2000,1,1,0,0,3,2000,1,1,1,0,3],
     [2000,1,1,0,0,0,2000,1,1,0,0,0],
     [2000,1,1,0,59,0,2000,1,1,0,59,0],
     [2000,1,1,0,11,3,2000,1,1,1,0,3],
     [2000,1,1,0,0,60,2000,1,1,1,0,60],
     [2000,1,1,0,0,61,2000,1,1,1,0,61],
     [2000,1,1,0,30,60,2000,1,1,1,0,60],
     [2000,12,31,23,59,1,2001,1,1,0,0,1]
    ].each{|y,m,d,h,n,add,yr,mr,dr,hr,nr,rem|
      start=DateTime.new(y,m,d,h,n)
      result,remainder = resting_hour.calc(start,add)
      assert_equal DateTime.new(yr,mr,dr,hr,nr), result, "result calc(#{start},#{add})"
      assert_equal rem, remainder, "remainder calc(#{start},#{add})"  
    }
    
  end
  
  must 'add minutes in a patterned hour' do

    pattern_hour = Workpattern::WORKING_HOUR
    pattern_hour = pattern_hour.workpattern(1,10,0)
    pattern_hour = pattern_hour.workpattern(55,59,0)
    [
     [2000,1,1,0,0,3,2000,1,1,0,13,0],
     [2000,1,1,0,0,0,2000,1,1,0,0,0],
     [2000,1,1,0,59,0,2000,1,1,0,59,0],
     [2000,1,1,0,11,3,2000,1,1,0,14,0],
     [2000,1,1,0,0,60,2000,1,1,1,0,15],
     [2000,1,1,0,0,61,2000,1,1,1,0,16],
     [2000,1,1,0,30,60,2000,1,1,1,0,35],
     [2000,12,31,23,59,1,2001,1,1,0,0,1]
    ].each{|y,m,d,h,n,add,yr,mr,dr,hr,nr,rem|
      start=DateTime.new(y,m,d,h,n)
      result,remainder = pattern_hour.calc(start,add)
      assert_equal DateTime.new(yr,mr,dr,hr,nr), result, "result calc(#{start},#{add})"
      assert_equal rem, remainder, "remainder calc(#{start},#{add})"  
    }
    
  end
  
  must 'subtract minutes in a working hour' do
    working_hour = Workpattern::WORKING_HOUR
    [
     [2000,1,1,0,10,-3,2000,1,1,0,7,0],
     [2000,1,1,0,10,0,2000,1,1,0,10,0],
     [2000,1,1,0,59,0,2000,1,1,0,59,0],
     [2000,1,1,0,11,-3,2000,1,1,0,8,0],
     [2000,1,1,0,10,-60,2000,1,1,0,0,-50],
     [2000,1,1,0,10,-61,2000,1,1,0,0,-51],
     [2000,1,1,0,30,-60,2000,1,1,0,0,-30],
     [2001,1,1,0,0,-1,2001,1,1,0,0,-1]
    ].each{|y,m,d,h,n,add,yr,mr,dr,hr,nr,rem|
      start=DateTime.new(y,m,d,h,n)
      result,remainder = working_hour.calc(start,add)
      assert_equal DateTime.new(yr,mr,dr,hr,nr), result, "result calc(#{start},#{add})"
      assert_equal rem, remainder, "remainder calc(#{start},#{add})"  
    }
    
  end
  
  must 'subtract minutes in a resting hour' do
    resting_hour = Workpattern::RESTING_HOUR
    [
     [2000,1,1,0,10,-3,2000,1,1,0,0,-3],
     [2000,1,1,0,10,0,2000,1,1,0,10,0],
     [2000,1,1,0,59,0,2000,1,1,0,59,0],
     [2000,1,1,0,11,-3,2000,1,1,0,0,-3],
     [2000,1,1,0,10,-60,2000,1,1,0,0,-60],
     [2000,1,1,0,10,-61,2000,1,1,0,0,-61],
     [2000,1,1,0,30,-60,2000,1,1,0,0,-60],
     [2001,1,1,0,0,-1,2001,1,1,0,0,-1]
    ].each{|y,m,d,h,n,add,yr,mr,dr,hr,nr,rem|
      start=DateTime.new(y,m,d,h,n)
      result,remainder = resting_hour.calc(start,add)
      assert_equal DateTime.new(yr,mr,dr,hr,nr), result, "result calc(#{start},#{add})"
      assert_equal rem, remainder, "remainder calc(#{start},#{add})"  
    }
    
  end
  
  must 'subtract minutes in a patterned hour' do
  
    pattern_hour = Workpattern::WORKING_HOUR
    pattern_hour = pattern_hour.workpattern(1,10,0)
    pattern_hour = pattern_hour.workpattern(55,59,0)
    [
     [2000,1,1,0,0,-3,2000,1,1,0,0,-3],
     [2000,1,1,0,0,0,2000,1,1,0,0,0],
     [2000,1,1,0,59,0,2000,1,1,0,59,0],
     [2000,1,1,0,11,-2,2000,1,1,0,0,-1],
     [2000,1,1,0,0,-60,2000,1,1,0,0,-60],
     [2000,1,1,0,0,-61,2000,1,1,0,0,-61],
     [2000,1,1,0,30,-60,2000,1,1,0,0,-40],
     [2001,1,1,23,59,-1,2001,1,1,23,54,0]
    ].each{|y,m,d,h,n,add,yr,mr,dr,hr,nr,rem|
      start=DateTime.new(y,m,d,h,n)
      result,remainder = pattern_hour.calc(start,add)
      assert_equal DateTime.new(yr,mr,dr,hr,nr), result, "result calc(#{start},#{add})"
      assert_equal rem, remainder, "remainder calc(#{start},#{add})"  
    }
  end
  
  
  must 'create complex patterns' do
    working_hour = Workpattern::WORKING_HOUR
    control=Array.new(60) {|i| 1}
    j=0
    [[0,0,0,59,1,59],
     [59,59,0,58,1,58],
     [11,30,0,38,1,58],
     [1,15,0,28,31,58],
     [2,5,1,32,2,58],
     [0,59,1,60,0,59],
     [0,59,0,0,nil,nil],
     [0,0,1,1,0,0],
     [59,59,1,2,0,59]
    ].each{|start,finish,type,total,first,last|
      working_hour = working_hour.workpattern(start,finish,type)
      assert_equal total,working_hour.total, "total working minutes #{j}"
      assert_equal first, working_hour.first, "first minute of the day #{j}"
      assert_equal last, working_hour.last, "last minute of the day #{j}"  
      start.upto(finish) {|i| control[i]=type}
      0.upto(59) {|i|
        if (control[i]==0)
          assert !working_hour.working?(i)    
        else
          assert working_hour.working?(i)
        end
      }
      j+=1
    }
  end

  must "calculate difference between minutes in working hour" do

    working_hour = Workpattern::WORKING_HOUR
    [[0,0,0],
     [0,1,1],
     [50,59,9],
     [50,60,10],
     [0,59,59],
     [0,60,60]
    ].each {|start,finish,result|
      assert_equal result, working_hour.diff(start,finish),"diff(#{start},#{finish})"
    }
    
  end

  must "calculate difference between minutes in resting hour" do
    resting_hour = Workpattern::RESTING_HOUR
    [[0,0,0],
     [0,1,0],
     [50,59,0],
     [50,60,0],
     [0,59,0],
     [0,60,0]
    ].each {|start,finish,result|
      assert_equal result, resting_hour.diff(start,finish),"diff(#{start},#{finish})"
    }
    
  end

  must "calculate difference between minutes in pattern hour" do

    pattern_hour = Workpattern::WORKING_HOUR
    pattern_hour = pattern_hour.workpattern(1,10,0)
    pattern_hour = pattern_hour.workpattern(55,59,0)
    pattern_hour = pattern_hour.workpattern(59,59,1)
    
    [[0,0,0],
     [0,1,1],
     [50,59,5],
     [50,60,6],
     [0,59,45],
     [0,60,46]
    ].each {|start,finish,result|
      assert_equal result, pattern_hour.diff(start,finish),"diff(#{start},#{finish})"
    }  
  end

end

