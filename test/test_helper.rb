require 'minitest/autorun'
require File.dirname(__FILE__) + '/../lib/workpattern.rb'

if RUBY_VERSION < "2"
    class WorkpatternTest < MiniTest::Unit::TestCase
    end
else
    class WorkpatternTest < MiniTest::Test
    end
end
