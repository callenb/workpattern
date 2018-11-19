#--
# Copyright (c) 2011 Barrie Callender
#
# email: barrie@callenb.org
#++
$LOAD_PATH.unshift(File.dirname(__FILE__)) unless
  $LOAD_PATH.include?(File.dirname(__FILE__)) || $LOAD_PATH.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'date'
require 'workpattern/clock'
require 'workpattern/week'
require 'workpattern/workpattern'

#
# workpattern.rb - date calculation library that takes into account patterns of
# working and resting time and is aimed at supporting scheduling applications
# such as critical path analysis.
#
# Author:        Barrie Callender 2011
#
# Documentation: Barrie Callender <barrie@callenb.org>
#
module Workpattern

  # default name of a new Workpattern
  DEFAULT_WORKPATTERN_NAME = 'default'.freeze
  
  # default base year for a new workpattern
  DEFAULT_BASE_YEAR = 2000

  # default span of years for a new Workpattern
  DEFAULT_SPAN = 100

  # 60 seconds in a minute
  MINUTE = 60

  # 60 minutes in an hour
  HOUR = MINUTE * 60

  # 24 hours in a day
  HOURS_IN_DAY = 24

  # Seconds in a day
  DAY = HOUR * HOURS_IN_DAY

  # 60 minutes in a working hour as binary bit per minute
  WORKING_HOUR = 2**MINUTE - 1

  # 0 minutes in a working hour as binary bits per minute
  RESTING_HOUR = 0

  # Earliest or first time in the day
  FIRST_TIME_IN_DAY = Clock.new(0, 0)

  # Latest or last time in the day
  LAST_TIME_IN_DAY = Clock.new(23, 59)

  # Specifies a working pattern
  WORK = 1

  # Specifies a resting pattern
  REST = 0

  # All the days of the week
  SUNDAY=0
  MONDAY=1
  TUESDAY=2
  WEDNESDAY=3
  THURSDAY=4
  FRIDAY=5
  SATURDAY=6
  
  # first and last day of week
  FIRST_DAY_OF_WEEK = SUNDAY
  LAST_DAY_OF_WEEK = SATURDAY

  # Represents the days of the week to be used in applying working
  # and resting patterns.
  # Values exist for each day of the week as well as for the weekend
  # (Saturday and Sunday), 
  # the week (Monday to Friday) and all days in the week.
  #
  daynames = { sun: [0], mon: [1], tue: [2], wed: [3],
               thu: [4], fri: [5], sat: [6], 
               weekday: [1, 2, 3, 4, 5], 
               weekend: [0, 6], 
               all: [0, 1, 2, 3, 4, 5, 6] }
  DAYNAMES = daynames.freeze
  # Covenience method to obtain a new <tt>Workpattern</tt>
  #
  # A negative <tt>span</tt> counts back from the <tt>base</tt> year
  #
  # @param [String] name Every workpattern has a unique name.
  # @param [Integer] base Workpattern starts on the 1st January of this year.
  # @param [Integer] number of years ending on 31st December.
  # @return [Workpattern]
  # @raise [NameError] creating a Workpattern with a name that already exists
  #
  def self.new(name = DEFAULT_WORKPATTERN_NAME,
               base = DEFAULT_BASE_YEAR,
               span = DEFAULT_SPAN)
    Workpattern.new(name, base, span)
  end

  # Covenience method to obtain an Array of all the known <tt>Workpattern</tt>
  # objects
  #
  # @return [Array] all <tt>Workpattern</tt> objects
  #
  def self.to_a
    Workpattern.to_a
  end

  # Covenience method to obtain an existing <tt>Workpattern</tt>
  #
  # @param [String] name The name of the Workpattern to retrieve.
  # @return [Workpattern]
  #
  def self.get(name)
    Workpattern.get(name)
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

  # Convenience method to create a Clock object.  This can be used for
  # specifying times if you don't want to create a <tt>DateTime</tt> object
  #
  # @param [Integer] hour the number of hours.
  # @param [Integer] min the number of minutes
  # @return [Clock]
  # @see Clock
  #
  def self.clock(hour, min)
    Clock.new(hour, min)
  end

end
