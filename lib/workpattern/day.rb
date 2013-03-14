module Workpattern
  
  # @author Barrie Callender
  # @!attribute values
  #   @return [Array] each hour of the day
  # @!attribute hours
  #   @return [Integer] number of hours in the day
  # @!attribute first_hour
  #   @return [Integer] first working hour in the day
  # @!attribute first_min
  #   @return [Integer] first working minute in first working hour in the day
  # @!attribute last_hour
  #   @return [Integer] last working hour in the day
  # @!attribute last_min
  #   @return [Integer] last working minute in last working hour in the day
  # @!attribute total
  #   @return [Integer] total number of minutes in the day
  #  
  # Represents the 24 hours of a day.
  #
  # @since 0.2.0
  # @todo implement a day with different number of hours in it to support daylight saving
  #
  class Day
    include Workpattern::Utility
    attr_accessor :values, :hours, :first_hour, :first_min, :last_hour, :last_min, :total
    
    # The new <tt>Day</tt> object can be created as either working or resting.
    #
    # @param [Integer] type is working (1) or resting (0)
    #
    def initialize(type=1)
      @hours=24
      hour=WORKING_HOUR if type==1
      hour=RESTING_HOUR if type==0
      @values=Array.new(@hours) {|index| hour }

      set_attributes
    end
    
    # Creates a duplicate of the current <tt>Day</tt> instance.
    #
    # @return [Day] 
    #
    def duplicate
      duplicate_day = Day.new()
      duplicate_values=Array.new(@values.size)
      @values.each_index {|index|
        duplicate_values[index]=@values[index]
        }
      duplicate_day.values=duplicate_values
      duplicate_day.hours = @hours
      duplicate_day.first_hour=@first_hour
      duplicate_day.first_min=@first_min
      duplicate_day.last_hour=@last_hour
      duplicate_day.last_min=@last_min
      duplicate_day.total = @total
      duplicate_day.refresh
      return duplicate_day
    end
    
    # Recalculates characteristics for this day
    #
    def refresh
      set_attributes
    end
    
    # Sets all minutes in a date range to be working or resting.
    #
    # @param [(#hour,#min)] start_time is the start of the range to set
    # @param [(#hour, #min)] finish_time is the finish of the range to be set
    # @param [Integer] type is either working (1) or resting (0)
    #
    def workpattern(start_time,finish_time,type)
    
      if start_time.hour==finish_time.hour
        @values[start_time.hour]=@values[start_time.hour].wp_workpattern(start_time.min,finish_time.min,type)
      else
        test_hour=start_time.hour
        @values[test_hour]=@values[test_hour].wp_workpattern(start_time.min,59,type)
        
        while ((test_hour+1)<finish_time.hour)
          test_hour+=1
          @values[test_hour]=@values[test_hour].wp_workpattern(0,59,type)     
        end
        
        @values[finish_time.hour]=@values[finish_time.hour].wp_workpattern(0,finish_time.min,type)
      end
      set_attributes
    end
    
    # Calculates the result of adding <tt>duration</tt> to
    # <tt>time</tt>.  The <tt>duration</tt> can be negative in
    # which case it subtracts from <tt>time</tt>.
    #
    # An addition where there are less working minutes left in 
    # the day than are being added will result in the time 
    # returned being 00:00 on the following day.
    #
    # A subtraction where there are less working minutes left in
    # the day than are being added will result in the time 
    # returned being the previous day with the <tt>midnight</tt> flag set to true.
    #
    # @param [DateTime] time when the calculation starts from
    # @param [Integer] duration is the number of minutes to add or subtract if it is negative
    # @param [Boolean] midnight is a flag used in subtraction to pretend the time is actually midnight
    # @return [DateTime,Integer,Boolean] Calculated time along with any remaining duration and the midnight flag
    # 
    def calc(time,duration,midnight=false)
    
      if (duration<0)
        return subtract(time,duration, midnight)  
      elsif (duration>0)
        return add(time,duration)                
      else
        return time,duration, false
      end
    
    end
    
    # Returns true if the given minute is working and false if it is resting
    #
    # @param [(#hour, #min)] start is the time in the day to inspect
    # @return [Boolean] true if the time is working and false if it is resting
    #
    def working?(start)
      return true if minutes(start.hour,start.min,start.hour,start.min)==1
      return false
    end
    
    # Returns the difference in working minutes between two times.
    #
    # @param [(#hour, #min)] start start time in the range
    # @param [(#hour, #min)] finish finish time in the range
    # @return [Integer] number of working minutes
    #
    def diff(start,finish)
      start,finish=finish,start if ((start <=> finish))==1
      # calculate to end of hour
      #
      if (start.jd==finish.jd) # same day
        duration=minutes(start.hour,start.min,finish.hour, finish.min)
        duration -=1 if working?(finish)
        start=finish
      else
        duration=minutes(start.hour,start.min,23, 59)
        start=start+((23-start.hour)*HOUR) +((60-start.min)*MINUTE)
      end
      return duration, start
    end
    
    # Returns the total number of minutes between two times.
    #
    # @param [Integer] start_hour first hour in range
    # @param [Integer] start_min first minute of first hour in range
    # @param [Integer] finish_hour last hour in range
    # @param [Integer] finish_min last minute of last hour in range
    # @return [Integer] minutes between supplied hours and minutes
    #
    # @todo can this method and #diff method be combined?
    #
    def minutes(start_hour,start_min,finish_hour,finish_min)
      
      if (start_hour > finish_hour) || ((finish_hour==start_hour) && (start_min > finish_min))
        start_hour,start_min,finish_hour,finish_min=finish_hour,finish_min,start_hour,finish_min 
      end
      
      if (start_hour==finish_hour)     
        retval=@values[start_hour].wp_minutes(start_min,finish_min)
      else
    
        retval=@values[start_hour].wp_minutes(start_min,59)
        while (start_hour+1<finish_hour)        
          retval+=@values[start_hour+1].wp_total     
          start_hour+=1
        end
        retval+=@values[finish_hour].wp_minutes(0,finish_min)
      end
        
      return retval
    end

    private
    
    # Calculates the attributes that describe the day.  Called after changes.
    #
    def set_attributes
      @first_hour=nil
      @first_min=nil
      @last_hour=nil
      @last_min=nil
      @total=0
      0.upto(@hours-1) {|index|
        @first_hour=index if ((@first_hour.nil?) && (@values[index].wp_total!=0))
        @first_min=@values[index].wp_first if ((@first_min.nil?) && (!@values[index].wp_first.nil?))        
        @last_hour=index if (@values[index].wp_total!=0)
        @last_min=@values[index].wp_last if (@values[index].wp_total!=0)
        @total+=@values[index].wp_total
      }
    end
    
    # Returns the first working minute as a <tt>DateTime</tt> or <tt>oo:oo</tt>
    # when there is no working minutes in the day.  Used by the <tt>#subtract</tt> method
    #
    # @param [DateTime] time day for which the first working time is sought.
    # @return [DateTime] the first working time of the day
    #
    def first_working_minute(time)
      if @first_hour.nil?
        return time - (HOUR*time.hour) - (MINUTE*time.min)
      else  
        time = time - HOUR * (time.hour - @first_hour)
        time = time - MINUTE * (time.min - @first_min )
        return time
      end  
    end
    
    # Handles the subtraction of a duration from a time in the day.
    # 
    # @param [DateTime] time when the subtraction starts from
    # @param [Integer] duration is the number of minutes to subtract from the <tt>time</tt>
    # @param [Boolean] midnight is a flag used in subtraction to pretend the time is actually midnight
    # @return [DateTime,Integer,Boolean] Calculated time along with any remaining duration and the midnight flag
    #
    def subtract(time,duration,midnight=false)    
      if (time.hour==0 && time.min==0)
        if midnight      
          duration+=minutes(23,59,23,59)
          time=time+(HOUR*23)+(MINUTE*59)
          return calc(time,duration)
        else
          return time.prev_day, duration,true  
        end
      elsif (time.hour==@first_hour && time.min==@first_min)
        time=time-(HOUR*@first_hour) - (MINUTE*@first_min)
        return time.prev_day, duration, true  
      elsif (time.min>0)
        available_minutes=minutes(0,0,time.hour,time.min-1) 
      else  
        available_minutes=minutes(0,0,time.hour-1,59)
      end  
      if ((duration+available_minutes)<0) # not enough minutes in the day  
        time = midnight_before(time.prev_day) 
        duration = duration + available_minutes
        return time, duration, true
      elsif ((duration+available_minutes)==0)
        duration=0
        time=first_working_minute(time)  
      else
        minutes_this_hour=@values[time.hour].wp_minutes(0,time.min-1)
        this_hour=time.hour
        until (duration==0)
          if (minutes_this_hour<duration.abs)     
            duration+=minutes_this_hour
            time = time - (MINUTE*time.min) - HOUR
            this_hour-=1
            minutes_this_hour=@values[this_hour].wp_total
          else
            next_hour=(time.min==0)
            time,duration=@values[this_hour].wp_calc(time,duration, next_hour)
          end
        end
      end  
      return time,duration, false
    end
    
    # Returns the result of adding <tt>duration</tt> to the given <tt>time</tt>
    # When there are not enough minutes in the day it returns the date
    # for the start of the following day.
    #
    # @param [DateTime] time when the calculation starts from
    # @param [Integer] duration is the number of minutes to add
    # @return [DateTime,Integer] Calculated time along with any remaining duration
    #
    def add(time,duration)
      available_minutes=minutes(time.hour,time.min,@hours-1,59)   
      if ((duration-available_minutes)>0) # not enough minutes left in the day      

        result_date= time.next_day - (HOUR*time.hour) - (MINUTE*time.min)
        duration = duration - available_minutes      
      else
        total=@values[time.hour].wp_minutes(time.min,59)
        if (total==duration) # this hour satisfies              
          result_date=time - (MINUTE*time.min) + (MINUTE*@values[time.hour].wp_last) + MINUTE                   
          duration = 0
        else  
          result_date = time
          until (duration==0)
            if (total<duration)
              duration-=total
              result_date=result_date + HOUR - (MINUTE*result_date.min)
            else
              result_date,duration=@values[result_date.hour].wp_calc(result_date,duration)     
            end
            total=@values[result_date.hour].wp_total
          end
        end
      end    
      return result_date,duration, false
    end
    
    # Returns the start of the next hour.
    #
    # The next hour could be the start of the following day.
    #
    # @param [DateTime] start is the <tt>DateTime</tt> for which the following hour is required.
    # @return [DateTime] the start of the next hour following the <tt>DateTime</tt> supplied
    #
    def next_hour(start)
      return start+HOUR-(start.min*MINUTE) 
    end
    
    # Returns the number of working minutes left in the current hour
    #
    # @param [DateTime] start is the <tt>DateTime</tt> for which the remaining working minutes 
    #                   in the hour are required
    # @return [Integer] number of remaining working minutes
    #
    def minutes_left_in_hour(start)
      return @values[start.hour].wp_diff(start.min,60)
    end
    
  end
end
