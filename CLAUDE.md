# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Workpattern is a Ruby gem that calculates dates and durations while accounting for working and non-working times. It creates calendars similar to project scheduling software like Microsoft Project and Primavera P6.

**Key Features:**
- Date arithmetic that respects working hours and rest periods
- Configurable work patterns (weekdays, weekends, custom schedules)
- Support for vacations and holidays
- Duration calculations between dates
- Minute-level precision for all calculations

## Common Commands

### Testing
```bash
# Run all tests
rake test

# Run a single test file
ruby test/test_workpattern.rb

# Run a specific test method
ruby test/test_workpattern.rb -n test_must_follow_the_example_in_workpattern
```

### Building and Installation
```bash
# Install dependencies
bundle install

# Build the gem
rake build

# Install the gem locally
gem install workpattern

# Interactive console for testing
rake console
```

## Architecture

### Core Data Structure: Binary Minute Representation

The library uses a clever binary representation for time patterns:
- Each minute in a day is represented by a single bit in a binary number
- A `1` bit = working minute, `0` bit = resting minute
- A 24-hour day = 1440 minutes = up to 2^1440 possible patterns
- Bitwise operations (AND, OR) efficiently apply working/resting patterns

### Class Hierarchy

**Workpattern** (lib/workpattern/workpattern.rb)
- Top-level class that users interact with
- Manages a collection of `Week` patterns across a date range
- Provides `calc()`, `diff()`, `working?()`, and `resting?()` methods
- Handles timezone conversions (UTC internally, local time for API)
- Stored in class variable `@@workpatterns` hash by name

**WeekPattern** (lib/workpattern/week_pattern.rb)
- Coordinates pattern changes across the workpattern's date range
- Splits and clones `Week` objects when patterns change
- Handles the complex logic of applying patterns to date ranges

**Week** (lib/workpattern/week.rb)
- Represents a date range with 7 `Day` objects (Sun-Sat)
- Optimizes calculations by processing full weeks at once
- Contains logic for adding/subtracting durations and calculating diffs
- Each `Week` has a start and finish date defining its validity range

**Day** (lib/workpattern/day.rb)
- Stores the binary pattern for a single day (which minutes are working)
- Implements `working_minutes()` by counting `1` bits in the pattern
- Binary search algorithms to find first/last working minutes
- Handles minute-level date arithmetic within a day

**Clock** (lib/workpattern/clock.rb)
- Simple value object representing hour and minute
- Used for specifying working/resting time ranges
- Alternative to using `DateTime` or `Time` objects

### Important Patterns

**Date Range Splitting:**
When applying a pattern to a date range that crosses existing week patterns, the library clones and splits `Week` objects to maintain the correct pattern for each range.

**Calculation Flow:**
1. Convert input date to UTC
2. Find the `Week` pattern containing that date
3. Use `Week.calc()` to add/subtract duration
4. If duration remains, move to next/previous week
5. Optimize by skipping full weeks when possible
6. Convert result back to local time

**Diff Calculation:**
Similar to `calc()` but counts working minutes between two dates by iterating through days and weeks, using `Day.working_minutes()` to count bits.

### Constants (lib/workpattern/constants.rb)

- `WORK_TYPE = 1`, `REST_TYPE = 0`: Pattern types
- `DAYNAMES`: Hash mapping symbols like `:weekday`, `:weekend` to day arrays
- Time constants: `MINUTE = 60`, `HOUR = 3600`, `DAY = 86400`
- `DEFAULT_BASE_YEAR = 2000`, `DEFAULT_SPAN = 100`: Default workpattern range

## Key Implementation Details

### Time Handling
- All internal calculations use `Time.gm()` (UTC)
- API accepts and returns local time objects
- Dates are normalized to midnight (00:00:00) when finding week patterns

### Working with Patterns
- The `workpattern()` method is the core pattern-setting method
- `working()` and `resting()` are convenience wrappers
- Patterns can be applied to specific days (`:mon`, `:tue`, etc.), `:weekday`, `:weekend`, or `:all`
- Time ranges use `from_time` and `to_time` parameters (defaults to full day)

### Test Framework
- Uses Minitest (v5.25.3)
- Tests inherit from `WorkpatternTest` base class
- Each test calls `Workpattern.clear` in setup to reset state
- Test pattern: create workpattern, configure patterns, assert calculations

### Performance Considerations
- Some tests are commented out with "TODO: Speed this up" or "TODO: improve performance"
- Full week optimizations exist to skip calculating individual days when possible
- Binary operations on patterns are fast, but large date ranges can be slow

## Ruby Version Requirements

- Requires Ruby >= 3.0.0 (specified in gemspec)
- Recent commits removed support for Ruby < 3.0.0
- Uses `SortedSet` (requires explicit require for Ruby >= 2.4)

## Dependencies

Runtime dependencies:
- `tzinfo`: Timezone handling
- `sorted_set`: Maintains ordered collection of week patterns

Development dependencies:
- `rake ~> 13.0`: Task runner
- `minitest ~> 5.25.3`: Testing framework
