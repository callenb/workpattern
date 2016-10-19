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
    attr_accessor :values, :hours_per_day, :start, :finish, :week_total, :total

    def initialize(start, finish, type = 1, hours_per_day = 24)
      @hours_per_day = hours_per_day
      @start = Time.gm(start.year, start.month, start.day)
      @finish = Time.gm(finish.year, finish.month, finish.day)
      @values = Array.new(6)
      0.upto(6) do |i|
        @values[i] = working_day * type
      end
    end

    def <=>(other)
      return -1 if start < other.start
      return 0 if start == other.start
      1
    end

    def week_total
      elapsed_days > 6 ? full_week_total_minutes : part_week_total_minutes
    end

    def total
      elapsed_days < 8 ? week_total : range_total
    end

    def workpattern(days, from_time, to_time, type)
      DAYNAMES[days].each do |day|
        if type == 1
          work_on_day(day, from_time, to_time)
        else
          rest_on_day(day, from_time, to_time)
        end
      end
    end

    def duplicate
      duplicate_week = Week.new(start, finish)
      0.upto(6).each { |i| duplicate_week.values[i] = @values[i] }
      duplicate_week
    end

    def calc(start_date, duration, midnight = false)
      return start_date, duration, false if duration == 0
      return add(start_date, duration) if duration > 0
      return subtract(start, duration, midnight) if total == 0 && duration < 0
      subtract(start_date, duration, midnight)
    end

    def working?(time)
      return true if bit_pos(time.hour, time.min) & @values[time.wday] > 0
      false
    end

    def resting?(date)
      !working?(date)
    end

    def diff(start_d, finish_d)
      start_d, finish_d = finish_d, start_d if ((start_d <=> finish_d)) == 1

      return diff_in_same_day(start_d, finish_d) if jd(start_d) == jd(finish_d)
      return diff_in_same_weekpattern(start_d, finish_d) if jd(finish_d) <= jd(finish)
      diff_beyond_weekpattern(start_d, finish_d)
    end

    private

    def working_minutes_in(day)
      day.to_s(2).count('1')
    end

    def elapsed_days
      (finish - start).to_i / 86_400 + 1
    end

    def full_week_total_minutes
      minutes_in_day_range 0, 6
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
      minutes_in_day_range(start.wday, 6)
    end

    def minutes_to_finish_day
      minutes_in_day_range(0, finish.wday)
    end

    def minutes_in_day_range(first, last)
      @values[first..last].inject(0) { |a, e| a + working_minutes_in(e) }
    end

    def add(initial_date, duration)
      running_date, duration = add_to_end_of_day(initial_date, duration)

      running_date, duration = add_to_finish_day running_date, duration
      running_date, duration = add_full_weeks running_date, duration
      running_date, duration = add_remaining_days running_date, duration
      [running_date, duration, false]
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
        initial_date = consume_minutes(initial_date, duration)
        duration = 0
      end
      [initial_date, duration]
    end

    def add_to_finish_day(date, duration)
      while (duration != 0) && (date.wday != next_day(finish).wday) && (jd(date) <= jd(finish))
        date, duration = add_to_end_of_day(date, duration)
      end

      [date, duration]
    end

    def add_full_weeks(date, duration)
      while (duration != 0) && (duration >= week_total) && ((jd(date) + (6 * 86_400)) <= jd(finish))
        duration -= week_total
        date += (7 * 86_400)
      end

      [date, duration]
    end

    def add_remaining_days(date, duration)
      while (duration != 0) && (jd(date) <= jd(finish))
        date, duration = add_to_end_of_day(date, duration)
      end
      [date, duration]
    end
    
    def add_to_finish_day(date, duration)
      while ( duration != 0) && (date.wday != next_day(self.finish).wday) && (jd(date) <= jd(self.finish))
        date, duration = add_to_end_of_day(date,duration)
      end

      return date, duration
    end

    def add_full_weeks(date, duration)

      while (duration != 0) && (duration >= self.week_total) && ((jd(date) + (6*86400)) <= jd(self.finish))
        duration -= self.week_total
        date += (7*86400)
      end

      return date, duration
    end

    def add_remaining_days(date, duration)
      while (duration != 0) && (jd(date) <= jd(self.finish))
        date, duration = add_to_end_of_day(date,duration)
      end
      return date, duration
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

    def work_on_day(day, from_time, to_time)
      values[day] = values[day] | time_mask(from_time, to_time)
    end

    def rest_on_day(day, from_time, to_time)
      mask_of_ones = time_mask(from_time, to_time)
      mask = mask_of_ones ^ working_day & working_day
      values[day] = values[day] & mask
    end

    def time_mask(from_time, to_time)
      bit_pos(to_time.hour, to_time.min + 1) - bit_pos(from_time.hour, from_time.min)
    end

    def bit_pos(hour, minute)
      2**((hour * 60) + minute)
    end

    def minutes_to_end_of_day(date)
      working_minutes_in pattern_to_end_of_day(date)
    end

    def pattern_to_end_of_day(date)
      mask = mask_to_end_of_day(date)
      (values[date.wday] & mask)
    end

    def mask_to_end_of_day(date)
      bit_pos(hours_per_day, 0) - bit_pos(date.hour, date.min)
    end

    def working_day
      2**(60 * hours_per_day) - 1
    end

    def start_of_next_day(date)
      next_day(date) - (HOUR * date.hour) - (MINUTE * date.min)
    end

    def start_of_previous_day(date)
      prev_day(prev_day(start_of_next_day(date)))
    end

    def start_of_today(date)
      start_of_next_day(prev_day(date))
    end

    def end_of_this_day(date)
      position = pattern_to_end_of_day(date).to_s(2).size
      adjust_date(date, position)
    end

    def adjust_date(date, adjustment)
      date - (HOUR * date.hour) - (MINUTE * date.min) + (MINUTE * adjustment)
    end

    def mask_to_start_of_day(date)
      bit_pos(date.hour, date.min) - bit_pos(0, 0)
    end

    def pattern_to_start_of_day(date)
      mask = mask_to_start_of_day(date)
      (values[date.wday] & mask)
    end

    def minutes_to_start_of_day(date)
      working_minutes_in pattern_to_start_of_day(date)
    end

    def consume_minutes(date, duration)
      minutes = pattern_to_end_of_day(date).to_s(2).reverse! if duration > 0
      minutes = pattern_to_start_of_day(date).to_s(2) if duration < 0

      top = minutes.size
      bottom = 1
      mark = top / 2

      while minutes[0, mark].count('1') != duration.abs
        last_mark = mark
        if minutes[0, mark].count('1') < duration.abs

          bottom = mark
          mark = (top - mark) / 2 + mark
          mark = top if last_mark == mark

        else

          top = mark
          mark = (mark - bottom) / 2 + bottom
          mark = bottom if last_mark == mark

        end
      end

      mark = minutes_addition_adjustment(minutes, mark) if duration > 0
      mark = minutes_subtraction_adjustment(minutes, mark) if duration < 0

      return adjust_date(date, mark) if duration > 0
      return start_of_today(date) + (MINUTE * mark) if duration < 0
    end

    def minutes_subtraction_adjustment(minutes, mark)
      i = mark - 1

      while minutes[i] == '0'
        i -= 1
      end

      minutes.size - (i + 1)
    end

    def minutes_addition_adjustment(minutes, mark)
      minutes = minutes[0, mark]

      while minutes[minutes.size - 1] == '0'
        minutes.chop!
      end

      minutes.size
    end

    def subtract_to_start_of_day(initial_date, duration, midnight)
      initial_date, duration, midnight = handle_midnight(initial_date, duration) if midnight
      available_minutes_in_day = minutes_to_start_of_day(initial_date)

      if duration != 0
        if available_minutes_in_day < duration.abs
          duration += available_minutes_in_day
          initial_date = start_of_previous_day(initial_date)
          midnight = true
        else
          initial_date = consume_minutes(initial_date, duration)
          duration = 0
          midnight = false
        end
      end
      [initial_date, duration, midnight]
    end

    def handle_midnight(initial_date, duration)
      if working?(start_of_next_day(initial_date) - MINUTE)
        duration += 1
      end

      initial_date -= (HOUR * initial_date.hour)
      initial_date -= (MINUTE * initial_date.min)
      initial_date = next_day(initial_date) - MINUTE

      [initial_date, duration, false]
    end

    def subtract(initial_date, duration, midnight)
      initial_date, duration, midnight = handle_midnight(initial_date, duration) if midnight

      initial_date, duration, midnight = subtract_to_start_of_day(initial_date, duration, midnight)

      while (duration != 0) && (initial_date.wday != prev_day(start.wday)) && (jd(initial_date) >= jd(start))
        initial_date, duration, midnight = subtract_to_start_of_day(initial_date, duration, midnight)
      end

      while (duration != 0) && (duration >= week_total) && ((jd(initial_date) - (6 * 86_400)) >= jd(start))
        duration += week_total
        initial_date -= 7
      end

      while (duration != 0) && (jd(initial_date) >= jd(start))
        initial_date, duration, midnight = subtract_to_start_of_day(initial_date,
                                                                    duration,
                                                                    midnight)
      end

      [initial_date, duration, midnight]
    end

    def diff_in_same_weekpattern(start_date, finish_date)
      duration, start_date = diff_to_tomorrow(start_date)
      loop do
        break if start_date.wday == (finish.wday + 1)
        break if jd(start_date) == jd(finish)
        break if jd(start_date) == jd(finish_date)
        duration += minutes_to_end_of_day(start_date)
        start_date = start_of_next_day(start_date)
      end

      loop do
        break if (start_date + (7 * 86_400)) > finish_date
        break if jd(start_date + (6 * 86_400)) > jd(finish)
        duration += week_total
        start_date += (7 * 86_400)
      end

      loop do
        break if jd(start_date) >= jd(finish)
        break if jd(start_date) >= jd(finish_date)
        duration += minutes_to_end_of_day(start_date)
        start_date = start_of_next_day(start_date)
      end

      if start_date < finish
        interim_duration, start_date = diff_in_same_day(start_date, finish_date)
      end
      duration += interim_duration unless interim_duration.nil?
      [duration, start_date]
    end

    def diff_beyond_weekpattern(start_date, finish_date)
      duration, start_date = diff_in_same_weekpattern(start_date, finish_date)
      [duration, start_date]
    end

    def diff_to_tomorrow(start_date)
      finish_bit_pos = bit_pos(hours_per_day, 0)
      start_bit_pos = bit_pos(start_date.hour, start_date.min)
      mask = finish_bit_pos - start_bit_pos
      minutes = working_minutes_in(values[start_date.wday] & mask)
      [minutes, start_of_next_day(start_date)]
    end

    def diff_in_same_day(start_date, finish_date)
      finish_bit_pos = bit_pos(finish_date.hour, finish_date.min)
      start_bit_pos = bit_pos(start_date.hour, start_date.min)
      mask = finish_bit_pos - start_bit_pos
      minutes = working_minutes_in(values[start_date.wday] & mask)
      [minutes, finish_date]
    end

    def next_day(time)
      time + 86_400
    end

    def prev_day(time)
      time - 86_400
    end

    def jd(time)
      Time.gm(time.year, time.month, time.day)
    end
  end
end
