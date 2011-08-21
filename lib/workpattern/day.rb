module Workpattern
  class Day
    
    attr_accessor :values, :hours, :first_hour, :first_min, :last_hour, :last_min, :total
    
    def initialize(type=1,hours_in_day=24)
      @hours=hours_in_day
      hour=Workpattern::WORKING_HOUR if type==1
      hour=Workpattern::RESTING_HOUR if type==0
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
  end
end
