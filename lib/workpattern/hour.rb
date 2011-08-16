module Workpattern
  module Hour
  
    def total
      return minutes(0,59)
    end  
    
    def workpattern(start,finish,type)
      working(start,finish) if type==1
      resting(start,finish) if type==0
    end
    
    def first
      0.upto(59) {|minute| return minute if self.minutes(minute,minute)==1}
      return 60
    end
    
    def last
      59.downto(0) {|minute| return minute if self.minutes(minute,minute)==1}
      return -1
    end
    
    def minute?(start)
      return true if minutes(start,start)==1
      return false
    end
    
    def minutes(start,finish)
      start,finish=finish,start if start > finish
      return (self & mask(start,finish)).to_s(2).count('1')
    end
    
    def working(start,finish)
      return self & mask(start,finish)
    end
    
    def resting(start,finish)
      return self & ((2**60-1)-mask(start,finish))
    end
    
    def calc(time,duration)
    
      if (duration<0)
        return subtract(time,duration)  
      elsif (duration>0)
        return add(time,duration)                
      else
        return time,duration
      end 
        
      # if time to end is less than duration then count up and return
      #
      
      # otherwise count duration towards end then 1 by 1
      #
    end
    
    private
    
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
      maximum=minutes(0,time-1)
      return 0,(duration+maximum) if ((duration + maximum)<=0)
    end
  end
end

class Fixnum
  include Workpattern::Hour
end
class Bignum
  include Workpattern::Hour
end
  
