# ce-code-review run 20260426-001

**Branch**: feat/persistence-to-h-from-h  
**Base**: e8b397582d79990b64b037b9fcf96d21bc7160b8  
**Mode**: autofix  
**Plan**: docs/plans/2026-04-26-001-feat-persistence-to-h-from-h-plan.md  
**Date**: 2026-04-26  
**Tests after fixes**: 123 runs, 0 failures, 0 errors

## Intent

Added `to_h`/`from_h` round-trip serialisation to Workpattern, Week, and Day, replacing a broken 14-year-old persistence callback. Enables serialisation to plain Ruby hashes (JSON-safe) and reconstruction via `allocate` + `instance_variable_set`. Also fixes a latent cache-coherence bug in `Day#pattern=`.

## Reviewers dispatched (9)

correctness, testing, maintainability, project-standards, agent-native, learnings-researcher, adversarial, api-contract, security

## Applied fixes (safe_auto)

| # | Severity | File | Description |
|---|----------|------|-------------|
| 1 | P0 | lib/workpattern/workpattern.rb:64 | Fixed `DEFAULT_NAME` → `DEFAULT_WORKPATTERN_NAME` (pre-existing bug) |
| 2 | P1 | lib/workpattern.rb:78 | Fixed docstring: 'serialise' → 'deserialise' on `from_h` |
| 3 | P1 | lib/workpattern/workpattern.rb | Added required-key validation in `from_h` (:name String, :base Integer, :span non-zero Integer, :weeks Array) |
| 4 | P1 | lib/workpattern/workpattern.rb | Added empty-weeks guard in `from_h` (raises ArgumentError instead of crashing on first use) |
| 5 | P1 | lib/workpattern/day.rb | Added `hours_per_day` validation in `Day.from_h` (must be Integer 1..24, prevents CPU DoS) |
| 6 | P1 | lib/workpattern/day.rb | Added `pattern` length validation in `Day.from_h` (must be String ≤400 chars, prevents memory DoS) |
| 7 | P2 | lib/workpattern/week.rb:12 | Removed dead `attr_writer :week_total, :total` |
| 8 | P2 | lib/workpattern/week.rb:18 | Fixed `Array.new(LAST_DAY_OF_WEEK)` → `Array.new(LAST_DAY_OF_WEEK + 1)` in `Week.initialize` |
| 9 | P2 | lib/workpattern/week.rb:290 | Removed dead private `prev_day` method |
| 10 | P3 | lib/workpattern/workpattern.rb | Made instance `workpatterns` helper private |
| 11 | P3 | lib/workpattern/week.rb:31 | Split semicolon-separated statement in `Week.from_h` |
| 12 | P2 | test/test_day.rb | Added `working_minutes` assertion to cache-restore test |
| 13 | P2 | test/test_day.rb | Added `test_from_h_round_trips_partial_day_working_minutes` test |
| 14 | P2 | test/test_workpattern_serialisation.rb | Added behavioral (pattern) assertion to overwrite test |
| 15 | P2 | test/test_workpattern_serialisation.rb | Added `test_round_trip_negative_span` test |
| 16 | P3 | test/test_day.rb | Fixed key-order assertions → key-presence assertions |
| 17 | P3 | test/test_workpattern_serialisation.rb | Removed spurious `Workpattern.new('strkeys')` setup in string-keys test |

## Residual actionable work

See residual section below — 15 downstream-resolver findings remain.
