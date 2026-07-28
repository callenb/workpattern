require 'date'
require 'holidays'

module Workpattern
  # Bridges the third-party <tt>holidays</tt> gem to a <tt>Workpattern</tt>,
  # applying a region's public holidays as resting days in a single call.
  #
  # This file is never required by <tt>workpattern.rb</tt> itself — it is a
  # soft dependency that only activates when a caller explicitly does
  # <tt>require 'workpattern/holidays'</tt>. The <tt>holidays</tt> gem must
  # already be available (e.g. in the caller's own Gemfile); otherwise this
  # require raises Ruby's standard <tt>LoadError</tt>.
  #
  module Holidays
    # Applies one region's public holidays for one calendar year to a
    # <tt>Workpattern</tt>, marking each returned date resting for its whole
    # day.
    #
    # Requests observed dates (a holiday falling on a weekend is shifted to
    # its statutory observed weekday) and excludes informal holidays (days
    # people don't get off work, e.g. "Mothering Sunday"), matching the
    # <tt>holidays</tt> gem's own default. Neither is configurable.
    #
    # No validation is performed beyond what Ruby's keyword arguments
    # already enforce: an unrecognised <tt>region</tt> raises
    # <tt>Holidays::InvalidRegion</tt> from the <tt>holidays</tt> gem
    # unchanged, and a <tt>year</tt> outside the <tt>workpattern</tt>'s own
    # <tt>base</tt>/<tt>span</tt> window is silently absorbed exactly as
    # <tt>#resting</tt> already absorbs any other out-of-range date — no
    # holiday is actually applied, but no error is raised either.
    #
    # Passing an <tt>Array</tt> of regions happens to work today as a
    # byproduct of the <tt>holidays</tt> gem's own option parsing, but this
    # is not a feature this adapter tests or commits to preserving — call
    # <tt>apply</tt> once per region for guaranteed behaviour.
    #
    # A region whose observed-date rule shifts a Saturday-falling holiday
    # *backward* to the preceding Friday (the common US-style rule) can
    # push that date into the *previous* calendar year, outside this
    # method's single-year query window — the holiday will not appear in
    # that year's result and must be picked up via the adjacent year's
    # <tt>apply</tt> call instead.
    #
    # @param [Workpattern::Workpattern] workpattern the workpattern to update
    # @param [Symbol] region a region recognised by the <tt>holidays</tt> gem
    #     (e.g. <tt>:gb</tt>, <tt>:us</tt>)
    # @param [Integer] year the calendar year to apply holidays for
    # @return [Array<Date>] every holiday date the <tt>holidays</tt> gem
    #     reported for this region/year, sorted — each is passed to
    #     <tt>#resting</tt>, but a date outside the workpattern's own
    #     <tt>base</tt>/<tt>span</tt> window is still included here even
    #     though it did not actually change the workpattern's working state
    #     (see the out-of-range note above)
    # @raise [Holidays::InvalidRegion] if the <tt>holidays</tt> gem does not
    #     recognise +region+
    # @see Workpattern::Workpattern#resting
    #
    def self.apply(workpattern, region:, year:)
      start_date = Date.new(year, 1, 1)
      finish_date = Date.new(year, 12, 31)

      ::Holidays.between(start_date, finish_date, region, :observed).map do |holiday|
        date = holiday[:date]
        workpattern.resting(start: date, finish: date, days: :all)
        date
      end
    end
  end
end
