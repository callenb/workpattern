# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`workpattern` is a Ruby gem that calculates dates and durations while accounting for working/resting time (evenings, weekends, holidays, custom shift patterns) — the kind of calendar logic used by project-scheduling tools (MS Project, Primavera P6). No monkey-patching; requires Ruby >= 3.1.

## Commands

```sh
bundle install                 # install dependencies
bundle exec rake test          # run the full test suite (also the default rake task)
bundle exec ruby -Itest -Ilib test/test_workpattern.rb   # run a single test file
bundle exec ruby -Itest -Ilib test/test_workpattern.rb -n test_must_add_minutes_in_a_working_workpattern  # run a single test
bundle exec rubocop            # lint (see .rubocop.yml / .rubocop_todo.yml)
bundle exec rake console       # open an IRB console with Workpattern already required
bundle exec rake build         # build the gem into pkg/
```

Tests are Minitest (`Minitest::Test`), one file per class under `test/`, run via `rake test` which globs `test/test_*.rb`.

## Architecture

The gem is a layered model, from bit-level detail up to the public API. Understanding a bug or feature request usually means knowing which layer it belongs to:

- **`Clock`** (`lib/workpattern/clock.rb`) — a plain hour/minute value object. Anything responding to `#hour`/`#min` (e.g. `Time`, `DateTime`) can be used in its place throughout the API.
- **`Day`** (`lib/workpattern/day.rb`, `@private`) — the core representation. A day's working/resting minutes are packed into a single **integer used as a bitmask** (1 bit per minute, 1 = working). All the working/resting queries, masks, and the binary-search-style `first_minute`/`last_minute` scans operate on this bitmask. This is the performance-critical, least-obvious layer.
- **`Week`** (`lib/workpattern/week.rb`, `@private`) — holds 7 `Day` objects plus a `start`/`finish` date range it applies to. A `Workpattern` is a `SortedSet` of non-overlapping `Week` objects (`<=>` compares by `start`), each covering a contiguous date range with its own 7-day pattern. This is how the gem supports "normal pattern most of the time, different pattern for this date range" (e.g. vacations) without storing per-day state for every day in the span.
- **`WeekPattern`** (`lib/workpattern/week_pattern.rb`) — the mutation engine. `#workpattern` (called by `Workpattern#resting`/`#working`) walks the `Week` set for the requested date range, splitting/cloning existing `Week` objects at the boundaries as needed so a new pattern can be applied to exactly the requested sub-range without disturbing weeks outside it. This split-and-clone logic is the trickiest part of the codebase.
- **`Workpattern`** (`lib/workpattern/workpattern.rb`) — the public-facing class. Owns a **process-wide, name-keyed, mutex-guarded registry** (`@@workpatterns`, `@@mutex`) so `Workpattern.new("x")`, `.get`, `.delete`, `.clear` are safe under concurrent access (see `docs/solutions/logic-errors/thread-safe-workpattern-registry-2026-07-24.md`). `#calc` (add/subtract minutes) and `#diff` (minutes between two dates) delegate down to `find_weekpattern` → `Week` → `Day`.
- **`Workpattern` module** (`lib/workpattern.rb`) — thin convenience wrappers (`Workpattern.new`, `.get`, `.clock`, etc.) delegating to the `Workpattern::Workpattern` class of the same name. `Workpattern` and `Clock` are the only two classes calling applications should reference directly; everything else is `@private`.
- **`Workpattern::Holidays`** (`lib/workpattern/holidays.rb`) — an **optional adapter**, never required by `workpattern.rb` itself. Bridges the third-party `holidays` gem to mark one region's public holidays resting for one calendar year. Callers must `require 'workpattern/holidays'` explicitly and add the `holidays` gem to their own Gemfile.

### Non-obvious behaviors worth knowing before touching date logic

- **UTC vs local-time conversion mismatch**: `Workpattern#working?`/`#calc`/`#diff` convert dates via `date.to_time.utc` (local-timezone-dependent), while `#resting`/`#working` (pattern application) convert via `Time.gm` (UTC-direct). A bare `Date` object passed to `#working?` can resolve to the *wrong day* whenever the host system's local timezone isn't UTC. Always test with explicit `Time.gm(...)` or be aware of this when passing bare `Date` objects. Full writeup: `docs/solutions/test-failures/bare-date-vs-time-gm-timezone-mismatch-in-working-2026-07-28.md`.
- **Serialisation** (`Workpattern#to_h` / `Workpattern.from_h`): produces a JSON-safe plain hash (`Day` bitmasks stored as hex strings). `from_h` raises `NameError` if a workpattern with the same name already exists unless `overwrite: true` is passed, and raises `ArgumentError` on missing/unsupported `:version` or malformed fields.
- **`Workpattern::Holidays.apply`**: a `year:` outside the workpattern's own `base`/`span` window is a silent no-op (consistent with how `#resting` already handles out-of-range dates). Holidays near a year boundary under a backward-shifting observed-date rule (e.g. US-style "Saturday shifts to preceding Friday") may fall in the *previous* calendar year's `apply` call rather than the requested year's.
- **Registry mutability**: `Workpattern.workpatterns` returns a frozen `dup` of the registry — mutate it via `.new`/`.delete`/`.clear`/`.from_h`, not by touching the returned hash.

## Project docs

- `docs/brainstorms/`, `docs/plans/`, `docs/ideation/` — dated design discussions and implementation plans for past features (persistence, thread-safe registry, holidays adapter).
- `docs/solutions/` — postmortem-style writeups of specific bugs, categorized by `logic-errors/` and `test-failures/`. Check here first when debugging something that touches timezones, the registry, or concurrency — it may already be documented.
