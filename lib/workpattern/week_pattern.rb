module Workpattern
  class WeekPattern
    def initialize(work_pattern)
      @work_pattern = work_pattern
    end

    def work_pattern
      @work_pattern
    end

    def weeks
      work_pattern.weeks
    end

    def from
      work_pattern.from
    end

    def to
      work_pattern.to
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
    def workpattern(opts = {}, persist = nil)
      args = all_workpattern_options(opts)

      persist.store(name: @name, workpattern: args) if !persist.nil?

      args = standardise_args(args)

      upd_start = work_pattern.to_utc(args[:start])
      upd_finish = work_pattern.to_utc(args[:finish])

      while upd_start <= upd_finish

	      current_wp = work_pattern.find_weekpattern(upd_start)

        if current_wp.start == upd_start
          if current_wp.finish > upd_finish
            clone_wp = fetch_updatable_week_pattern(current_wp,
                                                   upd_finish + DAY,
                                                   current_wp.finish,
                                                   upd_start,
                                                   upd_finish)
            update_and_store_week_pattern(clone_wp, args)
            upd_start = upd_finish + DAY
          else # (current_wp.finish == upd_finish)
            current_wp.workpattern(args[:days], args[:from_time],
                                   args[:to_time], args[:work_type])
            upd_start = current_wp.finish + DAY
          end
        else
          clone_wp = fetch_updatable_week_pattern(current_wp, current_wp.start,
                                                 upd_start - DAY, upd_start)
          if clone_wp.finish > upd_finish
            after_wp = fetch_updatable_week_pattern(clone_wp,
                                                   upd_start,
                                                   upd_finish,
                                                   upd_finish + DAY)
            weeks << after_wp
          end
          update_and_store_week_pattern(clone_wp, args)
          upd_start = clone_wp.finish + DAY
        end
      end
    end

    private

    def all_workpattern_options(opts)
	    
      args = { start: from, finish: to, days: :all,
               from_time: FIRST_TIME_IN_DAY, to_time: LAST_TIME_IN_DAY,
               work_type: WORK_TYPE }

      args.merge! opts
    end  

    def standardise_args(args)

      args[:start] = dmy_date(args[:start])
      args[:finish] = dmy_date(args[:finish])
      args[:from_time] = hhmn_date(args[:from_time])
      args[:to_time] = hhmn_date(args[:to_time])

      args
    end

    # Clones the supplied Week Pattern then changes the dates on it
    # The newly cloned Week pattern dates are also changed and it is 
    # returned by this method
    #
    def fetch_updatable_week_pattern(keep_week, keep_start, keep_finish,
                                    change_start, change_finish = nil)
      change_week = keep_week.duplicate
      adjust_date_range(keep_week, keep_start, keep_finish)
      if change_finish.nil?
        adjust_date_range(change_week, change_start, change_week.finish)
      else
        adjust_date_range(change_week, change_start, change_finish)
      end
      change_week
    end

    def update_and_store_week_pattern(week_pattern, args)
      week_pattern.workpattern(args[:days], args[:from_time],
                         args[:to_time], args[:work_type])
      weeks << week_pattern
    end

    def adjust_date_range(week_pattern, start_date, finish_date)
      week_pattern.start = start_date
      week_pattern.finish = finish_date
    end

    # Strips off hours, minutes, seconds etc from a supplied <tt>Date</tt> or
    # <tt>DateTime</tt>
    #
    # @param [DateTime] date
    # @return [DateTime] with zero hours, minutes, seconds and so forth.
    #
    def dmy_date(date)
      Time.gm(date.year, date.month, date.day)
    end

    # Extract the time into a <tt>Clock</tt> object
    #
    # @param [DateTime] date
    # @return [Clock]
    def hhmn_date(date)
      Clock.new(date.hour, date.min)
    end
  end
end
