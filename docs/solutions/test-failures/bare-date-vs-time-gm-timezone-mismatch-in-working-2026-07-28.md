---
title: Bare Date arguments to #working?/#calc/#diff resolve to the wrong day off-UTC
date: 2026-07-28
category: docs/solutions/test-failures
module: workpattern
problem_type: test_failure
component: testing_framework
symptoms:
  - "wp.working?(date) returns true (working) for a date just marked resting via #resting, when date is a bare Date object"
  - "Expected true to not be truthy at test/test_workpattern_holidays.rb:17 (Minitest failure)"
  - "Failure only reproduces when the host system's local timezone is not UTC (e.g. BST, UTC+1)"
root_cause: logic_error
resolution_type: test_fix
severity: medium
tags: [timezone, date-vs-time, working, to_utc, bst, test-authoring-convention]
---

# Bare Date arguments to #working?/#calc/#diff resolve to the wrong day off-UTC

## Problem

`Workpattern#working?` (and `#calc`/`#diff`) silently interpret a bare `Date` argument as one day earlier than `#resting` does, whenever the system clock isn't UTC, because `#working?` converts dates via `Date#to_time` (local-timezone-dependent) while `#resting` converts them via `Time.gm` (UTC-direct). A new test for `Workpattern::Holidays.apply` that passed a bare `Date` to `wp.working?` failed as a result.

## Symptoms

```
1) Failure:
TestWorkpatternHolidays#test_apply_returns_dates_and_marks_them_resting [test/test_workpattern_holidays.rb:17]:
Expected true to not be truthy.
```

- `wp.resting(start: date, finish: date, days: :all)` correctly marked the date resting.
- `wp.working?(date)` — the same bare `Date` object — nonetheless returned `true` instead of the expected `false`, on a system running in BST (UTC+1).

## What Didn't Work

No failed investigation attempts occurred here — this traced to root cause on the first pass. Reading `Workpattern#working?` immediately showed the `to_utc` call, and comparing it against `WeekPattern#dmy_date` (used internally by `#resting`) immediately showed the divergent Date-to-Time conversion.

## Solution

Wrong (bare `Date`, timezone-sensitive):

```ruby
dates.each do |date|
  assert refute(wp.working?(date))
end
```

Correct (explicit UTC time via `Time.gm`, matching every other call site in the existing test suite):

```ruby
dates.each do |date|
  assert refute(wp.working?(Time.gm(date.year, date.month, date.day, 12, 0)))
end
```

No production code in `lib/workpattern/workpattern.rb` or `lib/workpattern/week_pattern.rb` changed — the library's existing behavior is correct by design, once its calling convention is respected.

## Why This Works

`Workpattern#to_utc` (`lib/workpattern/workpattern.rb:47-49`):

```ruby
def to_utc(date)
  date.to_time.utc
end
```

`Date#to_time` builds midnight in the **system's local timezone**, then `.utc` converts that instant to UTC. On a BST (UTC+1) system, `Date.new(2026,4,3).to_time.utc` yields `2026-04-02 23:00:00 UTC` — the *previous* day, one hour before actual midnight UTC. `#working?`, `#calc`, and `#diff` (`workpattern.rb:230,259,270`) all route their `start`/`finish` arguments through `to_utc`, so this shift affects all three.

`WeekPattern#dmy_date` (`lib/workpattern/week_pattern.rb:144-145`), used internally when `#resting`/`#workpattern` normalize `:start`/`:finish`:

```ruby
def dmy_date(date)
  Time.gm(date.year, date.month, date.day)
end
```

`Time.gm` builds UTC midnight directly from the Date's own year/month/day components — no local-timezone step, so it's timezone-immune.

The same bare `Date` object therefore lands on different calendar days depending on which method receives it: `#resting` (timezone-safe) marks the intended day resting, but `#working?` (timezone-sensitive) checks the *previous* day, which was never touched and is still working — hence `true` where `false` was expected.

This isn't an accident of this one method — it's consistent with the library's long-standing, deliberate design. [GitHub issue #24](https://github.com/callenb/workpattern/issues/24) (2016, closed) records the original author explicitly moving all internal calculation to UTC-only arithmetic, tested across timezones including DST boundary crossing. `#working?`/`#calc`/`#diff` hold up their end of that contract correctly; the bug here was a caller (a new test) not respecting it by passing a timezone-ambiguous `Date` instead of an explicit UTC `Time`.

## Prevention

**1. Always pass `Time.gm(...)`-constructed UTC times to `working?`, `calc`, and `diff` — never a bare `Date` object.** This is the unwritten convention every existing test in `test/test_workpattern.rb` and `test/test_workpattern_serialisation.rb` already follows (confirmed: 100% of existing call sites use `Time.gm`, none pass a bare `Date`).

```ruby
# Wrong — timezone-sensitive, may resolve to the wrong day
wp.working?(some_date)

# Right — explicit UTC time, matches #resting's own date handling
wp.working?(Time.gm(some_date.year, some_date.month, some_date.day, 12, 0))
```

**2. Namespace-collision rule (directly related, found in the same file):** when a file defines a module nested under `Workpattern::` with the same name as an external gem's top-level module (here, `Workpattern::Holidays` vs. the `holidays` gem's `::Holidays`), any bare reference to that name inside the nested module resolves to the *nested* constant first (Ruby's lexical scoping), not the gem. Always qualify the external reference with a leading `::`.

```ruby
module Workpattern
  module Holidays
    def self.apply(...)
      # Wrong — resolves to Workpattern::Holidays itself, raises NoMethodError
      Holidays.between(start_date, finish_date, region, :observed)

      # Right — :: forces top-level lookup, reaches the gem's Holidays module
      ::Holidays.between(start_date, finish_date, region, :observed)
    end
  end
end
```

This is already correctly applied in `lib/workpattern/holidays.rb`; the prevention is to keep this pattern in mind for any future adapter file that wraps a gem sharing a name with a `Workpattern::` submodule.

## Related Issues

- [callenb/workpattern#24](https://github.com/callenb/workpattern/issues/24) — "Calculations are always in utc and so do not take into account timezones" (2016, closed). The original design decision this bug re-discovered from the consumer side: the library commits to UTC-only arithmetic, so callers must hand it unambiguous UTC times, not locale-dependent `Date` objects.
