module Workpattern
  
  class Day
    
    attr_reader  :pattern, :hours_per_day

    def initialize(hours_per_day = HOURS_IN_DAY, type = WORK_TYPE)
      @hours_per_day = hours_per_day
      @pattern = working_day * type
    end

    #REMOVE
    def work_on_day(from_time,to_time)
      #@pattern = @pattern | time_mask(from_time, to_time)
      @pattern = work(from_time, to_time)
    end

    def set_resting(from_time, to_time)
      mask = 0 if last_minute?(to_time) && first_minute?(from_time)
      mask = bit_time(from_time.hour, from_time.min) - 1 if last_minute?(to_time)
      mask = bit_time(23, 59, 1) - bit_time(to_time.hour, to_time.min,1)  if first_minute?(from_time) 
      mask = working_day - (bit_time(to_time.hour, to_time.min,1) - bit_time(from_time.hour, from_time.min)) if !first_minute?(from_time) && !last_minute?(to_time)
      @pattern = @pattern & mask
    end

    def set_working(from_time, to_time)
      mask = working_day if last_minute?(to_time) && first_minute?(from_time)
      mask = bit_time(to_time.hour, to_time.min, 1) - 1 if first_minute?(from_time) 
      mask = bit_time(23,59,1) - bit_time(from_time.hour, from_time.min ) if last_minute?(to_time)
      mask = bit_time(to_time.hour, to_time.min,1) - bit_time(from_time.hour, from_time.min) if !first_minute?(from_time) && !last_minute?(to_time)
      @pattern = @pattern | mask
    end

    #REMOVE
    def work(from_time, to_time)
      if from_time.hour == 0 && from_time.min == 0 
        mask = (2**((60*to_time.hour) + to_time.min) - 1)
      else
        mask = (2**((60*to_time.hour) + to_time.min + 1)) - (2**((60*from_time.hour) + from_time.min))
      end
      @pattern = @pattern | mask
    end	


    def working_day
      2**(60 * @hours_per_day) - 1
    end

    def total_minutes
      @pattern.to_s(2).count('1')
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

    def bit_time(hour, minute, offset=0)
      2**((60 * hour) + minute + offset)
    end

    def last_minute?(time)
      return true if time.hour == 23 && time.min == 59
      false
    end

    def first_minute?(time)
      return true if time.hour == 0 && time.min == 0
      false
    end



    #REMOVE
    def time_mask(from_time, to_time)
      if from_time.hour == 0 && from_time.min == 0
        bit_pos(to_time.hour, to_time.min)-1
      else
        bit_pos(to_time.hour, to_time.min + 1) - bit_pos(from_time.hour, from_time.min)
      end	
    end

    #REMOVE
    def bit_pos(hour,minute)
      2**( (hour * 60) + minute )
    end
  end

end
