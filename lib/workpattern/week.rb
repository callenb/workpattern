module Workpattern
  # The representation of a week might not be obvious so I am writing about it
  # here.  It will also help me if I ever need to come back to this in the
  # future.
  #
  # Each day is represented by a binary number where a 1 represents a working
  # minute and a 0 represents a resting minute.
  #
  # @private
  class Week
    attr_accessor :hours_per_day, :start, :finish, :days
    attr_writer :week_total, :total

    def initialize(start, finish, type = WORK_TYPE, hours_per_day = HOURS_IN_DAY)
      @hours_per_day = hours_per_day
      @start = Time.gm(start.year, start.month, start.day)
      @finish = Time.gm(finish.year, finish.month, finish.day)
      @days = Array.new(LAST_DAY_OF_WEEK)
      FIRST_DAY_OF_WEEK.upto(LAST_DAY_OF_WEEK) do |i|
        @days[i] = Day.new(hours_per_day, type)
      end
    end

    def <=>(other)
      return -1 if start < other.start
      return 0 if start == other.start
      1
    end

    def week_total
      elapsed_days > 6 ? full_week_working_minutes : part_week_total_minutes
    end

    def total
      elapsed_days < 8 ? week_total : range_total
    end

    def workpattern(days, from_time, to_time, type)
      DAYNAMES[days].each do |day|
        if type == WORK_TYPE
          @days[day].set_working(from_time, to_time)
        else
          @days[day].set_resting(from_time, to_time)
        end
      end
    end

    def duplicate
      duplicate_week = Week.new(@start, @finish)
      FIRST_DAY_OF_WEEK.upto(LAST_DAY_OF_WEEK) do |i|
        duplicate_week.days[i] = @days[i].clone
	      duplicate_week.days[i].hours_per_day = @days[i].hours_per_day
	      duplicate_week.days[i].pattern = @days[i].pattern
      end
      duplicate_week
    end

    def calc(a_date, a_duration, a_day = SAME_DAY) 
      if a_duration == 0
        return a_date, a_duration
      elsif a_duration > 0	
        return add(a_date, a_duration)
      else	
        subtract(a_date, a_duration, a_day)
      end	
    end

    def working?(time)
      @days[time.wday].working?(time.hour, time.min)
    end

    def resting?(time)
      @days[time.wday].resting?(time.hour, time.min)
    end

    def diff(start_date, finish_date)
      if start_date > finish_date
        start_date, finish_date = finish_date, start_date
      end

      if jd(start_date) == jd(finish_date)
        return diff_in_same_day(start_date, finish_date)
      else
        return diff_in_same_weekpattern(start_date, finish_date)
      end
    end
    
    private

    def elapsed_days
      (finish - start).to_i / DAY + 1
    end

    def full_week_working_minutes
      minutes_in_day_range FIRST_DAY_OF_WEEK, LAST_DAY_OF_WEEK
    end

    def part_week_total_minutes
      start.wday <= finish.wday ? no_rollover_minutes : rollover_minutes
    end

    def no_rollover_minutes
      minutes_in_day_range(start.wday, finish.wday)
    end

    def rollover_minutes
      minutes_to_first_saturday + minutes_to_finish_day
    end

    def range_total
      total_days = elapsed_days

      sum = minutes_to_first_saturday
      total_days -= (7 - start.wday)

      sum += minutes_to_finish_day
      total_days -= (finish.wday + 1)

      sum += week_total * total_days / 7
      sum
    end

    def minutes_to_first_saturday
      minutes_in_day_range(start.wday, LAST_DAY_OF_WEEK)
    end

    def minutes_to_finish_day
      minutes_in_day_range(FIRST_DAY_OF_WEEK, finish.wday)
    end

    def minutes_in_day_range(first, last)
      @days[first..last].inject(0) { |sum, day| sum + day.working_minutes }
    end

    def add(a_date, a_duration)

      r_date, r_duration = add_to_end_of_day(a_date, a_duration)

      r_date, r_duration = add_to_finish_day r_date, r_duration
      r_date, r_duration = add_full_weeks r_date, r_duration
      r_date, r_duration = add_remaining_days r_date, r_duration
      [r_date, r_duration, false]
    end

    def add_to_end_of_day(a_date, a_duration)
      r_date, r_duration, r_day = @days[a_date.wday].calc(a_date,a_duration)

      if r_day == NEXT_DAY
        r_date = start_of_next_day(r_date)

      end

      [r_date, r_duration]
    end

    def add_to_finish_day(a_date, a_duration)
      while ( a_duration != 0) && (a_date.wday != next_day(self.finish).wday) && (jd(a_date) <= jd(self.finish))
        a_date, a_duration = add_to_end_of_day(a_date,a_duration)
      end

      [a_date, a_duration]
    end

    def add_full_weeks(a_date, a_duration)

      while (a_duration != 0) && (a_duration >= self.week_total) && ((jd(a_date) + (6*86400)) <= jd(self.finish))
        a_duration -= self.week_total
        a_date += (7*86400)
      end

      [a_date, a_duration]
    end

    def add_remaining_days(a_date, a_duration)
      while (a_duration != 0) && (jd(a_date) <= jd(self.finish))
        a_date, a_duration = add_to_end_of_day(a_date,a_duration)
      end
      [a_date, a_duration]
    end

    def start_of_next_day(date)
      next_day(date) - (HOUR * date.hour) - (MINUTE * date.min)
    end

    def subtract_to_start_of_day(a_date, a_duration, a_day)
      
      
      a_date, a_duration, a_day = handle_midnight(a_date, a_duration, a_day)

      r_date, r_duration, r_day = @days[a_date.wday].calc(a_date, a_duration)

      [r_date, r_duration, r_day]

    end

    def handle_midnight(a_date, a_duration, a_day)
      
      if a_day == PREVIOUS_DAY
        a_date -= DAY
        a_date = Time.gm(a_date.year, a_date.month, a_date.day,LAST_TIME_IN_DAY.hour, LAST_TIME_IN_DAY.min)

        if @days[a_date.wday].working?(a_date.hour, a_date.min)
          a_duration += 1
        end	
      end

      [a_date, a_duration, SAME_DAY]
    end

    def subtract(a_date, a_duration, a_day)
      a_date, a_duration, a_day = handle_midnight(a_date, a_duration, a_day)
      a_date, a_duration, a_day = subtract_to_start_of_day(a_date, a_duration, a_day)
      
      while (a_duration != 0) && (a_date.wday != start.wday) && (jd(a_date) > jd(start))  
        a_date, a_duration, a_day = handle_midnight(a_date, a_duration, a_day)
        a_date, a_duration, a_day = subtract_to_start_of_day(a_date, a_duration, a_day)
      end

      while (a_duration != 0) && (a_duration >= week_total) && ((jd(a_date) - (6 * DAY)) >= jd(start))
        a_duration += week_total
        a_date -= 7
      end

      while (a_duration != 0) && (jd(a_date) > jd(start))
        a_date, a_duration, a_day = subtract_to_start_of_day(a_date,a_duration,a_day)
      end

      [a_date, a_duration, a_day]
    end

    def diff_in_same_weekpattern(start_date, finish_date)
      minutes = @days[start_date.wday].working_minutes(start_date, LAST_TIME_IN_DAY)
      run_date = start_of_next_day(start_date)
      while (run_date.wday != start.wday) && (jd(run_date) < jd(finish)) && (jd(run_date) != jd(finish_date))      
        minutes += @days[run_date.wday].working_minutes
	      run_date += DAY
      end

      while ((jd(run_date) + (7 * DAY)) < jd(finish_date))  && ((jd(run_date) + (7 * DAY)) < jd(finish))
        minutes += week_total
	      run_date += (7 * DAY)
      end

      while (jd(run_date) < jd(finish_date)) && (jd(run_date) <= jd(finish))
        minutes += @days[run_date.wday].working_minutes
	      run_date += DAY
      end

      if run_date != finish_date
        
        if (jd(run_date) == jd(finish_date)) && (jd(run_date) <= jd(finish))
          minutes += @days[run_date.wday].working_minutes(run_date, finish_date - MINUTE)
	        run_date = finish_date
        elsif (jd(run_date) <= jd(finish)) 
          minutes += @days[run_date.wday].working_minutes
	        run_date += DAY
        end
      end

      [minutes, run_date]

    end

    def diff_in_same_day(start_date, finish_date)
      minutes = @days[start_date.wday].working_minutes(start_date, finish_date - MINUTE)
      [minutes, finish_date]
    end

    def next_day(time)
      time + DAY
    end

    def prev_day(time)
      time - DAY
    end

    def jd(time)
      Time.gm(time.year, time.month, time.day)
    end
  end
end
