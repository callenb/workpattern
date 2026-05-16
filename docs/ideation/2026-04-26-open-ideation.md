---
date: 2026-04-26
topic: open-ideation
focus: surprise-me
mode: repo-grounded
---

# Ideation: workpattern — Surprise-Me Session

## Grounding Context

**Project:** workpattern v0.6.0 — pure-Ruby gem calculating dates and durations for working/resting periods down to the minute. Named Workpattern calendar objects stored in a class-level registry (`@@workpatterns`). Core engine: `Day` class uses bit-packed integers (1 bit = 1 minute) for fast pattern operations. UTC-at-boundaries discipline throughout. Public API: `Workpattern` class and `Clock` only (`Week`, `Day`, `WeekPattern` are private). `SortedSet` for ordered `Week` storage.

**Activity:** Last release Feb 2021 (5-year gap). 11 GitHub stars vs working\_hours' 536 and 639 dependents. Only open GitHub issue: "Add a way to persist workpatterns" (filed 2012). Recent commits are CI/compatibility-only.

**Pain points confirmed in code:** Thread-unsafe global state (`@@workpatterns`), partially-implemented persistence hook with a naming bug (`@@persist` set vs `@@persistence` read), no holiday data integration, no calendar composition, one commented-out slow test ("TODO: Speed this up"), no benchmarks.

**External landscape:** working\_hours dominates (639 dependents); business gem in maintenance mode. No Ruby gem currently offers: built-in holiday API integration, calendar inheritance/composition, pause/resume duration semantics, or pre-bundled locale calendars.

## Ranked Ideas

### 1. Fix the Persistence Architecture

**Description:** The persistence hook has a naming bug (`@@persist` set by `persistence_class=`, but `@@persistence` read by `week_pattern.workpattern` — two different variables). The feature has never worked in any released version. Replace the broken callback architecture with a `#to_h` / `.from_h` round-trip that serialises the full pattern state to a plain Ruby hash, and document the schema as a versioned contract.

**Warrant:** `direct:` `lib/workpattern/workpattern.rb` lines 43–49: `persistence_class=` stores to `@@persist`; the `workpattern()` method references the undefined `@@persistence`. The only open GitHub issue has been this feature request for 14 years.

**Rationale:** Every production use eventually hits this gap. A `to_h`/`from_h` contract is simpler than the callback architecture, trivially testable, and composable with any storage backend the caller chooses. The `Day#pattern` Bignum already hexdumps to a string in one expression — the serialisation cost is near-zero.

**Downsides:** Committing to a serialisation schema means versioning it — schema drift between gem versions could break persisted workpatterns. Needs a version field from day one.

**Confidence:** 95%
**Complexity:** Low
**Status:** Unexplored

***

### 2. Thread-Safe Named Registry

**Description:** `@@workpatterns`, `@@persist`, and `@@tz` are bare class variables with no Mutex or thread-local isolation. Any multi-threaded Rails or Sidekiq deployment can silently corrupt calendar state. Replace the class-variable registry with thread-local storage (`Thread.current[:workpatterns]`) with an optional shared read-only base namespace — the same inversion working\_hours applies to its per-thread config.

**Warrant:** `direct:` `lib/workpattern/workpattern.rb` — `@@workpatterns = {}` shared across all threads with no synchronisation anywhere in the codebase. `external:` working\_hours gem uses `Thread.current` explicitly to solve this; the gem's README documents it as the deliberate fix to the same class-variable problem.

**Rationale:** Rails serves concurrent requests; Sidekiq runs concurrent workers. Thread-unsafe global state produces wrong answers with no exception — the worst failure mode. This is a single-file change with no public API impact.

**Downsides:** Thread-local storage means patterns created in one thread aren't visible to another by default. Applications that intentionally share a warm registry across threads need an explicit "shared" namespace with appropriate locking.

**Confidence:** 90%
**Complexity:** Low
**Status:** Unexplored

***

### 3. holidays Gem Adapter

**Description:** The `holidays` gem (actively maintained, Ruby 4.0-tested, 50+ region coverage) returns public holiday dates for any country-year pair. Workpattern already has `.resting(days:, start:, finish:)`. The gap is the translation loop every user must write. An adapter — `Workpattern::Holidays.apply(wp, region: :gb, year: 2026)` — queries the holidays gem and calls `.resting` for each result, eliminating the most complained-about manual configuration step across all Ruby business-time gems.

**Warrant:** `external:` The `holidays` gem (rubygems.org/gems/holidays) covers 50+ regions with a stable `Holidays.on(date, :gb)` API. No existing Ruby working-time gem bridges them. Research confirms this is the top onboarding friction point across the space.

**Rationale:** Manual holiday configuration is error-prone, region-specific, and must be redone every year. One adapter call replacing a configuration file is a qualitatively different experience. The adapter is additive — a soft dependency on `holidays` that activates only when explicitly required.

**Downsides:** Adds a soft dependency; the holidays gem has gaps in some regions and regional rules can be complex (observed vs. statutory holidays). Needs documentation on which regions are reliable.

**Confidence:** 85%
**Complexity:** Low–Medium
**Status:** Unexplored

***

### 4. Bundled CLDR Locale Presets

**Description:** The Unicode CLDR encodes `weekendStart` and `weekendEnd` for 200+ territories as freely licensed data. Ship a vendored data file derived from `CLDR supplemental/weekData.xml` — similar to how `tzinfo-data` bundles timezone data — and expose `Workpattern.for_locale("ar-SA")` that returns a pre-built Workpattern with the correct weekend days set. Callers still configure their hours; the gem handles the "which days are working days" baseline.

**Warrant:** `external:` CLDR `supplemental/weekData.xml` (unicode-org/cldr on GitHub) encodes weekend structure for 200+ territories under the Unicode License. It is the authoritative source for locale calendar data used by browsers, mobile OSes, and i18n libraries globally.

**Rationale:** Every caller currently writes "set Saturday and Sunday to resting" — wrong by default for Friday-Saturday weekend countries (Saudi Arabia, etc.). A 50KB vendored data file gives every user a correct regional baseline in one line. Distinct from the holidays adapter — this handles *structure* (which days count as weekend), not *specific dates* (holiday events).

**Downsides:** Adds a vendored data file needing periodic refresh as CLDR updates (usually annually). Some territories have complex rules that CLDR doesn't fully encode.

**Confidence:** 80%
**Complexity:** Low
**Status:** Unexplored

***

### 5. Calendar Inheritance / Composition

**Description:** Every Workpattern is currently a standalone island with no relationship to any other. Add a parent-child calendar model: `child = Workpattern.inherit_from("base_calendar")` creates a Workpattern whose pattern defaults to the parent's, with child-level overrides applied on top. This is the architecture used by MS Project, Primavera P6, and every production scheduling engine.

**Warrant:** `external:` MS Project's "Resource Calendar inherits from Base Calendar" cascade model and Primavera P6's identical Global > Project > Resource hierarchy are the validated production architectures for this exact problem domain. The current codebase treats each Workpattern as a flat island — confirmed by `@@workpatterns` being a flat hash with no parent reference.

**Rationale:** The most common real-world usage is "company calendar plus per-project exceptions." Today users copy all base rules to every new Workpattern or maintain duplication in application code. Inheritance makes workpattern usable for HR and resource-planning tools without wrapper infrastructure.

**Downsides:** Adds semantic complexity (merge semantics when child overrides parent). Serialisation becomes more complex — must capture the inheritance chain. Best implemented after items 1 and 4.

**Confidence:** 75%
**Complexity:** Medium–High
**Status:** Unexplored

***

### 6. ActiveSupport Integration

**Description:** Ship an optional `require 'workpattern/active_support'` module adding `#working_minutes_until`, `#working_minutes_since`, and `#advance_working_minutes` to `ActiveSupport::TimeWithZone`, using a named Workpattern as the calendar. Patterned on how working\_hours integrates. Makes workpattern a drop-in replacement for working\_hours in any Rails app.

**Warrant:** `external:` working\_hours has 639 reverse gem dependencies vs. workpattern's \~11 stars. Research attributes this adoption gap directly to working\_hours' ActiveSupport integration. working\_hours has a known open consistency bug since 2015 and no named-calendar model — workpattern has both as strengths.

**Rationale:** Rails is where the users are. An ActiveSupport extension is the key that puts workpattern into Rails Gemfiles. Workpattern's minute-granularity and named-calendar model are then exposed to users currently settling for working\_hours' day-level granularity.

**Downsides:** ActiveSupport is a significant transitive dependency even when optional. Must be carefully scoped to not conflict with working\_hours if both are present (migration scenario).

**Confidence:** 85%
**Complexity:** Medium
**Status:** Unexplored

***

### 7. Verified Engine Testing

**Description:** Three mutually reinforcing moves on the Day bit-arithmetic engine: (a) replace two \~40-line binary-search loops in `Day#first_minute` and `Day#last_minute` with native Ruby integer operations (`(pattern & -pattern)` for first set bit; `pattern.bit_length - 1` for last set bit) — O(1) native C vs. O(1440) hand-coded loops; (b) introduce property-based testing to assert algebraic invariants across random inputs; (c) add a consistency invariant test asserting that `working?()` and `calc()` always agree at boundaries.

**Warrant:** `direct:` `lib/workpattern/day.rb` lines 149–221: two near-identical binary-search loops with boundary guards that signal past off-by-one bugs. Commented-out slow test: "TODO: Speed this up". `external:` working\_hours has had a consistency bug between `return_to_working_time()` and `in_working_hours?()` open since 2015 — demonstrating this is a real systemic failure mode in this domain.

**Rationale:** The bit-arithmetic engine is the most complex code and has historically been the source of boundary bugs (CHANGELOG references issues #12, #13, #14 in v0.3.3). PBT turns this from a manually-tested black box into a systematically verified foundation. The native integer ops fix removes 80 lines of fragile code and replaces with 2 standard one-liners. Together these make it safe for contributors to touch the engine.

**Downsides:** PBT libraries add a dev dependency; rantly is less maintained than alternatives. The native integer ops change requires careful verification for the all-zeros case (fully resting day).

**Confidence:** 90%
**Complexity:** Low (native int ops) + Medium (PBT setup)
**Status:** Unexplored

***

## Rejection Summary

| #  | Idea                               | Reason Rejected                                                        |
| :- | :--------------------------------- | :--------------------------------------------------------------------- |
| 1  | Argument validation                | Tactical; below ambition floor                                         |
| 2  | Factory methods                    | Subsumed by locale presets                                             |
| 3  | diff() return value contract       | Too tactical (test fix)                                                |
| 4  | Document bit-packing               | Below ambition floor; bundled into Verified Engine                     |
| 5  | Expose DayPattern as public object | Subsumed by serialisation                                              |
| 6  | WorkTimer / WorkingDuration        | Scope creep for current gem maturity                                   |
| 7  | Change Events / Audit Log          | Speculative; overbuilding for a 11-star gem                            |
| 8  | Weighted Working Minutes           | Requires replacing the bit model; no demand evidence                   |
| 9  | Capacity Analytics                 | Too vague; weak warrant                                                |
| 10 | Flyweight Pool                     | Premature — no scale problem yet                                       |
| 11 | Millisecond resolution             | No demonstrated demand; expensive redesign                             |
| 12 | Interval list / Jump table         | Speculative without benchmark data                                     |
| 13 | Serialisable CalcState             | Too niche                                                              |
| 14 | DST-explicit API                   | Existing UTC-at-boundaries design is adequate                          |
| 15 | Value-Object Immutability          | API-breaking for same win as thread-local registry                     |
| 16 | Pluggable Registry Backends        | Subsumed by to\_h/from\_h (application code once serialisation exists) |
| 17 | iCalendar Export-Import            | Narrowly cut; strong external warrant but weakest demand signal        |
| 18 | N-Day Cycle Patterns               | Too high complexity for current gem maturity (honourable mention)      |
