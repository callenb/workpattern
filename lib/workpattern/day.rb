module Workpattern
  # Represents the 24 hours of a day using module <tt>hour</tt>
  #
  class Day
    
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
    def calc(time,duration)
    
      if (duration<0)
        return subtract(time,duration)  
      elsif (duration>0)
        return add(time,duration)                
      else
        return time,duration
      end
    
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
    
    
    def subtract(time,duration)
      if (time.hour==0 && time.min==0)
        available_minutes = 0
      elsif (time.min>0)
        available_minutes=minutes(0,0,time.hour,time.min-1) 
      else  
        available_minutes=minutes(0,0,time.hour-1,59)
      end  
      if ((duration+available_minutes)<=0) # not enough minutes in the day
        result_date = time - (HOUR*time.hour) - (MINUTE*time.min)    
        duration = duration + available_minutes
      else
        total=@values[time.hour].minutes(0,time.min)
        if (total==duration.abs) # this hour satisfies
          result_date=time - (MINUTE*time.min)
          duration = 0
        else
          test_hour=time.hour
          until (duration==0)
            if (total<=duration.abs)     
              duration+=total
            else
              result_date = time - (HOUR*(time.hour-test_hour)) - (MINUTE*time.min) + (MINUTE*59)
              next_hour = (test_hour!=result_date.hour)
              result_date,duration=@values[test_hour].calc(result_date,duration, next_hour)
            end    
            test_hour = test_hour - 1 if duration<0
            total=@values[test_hour].total if duration<0  
          end
        end
      end        
      return result_date,duration
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
            if (total<=duration)
              duration-=total
              result_date=result_date + HOUR - (MINUTE*result_date.min)
            else
              result_date,duration=@values[result_date.hour].calc(result_date,duration)     
            end
            total=@values[result_date.hour].total
          end
        end
      end    
      return result_date,duration
    end
  end
end
