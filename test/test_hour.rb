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
    assert !working_hour.minute?(0)
    assert working_hour.minute?(1)
  end
  
  must 'add minutes in a working hour' do
    
    working_hour = Workpattern::WORKING_HOUR
    result,remainder = working_hour.calc(0,3)
    assert_equal 3, result, "result calc(0,3)"
    assert_equal 0, remainder, "remainder calc(0,3)"
    
    result,remainder = working_hour.calc(0,0)
    assert_equal 0, result, "result calc(0,0)"
    assert_equal 0, remainder, "remainder calc(0,0)"
    
    result,remainder = working_hour.calc(59,0)
    assert_equal 59, result, "result calc(59,0)"
    assert_equal 0, remainder, "remainder calc(59,0)"
    
    result,remainder = working_hour.calc(11,0)
    assert_equal 11, result, "result calc(11,0)"
    assert_equal 0, remainder, "remainder calc(11,0)"
    
    result,remainder = working_hour.calc(0,60)
    assert_equal 60, result, "result calc(0,60)"
    assert_equal 0, remainder, "remainder calc(0,60)"
    
    result,remainder = working_hour.calc(0,61)
    assert_equal 60, result, "result calc(0,61)"
    assert_equal 1, remainder, "remainder calc(0,61)"
    
    result,remainder = working_hour.calc(30,60)
    assert_equal 60, result, "result calc(30,60)"
    assert_equal 30, remainder, "remainder calc(30,60)"
    
  end
  
  must 'add minutes in a resting hour' do
  
    resting_hour = Workpattern::RESTING_HOUR
    result,remainder = resting_hour.calc(0,3)
    assert_equal 60, result, "result calc(0,3)"
    assert_equal 3, remainder, "remainder calc(0,3)"
    
    result,remainder = resting_hour.calc(0,0)
    assert_equal 0, result, "result calc(0,0)"
    assert_equal 0, remainder, "remainder calc(0,0)"
    
    result,remainder = resting_hour.calc(59,0)
    assert_equal 59, result, "result calc(59,0)"
    assert_equal 0, remainder, "remainder calc(59,0)"
    
    result,remainder = resting_hour.calc(11,0)
    assert_equal 11, result, "result calc(11,0)"
    assert_equal 0, remainder, "remainder calc(11,0)"
    
    result,remainder = resting_hour.calc(0,60)
    assert_equal 60, result, "result calc(0,60)"
    assert_equal 60, remainder, "remainder calc(0,60)"
    
    result,remainder = resting_hour.calc(0,61)
    assert_equal 60, result, "result calc(0,61)"
    assert_equal 61, remainder, "remainder calc(0,61)"
    
    result,remainder = resting_hour.calc(30,60)
    assert_equal 60, result, "result calc(30,60)"
    assert_equal 60, remainder, "remainder calc(30,60)"
    
  end
  
  must 'add minutes in a patterned hour' do
    
    pattern_hour = Workpattern::WORKING_HOUR
    pattern_hour = pattern_hour.workpattern(1,10,0)
    pattern_hour = pattern_hour.workpattern(55,59,0)
    
    result,remainder = pattern_hour.calc(0,3)
    assert_equal 13, result, "result calc(0,3)"
    assert_equal 0, remainder, "remainder calc(0,3)"
    
    result,remainder = pattern_hour.calc(0,0)
    assert_equal 0, result, "result calc(0,0)"
    assert_equal 0, remainder, "remainder calc(0,0)"
    
    result,remainder = pattern_hour.calc(59,0)
    assert_equal 59, result, "result calc(59,0)"
    assert_equal 0, remainder, "remainder calc(59,0)"
    
    result,remainder = pattern_hour.calc(11,0)
    assert_equal 11, result, "result calc(11,0)"
    assert_equal 0, remainder, "remainder calc(11,0)"
    
    result,remainder = pattern_hour.calc(0,60)
    assert_equal 60, result, "result calc(0,60)"
    assert_equal 15, remainder, "remainder calc(0,60)"
    
    result,remainder = pattern_hour.calc(0,61)
    assert_equal 60, result, "result calc(0,61)"
    assert_equal 16, remainder, "remainder calc(0,61)"
    
    result,remainder = pattern_hour.calc(30,60)
    assert_equal 60, result, "result calc(30,60)"
    assert_equal 35, remainder, "remainder calc(30,60)"
    
  end
  
  must 'subtract minutes in a working hour' do

    working_hour = Workpattern::WORKING_HOUR
    result,remainder = working_hour.calc(0,-3)
    assert_equal 0, result, "result calc(0,-3)"
    assert_equal(-3, remainder, "remainder calc(0,-3)")
    
    result,remainder = working_hour.calc(0,0)
    assert_equal 0, result, "result calc(0,0)"
    assert_equal 0, remainder, "remainder calc(0,0)"
    
    result,remainder = working_hour.calc(59,0)
    assert_equal 59, result, "result calc(59,0)"
    assert_equal 0, remainder, "remainder calc(59,0)"
    
    result,remainder = working_hour.calc(11,0)
    assert_equal 11, result, "result calc(11,0)"
    assert_equal 0, remainder, "remainder calc(11,0)"
    
    result,remainder = working_hour.calc(0,-60)
    assert_equal 0, result, "result calc(0,-60)"
    assert_equal(-60, remainder, "remainder calc(0,-60)")
    
    result,remainder = working_hour.calc(0,-61)
    assert_equal 0, result, "result calc(0,-61)"
    assert_equal(-61, remainder, "remainder calc(0,-61)")
    
    result,remainder = working_hour.calc(30,-60)
    assert_equal 0, result, "result calc(30,-60)"
    assert_equal(-30, remainder, "remainder calc(30,-60)")
  
    result,remainder = working_hour.calc(60,0)
    assert_equal 60, result, "result calc(60,0)"
    assert_equal 0, remainder, "remainder calc(60,0)"
    
    result,remainder = working_hour.calc(60,-10)
    assert_equal 50, result, "result calc(60,-10)"
    assert_equal 0, remainder, "remainder calc(60,-10)"
    
    result,remainder = working_hour.calc(60,-60)
    assert_equal 0, result, "result calc(60,-60)"
    assert_equal 0, remainder, "remainder calc(60,-60)"
    
    result,remainder = working_hour.calc(60,-61)
    assert_equal 0, result, "result calc(60,-61)"
    assert_equal(-1, remainder, "remainder calc(60,-61)")
  end
  
  must 'subtract minutes in a resting hour' do
  
    resting_hour = Workpattern::RESTING_HOUR
    result,remainder = resting_hour.calc(0,-3)
    assert_equal 0, result, "result calc(0,-3)"
    assert_equal(-3, remainder, "remainder calc(0,-3)")
    
    result,remainder = resting_hour.calc(0,0)
    assert_equal 0, result, "result calc(0,0)"
    assert_equal 0, remainder, "remainder calc(0,0)"
    
    result,remainder = resting_hour.calc(59,0)
    assert_equal 59, result, "result calc(59,0)"
    assert_equal 0, remainder, "remainder calc(59,0)"
    
    result,remainder = resting_hour.calc(11,0)
    assert_equal 11, result, "result calc(11,0)"
    assert_equal 0, remainder, "remainder calc(11,0)"
    
    result,remainder = resting_hour.calc(0,-60)
    assert_equal 0, result, "result calc(0,-60)"
    assert_equal(-60, remainder, "remainder calc(0,-60)")
    
    result,remainder = resting_hour.calc(0,-61)
    assert_equal 0, result, "result calc(0,-61)"
    assert_equal(-61, remainder, "remainder calc(0,-61)")
    
    result,remainder = resting_hour.calc(30,-60)
    assert_equal 0, result, "result calc(30,-60)"
    assert_equal(-60, remainder, "remainder calc(30,-60)")
  
    result,remainder = resting_hour.calc(60,0)
    assert_equal 60, result, "result calc(60,0)"
    assert_equal 0, remainder, "remainder calc(60,0)"
    
    result,remainder = resting_hour.calc(60,-10)
    assert_equal 0, result, "result calc(60,-10)"
    assert_equal(-10, remainder, "remainder calc(60,-10)")
    
    result,remainder = resting_hour.calc(60,-60)
    assert_equal 0, result, "result calc(60,-60)"
    assert_equal(-60, remainder, "remainder calc(60,-60)")
    
    result,remainder = resting_hour.calc(60,-61)
    assert_equal 0, result, "result calc(60,-61)"
    assert_equal(-61, remainder, "remainder calc(60,-61)")
  end
  
  must 'subtract minutes in a patterned hour' do
  
    pattern_hour = Workpattern::WORKING_HOUR
    pattern_hour = pattern_hour.workpattern(1,10,0)
    pattern_hour = pattern_hour.workpattern(55,59,0)
    
    result,remainder = pattern_hour.calc(0,-3)
    assert_equal 0, result, "result calc(0,-3)"
    assert_equal(-3, remainder, "remainder calc(0,-3)")
    
    result,remainder = pattern_hour.calc(0,0)
    assert_equal 0, result, "result calc(0,0)"
    assert_equal 0, remainder, "remainder calc(0,0)"
    
    result,remainder = pattern_hour.calc(59,0)
    assert_equal 59, result, "result calc(59,0)"
    assert_equal 0, remainder, "remainder calc(59,0)"
    
    result,remainder = pattern_hour.calc(11,0)
    assert_equal 11, result, "result calc(11,0)"
    assert_equal 0, remainder, "remainder calc(11,0)"
    
    result,remainder = pattern_hour.calc(0,-60)
    assert_equal 0, result, "result calc(0,-60)"
    assert_equal(-60, remainder, "remainder calc(0,-60)")
    
    result,remainder = pattern_hour.calc(0,-61)
    assert_equal 0, result, "result calc(0,-61)"
    assert_equal(-61, remainder, "remainder calc(0,-61)")
    
    result,remainder = pattern_hour.calc(30,-60)
    assert_equal 0, result, "result calc(30,-60)"
    assert_equal(-40, remainder, "remainder calc(30,-60)")
  
    result,remainder = pattern_hour.calc(60,0)
    assert_equal 60, result, "result calc(60,0)"
    assert_equal 0, remainder, "remainder calc(60,0)"
    
    result,remainder = pattern_hour.calc(60,-10)
    assert_equal 45, result, "result calc(60,-10)"
    assert_equal 0, remainder, "remainder calc(60,-10)"
    
    result,remainder = pattern_hour.calc(60,-60)
    assert_equal 0, result, "result calc(60,-60)"
    assert_equal(-15, remainder, "remainder calc(60,-60)")
    
    result,remainder = pattern_hour.calc(60,-61)
    assert_equal 0, result, "result calc(60,-61)"
    assert_equal(-16, remainder, "remainder calc(60,-61)")
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
     [0,59,0,0,60,-1],
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
          assert !working_hour.minute?(i)    
        else
          assert working_hour.minute?(i)
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

