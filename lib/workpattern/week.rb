module Workpattern
  
  # @author Barrie Callender
  # @!attribute values
  #   @return [Array] each day of the week
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
    
    attr_accessor :values, :hours_per_day, :start, :finish, :week_total, :total

    # The new <tt>Week</tt> object can be created as either working or resting.
    #
    # @param [DateTime] start first date in the range
    # @param [DateTime] finish last date in the range
    # @param [Integer] type working (1) or resting (0)
    # @return [Week] newly initialised Week object    
    #
    def initialize(start,finish,type=1,hours_per_day=24)
      @hours_per_day = hours_per_day
      @start=DateTime.new(start.year,start.month,start.day)
      @finish=DateTime.new(finish.year,finish.month,finish.day)
      @values = 2**(7*60*hours_per_day*type) - 1
    end

    def week_total
      @values.to_s(2).count('1')
    end 

    def total
      total_days = span_in_days
      return week_total if total_days < 8
      sum = total_minutes(self.start.wday,6)
      total_days -= (7-self.start.wday)
      sum += total_minutes(0,self.finish.wday)
      total_days-=(self.finish.wday+1)
      sum += week_total * total_days / 7
      return sum
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
      DAYNAMES[days].each do |day| 
        type==1 ? work_on_day(day,from_time,to_time) : rest_on_day(day,from_time,to_time)
      end
    end

  private
    def bit_week
      2**(7*60*self.hours_per_day)-1
    end
    
    def bit_pos(day,time)
      2**((day * self.hours_per_day * 60) + (time.hour * 60) + time.min )
    end

    def bit_pos_above(day,time)
      2**((day * self.hours_per_day * 60) + (time.hour * 60) + time.min + 1)
    end

    def time_mask(day,from_time, to_time)
      bit_pos_above(day,to_time) - bit_pos(day,from_time)      
    end

    def span_in_days
      (self.finish-self.start).to_i + 1
    end

    def total_minutes(start,finish)
      mask = ((2**((finish+1)*60*self.hours_per_day)) - (2**(start*60*self.hours_per_day))).to_i
      return (self.values & mask).to_s(2).count('1')
    end

    def work_on_day(day,from_time,to_time)
      self.values = self.values | time_mask(day, from_time, to_time)  
    end

    def rest_on_day(day,from_time,to_time)
      mask = bit_week & ~(time_mask(day,from_time, to_time))
      self.values = self.values & mask
    end

    
#################################################################
## NOT USED YET
#################################################################
    
    # Duplicates the current <tt>Week</tt> object
    #
    # @return [Week] a duplicated instance of the current <tt>Week</tt> object
    #
    def xduplicate()
      duplicate_week=Week.new(self.start,self.finish)
      duplicate_values=Array.new(self.values.size)
      self.values.each_index {|index|
        duplicate_values[index]=self.values[index].duplicate
        }
      duplicate_week.values=duplicate_values  
      duplicate_week.days=self.days
      duplicate_week.start=self.start
      duplicate_week.finish=self.finish
      duplicate_week.week_total=self.week_total
      duplicate_week.total=self.total
      duplicate_week.refresh
      return duplicate_week
    end
    
    # Recalculates the attributes that define a <tt>Week</tt> object.
    # This was made public for <tt>#duplicate</tt> to work
    #
    def xrefresh
      set_attributes
    end
    
    # Changes the date range.
    # This method calls <tt>#refresh</tt> to update the attributes.
    #
    # @param [DateTime] start is the new starting date for the <tt>Week</tt>
    # @param [DateTime] finish is the new finish date for the <tt>Week</tt>    
    #
    def xadjust(start_date,finish_date)
      self.start=DateTime.new(start_date.year,start_date.month,start_date.day)
      self.finish=DateTime.new(finish_date.year,finish_date.month,finish_date.day)
      refresh
    end
    
    
    # Calculates a new date by adding or subtracting a duration in minutes.
    #
    # @param [DateTime] start original date
    # @param [Integer] duration minutes to add or subtract
    # @param [Boolean] midnight flag used for subtraction that indicates the start date is midnight
    #
    def xcalc(start_date,duration, midnight=false)
      return start_date,duration,false if duration==0
      return add(start_date,duration) if duration > 0
      return subtract(self.start,duration, midnight) if (self.total==0) && (duration <0)
      return subtract(start_date,duration, midnight) if duration <0  
    end
    
    # Comparison Returns an integer (-1, 0, or +1) if week is less than, equal to, or greater than other_week
    #
    # @param [Week] other_week object to compare to
    # @return [Integer] -1,0 or +1 if week is less than, equal to or greater than other_week
    def x(other_week)#<=>
      if self.start < other_week.start
        return -1
      elsif self.start == other_week.start
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
    def xworking?(start_date)
      self.values[start_date.wday].working?(start_date)
    end    

    # Returns the difference in minutes between two DateTime values.
    #
    # @param [DateTime] start starting DateTime
    # @param [DateTime] finish ending DateTime
    # @return [Integer, DateTime] number of minutes and start date for rest of calculation.
    #
    def xdiff(start_date,finish_date)
      start_date,finish_date=finish_date,start_date if ((start_date <=> finish_date))==1
      # calculate to end of day
      #
      if (start_date.jd==finish_date.jd) # same day
        duration, start_date=self.values[start_date.wday].diff(start_date,finish_date)
      elsif (finish_date.jd<=self.finish.jd) #within this week
        duration, start_date=diff_detail(start_date,finish_date,finish_date)
      else # after this week
        duration, start_date=diff_detail(start_date,finish_date,self.finish)
      end
      return duration, start_date
    end
   

    private

    def xday_indexes
      self.start.wday > self.finish.wday ? self.start.wday.upto(6).to_a.concat(0.upto(self.finish.wday).to_a) : self.start.wday.upto(self.finish.wday).to_a
    end

    

    # Recalculates all the attributes for a Week object
    #
    def xset_attributes

    end
    
    
    # Adds a duration in minutes to a date.
    #
    # The Boolean returned is always false.
    #
    # @param [DateTime] start original date
    # @param [Integer] duration minutes to add
    # @return [DateTime, Integer, Boolean] the calculated date, remaining minutes and flag used for subtraction
    #
    def xadd(start,duration)
      # aim to calculate to the end of the day
      start,duration = self.values[start.wday].calc(start,duration)   
      return start,duration,false if (duration==0) || (start.jd > self.finish.jd) 
      # aim to calculate to the end of the next week day that is the same as @finish
      while((duration!=0) && (start.wday!=self.finish.next_day.wday) && (start.jd <= self.finish.jd))
        if (duration>self.values[start.wday].total)
          duration = duration - self.values[start.wday].total
          start=start.next_day
        elsif (duration==self.values[start.wday].total)
          start=after_last_work(start)
          duration = 0
        else
          start,duration = self.values[start.wday].calc(start,duration)
        end
      end
      
      return start,duration,false if (duration==0) || (start.jd > self.finish.jd) 
      
      # while duration accomodates full weeks
      while ((duration!=0) && (duration>=self.week_total) && ((start.jd+6) <= self.finish.jd))
        duration=duration - self.week_total
        start=start+7
      end

      return start,duration,false if (duration==0) || (start.jd > self.finish.jd) 

      # while duration accomodates full days
      while ((duration!=0) && (start.jd<= self.finish.jd))
        if (duration>self.values[start.wday].total)
          duration = duration - self.values[start.wday].total
          start=start.next_day
        else
          start,duration = self.values[start.wday].calc(start,duration)
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
    def xsubtract(start,duration,midnight=false)
      
      # Handle subtraction from start of day
      if midnight
        start,duration=minute_b4_midnight(start,duration)
        midnight=false
      end

      # aim to calculate to the start of the day
      start,duration, midnight = self.values[start.wday].calc(start,duration)

      if midnight && (start.jd >= self.start.jd)
        start,duration=minute_b4_midnight(start,duration)
        return subtract(start,duration, false)
      elsif midnight
        return start,duration,midnight
      elsif  (duration==0) || (start.jd ==self.start.jd) 
        return start,duration, midnight
      end  

      # aim to calculate to the start of the previous week day that is the same as @start
      while((duration!=0) && (start.wday!=self.start.wday) && (start.jd >= self.start.jd))

        if (duration.abs>=self.values[start.wday].total)
          duration = duration + self.values[start.wday].total
          start=start.prev_day
        else
          start,duration=minute_b4_midnight(start,duration)             
          start,duration = self.values[start.wday].calc(start,duration)
        end
      end

      return start,duration if (duration==0) || (start.jd ==self.start.jd) 

      #while duration accomodates full weeks
      while ((duration!=0) && (duration.abs>=self.week_total) && ((start.jd-6) >= self.start.jd))
        duration=duration + self.week_total
        start=start-7
      end

      return start,duration if (duration==0) || (start.jd ==self.start.jd) 

      #while duration accomodates full days
      while ((duration!=0) && (start.jd>= self.start.jd))    
        if (duration.abs>=self.values[start.wday].total)
          duration = duration + self.values[start.wday].total
          start=start.prev_day
        else
          start,duration=minute_b4_midnight(start,duration)       
          start,duration = self.values[start.wday].calc(start,duration)
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
    def xminute_b4_midnight(start,duration)
      start -= start.hour * HOUR
      start -= start.min * MINUTE
      duration += self.values[start.wday].minutes(23,59,23,59)
      start = start.next_day - MINUTE
      return start,duration
    end  
    
    # Calculates the date and time after the last working minute of the current date
    #
    # @param [DateTime] start is the current date
    # @return [DateTime] the new date
    #
    def xafter_last_work(start_date)
      if self.values[start_date.wday].last_hour.nil?
        return start_date.next_day
      else  
        start_date = start_date + HOUR * (self.values[start_date.wday].last_hour - start_date.hour)
        start_date = start_date + MINUTE * (self.values[start_date.wday].last_min - start_date.min + 1)
        return start_date
      end  
    end
    
    # Calculates the difference between two dates that exist in this Week object.
    #
    # @param [DateTime] start first date 
    # @param [DateTime] finish last date
    # @param [DateTime] finish_on the range to be used in this Week object.  
    # @return [DateTime, Integer] new date for rest of calculation and total number of minutes calculated thus far.
    #
    def xdiff_detail(start_date,finish_date,finish_on_date)
      
      duration, start_date=diff_in_day(start_date, finish_date)
      return duration,start_date if start_date > finish_on_date
      
      #rest of week to finish day
      while (start_date.wday<finish_date.wday) do
        duration+=day_total(start_date)
        start_date=start_date.next_day
      end

      #weeks
      while (start_date.jd+7<finish_on_date.jd) do
        duration+=self.week_total
        start_date+=7
      end

      #days
      while (start_date.jd < finish_on_date.jd) do
        duration+=day_total(start_date)
        start_date=start_date.next_day
      end

      #day      
      day_duration, start_date=diff_in_day(start_date, finish_date)
      duration+=day_duration
      return duration, start_date
    end
    
    def xdiff_in_day(start_date,finish_date)
      return self.values[start_date.wday].diff(start_date,finish_date)
    end

    def xday_total(start_date)
      return self.values[start_date.wday].total
    end

  end
end
