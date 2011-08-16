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
  
  must 'add minutes' do
    # working hour
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
    
    # resting hour
    
    # pattern hour
    
  end
  
  must 'subtract minutes' do
  
  end
  
  must 'create complex patterns' do
    
  end

  must "calculate difference between minutes" do
  
  end
  
  private
  
end

