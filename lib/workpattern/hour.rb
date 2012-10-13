module Workpattern
  
  # Represents the 60 minutes of an hour using a <tt>Fixnum</tt> or <tt>Bignum</tt>
  #
  module Hour
 
    # :call-seq: total => Integer
    # Returns the total working minutes in the hour
    # 
    def total
      return minutes(0,59)
    end  
    
    # :call-seq: workpattern(start,finish,type) => Fixnum
    # Sets the minutes to either working (type=1) or resting (type=0)
    #
    def workpattern(start,finish,type)
      return working(start,finish) if type==1
      return resting(start,finish) if type==0
    end
    
    # :call-seq: first => Integer
    # Returns the first working minute in the hour or 60 if there are none
    #
    def first
      0.upto(59) {|minute| return minute if self.minutes(minute,minute)==1}
      return nil
    end
    
    # :call-seq: last => Integer
    # Returns the last working minute in the hour or -1 if there are none
    #
    def last
      59.downto(0) {|minute| return minute if self.minutes(minute,minute)==1}
      return nil
    end
    
    # :call-seq: working?(start) => Boolean
    # Returns true if the given minute is working and false if it isn't
    #
    def working?(start)
      return true if minutes(start,start)==1
      return false
    end
    
    # :call-seq: minutes(start,finish) => Integer
    # Returns the total number of minutes between and including two minutes
    #
    def minutes(start,finish)
      start,finish=finish,start if start > finish
      return (self & mask(start,finish)).to_s(2).count('1')
    end
    
    # :call-seq: calc(datetime,duration) => DateTime, Integer
    # Returns the DateTime and remainding minutes when adding or subtracting duration 
    # to/from a minute in an hour.
    # Subtraction with a remainder returns the time of the current date as 00:00.
    #
    def calc(time,duration,next_hour=false)
    
      if (duration<0)
        return subtract(time,duration, next_hour)  
      elsif (duration>0)
        return add(time,duration)                
      else
        return time,duration
      end 
    end
    
    # :call-seq: diff(start,finish) => Integer
    # returns the number of minutes between two minutes
    #
    def diff(start,finish)
      start,finish=finish,start if start > finish
      return 0 if start==finish
      return (self & mask(start,finish-1)).to_s(2).count('1')
    end
    
    private

    # sets working pattern
    def working(start,finish)
      return self | mask(start,finish)
    end
    
    # sets resting pattern
    def resting(start,finish)
      return self & ((2**60-1)-mask(start,finish))
    end
    
    # creates a mask over the specified bits
    def mask(start,finish)
      return ((2**(finish+1)-1)-(2**start-1))
    end
    
    # adds a duration to a time
    def add(time,duration)
      start = time.min
      available_minutes=minutes(start,59)

      if ((duration-available_minutes)>=0)
        result_date = time + HOUR - (MINUTE*start)
        result_remainder = duration-available_minutes
      elsif ((duration-available_minutes)==0)
        result_date = time - (MINUTE*start) + last + 1 
        result_remainder = 0
      elsif (minutes(start,start+duration-1)==duration)
        result_date = time + (MINUTE*duration)
        result_remainder = 0
      else
        step = start + duration
        duration-=minutes(start,step)
        until (duration==0)
          step+=1
          duration-=minutes(step,step)
        end
        step+=1
        result_date = time + (MINUTE*step)
        result_remainder = 0
      end  
      return result_date, result_remainder  
    end
    
    # subtracts a duration from a time
    def subtract(time,duration,next_hour)
      if next_hour
        if working?(59)
          duration+=1
          time=time+(MINUTE*59)
          return calc(time,duration)
        end  
      else  
        start=time.min  
        available_minutes=0
        available_minutes = minutes(0,start-1) if start > 0
      end
      
      if ((duration + available_minutes)<=0)
        result_date = time - (MINUTE*start)
        result_remainder = duration+available_minutes
      elsif (minutes(start+duration,start-1)==duration.abs)
        result_date = time + (MINUTE*duration)
        result_remainder = 0
      else     
        step = start + duration
        duration+=minutes(step,start-1)
        until (duration==0)
          step-=1
          duration+=minutes(step,step)
        end
        result_date = time - (MINUTE * (start-step))
        result_remainder = 0
      end  
      return result_date, result_remainder  
      
    end
  end
end

class Integer
  include Workpattern::Hour
end
