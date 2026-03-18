# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/test_helper.rb"

class TestWorkpatternRegistry < WorkpatternTest # :nodoc:
  def test_must_register_workpattern_with_defaults
    wp = Workpattern.new
    WorkpatternRegistry.register(wp)
    fetched_wp = WorkpatternRegistry.find(Workpattern::DEFAULT_WORKPATTERN_NAME)

    assert_equal Workpattern::DEFAULT_WORKPATTERN_NAME, fetched_wp.name,
                 'WorkpatternRegistry has not returned the default workpattern name'
  end
end
