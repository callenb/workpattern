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

    def initialize(start, finish, type = WORK_TYPE, hours_per_day = HOURS_IN_DAY)
      @hours_per_day = hours_per_day
      @start = Time.gm(start.year, start.month, start.day)
      @finish = Time.gm(finish.year, finish.month, finish.day)
      @days = Array.new(LAST_DAY_OF_WEEK + 1)
      FIRST_DAY_OF_WEEK.upto(LAST_DAY_OF_WEEK) do |i|
        @days[i] = Day.new(hours_per_day, type)
      end
    end

    def to_h
      { start: { year: @start.year, month: @start.month, day: @start.day },
        finish: { year: @finish.year, month: @finish.month, day: @finish.day },
        days: (FIRST_DAY_OF_WEEK..LAST_DAY_OF_WEEK).map { |i| @days[i].to_h } }
    end

    def self.from_h(hweek)
      s = hweek[:start]
      f = hweek[:finish]
      week = allocate
      week.hours_per_day = HOURS_IN_DAY
      week.start  = Time.gm(s[:year], s[:month], s[:day])
      week.finish = Time.gm(f[:year], f[:month], f[:day])
      week.days   = Array.new(LAST_DAY_OF_WEEK + 1)
      hweek[:days].each_with_index { |dh, i| week.days[i] = Day.from_h(dh) }
      week
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
        duplicate_week.days[i] = @days[i].dup
        duplicate_week.days[i].hours_per_day = @days[i].hours_per_day
        duplicate_week.days[i].pattern = @days[i].pattern
      end
      duplicate_week
    end

    def calc(from_date, minutes, a_day = SAME_DAY)
      if minutes.zero?
        [from_date, minutes]
      elsif minutes.positive?
        add(from_date, minutes)
      else
        subtract(from_date, minutes, a_day)
      end
    end

    def working?(time)
      @days[time.wday].working?(time.hour, time.min)
    end

    def resting?(time)
      @days[time.wday].resting?(time.hour, time.min)
    end

    def diff(start_date, finish_date)
      start_date, finish_date = finish_date, start_date if start_date > finish_date

      return diff_in_same_day(start_date, finish_date) if jd(start_date) == jd(finish_date)

      diff_in_same_weekpattern(start_date, finish_date)
    end

    private

    def elapsed_days
      ((finish - start).to_i / DAY) + 1
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
      @days[first..last].sum { |day| 1 * day.working_minutes }

    end

    def add(from_date, minutes)
      r_date, r_duration = add_to_end_of_day(from_date, minutes)

      r_date, r_duration = add_to_finish_day r_date, r_duration
      r_date, r_duration = add_full_weeks r_date, r_duration
      r_date, r_duration = add_remaining_days r_date, r_duration
      [r_date, r_duration, false]
    end

    def add_to_end_of_day(from_date, minutes)
      r_date, r_duration, r_day = @days[from_date.wday].calc(from_date, minutes)

      r_date = start_of_next_day(r_date) if r_day == NEXT_DAY

      [r_date, r_duration]
    end

    def add_to_finish_day(from_date, minutes)
      from_date, minutes = add_to_end_of_day(from_date, minutes) while (minutes != 0) && (from_date.wday != next_day(finish).wday) && (jd(from_date) <= jd(finish))

      [from_date, minutes]
    end

    def add_full_weeks(from_date, minutes)
      while (minutes != 0) && (minutes >= week_total) && ((jd(from_date) + (6 * 86400)) <= jd(finish))
        minutes -= week_total
        from_date += (7 * 86400)
      end

      [from_date, minutes]
    end

    def add_remaining_days(from_date, minutes)
      from_date, minutes = add_to_end_of_day(from_date, minutes) while (minutes != 0) && (jd(from_date) <= jd(finish))
      [from_date, minutes]
    end

    def start_of_next_day(date)
      next_day(date) - (HOUR * date.hour) - (MINUTE * date.min)
    end

    def subtract_to_start_of_day(from_date, minutes, a_day)
      from_date, minutes, = handle_midnight(from_date, minutes, a_day)

      r_date, r_duration, r_day = @days[from_date.wday].calc(from_date, minutes)

      [r_date, r_duration, r_day]
    end

    def handle_midnight(midnight_date, minutes, a_day)
      if a_day == PREVIOUS_DAY
        midnight_date -= DAY
        midnight_date = Time.gm(midnight_date.year, midnight_date.month, midnight_date.day, LAST_TIME_IN_DAY.hour, LAST_TIME_IN_DAY.min)

        minutes += 1 if @days[midnight_date.wday].working?(midnight_date.hour, midnight_date.min)
      end

      [midnight_date, minutes, SAME_DAY]
    end

    def subtract(from_date, minutes, a_day)
      from_date, minutes, a_day = handle_midnight(from_date, minutes, a_day)
      from_date, minutes, a_day = subtract_to_start_of_day(from_date, minutes, a_day)

      while (minutes != 0) && (from_date.wday != start.wday) && (jd(from_date) > jd(start))
        from_date, minutes, a_day = handle_midnight(from_date, minutes, a_day)
        from_date, minutes, a_day = subtract_to_start_of_day(from_date, minutes, a_day)
      end

      while (minutes != 0) && (minutes >= week_total) && ((jd(from_date) - (6 * DAY)) >= jd(start))
        minutes += week_total
        from_date -= 7
      end

      from_date, minutes, a_day = subtract_to_start_of_day(from_date, minutes, a_day) while (minutes != 0) && (jd(from_date) > jd(start))

      [from_date, minutes, a_day]
    end

    def diff_in_same_weekpattern(start_date, finish_date)
      minutes = @days[start_date.wday].working_minutes(start_date, LAST_TIME_IN_DAY)
      run_date = start_of_next_day(start_date)
      while (run_date.wday != start.wday) && (jd(run_date) < jd(finish)) && (jd(run_date) != jd(finish_date))
        minutes += @days[run_date.wday].working_minutes
        run_date += DAY
      end

      while ((jd(run_date) + (7 * DAY)) < jd(finish_date)) && ((jd(run_date) + (7 * DAY)) < jd(finish))
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
        elsif jd(run_date) <= jd(finish)
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

    def jd(time)
      Time.gm(time.year, time.month, time.day)
    end
  end
end
