#--
# Copyright (c) 2011 Barrie Callender
#
# email: barrie@callenb.org
#++
$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
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
# == Overview
#
# The core Ruby classes that represent date and time allow calculations by
# adding a duration such as days or minutes to a date and returning the new
# #Date or #DateTime as the result. 
#
# Although there are 60 seconds in every minute and 60 minutes in every hour, there
# aren't always 24 hours in every day, and if there was, we still wouldn't
# be working during all of them.  We'll would be doing other things like eating,
# sleeping, travelling and having a bit of leisure time.  Workpattern calls this 
# Resting.
#
# When it comes to scheduling work, whether part of a project, teachers in a 
# classroom or even bed availability in a hospital, the working day can have
# anything from 0 hours to the full 24 hours.  Most office based work
# is something like 7.5 or 8 hours a day except weekends, public holidays and
# vacations when no work takes place.
#
# The #Workpattern library was born to allow date related calculations to take 
# into account real life working and resting times.  It gets told about working
# and resting periods and can then perform calculations on a given date.  It can
# add and subtract a number of minutes, calculate the working minutes between
# two dates and say with a specific minute is working or resting.
#
# == Illustration
#
# In real life we may be reasonably confident that it will take us 32 hours to
# write a document.  If we started on a Thursday at 9:00am we wouldn't be
# working 32 hours without interruption (let's pretend we're not software
# developers for this one!).  We'd go home at the end of one working day and
# not return until the next.  We'd also not do anything on the weekend.  We
# would probably work 8 hours on Thursday, Friday, Monday and Tuesday to
# complete the work.
#
# This library will be able to tell you that if you started at 9:00 am on
# Thursday, you should be finished at 6:00 pm on Tuesday - allowing an hour
# for lunch each day!  For it to do that it has to know when you can work and
# when you are resting.
#
# == An Example Session
# 
# Using the illustration as a basis, we want to find out when I will finish the document.
# It is going to take me 32 hours to complete the document and I'm going to start on it 
# as soon as I arrive at work on the morning of Thursday 1st September 2011.  My working
# day starts at 9:00am,finishes at 6:00pm and I take an hour for lunch. I don't work 
# on the weekend.
#
# The first step is to create a #Workpattern to hold all the working and resting times.
# I'll start in 2011 and let it run for 10 years.
#
#  mywp=Workpattern.new('My Workpattern',2011,10)
#
# My #Workpattern will be created as a 24 hour a day full working time.  Now it has to 
# be told about the resting periods.  First the weekends.
#
#  mywp.resting(:days => :weekend)
# 
# then the days in the week ...
#
#  mywp.resting(:Weekday, :from_time=>'0:0',:to_time=>'8:59')
#  mywp.resting(:Weekday, :from_time=>'12:0',:to_time=>'12:59')
#  mywp.resting(:Weekday, :from_time=>'18:0',:to_time=>'23:59')
#
# Now we have the working and resting periodssetup we can just add 32 hours as 
# minutes (115,200) to our date.
#
#  mydate=DateTime.civil(2011,09,01,9,0)
#  mywp.calc(mydate,115200) # => 6/9/11@18:00
#
# == Things To Do
#
# In its current form this library is being made available to see if there is any interest
# in using it.  At the moment it can perform the following:
# * define the working and resting minutes for any 24 hour day
# * given a date it can return the resulting date after adding or subtracting a number of minutes
# * calculate the number of working minutes between two dates
# * report whether a specific minute in time is working or resting
# This is what I consider to be the basics, butthere are a number of functional and 
# non-functial areas I would like to address in a future version
#
# === Functional
#
# * Merge two Workpatterns together to create a new one allowing either resting or working to take precedence
# * Given a date, find the next working or resting minute either before or after it.
# * Handle both 23 and 25 hour days that occur when the clocks change.
# * Extract patterns from the workpattern so they can be persisted in a database.
# * Decide how to handle different Timezones apart from UTC.
#
# === Non-Functional
#
# * Improve the documentation and introduce real world use as an example
# * Write better Ruby code
#
module Workpattern
  
  # Workpattern version number
  VERSION = '0.0.1'
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
  # Represents the days of the week to be used in applying working and resting patterns.
  #
  # ==== Valid Values
  #
  # <tt>:sun, :mon, :tue, :wed, :thu, :fri, :sat</tt> a day of the week.
  # <tt>:all</tt> all days of the week.
  # <tt>:weekend</tt> Saturday and Sunday.
  # <tt>:weekday</tt> Monday to Friday inclusive.
  #
  DAYNAMES={:sun => [0],:mon => [1], :tue => [2], :wed => [3], :thu => [4], :fri => [5], :sat => [6],
              :weekday => [1,2,3,4,5],
              :weekend => [0,6],
              :all => [0,1,2,3,4,5,6]}
              
  # :call-seq: new(name, base, span) => workpattern 
  #
  # Covenience method to obtain a new #Workpattern::Workpattern 
  #
  # ==== Parameters
  #
  # +name+:: 
  #   Every workpattern has a unique name.
  # +base+:: 
  #   The starting year for the range of dates the Calendar
  #   can use.  Always the 1st january.
  # +span+:: 
  #   Duration of the Calendar in years.  If <tt>span</tt> is negative
  #   then the range counts backwards from the <tt>base</tt>.
  #
  def self.new(name=DEFAULT_WORKPATTERN_NAME, base=DEFAULT_BASE_YEAR, span=DEFAULT_SPAN)
    return Workpattern.new(name, base,span)
  end
  
  # :call-seq: to_a => array 
  #
  # Covenience method to obtain an Array of all the known Workpattern::Workpattern objects
  #
  def self.to_a()
    return Workpattern.to_a
  end

  # :call-seq: get(name) => workpattern 
  #
  # Covenience method to obtain an existing Workpattern::Workpattern 
  #
  # ==== Parameters
  #
  # +name+:: The name of the Workpattern.
  #
  def self.get(name)
    return Workpattern.get(name)
  end
  
  # :call-seq: delete(name) => boolean 
  #
  # Convenience method to delete the named Workpattern::Workpattern
  #
  # === Parameters
  #
  # +name+:: The name of the Workpattern.
  #
  def self.delete(name)
    Workpattern.delete(name)
  end
   
  # :call-seq: clear
  #
  # Convenience method to delete all Workpatterns.
  # 
  def self.clear
    Workpattern.clear
  end
  
  
end
