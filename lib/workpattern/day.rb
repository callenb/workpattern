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

    def work_to_end_of_day(time)
      binary_time(self.hours_per_day,0) - binary_time(time.hour, time.min)
    end

    def remaining_binary_minutes(time)
      mask = work_to_end_of_day(time)
      (self.value & mask)
    end

  end

end
