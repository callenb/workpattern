

module Workpattern
  require 'set'
  
  # Represents the working and resting periods across a number of whole years.  The #base year
  # is the first year and the #span is the number of years including that year that is covered.
  # The #Workpattern is given a unique name so it can be easily identified amongst other Workpatterns.
  #
  class Workpattern
    
    # Holds collection of <tt>Workpattern</tt> objects  
    @@workpatterns = Hash.new()
    
    attr_accessor :name, :base, :span, :from, :to, :weeks
    
    def initialize(name=DEFAULT_NAME,base_year=DEFAULT_BASE_YEAR,span=DEFAULT_SPAN)

      raise(NameError, "Workpattern '#{name}' already exists and can't be created again") if @@workpatterns.key?(name) 
        
      if span < 0
        offset = span.abs - 1
      else
        offset = 0
      end
      
      @name = name
      @base = base_year
      @span = span
      @from = DateTime.new(base_year.abs - offset)
      @to = DateTime.new(@from.year + span.abs - 1,12,31,23,59)
      @weeks = SortedSet.new
      @weeks << Week.new(@from,@to,1)
     
      
      @@workpatterns[name]=self
    end
    
    def self.clear
      @@workpatterns.clear
    end
    
    def self.to_a
      @@workpatterns.to_a
    end
    
    def self.get(name)
      return @@workpatterns[name] if @@workpatterns.key?(name) 
      raise(NameError, "Workpattern '#{name}' doesn't exist so can't be retrieved")
    end
    
    def self.delete(name)
      if @@workpatterns.delete(name).nil?
        return false
      else
        return true
      end        
    end
    
    # Sets a work or resting pattern in the _Workpattern_.
    #
    # Can also use <tt>resting</tt> and <tt>working</tt> methods leaving off the 
    # :work_type
    #
    # === Parameters
    #
    # * <tt>:start</tt> - The first date to apply the pattern.  Defaults
    #   to the _Workpattern_ <tt>start</tt>.
    # * <tt>:finish</tt> - The last date to apply the pattern.  Defaults to
    #   the _Workpattern_ <tt>finish</tt>.
    # * <tt>:days</tt> - The specific day or days the pattern will apply to. This
    #   references _Workpattern::DAYNAMES_.  It defailts to <tt>:all</tt> which is 
    #   everyday. Valid values are <tt>:sun, :mon, :tue, :wed, :thu, :fri, :sat, 
    #   :weekend, :weekday</tt> and <tt>:all</tt>
    # * <tt>:start_time</tt> - The first time in the selected days to apply the pattern.
    #   Must implement #hour and #min to get the Hours and Minutes for the time.  It will default to 
    #   the first time in the day <tt>00:00</tt>.
    # * <tt>:finish_time</tt> - The last time in the selected days to apply the pattern.
    #   Must implement #hour and #min to get the Hours and Minutes for the time.  It will default to
    #   to the last time in the day <tt>23:59</tt>.
    # * <tt>:work_type</tt> - type of pattern is either working (1 or <tt>Workpattern::WORK</tt>) or
    #   resting (0 or <tt>Workpattern::REST</tt>).  Alternatively make use of the <tt>working</tt>
    #   or <tt>resting</tt> methods that will set this value for you
    #
    def workpattern(args={})
      
      #
      upd_start = args[:start] || @from
      upd_start = dmy_date(upd_start)
      args[:start] = upd_start
      
      upd_finish = args[:finish] || @to
      upd_finish = dmy_date(upd_finish)
      args[:finish] = upd_finish
      
      #args[:days]  = args[:days] || :all
      days= args[:days] || :all
      from_time = args[:from_time] || FIRST_TIME_IN_DAY
      from_time = hhmn_date(from_time)
      #args[:from_time] = upd_from_time
      
      to_time = args[:to_time] || LAST_TIME_IN_DAY
      to_time = hhmn_date(to_time)
      #args[:to_time] = upd_to_time
      
      args[:work_type] = args[:work_type] || WORK
      type= args[:work_type] || WORK
      
      while (upd_start <= upd_finish)

        current_wp=find_weekpattern(upd_start)
        if (current_wp.start == upd_start)
          if (current_wp.finish > upd_finish)
            clone_wp=current_wp.duplicate
            current_wp.adjust(upd_finish+1,current_wp.finish)
            clone_wp.adjust(upd_start,upd_finish)
            clone_wp.workpattern(days,from_time,to_time,type)
            @weeks<< clone_wp
            upd_start=upd_finish+1
          else # (current_wp.finish == upd_finish)
            current_wp.workpattern(days,from_time,to_time,type)
            upd_start=current_wp.finish + 1 
          end
        else
          clone_wp=current_wp.duplicate
          current_wp.adjust(current_wp.start,upd_start-1)
          clone_wp.adjust(upd_start,clone_wp.finish)          
          if (clone_wp.finish <= upd_finish)
            clone_wp.workpattern(days,from_time,to_time,type)
            @weeks<< clone_wp
            upd_start=clone_wp.finish+1
          else
            after_wp=clone_wp.duplicate
            after_wp.adjust(upd_finish+1,after_wp.finish)
            @weeks<< after_wp
            clone_wp.adjust(upd_start,upd_finish)
            clone_wp.workpattern(days,from_time,to_time,type)
            @weeks<< clone_wp
            upd_start=clone_wp.finish+1
          end
        end    
      end
    end
    
    # Identical to the <tt>workpattern</tt> method apart from it always creates
    # resting patterns so there is no need to set the <tt>:work_type</tt> argument
    #
    def resting(args={})
      args[:work_type]=REST
      workpattern(args)
    end
    
    # Identical to the <tt>workpattern</tt> method apart from it always creates
    # working patterns so there is no need to set the <tt>:work_type</tt> argument
    #
    def working(args={})
      args[:work_type]=WORK
      workpattern(args)
    end
    
    # :call-seq: calc(start,duration) => DateTime
    # Calculates the resulting date when #duration is added to #start date using the #Workpattern.
    # Duration is always in whole minutes and can be a negative number, in which case it subtracts 
    # the minutes from the date.
    #
    def calc(start,duration)
      return start if duration==0 
      midnight=false
      
      while (duration !=0)
        week=find_weekpattern(start)
        if (week.start==start) && (duration<0) && (!midnight)
          start=start.prev_day
          week=find_weekpattern(start)
          midnight=true
        end    
        
        start,duration,midnight=week.calc(start,duration,midnight)
      end 
      
      return start
    end

    # :call-seq: working?(start) => Boolean
    # Returns true if the given minute is working and false if it isn't
    #
    def working?(start)
      return find_weekpattern(start).working?(start)
    end    
        
    private
    
    # Retrieve the correct pattern for the supplied date
    #
    def find_weekpattern(date)
      # find the pattern that fits the date
      # TODO: What if there is no pattern?
      #
      date = DateTime.new(date.year,date.month,date.day)

      @weeks.find {|week| week.start <= date and week.finish >= date}
      
    end
    
        
    def dmy_date(date)
      return DateTime.new(date.year,date.month,date.day)
    end
      
    def hhmn_date(date)
      return DateTime.new(2000,1,1,date.hour,date.min)
    end
    
  end
end
    
