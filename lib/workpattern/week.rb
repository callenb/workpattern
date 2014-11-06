module Workpattern

# The representation of a week might not be obvious so I am writing about it here.  It
# will also help me if I ever need to come back to this in the future.
#
# Each day is represented by a binary number where a 1 represents a working minute and 
# a 0 represents a resting minute.
#
  class Week
    
    attr_accessor :values, :hours_per_day, :start, :finish, :week_total, :total

    def initialize(start,finish,type=1,hours_per_day=24)
      @hours_per_day = hours_per_day
      @start=DateTime.new(start.year,start.month,start.day)
      @finish=DateTime.new(finish.year,finish.month,finish.day)
      @values = Array.new(6)
      0.upto(6) do |i| 
        @values[i] = working_day * type
      end
    end

    def <=>(other_week)
      return -1 if self.start < other_week.start
      return 0 if self.start == other_week.start
      1      
    end
 
    def week_total
      elapsed_days > 6 ? full_week_total_minutes : part_week_total_minutes
    end 

    def total
      elapsed_days < 8 ? week_total : range_total
    end

    def workpattern(days,from_time,to_time,type)
      DAYNAMES[days].each do |day| 
        type==1 ? work_on_day(day,from_time,to_time) : rest_on_day(day,from_time,to_time)
      end
    end

    def duplicate()
      duplicate_week=Week.new(self.start,self.finish)
      0.upto(6).each do |i| duplicate_week.values[i] = @values[i] end
      return duplicate_week
    end

    def calc(start_date,duration, midnight=false)
      return start_date,duration,false if duration==0
      return add(start_date,duration) if duration > 0
      return subtract(self.start,duration, midnight) if (self.total==0) && (duration <0)
      return subtract(start_date,duration, midnight) if duration <0  
    end

    def working?(datetime)
      return true if bit_pos(datetime.hour, datetime.min) & @values[datetime.wday] > 0
      false
    end

    def resting?(date)
      !working?(date)
    end

    def diff(start_date,finish_date)
      start_date,finish_date=finish_date,start_date if ((start_date <=> finish_date))==1
      
      if (start_date.jd==finish_date.jd) 
        duration, start_date=diff_in_same_day(start_date, finish_date)
      elsif (finish_date.jd<=self.finish.jd)
        duration, start_date=diff_in_same_weekpattern(start_date,finish_date)
      else 
        duration, start_date=diff_beyond_weekpattern(start_date,finish_date)
      end
      return duration, start_date

    end

  private

    def working_minutes_in(value)
      value.to_s(2).count('1')
    end

    def elapsed_days
      (self.finish-self.start).to_i + 1
    end

    def full_week_total_minutes
      minutes_in_day_range 0, 6
    end
    
    def part_week_total_minutes
      self.start.wday <= self.finish.wday ? no_rollover_minutes : rollover_minutes
    end

    def no_rollover_minutes
      minutes_in_day_range(self.start.wday, self.finish.wday)
    end

    def rollover_minutes
      minutes_to_first_saturday + minutes_to_finish_day
    end

    def range_total
      total_days = elapsed_days

      sum = minutes_to_first_saturday
      total_days -= (7 - self.start.wday)

      sum += minutes_to_finish_day
      total_days-=(self.finish.wday + 1)

      sum += week_total * total_days / 7
      sum
    end
    
    def minutes_to_first_saturday
      minutes_in_day_range(self.start.wday, 6)
    end

    def minutes_to_finish_day
      minutes_in_day_range(0, self.finish.wday)
    end

    def minutes_in_day_range(first,last)
      @values[first..last].inject(0) {|sum,item| sum + item.to_s(2).count('1')}
    end

    def add(initial_date,duration)

      initial_date, duration = add_to_end_of_day(initial_date,duration)

      while ( duration != 0) && (initial_date.wday != self.finish.next_day.wday) && (initial_date.jd <= self.finish.jd)
        initial_date, duration = add_to_end_of_day(initial_date,duration)
      end

      while (duration != 0) && (duration >= self.week_total) && ((initial_date.jd + 6) <= self.finish.jd)
        duration -= self.week_total
        initial_date += 7
      end

      while (duration != 0) && (initial_date.jd <= self.finish.jd)
        initial_date, duration = add_to_end_of_day(initial_date,duration)
      end
      return initial_date, duration, false
      
    end

    def add_to_end_of_day(initial_date, duration) 
      available_minutes_in_day = minutes_to_end_of_day(initial_date)

      if available_minutes_in_day < duration
        duration -= available_minutes_in_day
        initial_date = start_of_next_day(initial_date)
      elsif available_minutes_in_day == duration
        duration -= available_minutes_in_day
        initial_date = end_of_this_day(initial_date)
      else
        initial_date = consume_minutes(initial_date,duration)
        duration=0
      end
      return initial_date, duration
    end

    def work_on_day(day,from_time,to_time)
      self.values[day] = self.values[day] | time_mask(from_time, to_time)  
    end

    def rest_on_day(day,from_time,to_time) 
      mask_of_1s = time_mask(from_time, to_time)
      mask = mask_of_1s ^ working_day & working_day
      self.values[day] = self.values[day] & mask
    end

    def time_mask(from_time, to_time)
      bit_pos(to_time.hour, to_time.min + 1) - bit_pos(from_time.hour, from_time.min)
    end

    def bit_pos(hour,minute)
      2**( (hour * 60) + minute )
    end

    def minutes_to_end_of_day(date) 
      working_minutes_in pattern_to_end_of_day(date)
    end

    def pattern_to_end_of_day(date) 
      mask = mask_to_end_of_day(date)
      (self.values[date.wday] & mask)
    end

    def mask_to_end_of_day(date) 
      bit_pos(self.hours_per_day,0) - bit_pos(date.hour, date.min)
    end

    def working_day
      2**(60*self.hours_per_day)-1
    end

    def start_of_next_day(date)
      date.next_day - (HOUR * date.hour) - (MINUTE * date.minute)
    end

    def start_of_previous_day(date)
      start_of_next_day(date).prev_day.prev_day
    end

    def start_of_today(date)
      start_of_next_day(date.prev_day)
    end

    def end_of_this_day(date) 
      position = pattern_to_end_of_day(date).to_s(2).size
      return adjust_date(date,position)
    end

    def adjust_date(date,adjustment)
      date - (HOUR * date.hour) - (MINUTE * date.min) + (MINUTE * adjustment)
    end

    def diff_minutes_to_end_of_day(start_date) 
      mask = ((2**(60*self.hours_per_day + 1)) - (2**(start_date.hour*60 + start_date.min))).to_i
      working_minutes_in (self.values[start.wday] & mask)
    end

    def mask_to_start_of_day(date)
      bit_pos(date.hour, date.min) - bit_pos(0,0)
    end
    
    def pattern_to_start_of_day(date)
      mask = mask_to_start_of_day(date)
      (self.values[date.wday] & mask)
    end

    def minutes_to_start_of_day(date)
      working_minutes_in pattern_to_start_of_day(date)
    end

    def consume_minutes(date,duration) 

      minutes=pattern_to_end_of_day(date).to_s(2).reverse! if duration > 0
      minutes=pattern_to_start_of_day(date).to_s(2) if duration < 0

      top=minutes.size
      bottom=1
      mark = top / 2

      while minutes[0,mark].count('1') != duration.abs
        last_mark = mark
        if minutes[0,mark].count('1') < duration.abs

          bottom = mark
          mark = (top-mark) / 2 + mark
          mark = top if last_mark == mark

        else

          top = mark
          mark = (mark-bottom) / 2 + bottom
          mark = bottom if last_mark = mark

        end  
      end

      mark = minutes_addition_adjustment(minutes, mark) if duration > 0
      mark = minutes_subtraction_adjustment(minutes,mark) if duration < 0      

      return adjust_date(date, mark) if duration > 0
      return start_of_today(date) + (MINUTE * mark) if duration < 0

    end
    
    def minutes_subtraction_adjustment(minutes,mark)
       i = mark - 1
       
       while minutes[i]=='0'
         i-=1
       end
      
      minutes.size - (i + 1)
    end

    def minutes_addition_adjustment(minutes,mark)
      minutes=minutes[0,mark]

      while minutes[minutes.size-1]=='0'
        minutes.chop!
      end

      minutes.size
    end

    def subtract_to_start_of_day(initial_date, duration, midnight)

      initial_date,duration, midnight = handle_midnight(initial_date, duration) if midnight
      available_minutes_in_day = minutes_to_start_of_day(initial_date)

      if duration != 0
        if available_minutes_in_day < duration.abs
          duration += available_minutes_in_day
          initial_date = start_of_previous_day(initial_date)
          midnight = true
        else
          initial_date = consume_minutes(initial_date,duration)
          duration = 0
          midnight = false
        end
      end
      return initial_date, duration, midnight
    end


    def handle_midnight(initial_date,duration)
      if working?(start_of_next_day(initial_date) - MINUTE)
        duration += 1
      end
      
      initial_date -= (HOUR * initial_date.hour)
      initial_date -= (MINUTE * initial_date.min)
      initial_date = initial_date.next_day - MINUTE

      return initial_date, duration, false  
    end


    def subtract(initial_date, duration, midnight)
      initial_date,duration, midnight = handle_midnight(initial_date, duration) if midnight

      initial_date, duration, midnight = subtract_to_start_of_day(initial_date, duration, midnight)

      while ( duration != 0) && (initial_date.wday != self.start.prev_day.wday) && (initial_date.jd >= self.start.jd)
        initial_date, duration, midnight = subtract_to_start_of_day(initial_date,duration, midnight)
      end

      while (duration != 0) && (duration >= self.week_total) && ((initial_date.jd - 6) >= self.start.jd)
        duration += self.week_total
        initial_date -= 7
      end

      while (duration != 0) && (initial_date.jd >= self.start.jd)
        initial_date, duration, midnight = subtract_to_start_of_day(initial_date,duration, midnight)
      end

      return initial_date, duration, midnight

    end

    def diff_in_same_weekpattern(start_date, finish_date)
      duration, start_date = diff_to_tomorrow(start_date)
      while true
        break if (start_date.wday == (self.finish.wday + 1))
        break if (start_date.jd == self.finish.jd)
        break if (start_date.jd == finish_date.jd)
        duration += minutes_to_end_of_day(start_date)
        start_date = start_of_next_day(start_date)
      end 

      while true
        break if ((start_date + 7) > finish_date)
        break if ((start_date + 6).jd > self.finish.jd)
        duration += week_total
        start_date += 7
      end

      while true
        break if (start_date.jd >= self.finish.jd)
        break if (start_date.jd >= finish_date.jd)
        duration += minutes_to_end_of_day(start_date)
        start_date = start_of_next_day(start_date)
      end 
      
      interim_duration, start_date = diff_in_same_day(start_date, finish_date) if (start_date < self.finish)
      duration += interim_duration unless interim_duration.nil?
      return duration, start_date      
    end
    
    def diff_beyond_weekpattern(start_date,finish_date)
      duration, start_date = diff_in_same_weekpattern(start_date, finish_date)
      return duration, start_date
    end

    def diff_to_tomorrow(start_date)
      mask = bit_pos(self.hours_per_day, 0) - bit_pos(start_date.hour, start_date.min)
      return working_minutes_in(self.values[start_date.wday] & mask), start_of_next_day(start_date)
    end

    def diff_in_same_day(start_date, finish_date)
       mask = bit_pos(finish_date.hour, finish_date.min) - bit_pos(start_date.hour, start_date.min)
       return working_minutes_in(self.values[start_date.wday] & mask), finish_date
    end

  end
end
