module Workpattern
  
  class Day
    
    attr_accessor  :pattern, :hours_per_day

    def initialize(hours_per_day = HOURS_IN_DAY, type = WORK_TYPE)
      @hours_per_day = hours_per_day
      @pattern = initial_day(type)
    end

    def set_resting(start_time, finish_time)
      mask = resting_mask(start_time, finish_time)
      @pattern = @pattern & mask
    end

    def set_working(from_time, to_time)
      @pattern = @pattern | working_mask(from_time, to_time)
    end

    def working_minutes(from_time = FIRST_TIME_IN_DAY, to_time = LAST_TIME_IN_DAY)
      section = @pattern & working_mask(from_time, to_time)
      section.to_s(2).count('1') 
    end

    def working?(hour, minute)
      mask = (2**((hour * 60) + minute))
      result = mask & @pattern
      if mask == result
        return true
      else
        return false
      end
    end
   
    def resting?(hour, minute)
      !working?(hour,minute)
    end
    
    private

    def working_day
      2**((60 * @hours_per_day) +1) - 1
    end
    
    def initial_day(type = WORK_TYPE)

      pattern = 2**((60 * @hours_per_day) + 1)

      if type == WORK_TYPE
        pattern = pattern - 1
      end
      
      pattern
    end

    def working_mask(start_time, finish_time)
    
      start = minutes_in_time(start_time) 
      finish = minutes_in_time(finish_time) 

      mask = initial_day

      mask = mask - ((2**start) - 1)
      mask & ((2**(finish + 1)) -1)
    end

    def resting_mask(start_time, finish_time)

      start = minutes_in_time(start_time)
      finish_clock = Clock.new(finish_time.hour, finish_time.min + 1) 

      mask = initial_day(REST_TYPE)
      if minutes_in_time(finish_time) != LAST_TIME_IN_DAY.minutes
        mask = mask | working_mask(finish_clock,LAST_TIME_IN_DAY)
      end	
      mask | ((2**start) - 1)
    end 

    def minutes_in_time(a_time)
      (a_time.hour * 60) + a_time.min
    end

  end

end
