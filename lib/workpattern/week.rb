module Workpattern
  
  # Represents working and resting times of each day in a week from one date to another.
  # The two dates could be the same day or they could be several weeks or years apart.
  #
  class Week
    
    attr_accessor :values, :days, :start, :finish, :week_total, :total
    
    # :call-seq: new(start,finish,type, hours_in_days_in_week) => Week
    #  
    #
    def initialize(start,finish,type=1,hours_in_days_in_week=[24,24,24,24,24,24,24])
      @days=hours_in_days_in_week.size
      @values=Array.new(7) {|index| Day.new(type,hours_in_days_in_week[index])}
      @start=DateTime.new(start.year,start.month,start.day)
      @finish=DateTime.new(finish.year,finish.month,finish.day)
        
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
      @start=DateTime.new(start.year,start.month,start.day)
      @finish=DateTime.new(finish.year,finish.month,finish.day)
      refresh
    end
    
    def workpattern(days,from_time,to_time,type)
      DAYNAMES[days].each {|day| @values[day].workpattern(from_time.hour,from_time.min,to_time.hour,to_time.min,type)}  
      refresh
    end
    
    def calc(start,duration)
      return start,duration if duration==0
      return add(start,duration) if duration > 0
      return subtract(start,duration) if duration <0  
    end
    
    private
    
    def set_attributes
      @total=0
      @week_total=0
      days=(@finish-@start).to_i + 1 #/60/60/24+1 
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
        @total+=week_total * days / 7
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
    
    def add(start,duration)
      #
      # step 1: calculate to the end of the current day
      # step 2: find out the week day of the last date in the week class & calculate to the end of it
      # step 3: do a whole week thing
      #
      start_min = 0
      # aim to calculate to the end of the day
      while (duration !=0) && (start_min !=60)
        start_hour,start_min,duration = @values[start.wday].calc(start.hour,start.min,duration)
      end

      # aim to calculate to the end of the next week day that is the same as @finish
      if (start_min==60)
        start=start.next_day
        start=DateTime.civil(start.year,start.month,start.day,start_hour=0,start_min=0)
        # calculate to end of next week day
        while (duration>=@values[start.wday].total) && (start.wday!=@finish.next_day.wday)
          duration = duration - @values[start.wday].total
          start=start.next_day
        end
      else
        start=DateTime.civil(start.year,start.month,start.day,start_hour,start_min)  
      end
      
      #while duration accomodates full weeks
      while (duration>=@week_total) && ((start+7)<@finish.next_day)
        duration=duration - @week_total
        start=start+7
      end
      
      #while duration accomodates full days
      while (duration>=@values[start.wday].total) && (start<@finish.next_day)
        duration = duration - @values[start.wday].total
        start=start.next_day
      end
      
      
      #calculate in day
      if ((duration !=0) && (start<@finish.next_day)) 
        start_hour,start_min,duration = @values[start.wday].calc(start.hour,start.min,duration)
        start=DateTime.civil(start.year,start.month,start.day,start_hour,start_min)
      end
       
      return start, duration 
    end

  end
end
