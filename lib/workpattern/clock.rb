module Workpattern
  class Clock
  
    def initialize(hour=0,min=0)
      @hour=hour
      @min=min
    end
    
    def minutes
      return (@hour*60)+@min
    end
    
    def hour
      return @hour % 24
    end
    
    def min
      return @min % 60
    end
    
    def time
      return Time.new(1963,6,10,hour,min)
    end      
  end
end
