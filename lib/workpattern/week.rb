module Workpattern
  
  # Represents working and resting times of each day in a week from one date to another.
  # The two dates could be the same day or they could be several weeks or years apart.
  #
  class Week
    
    attr_accessor :values, :days, :start, :finish, :week_total, :total
    
    # :call-seq: new(start,finish,type) => Week
    #  
    #
    def initialize(start,finish,type=1)
      hours_in_days_in_week=[24,24,24,24,24,24,24]
      @days=hours_in_days_in_week.size
      @values=Array.new(7) {|index| Day.new(type)}
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
      DAYNAMES[days].each {|day| @values[day].workpattern(from_time,to_time,type)}  
      refresh
    end
    
    def calc(start,duration, next_day=false)
      return start,duration if duration==0
      return add(start,duration) if duration > 0
      return subtract(start,duration, next_day) if duration <0  
    end
    
    def <=>(obj)
      if @start < obj.start
        return -1
      elsif @start == obj.start
        return 0
      else
        return 1
      end      
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
      # aim to calculate to the end of the day
      start,duration = @values[start.wday].calc(start,duration)
      return start,duration if (duration==0) || (start.jd > @finish.jd) 
      # aim to calculate to the end of the next week day that is the same as @finish
      while((duration!=0) && (start.wday!=@finish.next_day.wday) && (start.jd <= @finish.jd))
        if (duration>=@values[start.wday].total)
          duration = duration - @values[start.wday].total
          start=start.next_day
        else
          start,duration = @values[start.wday].calc(start,duration)
        end
      end
      
      return start,duration if (duration==0) || (start.jd > @finish.jd) 
      
      #while duration accomodates full weeks
      while ((duration!=0) && (duration>=@week_total) && ((start.jd+6) <= @finish.jd))
        duration=duration - @week_total
        start=start+7
      end

      return start,duration if (duration==0) || (start.jd > @finish.jd) 

      #while duration accomodates full days
      while ((duration!=0) && (start.jd<= @finish.jd))
        if (duration>@values[start.wday].total)
          duration = duration - @values[start.wday].total
          start=start.next_day
        else
          start,duration = @values[start.wday].calc(start,duration)
        end
      end    
      return start, duration 
      
    end

    def subtract(start,duration,next_day)

      # Handle subtraction from start of day
      if next_day
        start,duration=end_of_day(start,duration)
      end

      # aim to calculate to the start of the day
      start,duration = @values[start.wday].calc(start,duration)
      return start,duration if (duration==0) || (start.jd ==@start.jd) 

      # aim to calculate to the start of the previous week day that is the same as @start
      while((duration!=0) && (start.wday!=@start.wday) && (start.jd >= @start.jd))

        if (duration.abs>=@values[start.wday].total)

          duration = duration + @values[start.wday].total
          start=start.prev_day
        else

          start,duration=end_of_day(start,duration)             
          start,duration = @values[start.wday].calc(start,duration)
        end
      end

      return start,duration if (duration==0) || (start.jd ==@start.jd) 

      #while duration accomodates full weeks
      while ((duration!=0) && (duration.abs>=@week_total) && ((start.jd-6) >= @start.jd))
        duration=duration + @week_total
        start=start-7
      end

      return start,duration if (duration==0) || (start.jd ==@start.jd) 

      #while duration accomodates full days
      while ((duration!=0) && (start.jd>= @start.jd))    
        if (duration.abs>=@values[start.wday].total)
          duration = duration + @values[start.wday].total
          start=start.prev_day
        else
          start,duration=end_of_day(start,duration)       
          start,duration = @values[start.wday].calc(start,duration)
        end
      end            
      return start, duration 
      
    end
    
    def end_of_day(start,duration)
      duration += @values[start.wday].minutes(23,59,23,59)
      start-=MINUTE
      return start,duration
    end  
  end
end
