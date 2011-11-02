module Workpattern
  class Week
    
    attr_accessor :values, :days, :start, :finish, :week_total, :total
    
    def initialize(start,finish,type=1,hours_in_days_in_week=[24,24,24,24,24,24,24])
      @days=hours_in_days_in_week.size
      @values=Array.new(7) {|index| Day.new(type,hours_in_days_in_week[index])}
      @start=Time.new(start.year,start.month,start.day)
      @finish=Time.new(finish.year,finish.month,finish.day)
        
      set_attributes
    end
    
    def duplicate()
      duplicate_week=Week.new(@start,@finish)
      duplicate_values=Array.new(@values.size)
      @values.each_index {|index|
        duplicate_values[index]=@values[index].duplicate
        }
      duplicate_week.values=duplicate_values  
      duplicate_week.days=@days
      duplicate_week.start=@start
      duplicate_week.finish=@finish
      duplicate_week.week_total=@week_total
      duplicate_week.total=@total
      duplicate_week.refresh
      return duplicate_week
    end
    
    def refresh
      set_attributes
    end
    
    def adjust(start,finish)
      @start=Time.new(start.year,start.month,start.day)
      @finish=Time.new(finish.year,finish.month,finish.day)
      refresh
    end
    
    def workpattern(days,from_time,to_time,type)
      DAYNAMES[days].each {|day| @values[day].workpattern(from_time.hour,from_time.min,to_time.hour,to_time.min,type)}  
      refresh
    end
    
    def calc(start_date,duration)
    
      if (duration<0)
        return subtract(start_date,duration)  
      elsif (duration>0)
        return add(start_date,duration)                
      else
        return start_date,duration
      end
    
    end
    
    private
    
    def set_attributes
      @total=0
      @week_total=0
      days=(@finish-@start)/60/60/24+1
      
      if (7-@start.wday) < days and days < 8
        @total+=total_hours(@start.wday,@finish.wday)
        @week_total=@total
      else
        @total+=total_hours(@start.wday,6)
        days -= (7-@start.wday)
        @total+=total_hours(0,@finish.wday)
        days-=(@finish.wday+1)
        @week_total=@total if days==0
        week_total=total_hours(0,6)
        @total+=week_total * days /7
        @week_total=week_total if days != 0
      end
    end
    
    def total_hours(start,finish)
      total=0
      start.upto(finish) {|day|
        total+=@values[day].total
        }
      return total
    end
    
        
  end
end
