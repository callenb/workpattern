module Workpattern

  class Day

    attr_accessor :hours_per_day, :total

    def initialize(type=1,hours_per_day=24)
      @hours_per_day = hours_per_day
      @value = working_day * type
    end

    def total
     @value.to_s(2).count('1')
    end

    private

    def working_day
      2**(60*self.hours_per_day)-1
    end

  end

end
