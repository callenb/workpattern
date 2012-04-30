module Workpattern
  # Represents the 24 hours of a day using module <tt>hour</tt>
  #
  class Day
    include Workpattern::Utility
    attr_accessor :values, :hours, :first_hour, :first_min, :last_hour, :last_min, :total
    
    # :call-seq: new(type=1) => Day
    # Creates a 24 hour day defaulting to a working day.
    # Pass 0 to create a non-working day.
    #
    def initialize(type=1)
      @hours=24
      hour=WORKING_HOUR if type==1
      hour=RESTING_HOUR if type==0
      @values=Array.new(@hours) {|index| hour }

      set_attributes
    end
    
    # :call-seq: duplicate => Day
    # Creates a duplicate of the current <tt>Day</tt> instance.
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
    
    # :call-seq: refresh
    # Recalculates characteristics for this day
    #
    def refresh
      set_attributes
    end
    
    # :call-seq: workpattern(start_time,finish_time,type)
    # Sets all minutes in a date range to be working or resting.
    # The <tt>start_time</tt> and <tt>finish_time</tt> need to have 
    # <tt>#hour</tt> and <tt>#min</tt> methods to return the time 
    # in hours and minutes respectively.
    #
    # Pass 1 as the <tt>type</tt> for working and 0 for resting.
    # 
    def workpattern(start_time,finish_time,type)
    
      if start_time.hour==finish_time.hour
        @values[start_time.hour]=@values[start_time.hour].workpattern(start_time.min,finish_time.min,type)
      else
        test_hour=start_time.hour
        @values[test_hour]=@values[test_hour].workpattern(start_time.min,59,type)
        
        while ((test_hour+1)<finish_time.hour)
          test_hour+=1
          @values[test_hour]=@values[test_hour].workpattern(0,59,type)     
        end
        
        @values[finish_time.hour]=@values[finish_time.hour].workpattern(0,finish_time.min,type)
      end
      set_attributes
    end
    
    # :call-seq: calc(time,duration) => time, duration
    #
    # Calculates the result of adding <tt>duration</tt> to
    # <tt>time</tt>.  The <tt>duration</tt> can be negative in
    # which case it subtracts from <tt>time</tt>.
    #
    # An addition where there are less working minutes left in 
    # the day than are being added will result in the time 
    # returned having 60 as the value in <tt>min</tt>. 
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
    
    # :call-seq: working?(start) => Boolean
    # Returns true if the given minute is working and false if it isn't
    #
    def working?(start)
      return true if minutes(start.hour,start.min,start.hour,start.min)==1
      return false
    end
    
    # :call-seq: diff(start,finish) => Duration, Date
    # Returns the difference in minutes between two times. if the given 
    # minute is working and false if it isn't
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
    
    # :call-seq: minutes(start_hour,start_min,finish_hour,finish_min) => duration    
    # Returns the total number of minutes between and including two minutes.
    # 
    def minutes(start_hour,start_min,finish_hour,finish_min)
      return 0 if (start_hour==finish_hour && start_hour==0 && start_min==finish_min && start_min==0)
      if (start_hour > finish_hour) || ((finish_hour==start_hour) && (start_min > finish_min))
        start_hour,start_min,finish_hour,finish_min=finish_hour,finish_min,start_hour,finish_min 
      end
      
      if (start_hour==finish_hour)     
        retval=@values[start_hour].minutes(start_min,finish_min)
      else
    
        retval=@values[start_hour].minutes(start_min,59)
        while (start_hour+1<finish_hour)        
          retval+=@values[start_hour+1].total     
          start_hour+=1
        end
        retval+=@values[finish_hour].minutes(0,finish_min)
      end
        
      return retval
    end

    private
    
    def set_attributes
      @first_hour=nil
      @first_min=nil
      @last_hour=nil
      @last_min=nil
      @total=0
      0.upto(@hours-1) {|index|
        @first_hour=index if ((@first_hour.nil?) && (@values[index].total!=0))
        @first_min=@values[index].first if ((@first_min.nil?) && (!@values[index].first.nil?))        
        @last_hour=index if (@values[index].total!=0)
        @last_min=@values[index].last if (@values[index].total!=0)
        @total+=@values[index].total
      }
    end
    
    def first_working_minute(time)
      if @first_hour.nil?
        return time - (HOUR*time.hour) - (MINUTE*time.min)
      else  
        time = time - HOUR * (time.hour - @first_hour)
        time = time - MINUTE * (time.min - @first_min )
        return time
      end  
    end
    
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
        minutes_this_hour=@values[time.hour].minutes(0,time.min-1)
        this_hour=time.hour
        until (duration==0)
          if (minutes_this_hour<duration.abs)     
            duration+=minutes_this_hour
            time = time - (MINUTE*time.min) - HOUR
            this_hour-=1
            minutes_this_hour=@values[this_hour].total
          else
            next_hour=(time.min==0)
            time,duration=@values[this_hour].calc(time,duration, next_hour)
          end
        end
      end  
      return time,duration, false
    end
    
    # 
    # Returns the result of adding #duration to the specified time
    # When there are not enough minutes in the day it returns the date
    # for the start of the following
    #
    def add(time,duration)
      available_minutes=minutes(time.hour,time.min,@hours-1,59)
      if ((duration-available_minutes)>0) # not enough minutes left in the day      
        result_date= time.next_day - (HOUR*time.hour) - (MINUTE*time.min)
        duration = duration - available_minutes      
      else
        total=@values[time.hour].minutes(time.min,59)
        if (total==duration) # this hour satisfies
          result_date=time + HOUR - (MINUTE*time.min)
          duration = 0
        else  
          result_date = time
          until (duration==0)
            if (total<duration)
              duration-=total
              result_date=result_date + HOUR - (MINUTE*result_date.min)
            else
              result_date,duration=@values[result_date.hour].calc(result_date,duration)     
            end
            total=@values[result_date.hour].total
          end
        end
      end    
      return result_date,duration, false
    end
    
    def next_hour(start)
      return start+HOUR-(start.min*MINUTE) 
    end
    
    def minutes_left_in_hour(start)
      return @values[start.hour].diff(start.min,60)
    end
    
    def minutes_left_in_day(start)
      start.hour
    end  
  end
end
