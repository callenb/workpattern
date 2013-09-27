module Workpattern
  
  # @author Barrie Callender
  # @!attribute values
  #   @return [Array] each day of the week
  # @!attribute days
  #   @return [Integer] number of days in the week
  # @!attribute start
  #   @return [DateTime] first date in the range
  # @!attribute finish
  #   @return [DateTime] last date in the range
  # @!attribute week_total
  #   @return [Integer] total number of minutes in a week
  # @!attribute total
  #   @return [Integer] total number of minutes in the range
  #  
  # Represents working and resting periods for each day in a week for a specified date range.
  #
  # @since 0.2.0
  #
  class Week
    
    attr_accessor :values, :days, :start, :finish, :week_total, :total

    # The new <tt>Week</tt> object can be created as either working or resting.
    #
    # @param [DateTime] start first date in the range
    # @param [DateTime] finish last date in the range
    # @param [Integer] type working (1) or resting (0)
    # @return [Week] newly initialised Week object    
    #
    def initialize(start,finish,type=1)
      hours_in_days_in_week=[24,24,24,24,24,24,24]
      @days=hours_in_days_in_week.size
      @values=Array.new(7) {|index| Day.new(type)}
      @start=DateTime.new(start.year,start.month,start.day)
      @finish=DateTime.new(finish.year,finish.month,finish.day)
        
      set_attributes
    end
    
    # Duplicates the current <tt>Week</tt> object
    #
    # @return [Week] a duplicated instance of the current <tt>Week</tt> object
    #
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
    
    # Recalculates the attributes that define a <tt>Week</tt> object.
    # This was made public for <tt>#duplicate</tt> to work
    #
    def refresh
      set_attributes
    end
    
    # Changes the date range.
    # This method calls <tt>#refresh</tt> to update the attributes.
    #
    # @param [DateTime] start is the new starting date for the <tt>Week</tt>
    # @param [DateTime] finish is the new finish date for the <tt>Week</tt>    
    #
    def adjust(start,finish)
      @start=DateTime.new(start.year,start.month,start.day)
      @finish=DateTime.new(finish.year,finish.month,finish.day)
      refresh
    end
    
    # Sets a range of minutes in a week to be working or resting.  The parameters supplied
    # to this method determine exactly what should be changed
    #
    # @param [Hash(DAYNAMES)] days identifies the days to be included in the range
    # @param [DateTime] from_time where the time portion is used to specify the first minute to be set
    # @param [DateTime] to_time where the time portion is used to specify the last minute to be set
    # @param [Integer] type where a 1 sets it to working and a 0 to resting
    #
    def workpattern(days,from_time,to_time,type)
      DAYNAMES[days].each {|day| @values[day].workpattern(from_time,to_time,type)}  
      refresh
    end
    
    # Calculates a new date by adding or subtracting a duration in minutes.
    #
    # @param [DateTime] start original date
    # @param [Integer] duration minutes to add or subtract
    # @param [Boolean] midnight flag used for subtraction that indicates the start date is midnight
    #
    def calc(start,duration, midnight=false)
      return start,duration,false if duration==0
      return add(start,duration) if duration > 0
      return subtract(@start,duration, midnight) if (@total==0) && (duration <0)
      return subtract(start,duration, midnight) if duration <0  
    end
    
    # Comparison Returns an integer (-1, 0, or +1) if week is less than, equal to, or greater than other_week
    #
    # @param [Week] other_week object to compare to
    # @return [Integer] -1,0 or +1 if week is less than, equal to or greater than other_week
    def <=>(other_week)
      if @start < other_week.start
        return -1
      elsif @start == other_week.start
        return 0
      else
        return 1
      end      
    end
    
    # Returns true if the supplied DateTime is working and false if resting
    #
    # @param [DateTime] start DateTime to be tested
    # @return [Boolean] true if the minute is working otherwise false if it is a resting minute
    #
    def working?(start)
      @values[start.wday].working?(start)
    end    

    # Returns the difference in minutes between two DateTime values.
    #
    # @param [DateTime] start starting DateTime
    # @param [DateTime] finish ending DateTime
    # @return [Integer, DateTime] number of minutes and start date for rest of calculation.
    #
    def diff(start,finish)
      start,finish=finish,start if ((start <=> finish))==1
      # calculate to end of day
      #
      if (start.jd==finish.jd) # same day
        duration, start=@values[start.wday].diff(start,finish)
      elsif (finish.jd<=@finish.jd) #within this week
        duration, start=diff_detail(start,finish,finish)
      else # after this week
        duration, start=diff_detail(start,finish,@finish)
      end
      return duration, start
    end
    
    private
    
    # Recalculates all the attributes for a Week object
    #
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
    
    # Calculates the total number of minutes between two dates
    #
    # @param [DateTime] start is the first date in the range
    # @param [DateTime] finish is the last date in the range
    # @return [Integer] total number of minutes between supplied dates
    #
    def total_hours(start,finish)
      total=0
      start.upto(finish) {|day|
        total+=@values[day].total
        }
      return total
    end
    
    # Adds a duration in minutes to a date.
    #
    # The Boolean returned is always false.
    #
    # @param [DateTime] start original date
    # @param [Integer] duration minutes to add
    # @return [DateTime, Integer, Boolean] the calculated date, remaining minutes and flag used for subtraction
    #
    def add(start,duration)
      # aim to calculate to the end of the day
      start,duration = @values[start.wday].calc(start,duration)   
      return start,duration,false if (duration==0) || (start.jd > @finish.jd) 
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
      
      return start,duration,false if (duration==0) || (start.jd > @finish.jd) 
      
      # while duration accomodates full weeks
      while ((duration!=0) && (duration>=@week_total) && ((start.jd+6) <= @finish.jd))
        duration=duration - @week_total
        start=start+7
      end

      return start,duration,false if (duration==0) || (start.jd > @finish.jd) 

      # while duration accomodates full days
      while ((duration!=0) && (start.jd<= @finish.jd))
        if (duration>@values[start.wday].total)
          duration = duration - @values[start.wday].total
          start=start.next_day
        else
          start,duration = @values[start.wday].calc(start,duration)
        end
      end    
      return start, duration, false 
      
    end
    
    # Subtracts a duration in minutes from a date
    #
    # @param [DateTime] start original date
    # @param [Integer] duration minutes to subtract - always a negative
    # @param [Boolean] midnight flag indicates the start date is midnight when true
    # @return [DateTime, Integer, Boolean] the calculated date, remaining number of minutes and 
    #     true if the time is midnight on the date
    #
    def subtract(start,duration,midnight=false)
      
      # Handle subtraction from start of day
      if midnight
        start,duration=minute_b4_midnight(start,duration)
        midnight=false
      end

      # aim to calculate to the start of the day
      start,duration, midnight = @values[start.wday].calc(start,duration)

      if midnight && (start.jd >= @start.jd)
        start,duration=minute_b4_midnight(start,duration)
        return subtract(start,duration, false)
      elsif midnight
        return start,duration,midnight
      elsif  (duration==0) || (start.jd ==@start.jd) 
        return start,duration, midnight
      end  

      # aim to calculate to the start of the previous week day that is the same as @start
      while((duration!=0) && (start.wday!=@start.wday) && (start.jd >= @start.jd))

        if (duration.abs>=@values[start.wday].total)
          duration = duration + @values[start.wday].total
          start=start.prev_day
        else
          start,duration=minute_b4_midnight(start,duration)             
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
          start,duration=minute_b4_midnight(start,duration)       
          start,duration = @values[start.wday].calc(start,duration)
        end
      end    
              
      return start, duration , midnight
      
    end
    
    # Supports calculating from midnight by updating the given duration depending on whether the
    # last minute in the day is resting or working.  It then sets the time to this minute.
    #
    # @param [DateTime] start is the date whose midnight is to be used as the start date
    # @param [Integer] duration is the number of minutes to subtract
    # @return [DateTime, Integer] the date with a time of 23:59 and remaining duration
    #     adjusted according to whether 23:59 is resting or not
    #
    def minute_b4_midnight(start,duration)
      start -= start.hour * HOUR
      start -= start.min * MINUTE
      duration += @values[start.wday].minutes(23,59,23,59)
      start = start.next_day - MINUTE
      return start,duration
    end  
    
    # Calculates the date and time after the last working minute of the current date
    #
    # @param [DateTime] start is the current date
    # @return [DateTime] the new date
    #
    def after_last_work(start)
      if @values[start.wday].last_hour.nil?
        return start.next_day
      else  
        start = start + HOUR * (@values[start.wday].last_hour - start.hour)
        start = start + MINUTE * (@values[start.wday].last_min - start.min + 1)
        return start
      end  
    end
    
    # Calculates the difference between two dates that exist in this Week object.
    #
    # @param [DateTime] start first date 
    # @param [DateTime] finish last date
    # @param [DateTime] finish_on the range to be used in this Week object.  
    # @return [DateTime, Integer] new date for rest of calculation and total number of minutes calculated thus far.
    #
    def diff_detail(start,finish,finish_on)
      duration, start=@values[start.wday].diff(start,finish)
      return duration,start if start > finish_on
      #rest of week to finish day
      while (start.wday<finish.wday) do
        duration+=@values[start.wday].total
        start=start.next_day
      end
      #weeks
      while (start.jd+7<finish_on.jd) do
        duration+=@week_total
        start+=7
      end
      #days
      while (start.jd < finish_on.jd) do
        duration+=@values[start.wday].total
        start=start.next_day
      end
      #day
      day_duration, start=@values[start.wday].diff(start,finish)
      duration+=day_duration
      return duration, start
    end
    
  end
end
