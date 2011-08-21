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
        @last_hour=index if ((@last_hour==(-1)) && (@values[index].total!=0))
        @last_min=@values[index].last if (@values[index].last!=(-1))
        @total+=@values[index].total
      }
    end
  end
end
