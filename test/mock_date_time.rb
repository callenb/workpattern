module Workpattern
  class MockDateTime
    attr_accessor :year, :month, :day, :hour, :min
    
    def initialize(year, month, day, hour, min)
      @year=year
      @month=month
      @day=day
      @hour=hour
      @min=min
    end
  end
end
