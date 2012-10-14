module Workpattern
  require 'set'
  
  # Represents the working and resting periods across a given number of whole years.  Each <tt>Workpattern</tt>
  # has a unique name so it can be easily identified amongst all the other <tt>Workpattern</tt> objects.
  #
  # This and the <tt>Clock</tt> class are the only two that should be referenced by calling applications when
  # using this gem.
  #
  # @since 0.2.0
  #
  class Workpattern
    
    # Holds collection of <tt>Workpattern</tt> objects
    @@workpatterns = Hash.new()
    
    # @!attribute [r] name
    #   Name given to the <tt>Workpattern</tt>
    # @!attribute [r] base
    #   Starting year
    # @!attribute [r] span
    #   Number of years
    # @!attribute [r] from
    #   First date in <tt>Workpattern</tt>
    # @!attribute [r] to
    #   Last date in <tt>Workpattern</tt>
    # @!attribute [r] weeks
    #   The <tt>Week</tt> objects that make up this workpattern
    #
    attr_reader :name, :base, :span, :from, :to, :weeks
    
    # The new <tt>Workpattern</tt> object is created with all working minutes.
    #
    # @param [String] name Every workpattern has a unique name
    # @param [Integer] base Workpattern starts on the 1st January of this year.
    # @param [Integer] span Workpattern spans this number of years ending on 31st December.
    # @raise [NameError] if the given name already exists
    #
    def initialize(name=DEFAULT_NAME,base=DEFAULT_BASE_YEAR,span=DEFAULT_SPAN)

      raise(NameError, "Workpattern '#{name}' already exists and can't be created again") if @@workpatterns.key?(name) 
        
      if span < 0
        offset = span.abs - 1
      else
        offset = 0
      end
      
      @name = name
      @base = base
      @span = span
      @from = DateTime.new(base.abs - offset)
      @to = DateTime.new(@from.year + span.abs - 1,12,31,23,59)
      @weeks = SortedSet.new
      @weeks << Week.new(@from,@to,1)
     
      
      @@workpatterns[name]=self
    end
    
    # Deletes all <tt>Workpattern</tt> objects
    #
    def self.clear
      @@workpatterns.clear
    end
    
    # Returns an Array containing all the <tt>Workpattern</tt> objects
    # @return [Array] all <tt>Workpattern</tt> objects
    # 
    def self.to_a
      @@workpatterns.to_a
    end
    
    # Returns the specific named <tt>Workpattern</tt>
    # @param [String] name of the required <tt>Workpattern</tt>
    # @raise [NameError] if a <tt>Workpattern</tt> of the supplied name does not exist
    #
    def self.get(name)
      return @@workpatterns[name] if @@workpatterns.key?(name) 
      raise(NameError, "Workpattern '#{name}' doesn't exist so can't be retrieved")
    end
    
    # Deletes the specific named <tt>Workpattern</tt>
    # @param [String] name of the required <tt>Workpattern</tt>
    # @return [Boolean] true if the named <tt>Workpattern</tt> existed or false if it doesn't
    #
    def self.delete(name)
      if @@workpatterns.delete(name).nil?
        return false
      else
        return true
      end        
    end
    
    # Applys a working or resting pattern to the <tt>Workpattern</tt> object.
    #
    # The #resting and #working methods are convenience methods that call 
    # this with the appropriate <tt>:work_type</tt> already set.
    #
    # @param [Hash] opts the options used to apply a workpattern
    # @option opts [Date] :start The first date to apply the pattern.  Defaults
    #     to the <tt>start</tt> attribute.
    # @option opts [Date] :finish The last date to apply the pattern.  Defaults
    #     to the <tt>finish</tt> attribute.
    # @option opts [DAYNAMES] :days The specific day or days the pattern will apply to.
    #     It defaults to <tt>:all</tt>
    # @option opts [(#hour, #min)] :start_time The first time in the selected days to apply the pattern.
    #     Defaults to <tt>00:00</tt>.
    # @option opts [(#hour, #min)] :finish_time The last time in the selected days to apply the pattern.
    #     Defaults to <tt>23:59</tt>.
    # @option opts [(WORK || REST)] :work_type Either working or resting.  Defaults to working.
    # @see #working
    # @see #resting
    #
    def workpattern(opts={})
    
      args={:start => @from, :finish => @to, :days => :all,
          :from_time => FIRST_TIME_IN_DAY, :to_time => LAST_TIME_IN_DAY,
          :work_type => WORK}   
          
      args.merge! opts

      args[:start] = dmy_date(args[:start])
      args[:finish] = dmy_date(args[:finish])
      from_time = hhmn_date(args[:from_time])
      to_time = hhmn_date(args[:to_time])
      
      upd_start=args[:start]
      upd_finish=args[:finish]
      while (upd_start <= upd_finish)

        current_wp=find_weekpattern(upd_start)
        if (current_wp.start == upd_start)
          if (current_wp.finish > upd_finish)
            clone_wp=current_wp.duplicate
            current_wp.adjust(upd_finish+1,current_wp.finish)
            clone_wp.adjust(upd_start,upd_finish)
            clone_wp.workpattern(args[:days],from_time,to_time,args[:work_type])
            @weeks<< clone_wp
            upd_start=upd_finish+1
          else # (current_wp.finish == upd_finish)
            current_wp.workpattern(args[:days],from_time,to_time,args[:work_type])
            upd_start=current_wp.finish + 1 
          end
        else
          clone_wp=current_wp.duplicate
          current_wp.adjust(current_wp.start,upd_start-1)
          clone_wp.adjust(upd_start,clone_wp.finish)          
          if (clone_wp.finish <= upd_finish)
            clone_wp.workpattern(args[:days],from_time,to_time,args[:work_type])
            @weeks<< clone_wp
            upd_start=clone_wp.finish+1
          else
            after_wp=clone_wp.duplicate
            after_wp.adjust(upd_finish+1,after_wp.finish)
            @weeks<< after_wp
            clone_wp.adjust(upd_start,upd_finish)
            clone_wp.workpattern(args[:days],from_time,to_time,args[:work_type])
            @weeks<< clone_wp
            upd_start=clone_wp.finish+1
          end
        end    
      end
    end
    
    # Convenience method that calls <tt>#workpattern</tt> with the <tt>:work_type</tt> specified as resting.
    #
    # @see #workpattern
    #
    def resting(args={})
      args[:work_type]=REST
      workpattern(args)
    end
    
    # Convenience method that calls <tt>#workpattern</tt> with the <tt>:work_type</tt> specified as working.
    #
    # @see #workpattern
    #
    def working(args={})
      args[:work_type]=WORK
      workpattern(args)
    end
    
    # Calculates the resulting date when the <tt>duration</tt> in minutes is added to the <tt>start</tt> date.
    # The <tt>duration</tt> is always in whole minutes and subtracts from <tt>start</tt> when it is a
    # negative number.
    #
    # @param [DateTime] start date to add or subtract minutes
    # @param [Integer] duration in minutes to add or subtract to date
    # @return [DateTime] the date when <tt>duration</tt> is added to <tt>start</tt>
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

    # Returns true if the given minute is working and false if it is resting.
    #
    # @param [DateTime] start DateTime being tested
    # @return [Boolean] true if working and false if resting
    #
    def working?(start)
      return find_weekpattern(start).working?(start)
    end    
    
    # Returns number of minutes between two dates
    #
    # @param [DateTime] start is the date to start from
    # @param [DateTime] finish is the date to end with
    # @return [Integer] number of minutes between the two dates
    #
    def diff(start,finish)
    
      start,finish=finish,start if finish<start
      duration=0
      while(start!=finish) do
        week=find_weekpattern(start)
        result_duration,start=week.diff(start,finish)
        duration+=result_duration
      end
      return duration
    end   
    
    private
    
    # Retrieve the correct <tt>Week</tt> pattern for the supplied date.
    #
    # If the supplied <tt>date</tt> is outside the span of the <tt>Workpattern</tt> object
    # then it returns an all working <tt>Week</tt> object for the calculation.
    # 
    # @param [DateTime] date whose containing <tt>Week</tt> pattern is required
    # @return [Week] <tt>Week</tt> object that includes the supplied <tt>date</tt> in it's range
    #
    def find_weekpattern(date)
      # find the pattern that fits the date
      #
      if date<@from
        result = Week.new(DateTime.jd(0),@from-MINUTE,1)
      elsif date>@to
        result = Week.new(@to+MINUTE,DateTime.new(9999),1)
      else
      
        date = DateTime.new(date.year,date.month,date.day)

        result=@weeks.find {|week| week.start <= date and week.finish >= date}
      end
      return result
    end
    
    # Strips off hours, minutes, seconds and so forth from a supplied <tt>Date</tt> or 
    # <tt>DateTime</tt>
    #
    # @param [DateTime] date 
    # @return [DateTime] with zero hours, minutes, seconds and so forth.
    #    
    def dmy_date(date)
      return DateTime.new(date.year,date.month,date.day)
    end
    
    # Extract the time into a <tt>Clock</tt> object
    #
    # @param [DateTime] date
    # @return [Clock] 
    def hhmn_date(date)
      return Clock.new(date.hour,date.min)
    end
    
  end
end
    
