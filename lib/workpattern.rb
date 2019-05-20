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
require 'workpattern/constants'
require 'workpattern/day'
require 'workpattern/week'
require 'workpattern/workpattern'
require 'workpattern/week_pattern'

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
