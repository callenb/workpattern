module Workpattern

  class Day

    attr_accessor :value, :hours_per_day, :total

    def initialize(type=1,hours_per_day=24)
      @hours_per_day = hours_per_day
      @value = working_day * type
    end
    
    def total
     working_minutes_in @value
    end

    def minutes_remaining(time)
      working_minutes_in remaining_binary_minutes(time)
    end

    def rest(start, finish)
      range_mask = time_range_mask(start.hour, start.min, finish.hour, finish.min)
      mask = range_mask ^ working_day & working_day
      self.value = self.value & mask
    end

    private

    def working_day
      2**(60*self.hours_per_day)-1
    end

    def working_minutes_in value
      value.to_s(2).count('1')
    end

    def binary_time(hour,minute)
      2**( (hour * 60) + minute )
    end
    
    def time_range_mask(from_hour, from_min, to_hour, to_min)
      binary_time(to_hour,to_min) - binary_time(from_hour, from_min)
    end

    def work_to_end_of_day(time)
      time_range_mask(time.hour, time.min,self.hours_per_day,0)
    end

    def remaining_binary_minutes(time)
      mask = work_to_end_of_day(time)
      (self.value & mask)
    end

  end

end
