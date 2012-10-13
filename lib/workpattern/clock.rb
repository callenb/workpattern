module Workpattern
  # Represents time on a clock in hours and minutes.
  # @example
  #   myClock=Clock.new(3,32)
  #   myClock.minutes #=> 212
  #   myClock.hour #=> 3
  #   myClock.min  #=> 32
  #   myClock.time #=> Time.new(1963,6,10,3,32)
  # 
  #
  #   aClock=Clock.new(27,80)
  #   aClock.minutes #=> 1700
  #   aClock.hour #=> 4
  #   aClock.min #=> 20
  #   aClock.time #=> Time.new(1963,6,10,4,20)
  #
  class Clock
    
    # Initialises an instance of <tt>Clock</tt> using the hours and minutes supplied
    # or 0 if they are absent.  Although there are 24 hours in a day
    # (0-23) and 60 minutes in an hour (0-59), <tt>Clock</tt> calculates
    # the full hours and remaining minutes of whatever is supplied.
    # @param [Fixnum] number of hours
    # @param [Fixnum] number of minutes
    # @return [Clock] mewly initialised Clock object
    #
    def initialize(hour=0,min=0)
      @hour=hour
      @min=min
      total_minutes = minutes
      @hour=total_minutes.div(60)
      @min=total_minutes % 60
    end
    
    # Returns the total number of minutes
    # @return [Fixnum] total minutes represented by the Clock object
    #
    def minutes
      return (@hour*60)+@min
    end
    
    # Returns the hour of the clock (0-23)
    # @return [Fixnum] hour of Clock from 0 to 23.
    #
    def hour
      return @hour % 24
    end
    
    # Returns the minute of the clock (0-59)
    # @return [Fixnum] minute of Clock from 0 to 59
    #
    def min
      return @min % 60
    end
    
    # Returns a <tt>Time</tt> object with the correct
    # <tt>hour</tt> and <tt>min</tt> values.  The date
    # is 10th June 1963.
    # @return [DateTime] The time using the date of 10th June 1963 (My Birthday)
    def time
      return DateTime.new(1963,6,10,hour,min)
    end
    
    # Returns a <tt>String</tt> representation of the clock value
    #
    def to_s      
      hour.to_s.concat(':').concat(min.to_s).concat(' ').concat(minutes.to_s)
    end
  end
end
