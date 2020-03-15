module Workpattern
  
  class Day
    
    attr_accessor  :pattern, :hours_per_day, :first_working_minute, :last_working_minute

    def initialize(hours_per_day = HOURS_IN_DAY, type = WORK_TYPE)
      @hours_per_day = hours_per_day
      @pattern = initial_day(type)
      set_first_and_last_minutes
    end

    def set_resting(start_time, finish_time)
      mask = resting_mask(start_time, finish_time)
      @pattern = @pattern & mask
      set_first_and_last_minutes
    end

    def set_working(from_time, to_time)
      @pattern = @pattern | working_mask(from_time, to_time)
      set_first_and_last_minutes
    end

    def working_minutes(from_time = FIRST_TIME_IN_DAY, to_time = LAST_TIME_IN_DAY)
      section = @pattern & working_mask(from_time, to_time)
      section.to_s(2).count('1') 
    end

    def working?(hour, minute)
      mask = (2**((hour * 60) + minute))
      result = mask & @pattern
      if mask == result
        return true
      else
        return false
      end
    end
   
    def resting?(hour, minute)
      !working?(hour,minute)
    end

    def calc(a_date, a_duration)
      if a_duration == 0
        return a_date, a_duration, SAME_DAY
      elsif a_duration > 0
        return add(a_date, a_duration)
      else
        return subtract(a_date, a_duration)
      end
    end  
    
    private

    def add(a_date, a_duration)
      minutes_left = working_minutes(a_date)
      if a_duration > minutes_left
        return [a_date, a_duration - minutes_left, NEXT_DAY]
      elsif a_duration < minutes_left
        return add_minutes(a_date, a_duration)
      else
        if working?(LAST_TIME_IN_DAY.hour, LAST_TIME_IN_DAY.min)
	  return [a_date, 0, NEXT_DAY]
	else
          return_date = Time.gm(a_date.year, a_date.month, a_date.day, @last_working_minute.hour, @last_working_minute.min) + 60
	  return [ return_date, 0, SAME_DAY]
	end
      end	
    end

    def add_minutes(a_date, a_duration)
      elapsed_date = a_date + (a_duration * 60) - 60

      if working_minutes(a_date, elapsed_date) == a_duration
        return [elapsed_date += 60, 0, SAME_DAY]
      else
        begin
          elapsed_date += 60
	end while working_minutes(a_date, elapsed_date) != a_duration
	return [elapsed_date += 60, 0, SAME_DAY]
      end
    end

    def subtract(a_date, a_duration)
      minutes_left = working_minutes(FIRST_TIME_IN_DAY,a_date - 60)
      abs_duration = a_duration.abs
      if abs_duration > minutes_left
        return [a_date, a_duration + minutes_left, PREVIOUS_DAY]
      elsif abs_duration < minutes_left
        return subtract_minutes(a_date, abs_duration)
      else
        return [Time.gm(a_date.year,a_date.month,a_date.day,@first_working_minute.hour,@first_working_minute.min), 0, SAME_DAY]
      end	
    end

    def subtract_minutes(a_date, abs_duration)
      elapsed_date = a_date - (abs_duration * 60)
      if working_minutes(elapsed_date, a_date - 60) == abs_duration
        return [elapsed_date, 0, SAME_DAY]
      else
        a_date -= 60
        begin
          elapsed_date -= 60
	end while working_minutes(elapsed_date, a_date) != abs_duration
	return [elapsed_date, 0, SAME_DAY]
      end
    end

    def working_day
      2**((60 * @hours_per_day) +1) - 1
    end
    
    def initial_day(type = WORK_TYPE)

      pattern = 2**((60 * @hours_per_day) + 1)

      if type == WORK_TYPE
        pattern = pattern - 1
      end
      
      pattern
    end

    def working_mask(start_time, finish_time)
    
      start = minutes_in_time(start_time) 
      finish = minutes_in_time(finish_time) 

      mask = initial_day

      mask = mask - ((2**start) - 1)
      mask & ((2**(finish + 1)) -1)
    end

    def resting_mask(start_time, finish_time)

      start = minutes_in_time(start_time)
      finish_clock = Clock.new(finish_time.hour, finish_time.min + 1) 

      mask = initial_day(REST_TYPE)
      if minutes_in_time(finish_time) != LAST_TIME_IN_DAY.minutes
        mask = mask | working_mask(finish_clock,LAST_TIME_IN_DAY)
      end	
      mask | ((2**start) - 1)
    end 

    def minutes_in_time(a_time)
      (a_time.hour * 60) + a_time.min
    end

    def last_minute
      if working?(LAST_TIME_IN_DAY.hour, LAST_TIME_IN_DAY.min)
        return LAST_TIME_IN_DAY
      end

      top = minutes_in_time(LAST_TIME_IN_DAY)
      bottom = minutes_in_time(FIRST_TIME_IN_DAY)
      mark = top / 2

      not_done = true
      while not_done
      
        minutes = working_minutes(minutes_to_time(mark), minutes_to_time(top))

	if minutes > 1
	  bottom = mark
	  mark = mark + ((top - bottom) / 2)

        elsif minutes == 0
          top = mark
	  mark = mark - (( top - bottom) / 2)

	elsif minutes == 1 && is_resting(mark)
          bottom = mark
	  mark = mark + ((top - bottom) / 2)

	else
	  not_done = false
        
	end  

        if mark == bottom #& last_mark != mark
	  mark = mark + 1
	end  

        if mark == 1 && top == 1 
          mark = 0
        end

      end
      minutes_to_time(mark)

    end

    def first_minute
      if working?(FIRST_TIME_IN_DAY.hour, FIRST_TIME_IN_DAY.min)
        return FIRST_TIME_IN_DAY
      end

      top = minutes_in_time(LAST_TIME_IN_DAY)
      bottom = minutes_in_time(FIRST_TIME_IN_DAY)
      mark = top / 2

      not_done = true
      while not_done
      
        minutes = working_minutes(minutes_to_time(bottom), minutes_to_time(mark))
	

	if minutes > 1

	  top = mark
	  mark = mark - ((top - bottom) / 2)

        elsif minutes == 0
	  
          bottom = mark
	  mark = mark + (( top - bottom) / 2)

	elsif minutes == 1 && is_resting(mark)

          top = mark
	  mark = mark - ((top - bottom) / 2)

	else

	  not_done = false
        
	end  
        
	if mark == 1 && top == 1
	  mark = 0
	end

      end
      
      minutes_to_time(mark)
    end  

    def minutes_to_time(minutes)
       Clock.new(minutes / 60, minutes - (minutes / 60 * 60))
    end

    def is_resting(minutes)
      a_time =(minutes_to_time(minutes))
      resting?(a_time.hour, a_time.min)
    end  

    def set_first_and_last_minutes
      if working_minutes == 0
        @first_working_minute = nil
        @last_working_minute = nil
      else	
	@first_working_minute = first_minute
	@last_working_minute = last_minute
      end	
    end  


  end

end
