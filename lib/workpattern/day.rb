module Workpattern
  
  class Day
    
    attr_accessor  :pattern, :hours_per_day

    def initialize(hours_per_day = HOURS_IN_DAY, type = WORK_TYPE)
      @hours_per_day = hours_per_day
      @pattern = working_day * type
    end

    def set_resting(from_time, to_time)
      mask = 0 if last_minute?(to_time) && first_minute?(from_time)
      mask = bit_time(from_time) - 1 if last_minute?(to_time)
      mask = bit_time(LAST_TIME_IN_DAY, 1) - bit_time(to_time,1)  if first_minute?(from_time) 
      mask = working_day - (bit_time(to_time,1) - bit_time(from_time)) if !first_minute?(from_time) && !last_minute?(to_time)
      @pattern = @pattern & mask
    end

    def set_working(from_time, to_time)
      @pattern = @pattern | working_mask(from_time, to_time)
    end

    def working_day
      2**(60 * @hours_per_day) - 1
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

    def bit_time(time, offset=0)
	    2**((60 * time.hour) + time.min + offset)
    end

    def working_mask(from_time, to_time)
      mask = working_day if last_minute?(to_time) && first_minute?(from_time)
      mask = bit_time(to_time, 1) - 1 if first_minute?(from_time) 
      mask = bit_time(LAST_TIME_IN_DAY,1) - bit_time(from_time ) if last_minute?(to_time)
      mask = bit_time(to_time,1) - bit_time(from_time) if !first_minute?(from_time) && !last_minute?(to_time)
      mask
    end

    def last_minute?(time)
      return true if time.hour == 23 && time.min == 59
      false
    end

    def first_minute?(time)
      return true if time.hour == 0 && time.min == 0
      false
    end

  end

end
