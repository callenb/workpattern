module Workpattern
  
  # Represents the 60 minutes of an hour using an <tt>Integer</tt>
  #
  # @since 0.2.0
  #
  module Hour
 
    # Returns the total working minutes in the hour
    #
    # @return [Integer] working minutes in the hour 
    #
    def wp_total
      return wp_minutes(0,59)
    end  
    
    # Sets the minutes to either working (type=1) or resting (type=0)
    # 
    # @param [Integer] start minute at start of range
    # @param [Integer] finish minute at end of range
    # @param [Integer] type defines whether working (1) or resting (0)
    #
    def wp_workpattern(start,finish,type)
      return wp_working(start,finish) if type==1
      return wp_resting(start,finish) if type==0
    end
    
    # Returns the first working minute in the hour or 60 if there are no working minutes
    #
    # @return [Integer] first working minute or 60 if none found
    #
    def wp_first
      0.upto(59) {|minute| return minute if self.wp_minutes(minute,minute)==1}
      return nil
    end
    
    # Returns the last working minute in the hour or nil if there are no working minutes
    #
    # @return [Integer] last working minute or nil if none found
    #
    def wp_last
      59.downto(0) {|minute| return minute if self.wp_minutes(minute,minute)==1}
      return nil
    end
    
    # Returns true if the given minute is working and false if it isn't
    # 
    # @param [Integer] start is the minute being tested
    # @return [Boolean] true if minute is working, otherwise false
    #
    def wp_working?(start)
      return true if wp_minutes(start,start)==1
      return false
    end
    
    # Returns the total number of minutes between and including two minutes
    #
    # @param [Integer] start first minute in range
    # @param [Integer] finish last minute in range
    # @return [Integer] number of minutes from <tt>start</tt> to <tt>finish</tt> inclusive
    #
    def wp_minutes(start,finish)
      return (self & wp_mask(start,finish)).to_s(2).count('1')
    end
    
    # Returns the DateTime and remainding minutes when adding a duration to a minute in the hour. 
    # A negative duration will subtract the minutes.
    #
    # @param [DateTime] time is the full date but only the minute element is used
    # @param [Integer] duration is the number of minutes to add and can be negative (subtraction)
    # @param [Boolean] next_hour used in subtraction to specify the starting point as midnight (00:00 the next day)
    # @return [DateTime,Integer,Boolean] The <tt>DateTime</tt> calculated along with remaining minutes and a flag indicating if starting point is next hour
    #
    def wp_calc(time,duration,next_hour=false)
      return wp_subtract(time,duration, next_hour) if duration < 0
      return wp_add(time,duration) if duration > 0
      return time,duration 
    end
    
    # Returns the number of minutes between two minutes
    # @param [Integer] start first minute in range
    # @param [Integer] finish last minute in range
    # @return [Integer] number of working minutes in the range
    #
    def wp_diff(start,finish)
      start,finish=finish,start if start > finish
      return 0 if start==finish
      return (self & wp_mask(start,finish-1)).to_s(2).count('1')
    end
    
    private

    # Sets a working pattern
    #
    # @param [Integer] start is first minute in the range
    # @param [Integer] finish is last minute in the range
    #
    def wp_working(start,finish)
      return self | wp_mask(start,finish)
    end
    
    # sets a resting pattern
    #
    # @param [Integer] start is first minute in the range
    # @param [Integer] finish is last minute in the range
    #
    def wp_resting(start,finish)
      return self & ((2**60-1)-wp_mask(start,finish))
    end
    
    # Creates a bit mask of 1's over the specified range
    #
    # @param [Integer] start is first minute in the range
    # @param [Integer] finish is the last minute in the range
    #
    def wp_mask(start,finish)
      return ((2**(finish+1)-1)-(2**start-1))
    end
    
    # Handles the addition of minutes to a time
    #
    # @param [DateTime] time is the full date but only the minute element is used
    # @param [Integer] duration is the number of minutes to add and can be negative (subtraction)
    # @return [DateTime, Integer] The resulting DateTime and any remaining minutes
    #
    def wp_add(time,duration)
      start = time.min
      available_minutes=wp_minutes(start,59)

      if not_enough_minutes duration, available_minutes
        result_date = time + HOUR - (MINUTE*start)
        result_remainder = duration-available_minutes
      elsif exact_amount_of_minutes(start,duration)
        result_date = time + (MINUTE*duration)
        result_remainder = 0
      else # more than enough minutes
        step = start + duration
        duration-=wp_minutes(start,step)
        until (duration==0)
          step+=1
          duration-=wp_minutes(step,step)
        end
        step+=1
        result_date = time + (MINUTE*step)
        result_remainder = 0
      end  
      return result_date, result_remainder  
    end
    
    # Handles the subtraction of minutes from a time.
    # @param [DateTime] time is the full date but only the minute element is used
    # @param [Integer] duration is the number of minutes to add and can be negative (subtraction)
    # @param [Boolean] next_hour indicates if the 59th second is the first one to be included
    # @return [DateTime, Integer] The resulting DateTime and any remaining minutes
    #
    def wp_subtract(time,duration,next_hour)
      if next_hour
        if wp_working?(59)
          duration+=1
          time=time+(MINUTE*59)
          return wp_calc(time,duration)
        end  
      else  
        start=time.min  
        available_minutes=0
        available_minutes = wp_minutes(0,start-1) if start > 0
      end
      
      if not_enough_minutes duration,available_minutes
        result_date = time - (MINUTE*start)
        result_remainder = duration+available_minutes
      elsif duration.abs==available_minutes
        result_date = time + (MINUTE*duration)
        result_remainder = 0
      else     
        step = start + duration
        duration+=wp_minutes(step,start-1)
        until (duration==0)
          step-=1
          duration+=wp_minutes(step,step)
        end
        result_date = time - (MINUTE * (start-step))
        result_remainder = 0
      end  
      return result_date, result_remainder  
      
    end

    private
 
    def not_enough_minutes(duration,available_minutes)
      return true if (duration.abs-available_minutes)>=0
      false
    end

    def exact_amount_of_minutes(start,duration)
      return true if wp_minutes(start,start+duration-1)==duration
      false
    end
  end
end

# Hours are represented by a bitwise <tt>Integer</tt> class so the code is mixed in to that class
# @ since 0.3.0
#
class Integer
  include Workpattern::Hour
end
