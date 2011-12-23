require File.dirname(__FILE__) + '/test_helper.rb'
require File.dirname(__FILE__) + '/mock_date_time.rb'

class TestClock < Test::Unit::TestCase #:nodoc:

  def setup
  end
  
  must "create midnight default"  do
    clock=Workpattern::Clock.new()
    
    assert_equal 0, clock.minutes, "total default minutes"
    assert_equal 0, clock.hour, "default hour is zero"
    assert_equal 0, clock.min, "default minute is zero"
    time = clock.time
    assert time.kind_of?(Time), "must return a Time object"
    assert_equal 0, time.hour, "hour in the day must be zero"
    assert_equal 0, time.min, "minute in the day must be zero"
  end
end  
