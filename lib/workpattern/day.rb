module Workpattern
  class Day
    
    attr_accessor :values, :hours, :first_hour, :first_min, :last_hour, :last_min, :total
    
    def initialize(type=1,hours_in_day=24)
      @hours=hours_in_day
      hour=WORKING_HOUR if type==1
      hour=RESTING_HOUR if type==0
      @values=Array.new(hours_in_day) {|index| hour }

      set_attributes
    end
    
    def workpattern(start_hour,start_min,finish_hour,finish_min,type)
    
      if start_hour==finish_hour
        @values[start_hour]=@values[start_hour].workpattern(start_min,finish_min,type)
      else
        @values[start_hour]=@values[start_hour].workpattern(start_min,59,type)
        
        while ((start_hour+1)<finish_hour)
          start_hour+=1
          @values[start_hour]=@values[start_hour].workpattern(0,59,type)
        end
        
        @values[finish_hour]=@values[finish_hour].workpattern(0,finish_min,type)
      end
      set_attributes
    end
    
    def calc(start_hour,start_min,duration)
    
      if (duration<0)
        return subtract(start_hour,start_min,duration)  
      elsif (duration>0)
        return add(start_hour,start_min,duration)                
      else
        return start_hour,start_min,duration
      end
    
    end
    
    # Returns the total number of minutes between and including two minutes
    #
    def minutes(start_hour,start_min,finish_hour,finish_min)
      if (start_hour > finish_hour) || ((finish_hour==start_hour) && (start_min > finish_min))
        start_hour,start_min,finish_hour,finish_min=finish_hour,finish_min,start_hour,finish_min 
      end
      
      if (start_hour==finish_hour)
        retval=@values[start_hour].minutes(start_min,finish_min)
      else
        retval=@values[start_hour].minutes(start_min,59)
        
        while (start_hour+1<finish_hour)
          retval+=@values[start_hour].total
          start_hour+=1
        end
        
        retval+=@values[start_hour].minutes(0,finish_min)
      end
        
      return retval
    end

    private
    
    def set_attributes
      @first_hour=@hours
      @first_min=60
      @last_hour=(-1)
      @last_min=(-1)
      @total=0
      0.upto(@hours-1) {|index|
        @first_hour=index if ((@first_hour==@hours) && (@values[index].total!=0))
        @first_min=@values[index].first if ((@first_min==60) && (@values[index].first!=60))        
        @last_hour=index if (@values[index].total!=0)
        @last_min=@values[index].last if (@values[index].total!=0)
        @total+=@values[index].total
      }
    end
    
    
    def subtract(start_hour,start_min,duration)

      maximum=0
      if (start_hour>0 || start_min>0)
        maximum=minutes(0,0,start_hour,start_min-1) if (start_min>0)
        maximum=minutes(0,0,start_hour-1,59) if (start_min==0)
      end
      
      return 0,0,(duration+maximum) if ((duration+maximum)<=0) # not enough minutes left in the day
      return start_hour,(start_min+duration),0 if (@values[start_hour].minutes(start_min+duration,start_min-1)==duration.abs) # enough minutes in first hour
      
      result_hour=start_hour
      duration+=@values[result_hour].minutes(0,start_min-1) if start_min>0

      until (duration==0)
        result_hour-=1
        total=@values[result_hour].total
        if (total<=duration.abs)
          duration+=total
        else  
         result_min,result_remainder=@values[result_hour].calc(60,duration)
         duration=0
        end
      end  
      
      return result_hour,result_min,0
    end
    
    def add(start_hour,start_min,duration)
      maximum=minutes(start_hour,start_min,@hours-1,59)
      return @hours-1,60,(duration-maximum) if ((duration-maximum)>=0) # not enough minutes left in the day
      
      return start_hour,(start_min+duration),0 if (@values[start_hour].minutes(start_min,start_min+duration-1)==duration) # enough minutes in first hour
      
      result_hour=start_hour
      duration-=@values[result_hour].minutes(start_min,59)
      until (duration==0)
        result_hour+=1
        total=@values[result_hour].total
        if (total<=duration)
          duration-=total
        else  
         result_min,result_remainder=@values[result_hour].calc(0,duration)
         duration=0
        end
      end  
      return result_hour,result_min,0
    end
  end
end
