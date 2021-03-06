module Workpattern
  require 'set'
  require 'tzinfo'

  # Represents the working and resting periods across a given number of whole
  # years.  Each <tt>Workpattern</tt>has a unique name so it can be easily
  # identified amongst all the other <tt>Workpattern</tt> objects.
  #
  # This and the <tt>Clock</tt> class are the only two that should be
  # referenced by calling applications when
  # using this gem.
  #
  class Workpattern

    # Holds collection of <tt>Workpattern</tt> objects
    @@workpatterns = {}

    def self.workpatterns
      @@workpatterns
    end

    def workpatterns
      @@workpatterns
    end

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

    # Class for handling persistence in user's own way
    #
    def self.persistence_class=(klass)
      @@persist = klass
    end

    def self.persistence?
      @@persist ||= nil
    end

    # Holds local timezone info
    @@tz = nil

    # Converts a date like object into utc
    #
    def to_utc(date)
      date.to_time.utc
    end
    # Converts a date like object into local time
    #
    def to_local(date)
      date.to_time.getgm
    end

    # Retrieves the local timezone
    def timezone
      @@tz || @@tz = TZInfo::Timezone.get(Time.now.zone)
    end

    # The new <tt>Workpattern</tt> object is created with all working minutes.
    #
    # @param [String] name Every workpattern has a unique name
    # @param [Integer] base Workpattern starts on the 1st January of this year.
    # @param [Integer] span Workpattern spans this number of years ending on
    # 31st December.
    # @raise [NameError] if the given name already exists
    #
    def initialize(name = DEFAULT_NAME, base = DEFAULT_BASE_YEAR, span = DEFAULT_SPAN)
      if workpatterns.key?(name)
        raise(NameError, "Workpattern '#{name}' already exists and can't be created again")
      end
      offset = span < 0 ? span.abs - 1 : 0

      @name = name
      @base = base
      @span = span
      @from = Time.gm(@base.abs - offset)
      @to = Time.gm(@from.year + @span.abs - 1, 12, 31, 23, 59)
      @weeks = SortedSet.new
      @weeks << Week.new(@from, @to)

      workpatterns[@name] = self
      @week_pattern = WeekPattern.new(self)
    end

    def week_pattern
      @week_pattern
    end

    # Deletes all <tt>Workpattern</tt> objects
    #
    def self.clear
      workpatterns.clear
    end

    # Returns an Array containing all the <tt>Workpattern</tt> objects
    # @return [Array] all <tt>Workpattern</tt> objects
    #
    def self.to_a
      workpatterns.to_a
    end

    # Returns the specific named <tt>Workpattern</tt>
    # @param [String] name of the required <tt>Workpattern</tt>
    # @raise [NameError] if a <tt>Workpattern</tt> of the supplied name does not
    # exist
    #
    def self.get(name)
      return workpatterns[name] if workpatterns.key?(name)
      raise(NameError, "Workpattern '#{name}' doesn't exist so can't be retrieved")
    end

    # Deletes the specific named <tt>Workpattern</tt>
    # @param [String] name of the required <tt>Workpattern</tt>
    # @return [Boolean] true if the named <tt>Workpattern</tt> existed or false
    # if it doesn't
    #
    def self.delete(name)
      workpatterns.delete(name).nil? ? false : true
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
    # @option opts [DAYNAMES] :days The specific day or days the pattern will
    # apply to.It defaults to <tt>:all</tt>
    # @option opts [(#hour, #min)] :start_time The first time in the selected
    # days to apply the pattern. Defaults to <tt>00:00</tt>.
    # @option opts [(#hour, #min)] :finish_time The last time in the selected
    # days to apply the pattern. Defaults to <tt>23:59</tt>.
    # @option opts [(WORK_TYPE || REST_TYPE)] :work_type Either working or resting.
    # Defaults to working.
    # @see #working
    # @see #resting
    #
    def workpattern(opts = {})
      if self.class.persistence?
        week_pattern.workpattern(opts, @@persistence)
      else
        week_pattern.workpattern(opts)
      end
    end

    # Convenience method that calls <tt>#workpattern</tt> with the
    # <tt>:work_type</tt> specified as resting.
    #
    # @see #workpattern
    #
    def resting(args = {})
      args[:work_type] = REST_TYPE
      workpattern(args)
    end

    # Convenience method that calls <tt>#workpattern</tt> with the
    # <tt>:work_type</tt> specified as working.
    #
    # @see #workpattern
    #
    def working(args = {})
      args[:work_type] = WORK_TYPE
      workpattern(args)
    end

    # Calculates the resulting date when the <tt>duration</tt> in minutes
    # is added to the <tt>start</tt> date.
    # The <tt>duration</tt> is always in whole minutes and subtracts from
    # <tt>start</tt> when it is a negative number.
    #
    # @param [DateTime] start date to add or subtract minutes
    # @param [Integer] duration in minutes to add or subtract to date
    # @return [DateTime] the date when <tt>duration</tt> is added to
    # <tt>start</tt>
    #
    def calc(start, duration)
      return start if duration == 0
      a_day = SAME_DAY

      utc_start = to_utc(start)

      while duration != 0

        if a_day == PREVIOUS_DAY
	        utc_start -= DAY
	        a_day = SAME_DAY
          utc_start = Time.gm(utc_start.year, utc_start.month, utc_start.day,LAST_TIME_IN_DAY.hour, LAST_TIME_IN_DAY.min)
	        week = find_weekpattern(utc_start)
	  
	        if week.working?(utc_start)
	          duration += 1
	        end
        else
	        week = find_weekpattern(utc_start)
        end
        utc_start, duration, a_day = week.calc(utc_start, duration, a_day)
      end
      to_local(utc_start)
    end

    # Returns true if the given minute is working and false if it is resting.
    #
    # @param [DateTime] start DateTime being tested
    # @return [Boolean] true if working and false if resting
    #
    def working?(start)
      utc_start = to_utc(start)
      find_weekpattern(utc_start).working?(utc_start)
    end

    # Returns number of minutes between two dates
    #
    # @param [DateTime] start is the date to start from
    # @param [DateTime] finish is the date to end with
    # @return [Integer] number of minutes between the two dates
    #
    def diff(start, finish)
      utc_start = to_utc(start)
      utc_finish = to_utc(finish)
      utc_start, utc_finish = utc_finish, utc_start if utc_finish < utc_start
      minutes = 0

      while utc_start != utc_finish
        week = find_weekpattern(utc_start)
        r_minutes, utc_start = week.diff(utc_start, utc_finish)
        minutes += r_minutes
      end
      minutes
    end

    # Retrieve the correct <tt>Week</tt> pattern for the supplied date.
    #
    # If the supplied <tt>date</tt> is outside the span of the
    # <tt>Workpattern</tt> object then it returns an all working <tt>Week</tt>
    # object for the calculation.
    #
    # @param [DateTime] date whose containing <tt>Week</tt> pattern is required
    # @return [Week] <tt>Week</tt> object that includes the supplied
    # <tt>date</tt> in it's range
    #
    def find_weekpattern(date)
      # find the pattern that fits the date
      #
      if date < @from
        result = Week.new(Time.at(0), @from - MINUTE, WORK_TYPE)
      elsif date > to
        result = Week.new(@to + MINUTE, Time.new(9999), WORK_TYPE)
      else

        date = Time.gm(date.year, date.month, date.day)

        result = @weeks.find { |week| week.start <= date && week.finish >= date }
      end
      result
    end
  end
end
