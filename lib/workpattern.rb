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
  # @since 0.2.0
  WORKING_HOUR = 2**60-1
  
  # Represents a full resting hour
  # @since 0.2.0  
  RESTING_HOUR = 0
  
  # The default workpattern name
  # @since 0.2.0  
  DEFAULT_WORKPATTERN_NAME = 'default'
  
  # The default base year
  # @since 0.2.0
  DEFAULT_BASE_YEAR = 2000
  
  # The default span in years
  # @since 0.2.0
  DEFAULT_SPAN = 100
  
  # Hour in terms of days
  # @since 0.2.0
  HOUR = Rational(1,24)
  
  # Minute in terms of days
  # @since 0.2.0
  MINUTE = Rational(1,1440)
  
  # Earliest or first time in the day
  # @since 0.0.1
  FIRST_TIME_IN_DAY=Clock.new(0,0)
  
  # Latest or last time in the day
  # @since 0.0.1
  LAST_TIME_IN_DAY=Clock.new(23,59)
  
  # Specifies a working pattern
  # @since 0.0.1
  WORK = 1
  
  # Specifies a resting pattern
  # @since 0.0.1
  REST = 0
  
  # Represents the days of the week to be used in applying working and resting patterns.
  # Values exist for each day of the week as well as for the weekend (Saturday and Sunday), 
  # the week (Monday to Friday) and all days in the week.
  #
  # @since 0.0.1
  DAYNAMES={:sun => [0],:mon => [1], :tue => [2], :wed => [3], :thu => [4], :fri => [5], :sat => [6],
              :weekday => [1,2,3,4,5],
              :weekend => [0,6],
              :all => [0,1,2,3,4,5,6]}
              
  # Covenience method to obtain a new <tt>Workpattern</tt> 
  #
  # A negative <tt>span</tt> counts back from the <tt>base</tt> year
  #
  # @param [String] name Every workpattern has a unique name.
  # @param [Integer] base Workpattern starts on the 1st January of this year.
  # @param [Integer] span Workpattern spans this number of years ending on 31st December.
  # @return [Workpattern]
  # @raise [NameError] when trying to create a Workpattern with a name that already exists
  # @since 0.2.0
  #
  def self.new(name=DEFAULT_WORKPATTERN_NAME, base=DEFAULT_BASE_YEAR, span=DEFAULT_SPAN)
    return Workpattern.new(name, base,span)
  end
  
  # Covenience method to obtain an Array of all the known <tt>Workpattern</tt> objects
  #
  # @return [Array] all <tt>Workpattern</tt> objects
  #
  # @since 0.2.0
  #
  def self.to_a()
    return Workpattern.to_a
  end

  # Covenience method to obtain an existing <tt>Workpattern</tt> 
  #
  # @param [String] name The name of the Workpattern to retrieve.
  # @return [Workpattern]
  #
  # @since 0.2.0
  #
  def self.get(name)
    return Workpattern.get(name)
  end
  
  # Convenience method to delete the named <tt>Workpattern</tt>
  #
  # @param [String] name The name of the Workpattern to be deleted.
  #
  # @since 0.2.0
  #
  def self.delete(name)
    Workpattern.delete(name)
  end
   
  # Convenience method to delete all Workpatterns.
  # 
  # @since 0.2.0
  #
  def self.clear
    Workpattern.clear
  end
  
  # Convenience method to create a Clock object.  This can be used for specifying times 
  # if you don't want to create a <tt>DateTime</tt> object
  # 
  # @param [Integer] hour the number of hours.
  # @param [Integer] min the number of minutes
  # @return [Clock]
  # @see Clock
  #
  # @since 0.2.0
  #
  def self.clock(hour,min)
    return Clock.new(hour,min)
  end
end
