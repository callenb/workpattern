require File.dirname(__FILE__) + '/test_helper.rb'

class TestDay < MiniTest::Unit::TestCase #:nodoc:

  def test_must_create_a_default_day_as_working
    working_day = Workpattern::Day.new()
    assert_equal (24*60), working_day.total
  end

end
