module Workpattern
  
  module Utility
  
    def midnight_before(adate)
      return adate -(HOUR * adate.hour) - (MINUTE * adate.min)
    end
    
    def midnight_after(adate)
      return midnight_before(adate.next_day)
    end
    
  end
end  
