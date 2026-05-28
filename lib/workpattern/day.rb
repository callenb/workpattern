module Workpattern
  # Day - represents a Day, the core of which is a binary number representing
  # all the minutes in a day where a 1 is a working minute and a 0 is a
  # non-working minute.
  #
  # The class maintains other values to help with calculations and performance
  # such as the `first_working_minute` and `last_working_minute'.
  #
  # @private
  class Day
    attr_accessor :hours_per_day, :first_working_minute, :last_working_minute
    attr_reader :pattern

    def pattern=(value)
      @pattern = value
      set_first_and_last_minutes
    end

    def to_h
      { pattern: @pattern.to_s(16), hours_per_day: @hours_per_day }
    end

    def self.from_h(hday)
      unless hday[:hours_per_day].is_a?(Integer) && hday[:hours_per_day].positive? && hday[:hours_per_day] <= HOURS_IN_DAY
        raise ArgumentError, "from_h: hours_per_day must be an Integer between 1 and #{HOURS_IN_DAY}"
      end
      raise ArgumentError, 'from_h: pattern must be a hex String of at most 400 characters' unless hday[:pattern].is_a?(String) && hday[:pattern].length <= 400

      day = allocate
      day.hours_per_day = hday[:hours_per_day]
      day.pattern = hday[:pattern].to_i(16)
      day
    end

    def initialize(hours_per_day = HOURS_IN_DAY, type = WORK_TYPE)
      @hours_per_day = hours_per_day
      @pattern = initial_day(type)
      set_first_and_last_minutes
    end

    def set_resting(start_time, finish_time)
      mask = resting_mask(start_time, finish_time)
      @pattern &= mask
      set_first_and_last_minutes
    end

    def set_working(from_time, to_time)
      @pattern |= working_mask(from_time, to_time)
      set_first_and_last_minutes
    end

    def working_minutes(from_time = FIRST_TIME_IN_DAY, to_time = LAST_TIME_IN_DAY)
      section = @pattern & working_mask(from_time, to_time)
      section.to_s(2).count('1')
    end

    def working?(hour, minute)
      mask = (2**((hour * 60) + minute))
      result = mask & @pattern
      mask == result
    end

    def resting?(hour, minute)
      !working?(hour, minute)
    end

    def calc(a_date, a_duration)
      return a_date, a_duration, SAME_DAY if a_duration.zero?

      a_duration.positive? ? add(a_date, a_duration) : subtract(a_date, a_duration)
    end

    private

    def add(a_date, a_duration)
      minutes_left = working_minutes(a_date)
      if a_duration > minutes_left
        [a_date, a_duration - minutes_left, NEXT_DAY]
      elsif a_duration < minutes_left
        add_minutes(a_date, a_duration)
      else
        return [a_date, 0, NEXT_DAY] if working?(LAST_TIME_IN_DAY.hour, LAST_TIME_IN_DAY.min)

        return_date = Time.gm(a_date.year, a_date.month, a_date.day, @last_working_minute.hour, @last_working_minute.min) + 60
        [return_date, 0, SAME_DAY]

      end
    end

    def add_minutes(a_date, a_duration)
      elapsed_date = a_date + (a_duration * 60) - 60

      return [elapsed_date += 60, 0, SAME_DAY] if working_minutes(a_date, elapsed_date) == a_duration

      loop do
        elapsed_date += 60
        break unless working_minutes(a_date, elapsed_date) != a_duration
      end
      [elapsed_date + 60, 0, SAME_DAY]
    end

    def subtract(a_date, a_duration)
      minutes_left = working_minutes(FIRST_TIME_IN_DAY, a_date - 60)
      abs_duration = a_duration.abs
      if abs_duration > minutes_left
        [a_date, a_duration + minutes_left, PREVIOUS_DAY]
      elsif abs_duration < minutes_left
        subtract_minutes(a_date, abs_duration)
      else
        [Time.gm(a_date.year, a_date.month, a_date.day, @first_working_minute.hour, @first_working_minute.min), 0, SAME_DAY]
      end
    end

    def subtract_minutes(a_date, abs_duration)
      elapsed_date = a_date - (abs_duration * 60)
      return [elapsed_date, 0, SAME_DAY] if working_minutes(elapsed_date, a_date - 60) == abs_duration

      a_date -= 60
      loop do
        elapsed_date -= 60
        break unless working_minutes(elapsed_date, a_date) != abs_duration
      end
      [elapsed_date, 0, SAME_DAY]
    end

    def working_day
      (2**((60 * @hours_per_day) + 1)) - 1
    end

    def initial_day(type = WORK_TYPE)
      pattern = 2**((60 * @hours_per_day) + 1)

      pattern -= 1 if type == WORK_TYPE

      pattern
    end

    def working_mask(start_time, finish_time)
      start = minutes_in_time(start_time)
      finish = minutes_in_time(finish_time)

      mask = initial_day

      mask -= ((2**start) - 1)
      mask & ((2**(finish + 1)) - 1)
    end

    def resting_mask(start_time, finish_time)
      start = minutes_in_time(start_time)
      finish_clock = Clock.new(finish_time.hour, finish_time.min + 1)

      mask = initial_day(REST_TYPE)
      mask |= working_mask(finish_clock, LAST_TIME_IN_DAY) if minutes_in_time(finish_time) != LAST_TIME_IN_DAY.minutes
      mask | ((2**start) - 1)
    end

    def minutes_in_time(a_time)
      (a_time.hour * 60) + a_time.min
    end

    def last_minute
      return LAST_TIME_IN_DAY if working?(LAST_TIME_IN_DAY.hour, LAST_TIME_IN_DAY.min)

      top = minutes_in_time(LAST_TIME_IN_DAY)
      bottom = minutes_in_time(FIRST_TIME_IN_DAY)
      mark = top / 2

      not_done = true
      while not_done

        minutes = working_minutes(minutes_to_time(mark), minutes_to_time(top))

        if (minutes > 1) || (minutes == 1 && at_rest?(mark))
          bottom = mark
          mark += ((top - bottom) / 2)

        elsif minutes.zero?
          top = mark
          mark -= ((top - bottom) / 2)

        else
          not_done = false

        end

        mark += 1 if mark == bottom # & last_mark != mark

        mark = 0 if mark == 1 && top == 1

      end
      minutes_to_time(mark)
    end

    def first_minute
      return FIRST_TIME_IN_DAY if working?(FIRST_TIME_IN_DAY.hour, FIRST_TIME_IN_DAY.min)

      top = minutes_in_time(LAST_TIME_IN_DAY)
      bottom = minutes_in_time(FIRST_TIME_IN_DAY)
      mark = top / 2

      not_done = true
      while not_done

        minutes = working_minutes(minutes_to_time(bottom), minutes_to_time(mark))
        if (minutes > 1) || (minutes == 1 && at_rest?(mark))
          top = mark
          mark -= ((top - bottom) / 2)
        elsif minutes.zero?
          bottom = mark
          mark += ((top - bottom) / 2)
        else
          not_done = false
        end

        mark = 0 if mark == 1 && top == 1
      end

      minutes_to_time(mark)
    end

    def minutes_to_time(minutes)
      Time.gm(1963, 6, 10, minutes / 60, minutes - (minutes / 60 * 60))
    end

    def at_rest?(minutes)
      a_time = minutes_to_time(minutes)
      resting?(a_time.hour, a_time.min)
    end

    def set_first_and_last_minutes
      if working_minutes.zero?
        @first_working_minute = nil
        @last_working_minute = nil
      else
        @first_working_minute = first_minute
        @last_working_minute = last_minute
      end
    end
  end
end
