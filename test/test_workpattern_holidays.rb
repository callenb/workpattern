require "#{File.dirname(__FILE__)}/test_helper.rb"
require 'workpattern/holidays'

class TestWorkpatternHolidays < WorkpatternTest
  def setup
    Workpattern.clear
  end

  # 1. Covers AE2. apply returns applied dates and marks them resting
  def test_apply_returns_dates_and_marks_them_resting
    wp = Workpattern.new('uk-2026', 2026, 1)
    dates = Workpattern::Holidays.apply(wp, region: :gb, year: 2026)

    assert_instance_of Array, dates
    assert_includes dates, Date.new(2026, 1, 1)
    dates.each do |date|
      assert refute(wp.working?(Time.gm(date.year, date.month, date.day, 12, 0)))
    end
  end

  # 2. Covers AE3. Observed-date shift on a weekend-falling holiday
  def test_apply_uses_observed_date_when_holiday_falls_on_a_weekend
    wp = Workpattern.new('uk-2028', 2028, 1)
    dates = Workpattern::Holidays.apply(wp, region: :gb, year: 2028)

    assert_includes dates, Date.new(2028, 1, 3)
    refute_includes dates, Date.new(2028, 1, 1)
  end

  # 3. Covers AE4. Informal holidays are excluded
  def test_apply_excludes_informal_holidays
    wp = Workpattern.new('uk-informal', 2026, 1)
    dates = Workpattern::Holidays.apply(wp, region: :gb, year: 2026)

    refute_includes dates, Date.new(2026, 3, 15) # Mothering Sunday
    refute_includes dates, Date.new(2026, 11, 5) # Guy Fawkes Day
  end

  # 4. Edge case: region is passed through to Holidays.between, not hardcoded
  def test_apply_passes_region_through_to_holidays_gem
    wp = Workpattern.new('scotland-2026', 2026, 1)
    dates = Workpattern::Holidays.apply(wp, region: :gb_sct, year: 2026)

    assert_includes dates, Date.new(2026, 11, 30) # St. Andrew's Day (gb_sct only)
  end

  # 5. Edge case: year outside the workpattern's base/span is a silent no-op
  def test_apply_for_out_of_range_year_does_not_raise_or_change_working_state
    wp = Workpattern.new('narrow-span', 2020, 10) # covers 2020-2029

    dates = Workpattern::Holidays.apply(wp, region: :gb, year: 2050)

    refute_empty dates
    assert(wp.working?(Time.gm(2050, 1, 1, 12, 0)))
  end

  # 6. Edge case: a backward-shifting :observed rule can push a holiday
  #    outside the requested year's query window entirely
  def test_apply_can_miss_a_holiday_that_shifts_across_the_year_boundary
    wp = Workpattern.new('us-2028', 2028, 1)
    dates = Workpattern::Holidays.apply(wp, region: :us, year: 2028)

    refute_includes dates, Date.new(2027, 12, 31)
    assert_nil(dates.find { |d| d.year == 2028 && d.yday <= 3 })
  end

  # 7. Error path: an unrecognised region raises Holidays::InvalidRegion unwrapped
  def test_apply_with_unknown_region_raises_invalid_region
    wp = Workpattern.new('bad-region', 2026, 1)

    assert_raises(Holidays::InvalidRegion) do
      Workpattern::Holidays.apply(wp, region: :not_a_real_region, year: 2026)
    end
  end

  # 8. Integration: applying a holiday that's already resting is a harmless no-op
  def test_apply_is_harmless_when_date_is_already_resting
    wp = Workpattern.new('already-resting', 2026, 1)
    wp.resting(days: :weekend)
    already_resting_saturday = Time.gm(2026, 1, 3, 12, 0) # a Saturday, already resting

    assert refute(wp.working?(already_resting_saturday))

    dates = Workpattern::Holidays.apply(wp, region: :gb, year: 2026)

    assert refute(wp.working?(already_resting_saturday))
    assert_includes dates, Date.new(2026, 1, 1)
  end
end
