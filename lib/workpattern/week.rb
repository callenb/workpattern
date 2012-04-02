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
    
    def calc(start,duration, midnight=false)
      return start,duration if duration==0
      return add(start,duration) if duration > 0
      return subtract(start,duration, midnight) if duration <0  
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
        if (duration>@values[start.wday].total)
          duration = duration - @values[start.wday].total
          start=start.next_day
        elsif (duration==@values[start.wday].total)
          start=after_last_work(start)
          duration = 0
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

    def subtract(start,duration,midnight=false)
puts "### subtract(#{start},#{duration},#{midnight})"
      
      # Handle subtraction from start of day
      if midnight
        start,duration=minute_b4_midnight(start,duration)
        midnight=false
      end
puts "### A: start=#{start},duration=#{duration},midnight=#{midnight}"
      # aim to calculate to the start of the day
      start,duration, midnight = @values[start.wday].calc(start,duration)
puts "### B: start=#{start},duration=#{duration},midnight=#{midnight}"      
      if midnight && (start.jd >= @start.jd)
        start,duration=minute_b4_midnight(start,duration)
puts "### B1: start=#{start},duration=#{duration},midnight=#{midnight}"          
        return subtract(start,duration, false)
      elsif midnight
puts "### B2: start=#{start},duration=#{duration},midnight=#{midnight}"        
        return start,duration,midnight
      elsif  (duration==0) || (start.jd ==@start.jd) 
puts "### B3: start=#{start},duration=#{duration},midnight=#{midnight}"        
        return start,duration, midnight
      end  

      # aim to calculate to the start of the previous week day that is the same as @start
      while((duration!=0) && (start.wday!=@start.wday) && (start.jd >= @start.jd))

        if (duration.abs>=@values[start.wday].total)

          duration = duration + @values[start.wday].total
          start=start.prev_day
puts "### C: start=#{start},duration=#{duration},midnight=#{midnight}"          
        else

          start,duration=minute_b4_midnight(start,duration)             
          start,duration = @values[start.wday].calc(start,duration)
puts "### D: start=#{start},duration=#{duration},midnight=#{midnight}"          
        end
      end

      return start,duration if (duration==0) || (start.jd ==@start.jd) 

      #while duration accomodates full weeks
      while ((duration!=0) && (duration.abs>=@week_total) && ((start.jd-6) >= @start.jd))
        duration=duration + @week_total
        start=start-7
puts "### E: start=#{start},duration=#{duration},midnight=#{midnight}"                  
      end

      return start,duration if (duration==0) || (start.jd ==@start.jd) 

      #while duration accomodates full days
      while ((duration!=0) && (start.jd>= @start.jd))    
        if (duration.abs>=@values[start.wday].total)
          duration = duration + @values[start.wday].total
          start=start.prev_day
puts "### F: start=#{start},duration=#{duration},midnight=#{midnight}"                    
        else
          start,duration=minute_b4_midnight(start,duration)       
          start,duration = @values[start.wday].calc(start,duration)
puts "### G: start=#{start},duration=#{duration},midnight=#{midnight}"                    
        end
      end    
puts "### Z: return(#{start},#{duration}"                                  
      return start, duration 
      
    end
    
    def minute_b4_midnight(start,duration)
      duration += @values[start.wday].minutes(23,59,23,59)
      start = start.next_day - MINUTE
      return start,duration
    end  
    
    def after_last_work(start)
      if @values[start.wday].last_hour.nil?
        return start.next_day
      else  
        start = start + HOUR * (@values[start.wday].last_hour - start.hour)
        start = start + MINUTE * (@values[start.wday].last_min - start.min + 1)
        return start
        #return start + (HOUR *(@values[start.wday].last_hour - start.hour)) + (MINUTE *(@values[start.wday].last_min - start.min))
      end  
    end
  end
end
