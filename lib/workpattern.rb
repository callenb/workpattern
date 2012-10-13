#--
# Copyright (c) 2011 Barrie Callender
#
# email: barrie@callenb.org
#++
$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'date'
require 'workpattern/utility/base.rb'
require 'workpattern/clock'
require 'workpattern/hour'
require 'workpattern/day'
require 'workpattern/week'
require 'workpattern/workpattern'

#
# workpattern.rb - date calculation library that takes into account patterns of
# working and resting time and is aimed at supporting scheduling applications such 
# as critical path analysis.
#
# Author:        Barrie Callender 2011
#
# Documentation: Barrie Callender <barrie@callenb.org>
#
module Workpattern
  
  # Represents a full working hour
  WORKING_HOUR = 2**60-1
  
  # Represents a full resting hour
  RESTING_HOUR = 0
  
  # The default workpattern name
  DEFAULT_WORKPATTERN_NAME = 'default'
  
  # The default base year
  DEFAULT_BASE_YEAR = 2000
  
  # The default span in years
  DEFAULT_SPAN = 100
  
  # Hour in terms of days
  HOUR = Rational(1,24)
  
  # Minute in terms of days
  MINUTE = Rational(1,1440)
  
  # Earliest or first time in the day
  FIRST_TIME_IN_DAY=Clock.new(0,0)
  
  # Latest or last time in the day
  LAST_TIME_IN_DAY=Clock.new(23,59)
  
  # Specifies a working pattern
  WORK = 1
  
  # Specifies a resting pattern
  REST = 0
  
  # Represents the days of the week to be used in applying working and resting patterns.
  # Values exist for each day of the week as well as for the weekend (Saturday and Sunday), 
  # the week (Monday to Friday) and all days in the week.
  #
  DAYNAMES={:sun => [0],:mon => [1], :tue => [2], :wed => [3], :thu => [4], :fri => [5], :sat => [6],
              :weekday => [1,2,3,4,5],
              :weekend => [0,6],
              :all => [0,1,2,3,4,5,6]}
              
  # Covenience method to obtain a new <tt>Workpattern</tt> 
  #
  # A negative <tt>span</tt> counts back from the <tt>base</tt> year
  #
  # @param [String] name Every workpattern has a unique name.
  # @param [Fixnum] base Workpattern starts on the 1st January of this year.
  # @param [Fixnum] span Workpattern spans this number of years ending on 31st December.
  # @return [Workpattern]
  def self.new(name=DEFAULT_WORKPATTERN_NAME, base=DEFAULT_BASE_YEAR, span=DEFAULT_SPAN)
    return Workpattern.new(name, base,span)
  end
  
  # Covenience method to obtain an Array of all the known <tt>Workpattern</tt> objects
  #
  # @return [Array] all <tt>Workpattern</tt> objects
  #
  def self.to_a()
    return Workpattern.to_a
  end

  # Covenience method to obtain an existing <tt>Workpattern</tt> 
  #
  # @param [String] name The name of the Workpattern to retrieve.
  # @return [Workpattern]
  #
  def self.get(name)
    return Workpattern.get(name)
  end
  
  # Convenience method to delete the named <tt>Workpattern</tt>
  #
  # @param [String] name The name of the Workpattern to be deleted.
  #
  def self.delete(name)
    Workpattern.delete(name)
  end
   
  # Convenience method to delete all Workpatterns.
  # 
  def self.clear
    Workpattern.clear
  end
  
  # Convenience method to create a Clock object.  This can be used for specifying times 
  # if you don't want to create a <tt>DateTime</tt> object
  # 
  # @param [Fixnum] hour the number of hours.
  # @param [Fixnum] min the number of minutes
  # @return [Clock]
  # @see Clock
  #
  def self.clock(hour,min)
    return Clock.new(hour,min)
  end
end
