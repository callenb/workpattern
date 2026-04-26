require File.dirname(__FILE__) + '/test_helper.rb'

class TestWorkpatternSerialisation < WorkpatternTest
  def setup
    Workpattern.clear
  end

  # 1. to_h basic structure
  def test_to_h_includes_version_1
    wp = Workpattern.new('basic', 2020, 1)
    assert_equal 1, wp.to_h[:version]
  end

  def test_to_h_includes_name_base_span
    wp = Workpattern.new('myname', 2021, 3)
    h = wp.to_h
    assert_equal 'myname', h[:name]
    assert_equal 2021,     h[:base]
    assert_equal 3,        h[:span]
  end

  def test_to_h_includes_weeks_array_with_start_finish_days
    wp = Workpattern.new('struct', 2020, 1)
    h = wp.to_h
    assert_instance_of Array, h[:weeks]
    refute_empty h[:weeks]
    wh = h[:weeks].first
    assert wh.key?(:start)
    assert wh.key?(:finish)
    assert wh.key?(:days)
    assert_equal 7, wh[:days].length
  end

  # 2. to_h is idempotent
  def test_to_h_is_idempotent
    wp = Workpattern.new('idem', 2020, 2)
    wp.resting(days: :weekend)
    assert_equal wp.to_h, wp.to_h
  end

  # 3. from_h missing :version raises ArgumentError
  def test_from_h_missing_version_raises_argument_error
    err = assert_raises(ArgumentError) { Workpattern.from_h({}) }
    assert_match(/version/, err.message)
  end

  # 4. from_h unsupported version raises ArgumentError with version in message
  def test_from_h_unsupported_version_raises_argument_error
    err = assert_raises(ArgumentError) do
      Workpattern.from_h({ version: 99, name: 'x', base: 2020, span: 1, weeks: [] })
    end
    assert_match(/99/, err.message)
    assert_match(/unsupported/, err.message)
  end

  # 5. from_h name conflict raises NameError (AE1)
  def test_from_h_name_conflict_raises_name_error
    wp = Workpattern.new('conflict', 2020, 1)
    err = assert_raises(NameError) { Workpattern.from_h(wp.to_h) }
    assert_match(/conflict/, err.message)
  end

  # 6. from_h name conflict with overwrite: true succeeds (AE2)
  def test_from_h_overwrite_replaces_existing
    wp = Workpattern.new('overwrite_me', 2020, 1)
    wp.resting(days: :weekend)
    h = wp.to_h
    wp2 = Workpattern.from_h(h, overwrite: true)
    assert_instance_of Workpattern::Workpattern, wp2
    assert_equal 'overwrite_me', wp2.name
    saturday = Time.gm(2020, 6, 6, 12, 0)
    assert_equal false, wp2.working?(saturday)
  end

  # 7. Round-trip: all-working workpattern
  def test_round_trip_all_working
    wp = Workpattern.new('all_working', 2020, 2)
    h = wp.to_h
    Workpattern.delete('all_working')
    wp2 = Workpattern.from_h(h)
    t1 = Time.gm(2020, 6, 1, 9, 0)
    t2 = Time.gm(2020, 6, 1, 17, 0)
    assert_equal wp.diff(t1, t2), wp2.diff(t1, t2)
    assert_equal wp.working?(t1), wp2.working?(t1)
    assert_equal wp.calc(t1, 480), wp2.calc(t1, 480)
  end

  # 8. Round-trip: resting weekends
  def test_round_trip_resting_weekends
    wp = Workpattern.new('weekends_off', 2020, 2)
    wp.resting(days: :weekend)
    h = wp.to_h
    Workpattern.delete('weekends_off')
    wp2 = Workpattern.from_h(h)
    saturday = Time.gm(2020, 6, 6, 12, 0)  # a Saturday
    monday   = Time.gm(2020, 6, 8, 12, 0)  # a Monday
    assert_equal false, wp2.working?(saturday)
    assert_equal true,  wp2.working?(monday)
    assert_equal wp.diff(saturday, monday), wp2.diff(saturday, monday)
  end

  # 9. Round-trip: business hours 09:00-17:00 weekdays (AE3)
  def test_round_trip_business_hours
    wp = Workpattern.new('biz_hours', 2020, 3)
    wp.resting(days: :weekend)
    wp.resting(days: :weekday,
               from_time: Workpattern.clock(0, 0),
               to_time:   Workpattern.clock(8, 59))
    wp.resting(days: :weekday,
               from_time: Workpattern.clock(17, 0),
               to_time:   Workpattern.clock(23, 59))
    h = wp.to_h
    Workpattern.delete('biz_hours')
    wp2 = Workpattern.from_h(h)

    # weekday morning — resting at 08:00, working at 09:00
    monday_morning = Time.gm(2020, 6, 8, 8, 0)
    monday_nine    = Time.gm(2020, 6, 8, 9, 0)
    assert_equal wp.working?(monday_morning), wp2.working?(monday_morning)
    assert_equal wp.working?(monday_nine),    wp2.working?(monday_nine)

    # diff across a full business day
    t1 = Time.gm(2020, 6, 8, 9, 0)
    t2 = Time.gm(2020, 6, 8, 17, 0)
    assert_equal wp.diff(t1, t2), wp2.diff(t1, t2)

    # calc: add 480 minutes from monday 09:00
    assert_equal wp.calc(t1, 480), wp2.calc(t1, 480)

    # diff spanning a weekend
    t3 = Time.gm(2020, 6, 5, 9, 0)   # Friday
    t4 = Time.gm(2020, 6, 8, 17, 0)  # Monday
    assert_equal wp.diff(t3, t4), wp2.diff(t3, t4)
  end

  # 10. from_h registers the workpattern — Workpattern.get returns it
  def test_from_h_registers_in_registry
    wp = Workpattern.new('registered', 2020, 1)
    h = wp.to_h
    Workpattern.delete('registered')
    Workpattern.from_h(h)
    assert_instance_of Workpattern::Workpattern, Workpattern.get('registered')
  end

  # 11. from_h overwrite: true — registry has exactly one entry for the name
  def test_from_h_overwrite_no_duplicate_in_registry
    wp = Workpattern.new('unique', 2020, 1)
    h = wp.to_h
    Workpattern.from_h(h, overwrite: true)
    names = Workpattern.workpatterns.keys.select { |k| k == 'unique' }
    assert_equal 1, names.length
  end

  # 12. from_h with string-keyed hash (JSON default) raises ArgumentError with symbolize_names hint
  def test_from_h_string_keys_gives_actionable_error
    # Simulate JSON.parse without symbolize_names: true
    string_keyed = { 'version' => 1, 'name' => 'strkeys', 'base' => 2020, 'span' => 1, 'weeks' => [] }
    err = assert_raises(ArgumentError) { Workpattern.from_h(string_keyed) }
    assert_match(/symbolize_names/, err.message)
  end

  # 13. overwrite: true with malformed hash leaves original intact
  def test_from_h_overwrite_malformed_preserves_original
    wp = Workpattern.new('atomic', 2020, 1)
    wp.resting(days: :weekend)
    bad_hash = wp.to_h.merge(weeks: [{ start: {year:2020,month:1,day:1}, finish: {year:2020,month:12,day:31}, days: nil }])
    assert_raises(NoMethodError) { Workpattern.from_h(bad_hash, overwrite: true) }
    assert_instance_of Workpattern::Workpattern, Workpattern.get('atomic')
    saturday = Time.gm(2020, 6, 6, 12, 0)
    assert_equal false, Workpattern.get('atomic').working?(saturday)
  end

  # 14. Round-trip: negative span
  def test_round_trip_negative_span
    wp = Workpattern.new('neg_span', 2020, -2)
    h = wp.to_h
    Workpattern.delete('neg_span')
    wp2 = Workpattern.from_h(h)
    assert_equal wp.from, wp2.from
    assert_equal wp.to,   wp2.to
    assert_equal wp.span, wp2.span
    t1 = Time.gm(2019, 6, 1, 9, 0)
    assert_equal wp.working?(t1), wp2.working?(t1)
  end
end
