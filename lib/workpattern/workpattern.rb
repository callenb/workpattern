

module Workpattern
  require 'set'
  # Represents the 60 minutes of an hour using a <tt>Fixnum</tt> or <tt>Bignum</tt>
  #
  class Workpattern
    
    # holds collection of <tt>Workpattern</tt> objects  
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
      @from = Time.new(base_year.abs - offset)
      @to = Time.new(@from.year + span.abs - 1,12,31,23,59)
      @weeks = SortedSet.new
      @weeks << Week.new(@from,@to,1,[24,24,24,24,24,24,24])
     
      
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
    #
    def workpattern(args={})
      
      #
      upd_start = args[:start] || @start
      upd_start = dmy_date(upd_start)
      args[:start] = upd_start
      
      upd_finish = args[:finish] || @finish
      upd_finish = dmy_date(upd_finish)
      args[:finish] = upd_finish
      
      #args[:days]  = args[:days] || :all
      days= args[:days] || :all
      from_time = args[:from_time] || Workpattern::FIRST_TIME_IN_DAY
      from_time = hhmn_date(from_time)
      #args[:from_time] = upd_from_time
      
      to_time = args[:to_time] || Workpattern::LAST_TIME_IN_DAY
      to_time = hhmn_date(to_time)
      #args[:to_time] = upd_to_time
      
      args[:work_type] = args[:work_type] || Workpattern::WORK
      type= args[:work_type] || Workpattern::WORK
      
      while (upd_start <= upd_finish)
        current_wp=find_workpattern(upd_start)
        if (current_wp.start == upd_start)
          if (current_wp.finish > upd_finish)
            clone_wp=current_wp.duplicate
            current_wp.adjust(upd_finish+1,current_wp.finish)
            clone_wp.adjust(upd_start,upd_finish)
            clone_wp.workpattern(days,from_time,to_time,type)
            @weeks<<clone_wp
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
            @weeks<<clone_wp
            upd_start=clone_wp.finish+1
          else
            after_wp=clone_wp.duplicate
            after_wp.adjust(upd_finish+1,after_wp.finish)
            @weeks<<after_wp
            clone_wp.adjust(upd_start,upd_finish)
            clone_wp.workpattern(days,from_time,to_time,type)
            @weeks<<clone_wp
            upd_start=clone_wp.finish+1
          end
        end    
      end
    end
    
    private
    
    # Retrieve the correct pattern for the supplied date
    #
    def find_workpattern(date)
      # find the pattern that fits the date
      # TODO: What if there is no pattern?
      #
      date = Time.new(date.year,date.month,date.day)

      @weeks.find {|week| week.start <= date and week.finish >= date}
      
    end
    
    def dmy_date(date)
      return Time.new(date.year,date.month,date.day)
    end
      
    def hhmn_date(date)
      return Time.new(2000,1,1,date.hour,date.min)
    end
    
  end
end
    