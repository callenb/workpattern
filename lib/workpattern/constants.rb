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

  # Flags for calculations
  PREVIOUS_DAY = -1
  SAME_DAY = 0
  NEXT_DAY = 1

  # Specifies a working pattern
  WORK_TYPE = 1

  # Specifies a resting pattern
  REST_TYPE = 0

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
end
