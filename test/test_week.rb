require File.dirname(__FILE__) + '/test_helper.rb'

class TestWeek < WorkpatternTest #:nodoc:
  def setup
    start = Time.gm(2000, 1, 3)
    finish = Time.gm(2000, 1, 9)

    @w_week = Workpattern::Week.new(start, finish, Workpattern::WORK_TYPE)

    @r_week = Workpattern::Week.new(start, finish, Workpattern::REST_TYPE)

    @p_week = Workpattern::Week.new(start, finish, Workpattern::WORK_TYPE)
    @p_week.workpattern(:weekend, set_time(0, 0),
                        set_time(23, 59), 0)
    @p_week.workpattern(:weekday, set_time(0, 0),
                        set_time(8, 59), 0)
    @p_week.workpattern(:weekday, set_time(12, 30),
                        set_time(13, 0), 0)
    @p_week.workpattern(:weekday, set_time(17, 0),
                        set_time(23, 59), 0)
  end

  def test_must_create_a_w_week
    start = Time.gm(2000, 1, 1, 11, 3)
    finish = Time.gm(2005, 12, 31, 16, 41)
    w_week = week(start, finish, Workpattern::WORK_TYPE)
    assert_equal Time.gm(start.year, start.month, start.day),
                 w_week.start
    assert_equal Time.gm(finish.year, finish.month, finish.day),
                 w_week.finish
    assert_equal 3_156_480, w_week.total # 2192 days
  end

  def test_create_w_week_of_3_concecutive_days
    start = Time.gm(2000, 1, 2, 11, 3) # Sunday
    finish = Time.gm(2000, 1, 4, 16, 41) # Tuesday
    w_week = week(start, finish, 1)
    assert_equal Time.gm(start.year, start.month,
                         start.day), w_week.start
    assert_equal Time.gm(finish.year, finish.month, finish.day),
                 w_week.finish
    assert_equal 1_440 * 3, w_week.total # 3 days
  end

  def test_create_working_week_friday_to_sunday
    start = Time.gm(2000, 1, 7, 11, 3) # Friday
    finish = Time.gm(2000, 1, 9, 16, 41) # Sunday
    w_week = week(start, finish, 1)
    assert_equal Time.gm(start.year, start.month, start.day),
                 w_week.start
    assert_equal Time.gm(finish.year, finish.month, finish.day),
                 w_week.finish
    assert_equal 1_440 * 3, w_week.total # 3 days
  end

  def test_create_working_week_thursday_to_sunday
    start = Time.gm(2000, 1, 6, 11, 3) # Thursday
    finish = Time.gm(2000, 1, 8, 16, 41) # Sunday
    w_week = week(start, finish, 1)
    assert_equal Time.gm(start.year, start.month, start.day),
                 w_week.start
    assert_equal Time.gm(finish.year, finish.month, finish.day),
                 w_week.finish
    assert_equal 1_440 * 3, w_week.total # 3 days
  end

  def test_must_create_a_resting_week
    start = Time.gm(2000, 1, 1, 11, 3)
    finish = Time.gm(2005, 12, 31, 16, 41)
    resting_week = week(start, finish, 0)
    assert_equal Time.gm(start.year, start.month, start.day),
                 resting_week.start
    assert_equal Time.gm(finish.year, finish.month, finish.day),
                 resting_week.finish
    assert_equal 0, resting_week.total # 2192
    assert_equal 0, resting_week.week_total
  end

  def test_must_duplicate_all_of_a_week
    start = Time.gm(2000, 1, 1, 11, 3)
    finish = Time.gm(2005, 12, 31, 16, 41)
    week = week(start, finish, 1)
    new_week = week.duplicate
    assert_equal Time.gm(start.year, start.month, start.day),
                 new_week.start
    assert_equal Time.gm(finish.year, finish.month, finish.day),
                 new_week.finish
    assert_equal 3_156_480, new_week.total # 2192
    week.workpattern(:weekend, set_time(0, 0),
                     set_time(23, 59), 0)
    assert_equal 3_156_480, new_week.total # 2192
  end

  def test_must_set_week_pattern_correctly
    start = Time.gm(2000, 1, 3)
    finish = Time.gm(2000, 1, 9)

    pattern_week = Workpattern::Week.new(start, finish, 1)
    assert_equal start, pattern_week.start
    assert_equal finish, pattern_week.finish
    assert_equal 10_080, pattern_week.week_total
    pattern_week.workpattern(:weekend, set_time(0, 0),
                             set_time(23, 59), 0)
    assert_equal 7_200, pattern_week.week_total
    pattern_week.workpattern(:weekday, set_time(0, 0),
                             set_time(8, 59), 0)
    assert_equal 4_500, pattern_week.week_total
    pattern_week.workpattern(:weekday, set_time(12, 30),
                             set_time(13, 0), 0)
    assert_equal 4_345, pattern_week.week_total
    pattern_week.workpattern(:weekday, set_time(17, 0),
                             set_time(23, 59), 0)
    assert_equal 2_245, pattern_week.week_total
  end

  def test_must_set_patterns_correctly
    start = Time.gm(2000, 1, 1, 0, 0)
    finish = Time.gm(2005, 12, 31, 8, 59)
    w_week = week(start, finish, 1)
    assert_equal 10_080, w_week.week_total
    w_week.workpattern(:all, start, finish, 0)
    assert_equal 6_300, w_week.week_total
    w_week.workpattern(:sun, start, finish, 1)
    assert_equal 6_840, w_week.week_total
    w_week.workpattern(:mon, start, finish, 1)
    assert_equal 7_380, w_week.week_total
    w_week.workpattern(:all, set_time(18, 0), set_time(18, 19), 0)
    assert_equal 7_240, w_week.week_total
    w_week.workpattern(:all, set_time(0, 0), set_time(23, 59), 0)
    assert_equal 0, w_week.week_total
    w_week.workpattern(:all, set_time(0, 0), set_time(0, 0), 1)
    assert_equal 7, w_week.week_total
    w_week.workpattern(:all, set_time(23, 59), set_time(23, 59), 1)
    assert_equal 14, w_week.week_total
    w_week.workpattern(:all, set_time(0, 0), set_time(23, 59), 1)
    assert_equal 10_080, w_week.week_total
    w_week.workpattern(:weekend, set_time(0, 0), set_time(23, 59), 0)
    assert_equal 7_200, w_week.week_total
  end

  def test_must_add_minutes_in_a_w_week_result_in_same_day
    r_date, r_duration, m_flag = @w_week.calc(Time.gm(2000, 1, 3, 7, 31),29)
    assert_equal Time.gm(2000, 1, 3, 8, 0), r_date
    refute m_flag
    assert_equal 0, r_duration
  end

  def test_must_add_minutes_in_a_w_week_result_in_next_day
    r_date, r_dur, m_flag = @w_week.calc(Time.gm(2000, 1, 3, 7, 31), 990)
    assert_equal Time.gm(2000, 1, 4, 0, 1), r_date
    refute m_flag
    assert_equal 0, r_dur
  end

  def test_must_add_minutes_in_a_w_week_result_in_later_day
    r_date, r_dur, m_flag = @w_week.calc(Time.gm(2000, 1, 3, 7, 31), 2430)
    assert_equal Time.gm(2000, 1, 5, 0, 1), r_date
    refute m_flag
    assert_equal 0, r_dur
  end

  def test_must_add_minutes_in_a_w_week_result_in_start_next_day
    r_date, r_dur, m_flag = @w_week.calc(Time.gm(2000, 1, 3, 7, 31), 989)
    assert_equal Time.gm(2000, 1, 4, 0, 0), r_date
    refute m_flag
    assert_equal 0, r_dur
  end

  def test_must_add_0_minutes_in_a_w_week
    r_date, r_dur, m_flag = @w_week.calc(Time.gm(2000, 1, 3, 7, 31), 0)
    assert_equal Time.gm(2000, 1, 3, 7, 31), r_date
    refute m_flag
    assert_equal 0, r_dur
  end

  def test_must_add_too_many_minutes_in_a_w_week
    r_date, r_dur, m_flag = @w_week.calc(Time.gm(2000, 1, 3, 7, 31), 9630)
    assert_equal Time.gm(2000, 1, 10, 0, 0), r_date
    refute m_flag
    assert_equal 1, r_dur
  end

  def test_must_add_minutes_in_a_resting_week
    r_date, r_dur, m_flag = @r_week.calc(Time.gm(2000, 1, 3, 7, 31), 29)
    assert_equal Time.gm(2000, 1, 10, 0, 0), r_date
    refute m_flag
    assert_equal 29, r_dur
  end

  def test_must_add_minutes_from_start_of_resting_week
    r_date, r_dur, m_flag = @r_week.calc(Time.gm(2000, 1, 3, 0, 0), 990)
    assert_equal Time.gm(2000, 1, 10, 0, 0), r_date
    refute m_flag
    assert_equal 990, r_dur
  end

  def test_must_add_minutes_to_last_minute_of_a_resting_week
    r_date, r_dur, m_flag = @r_week.calc(Time.gm(2000, 1, 9, 23, 59), 2430)
    assert_equal Time.gm(2000, 1, 10, 0, 0), r_date
    refute m_flag
    assert_equal 2_430, r_dur
  end

  def test_must_add_zero_minutes_in_a_resting_week
    r_date, r_dur, m_flag = @r_week.calc(Time.gm(2000, 1, 3, 7, 31), 0)
    assert_equal Time.gm(2000, 1, 3, 7, 31), r_date
    refute m_flag
    assert_equal 0, r_dur
  end

  def test_must_add_minutes_from_working_in_a_pattern_week_result_in_same_day
    r_date, r_dur, m_flag = @p_week.calc(Time.gm(2000, 1, 3, 10, 11), 110)
    assert_equal Time.gm(2000, 1, 3, 12, 1), r_date
    refute m_flag
    assert_equal 0, r_dur
  end

  def test_must_add_minutes_from_resting_in_a_pattern_week_result_in_same_day
    r_date, r_dur, m_flag = @p_week.calc(Time.gm(2000, 1, 3, 12, 45), 126)
    assert_equal Time.gm(2000, 1, 3, 15, 7), r_date
    refute m_flag
    assert_equal 0, r_dur
  end

  def test_must_add_minutes_from_working_in_a_pattern_week_result_in_next_day
    r_date, r_dur, m_flag = @p_week.calc(Time.gm(2000, 1, 3, 10, 11), 379)
    assert_equal Time.gm(2000, 1, 4, 9, 1), r_date
    refute m_flag
    assert_equal 0, r_dur
  end

  def test_must_add_minutes_from_resting_in_a_pattern_week_result_in_next_day
    r_date, r_dur, m_flag = @p_week.calc(Time.gm(2000, 1, 3, 12, 45), 240)
    assert_equal Time.gm(2000, 1, 4, 9, 1), r_date
    refute m_flag
    assert_equal 0, r_dur
  end

  def test_must_add_minutes_from_working_in_a_pattern_week_result_in_later_day
    r_date, r_dur, m_flag = @p_week.calc(Time.gm(2000, 1, 3, 10, 11), 828)
    assert_equal Time.gm(2000, 1, 5, 9, 1), r_date
    refute m_flag
    assert_equal 0, r_dur
  end

  def test_must_add_minutes_from_resting_in_a_w_week_result_in_later_day
    r_date, r_dur, m_flag = @p_week.calc(Time.gm(2000, 1, 3, 12, 45), 689)
    assert_equal Time.gm(2000, 1, 5, 9, 1), r_date
    refute m_flag
    assert_equal 0, r_dur
  end

  def test_must_add_0_minutes_from_working_in_a_resting_week
    r_date, r_dur, m_flag = @p_week.calc(Time.gm(2000, 1, 3, 10, 11), 0)
    assert_equal Time.gm(2000, 1, 3, 10, 11), r_date
    refute m_flag
    assert_equal 0, r_dur
  end

  def test_must_add_0_minutes_from_resting_in_a_resting_week
    r_date, r_dur, m_flag = @p_week.calc(Time.gm(2000, 1, 3, 12, 45), 0)
    assert_equal Time.gm(2000, 1, 3, 12, 45), r_date
    refute m_flag
    assert_equal 0, r_dur
  end

  def test_must_add_too_many_minutes_in_a_pattern__week
    r_date, r_dur, m_flag = @p_week.calc(Time.gm(2000, 1, 3, 10, 11), 2175)
    assert_equal Time.gm(2000, 1, 10, 0, 0), r_date
    refute m_flag
    assert_equal 1, r_dur
  end

  def test_must_subtract_minutes_in_a_w_week_result_in_same_day
    r_date, r_dur, r_day = @w_week.calc(Time.gm(2000, 1, 8, 7, 31), -29)
    assert_equal Time.gm(2000, 1, 8, 7, 2), r_date
    assert_equal Workpattern::SAME_DAY, r_day
    assert_equal 0, r_dur
  end

  def test_must_subtract_minutes_in_a_w_week_result_in_previous_day
    r_date, r_dur, r_day = @w_week.calc(Time.gm(2000, 1, 8, 7, 31), -452)
    assert_equal Time.gm(2000, 1, 7, 23, 59), r_date
    assert_equal Workpattern::SAME_DAY, r_day
    assert_equal 0, r_dur
  end

  def test_must_subtract_minutes_in_a_w_week_result_in_earlier_day
    r_date, r_dur, r_day = @w_week.calc(Time.gm(2000, 1, 8, 7, 31), -1892)
    assert_equal Time.gm(2000, 1, 6, 23, 59), r_date
    assert_equal Workpattern::SAME_DAY, r_day
    assert_equal 0, r_dur
  end

  def test_must_subtract_minutes_in_a_w_week_result_at_start_of_day
    r_date, r_dur, r_day = @w_week.calc(Time.gm(2000, 1, 8, 7, 31), -451)
    assert_equal Time.gm(2000, 1, 8, 0, 0), r_date
    assert_equal Workpattern::SAME_DAY, r_day
    assert_equal 0, r_dur
  end

  def test_must_subtract_minutes_in_a_w_week_result_at_start_of_previous_day
    r_date, r_dur, r_day = @w_week.calc(Time.gm(2000, 1, 8, 7, 31), -1891)
    assert_equal Time.gm(2000, 1, 7, 0, 0), r_date
    assert_equal Workpattern::SAME_DAY, r_day
    assert_equal 0, r_dur
  end

  def test_must_subtract_too_many_minutes_from_a_w_week
    r_date, r_dur, r_day = @w_week.calc(Time.gm(2000, 1, 8, 7, 31), -7652)
    assert_equal Time.gm(2000, 1, 3, 23, 59), r_date
    assert_equal Workpattern::PREVIOUS_DAY, r_day
    assert_equal (-1), r_dur
  end

  def test_must_subtract_1_minute_from_start_of_next_day_after_w_week
    r_date, r_dur, r_day = @w_week.calc(Time.gm(2000, 1, 10, 0, 0), -1,Workpattern::PREVIOUS_DAY)
    assert_equal Time.gm(2000, 1, 9, 23, 59), r_date
    assert_equal Workpattern::SAME_DAY, r_day
    assert_equal 0, r_dur
  end

  def test_must_subtract_2_minutes_from_start_of_next_day_after_w_week
    r_date, r_dur, r_day = @w_week.calc(Time.gm(2000, 1, 10, 0, 0), -2, Workpattern::PREVIOUS_DAY)
    assert_equal Time.gm(2000, 1, 9, 23, 58), r_date
    assert_equal Workpattern::SAME_DAY, r_day
    assert_equal 0, r_dur
  end

  def test_must_subtract_minutes_from_last_day_in_a_resting_week
    r_date, r_dur, r_day = @r_week.calc(Time.gm(2000, 1, 10, 7, 31), -29)
    assert_equal Time.gm(2000, 1, 3, 23, 59), r_date
    assert_equal Workpattern::PREVIOUS_DAY, r_day
    assert_equal (-29), r_dur
  end

  def test_must_subtract_minutes_from_middle_day_in_a_resting_week
    r_date, r_dur, r_day = @r_week.calc(Time.gm(2000, 1, 8, 7, 31), -452)
    assert_equal Time.gm(2000, 1, 3, 23, 59), r_date
    assert_equal Workpattern::PREVIOUS_DAY, r_day
    assert_equal (-452), r_dur
  end

  def test_must_subtract_minutes_from_start_of_resting_week
    r_date, r_dur, r_day = @r_week.calc(Time.gm(2000, 1, 3, 0, 0), -1892)
    assert_equal Time.gm(2000, 1, 3, 0, 0), r_date
    assert_equal Workpattern::PREVIOUS_DAY, r_day
    assert_equal (-1_892), r_dur
  end

  def test_must_subtract_minutes_from_start_of_next_day_after_resting_week
    r_date, r_dur, r_day = @r_week.calc(Time.gm(2000, 1, 9, 0, 0), -1, true)
    assert_equal Time.gm(2000, 1, 3, 23, 59), r_date
    assert_equal Workpattern::PREVIOUS_DAY, r_day
    assert_equal (-1), r_dur
  end

  def test_must_subtract_minutes_from_resting_day_in_a_pattern_week
    r_date, r_dur, r_day = @p_week.calc(Time.gm(2000, 1, 8, 13, 29), -29)
    assert_equal Time.gm(2000, 1, 7, 16, 31), r_date
    assert_equal Workpattern::SAME_DAY, r_day
    assert_equal 0, r_dur
  end

  def test_must_subtract_minutes_from_working_day_in_a_pattern_week
    r_date, r_dur, r_day = @p_week.calc(Time.gm(2000, 1, 7, 13, 29), -29)
    assert_equal Time.gm(2000, 1, 7, 12, 29), r_date
    assert_equal Workpattern::SAME_DAY, r_day
    assert_equal 0, r_dur
  end

  def test_must_subtract_minutes_in_a_pattern_week_result_in_previous_day
    r_date, r_dur, r_day = @p_week.calc(Time.gm(2000, 1, 7, 9, 1), -2)
    assert_equal Time.gm(2000, 1, 6, 16, 59), r_date
    assert_equal Workpattern::SAME_DAY, r_day
    assert_equal 0, r_dur
  end

  def test_must_subtract_minutes_in_a_pattern_week_result_in_earlier_day
    r_date, r_dur, r_day = @p_week.calc(Time.gm(2000, 1, 7, 13, 29), -240)
    assert_equal Time.gm(2000, 1, 6, 16, 58), r_date
    assert_equal Workpattern::SAME_DAY, r_day
    assert_equal 0, r_dur
  end

  def test_must_subtract_minutes_in_a_pattern_week_result_at_start_of_day
    r_date, r_dur, r_day = @p_week.calc(Time.gm(2000, 1, 7, 13, 29), -238)
    assert_equal Time.gm(2000, 1, 7, 9, 0), r_date
    assert_equal Workpattern::SAME_DAY, r_day
    assert_equal 0, r_dur
  end

  def test_must_subtract_minutes_in_a_pattern_week_result_at_start_of_prev_day
    r_date, r_dur, r_day = @p_week.calc(Time.gm(2000, 1, 7, 13, 29), -687)
    assert_equal Time.gm(2000, 1, 6, 9, 0), r_date
    assert_equal Workpattern::SAME_DAY, r_day
    assert_equal 0, r_dur
  end

  def test_must_subtract_too_many_minutes_from_a_pattern_week
    r_date, r_dur, r_day = @p_week.calc(Time.gm(2000, 1, 7, 9, 0), -1797)
    assert_equal Time.gm(2000, 1, 3, 23, 59), r_date
    assert_equal Workpattern::PREVIOUS_DAY, r_day
    assert_equal (-1), r_dur
  end

  def test_must_subtract_1_minute_from_start_of_next_day_after_pattern_week
    r_date, r_dur, r_day = @p_week.calc(Time.gm(2000, 1, 9, 0, 0), -1, true)
    assert_equal Time.gm(2000, 1, 7, 16, 59), r_date
    assert_equal Workpattern::SAME_DAY, r_day
    assert_equal 0, r_dur
  end

  def test_must_subtract_2_minutes_from_start_of_next_day_after_pattern_week
    r_date, r_dur, r_day = @p_week.calc(Time.gm(2000, 1, 9, 0, 0), -2, true)
    assert_equal Time.gm(2000, 1, 7, 16, 58), r_date
    assert_equal Workpattern::SAME_DAY, r_day
    assert_equal 0, r_dur
  end

  def must_diff_day_week_day_in_patterned_week
    start = Time.gm(2013, 9, 23, 0, 0)
    finish = Time.gm(2013, 10, 20, 23, 59)
    w_week = week(start, finish, 1)
    w_week.workpattern :all, set_time(0, 0),
                       set_time(8, 59), 0
    w_week.workpattern :all, set_time(12, 0),
                       set_time(12, 59), 0
    w_week.workpattern :all, set_time(18, 0),
                       set_time(23, 59), 0
    s_date = Time.gm(2013, 10, 3, 16, 0)
    f_date = Time.gm(2013, 10, 15, 12, 30)
    duration, start = w_week.diff(s_date, f_date)

    assert_equal 5_640, duration
    assert_equal Time.gm(2013, 10, 15, 12, 30), start
  end

  def test_must_calculate_difference_between_dates_in_w_week
    late_date = Time.gm(2000, 1, 6, 9, 32)
    early_date = Time.gm(2000, 1, 6, 8, 20)
    result_dur, r_date = @w_week.diff(early_date, late_date)
    assert_equal 72, result_dur
    assert_equal late_date, r_date
  end

  def test_must_calculate_difference_between_dates_in_resting_week
    late_date = Time.gm(2000, 1, 6, 9, 32)
    early_date = Time.gm(2000, 1, 6, 8, 20)
    result_dur, r_date = @r_week.diff(early_date, late_date)
    assert_equal 0, result_dur
    assert_equal late_date, r_date
  end

  def test_must_calculate_difference_between_dates_in_pattern_week
    late_date = Time.gm(2000, 1, 6, 13, 1)
    early_date = Time.gm(2000, 1, 6, 12, 29)
    result_dur, r_date = @p_week.diff(early_date, late_date)
    assert_equal 1, result_dur
    assert_equal late_date, r_date
  end

  def test_must_diff_from_last_day_of_patterned_week
    # #issue 15
    start = Time.gm(2013, 9, 23, 0, 0)
    finish = Time.gm(2013, 9, 26, 23, 59)
    w_week = week(start, finish, 1)
    w_week.workpattern :all, set_time(0, 0),
                       set_time(8, 59), 0
    w_week.workpattern :all, set_time(12, 0),
                       set_time(12, 59), 0
    w_week.workpattern :all, set_time(18, 0),
                       set_time(23, 59), 0

    s_date = Time.gm(2013, 9, 26, 17, 0)
    f_date = Time.gm(2013, 9, 27, 10, 0)
    duration, start = w_week.diff(s_date, f_date)

    assert_equal 60, duration
    assert_equal Time.gm(2013, 9, 27, 0, 0), start
  end

  def test_must_diff_long_distances_beyond_end_of_patterned_week
    start = Time.gm(2013, 9, 23, 0, 0)
    finish = Time.gm(2013, 10, 20, 23, 59)
    w_week = week(start, finish, 1)
    w_week.workpattern :all, set_time(0, 0),
                       set_time(8, 59), 0
    w_week.workpattern :all, set_time(12, 0),
                       set_time(12, 59), 0
    w_week.workpattern :all, set_time(18, 0),
                       set_time(23, 59), 0

    s_date = Time.gm(2013, 9, 26, 17, 0)
    f_date = Time.gm(2018, 9, 27, 10, 0)
    duration, start = w_week.diff(s_date, f_date)

    assert_equal 11_580, duration
    assert_equal Time.gm(2013, 10, 21, 0, 0), start
  end

  def test_must_diff_long_distances_within_patterned_week
    start = Time.gm(2013, 9, 23, 0, 0)
    finish = Time.gm(2013, 10, 20, 23, 59)
    w_week = week(start, finish, 1)
    w_week.workpattern :all, set_time(0, 0),
                       set_time(8, 59), 0
    w_week.workpattern :all, set_time(12, 0),
                       set_time(12, 59), 0
    w_week.workpattern :all, set_time(18, 0),
                       set_time(23, 59), 0

    s_date = Time.gm(2013, 9, 26, 17, 0)
    f_date = Time.gm(2013, 10, 15, 10, 0)
    duration, start = w_week.diff(s_date, f_date)

    assert_equal 8_760, duration
    assert_equal Time.gm(2013, 10, 15, 10, 0), start
  end

  private

  def week(start, finish, type)
    Workpattern::Week.new(start, finish, type)
  end

  def set_time(hour,min)
    Time.gm(1963,6,10,hour,min)
  end  
end
