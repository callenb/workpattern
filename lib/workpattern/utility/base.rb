module Workpattern
  
  module Utility
  
    def midnight_before(adate)
      return(midnight_after(adate.prev_day))
    end
    
    def midnight_after(adate)
      return adate -(HOUR * adate.hour) - (MINUTE * adate.min)
    end
    
  end
end  
