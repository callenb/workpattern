module Workpattern
  # Represents time on a clock in hours and minutes.
  #
  # myClock=Clock.new(3,32)
  # myClock.minutes #=> 212
  # myClock.hour #=> 3
  # myClock.min  #=> 32
  # myClock.time #=> Time.new(1963,6,10,3,32)
  # 
  #
  # aClock=Clock.new(27,80)
  # aClock.minutes #=> 1700
  # aClock.hour #=> 4
  # aClock.min #=> 20
  # aClock.time #=> Time.new(1963,6,10,4,20)
  #
  class Clock
  
    # :call-seq: new(hour,min) => Clock
    # initialises <tt>Clock</tt> using the hours and minutes supplied
    # or 0 if they are absent.  Although there are 24 hours in a day
    # (0-23) and 60 minutes in an hour (0-59), <tt>Clock</tt> calculates
    # the full hours and remaining minutes of whatever is supplied.
    #
    def initialize(hour=0,min=0)
      @hour=hour
      @min=min
      total_minutes = minutes
      @hour=total_minutes.div(60)
      @min=total_minutes % 60
    end
    
    # :call-seq: minutes => Integer
    # returns the total number of minutes
    #
    def minutes
      return (@hour*60)+@min
    end
    
    # :call-seq: hour => Integer
    # returns the hour of the clock (0-23)
    #
    def hour
      return @hour % 24
    end
    
    # :call-seq: min => Integer
    # returns the minute of the clock (0-59)
    #
    def min
      return @min % 60
    end
    
    # :call-seq: time => DateTime
    # returns a <tt>Time</tt> object with the correct
    # <tt>hour</tt> and <tt>min</tt> values.  The date
    # is 10th June 1963
    # 
    def time
      return DateTime.new(1963,6,10,hour,min)
    end      
  end
end
