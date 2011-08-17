module Workpattern
  module Hour
 
    # Returns the total working minutes in the hour
    # 
    def total
      return minutes(0,59)
    end  
    
    # Sets the minutes to either working (type=1) or resting (type=0)
    #
    def workpattern(start,finish,type)
      return working(start,finish) if type==1
      return resting(start,finish) if type==0
    end
    
    # Returns the first working minute in the hour or 60 if there are none
    #
    def first
      0.upto(59) {|minute| return minute if self.minutes(minute,minute)==1}
      return 60
    end
    
    # Returns the last working minute in the hour or -1 if there are none
    #
    def last
      59.downto(0) {|minute| return minute if self.minutes(minute,minute)==1}
      return -1
    end
    
    # Returns true if the given minute is working and false if it isn't
    #
    def minute?(start)
      return true if minutes(start,start)==1
      return false
    end
    
    # Returns the total number of minutes between and including two minutes
    #
    def minutes(start,finish)
      start,finish=finish,start if start > finish
      return (self & mask(start,finish)).to_s(2).count('1')
    end
    
    # Returns the result and remainder when adding duration to a minute
    # 60 is returned if it is really the next hour
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
    
    # returns the number of minutes between two minutes
    #
    def diff(start,finish)
      return 0 if start==finish
      return (self & mask(start,finish-1)).to_s(2).count('1')
    end
    
    private

    def working(start,finish)
      return self | mask(start,finish)
    end
    
    def resting(start,finish)
      return self & ((2**60-1)-mask(start,finish))
    end
    
    def mask(start,finish)
      return ((2**(finish+1)-1)-(2**start-1))
    end
    
    def add(time,duration)
      maximum=minutes(time,59)
      return 60,(duration-maximum) if ((duration-maximum)>=0) 
      return (time+duration),0 if (minutes(time,time+duration-1)==duration)
      
      start = time + duration
      duration-=minutes(time,time+duration)
      until (duration==0)
        start+=1
        duration-=minutes(start,start)
      end
      return start+1,0  
    end
    
    def subtract(time,duration)
      maximum=0
      maximum=minutes(0,time-1) if time>0
      return 0,(duration+maximum) if ((duration + maximum)<=0)
      return (time+duration),0 if (minutes(time+duration,time-1)==duration)
      
      start = time + duration
      duration+=minutes(time+duration,time-1)
      until (duration==0)
        start-=1
        duration+=minutes(start-1,start-1)
      end
      return start,0
      
    end
  end
end

class Fixnum
  include Workpattern::Hour
end
class Bignum
  include Workpattern::Hour
end
  
