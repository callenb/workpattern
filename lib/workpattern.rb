$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'workpattern/hour'

module Workpattern
  VERSION = '0.0.1'
  WORKING_HOUR = 2**60-1
  RESTING_HOUR = 0
end
