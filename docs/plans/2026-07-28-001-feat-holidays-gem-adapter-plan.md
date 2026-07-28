---
title: "holidays Gem Adapter"
type: feat
status: completed
date: 2026-07-28
origin: docs/brainstorms/2026-07-28-holidays-gem-adapter-requirements.md
deepened: 2026-07-28
---

# holidays Gem Adapter

## Overview

Every `workpattern` consumer who needs region-specific public holidays today writes their own translation loop: fetch holiday dates from somewhere, then call `.resting(start:, finish:, days: :all)` once per date. This plan adds `Workpattern::Holidays.apply(workpattern, region:, year:)` — a small, opt-in adapter that performs that translation in one call using the third-party `holidays` gem as its data source. It ships as a standalone file (`lib/workpattern/holidays.rb`) that is never loaded by default, keeping `holidays` a true soft dependency: callers who don't need it never pay for it, and `workpattern`'s own gemspec gains no new runtime dependency.

---

## Problem Frame

The `holidays` gem (rubygems.org, verified during the origin brainstorm against v11.1.0's actual source) already solves the holiday-data problem — 80+ region definition files behind a stable `Holidays.between(start_date, end_date, *options)` API returning `[{date:, name:, regions: [...]}, ...]`. The gap `workpattern` has is purely the translation step from "here are some holiday dates" to "these dates are now resting on my calendar." (See origin: `docs/brainstorms/2026-07-28-holidays-gem-adapter-requirements.md` for the full problem frame and the twelve requirements resolved during that brainstorm.)

---

## Requirements Trace

- R1. `Workpattern::Holidays.apply(workpattern, region:, year:)` is a standalone module method, not an instance method mixed into the core `Workpattern` class.
- R2. The adapter lives in `lib/workpattern/holidays.rb`, not required by `lib/workpattern.rb`. Callers must explicitly `require 'workpattern/holidays'`.
- R3. `holidays` is not added to the gemspec's runtime dependencies.
- R4. If `holidays` is not installed, `require 'workpattern/holidays'` raises Ruby's standard `LoadError` — no custom rescue or wrapper.
- R5. `apply` accepts exactly one `year:` (Integer) per call.
- R6. `apply` accepts exactly one `region:` (Symbol) per call, passed through to `Holidays.between`.
- R7. `apply` requests observed dates by default (passes `:observed`), no opt-out in v1.
- R8. `apply` excludes informal holidays (does not pass `:informal`), no opt-in in v1.
- R9. For each date `Holidays.between` returns, `apply` calls `workpattern.resting(start: date, finish: date, days: :all)`.
- R10. `apply` returns the array of `Date` objects it applied as resting days.
- R11. `apply` adds no new validation of its own — errors from `.resting` or `Holidays.between` propagate unchanged.
- R12. `holidays` is available to the test suite as a development-time dependency so tests can exercise real region data (see Key Technical Decisions for where this is declared — the origin doc's literal `spec.add_development_dependency` wording is revised below after research surfaced a repo-convention conflict).

**Origin acceptance examples:** AE1 (require without the gem installed raises `LoadError`), AE2 (apply returns applied dates and marks them resting), AE3 (observed-date shift on a weekend-falling holiday), AE4 (informal holidays excluded).

---

## Scope Boundaries

- No CLDR/locale weekend-structure presets (ideation idea #4) — this covers specific-date holidays only, not which weekdays count as weekend.
- No calendar inheritance/composition (ideation idea #5) — `apply` mutates a single named `Workpattern` directly.
- No custom/company-specific holiday definitions beyond what the `holidays` gem provides — a `Holidays.load_custom` passthrough is not part of v1.
- No caching or memoization of `Holidays.between` results across repeated `apply` calls.
- No opt-out for `:observed` or opt-in for `:informal` in v1 (R7, R8) — fixed defaults, not configurable options.
- No multi-region or multi-year batch call in v1 (R5, R6) — one region, one year, per `apply` call.
- No change to `Workpattern#resting`'s existing out-of-range-date behavior (silent no-op, see Key Technical Decisions) — this plan documents that inherited behavior, it does not alter it.

---

## Context & Research

### Relevant Code and Patterns

- `lib/workpattern.rb:1-16` — the explicit, non-glob require chain (`workpattern/clock`, `workpattern/constants`, `workpattern/day`, `workpattern/week`, `workpattern/workpattern`, `workpattern/week_pattern`). `lib/workpattern/holidays.rb` is deliberately **not** added here (R2) — it stands alone, matching how the module facade methods in this file (`Workpattern.new`, `.get`, etc., lines 33-100) delegate to the inner `Workpattern::Workpattern` class.
- `lib/workpattern/workpattern.rb:154-167` — `#resting`/`#working`, the RDoc style to mirror: one-line summary, blank comment line, `@see` tag, `<tt>...</tt>` markup around inline code/class names. `#resting` (line 154) is the exact method `apply` will call per holiday date.
- `lib/workpattern/week_pattern.rb:52-92` and `lib/workpattern/workpattern.rb:294-308` (`find_weekpattern`) — traced in full during research (see Key Technical Decisions below for the out-of-range finding this plan documents rather than changes).
- `lib/workpattern/constants.rb` — where shared constants like `WORK_TYPE`/`REST_TYPE` live; `Workpattern::Holidays` introduces no new constants, so no change needed here.
- `test/test_helper.rb` — `class WorkpatternTest < Minitest::Test; end`, an empty marker base class every test file subclasses. First line of every test file is `require "#{File.dirname(__FILE__)}/test_helper.rb"` (not `require_relative`).
- `test/test_workpattern_serialisation.rb` — closest existing precedent for a self-contained feature test file (`class TestWorkpatternSerialisation < WorkpatternTest`, `setup { Workpattern.clear }`). `test/test_workpattern_holidays.rb` should follow the same shape.
- `workpattern.gemspec` — `spec.required_ruby_version = Gem::Requirement.new('>= 3.1')` (line 15); runtime deps via `spec.add_dependency` (`sorted_set`, `tzinfo`, lines 32-33); **zero** `spec.add_development_dependency` calls anywhere.
- `Gemfile` — `gemspec` directive (line 4) plus direct `gem` lines for all dev tooling (`minitest`, `rake`, `rubocop`, `rubocop-minitest`, `rubocop-rake`, lines 6-10). This is the repo's actual, 100%-consistent convention for declaring dev-only dependencies.
- `README.md:96-116` — the `### Serialisation` section under `## Use` (line 27) is the closest style template for a new `### Holidays` section: short intro paragraph, fenced ` ```ruby ` example, then a short callout paragraph for a behavioral edge case (mirrors `from_h`'s `NameError`-on-duplicate-name callout).
- `CHANGELOG.md:1-3` — an open `## Workpattern v0.8.0 (unreleased) ##` section already exists (added by the thread-safe-registry fix) with one bullet. This plan adds a second bullet to that same still-open section rather than opening a new version heading.

### Institutional Learnings

- `docs/solutions/` currently has exactly one entry (`docs/solutions/logic-errors/thread-safe-workpattern-registry-2026-07-24.md`), and it is unrelated to this feature — `Workpattern::Holidays.apply` is a stateless module method that only calls the public instance method `#resting`; it never touches `@@workpatterns` or any of the registry's six guarded methods. No prior learning applies. This will be the first documented precedent in this repo for both a soft/optional third-party dependency and a standalone, non-core-loaded module — worth a `/ce-compound` write-up after landing (see Documentation / Operational Notes).
- The persistence (`to_h`/`from_h`) plan established this codebase's convention of thorough YARD/RDoc comments (`@param`, `@return`, `@raise`) on every new public method — mirrored here for `Holidays.apply`.

### External References

- `holidays` gem source, inspected directly (not from memory) at two pinned versions during planning:
  - **v11.1.0** (rubygems.org latest, verified during the origin brainstorm): confirmed `Holidays.between(start_date, end_date, *options)` returns holidays sorted by date as `{date:, name:, regions: [...]}` hashes; confirmed `:observed`/`:informal` option handling in `Holidays::Finder::Context::Between`; confirmed region data files include year-bounded entries (e.g. GB's one-off 2023 Coronation bank holiday), so the adapter needs no special handling for holidays that only exist in certain years — the gem's own data already scopes that.
  - **v8.8.0** (the version this plan pins as the dev dependency, see Key Technical Decisions): re-verified by unpacking the gem directly that `Holidays.between`/`.on` have the identical signature, and that `:observed`/`:informal` are handled identically in `Holidays::Finder::Context::ParseOptions#call` (`options.delete(:observed)` / `options.delete(:informal)`). Also confirmed `Holidays::InvalidRegion` (`lib/holidays/errors.rb`) is the exception raised by `parse_regions!`'s `validate!` when a region symbol isn't recognized — this is the concrete error type R11 lets propagate unchanged.
  - Ruby-version requirement history, checked against rubygems.org's version API (not guessed): 8.8.0 and earlier 8.x require Ruby `>= 2.4`; 9.0.0-9.2.0 require `>= 3.2`; 10.0.0/11.x require `>= 3.3`. Only the 8.x line satisfies `workpattern`'s own `>= 3.1` floor.

---

## Key Technical Decisions

- **Module + file structure:** `lib/workpattern/holidays.rb` defines `module Workpattern; module Holidays; def self.apply(workpattern, region:, year:); ...; end; end; end` (or the compact `module Workpattern::Holidays` form — implementer's choice, both are equivalent Ruby and match this codebase's existing module-then-class/module nesting). It is not added to `lib/workpattern.rb`'s require chain (R2) and defines no new constants.
- **Dev-dependency location — Gemfile, not gemspec (resolves R12's literal wording):** the origin brainstorm specified `spec.add_development_dependency 'holidays'`, written before this repo's actual convention was checked. Research found the gemspec has zero `add_development_dependency` calls; every existing dev-only gem (`minitest`, `rake`, `rubocop`, etc.) is declared directly in the `Gemfile` instead. Declaring `holidays` in the `Gemfile` fully satisfies R12's intent — the test suite gets real region data — without introducing the gemspec's first-ever `add_development_dependency` call for no added benefit. This is a deliberate, researched deviation from the origin doc's literal wording, not an oversight.
- **Version pin `~> 8.8` (resolves a Ruby-floor conflict, decided with the user during planning):** `holidays` 11.x (the version whose API the origin brainstorm verified) requires Ruby `>= 3.3`, stricter than `workpattern`'s own `>= 3.1` floor — pinning to 11.x would fail `bundle install` for any contributor on Ruby 3.1/3.2, and this repo currently has no CI (`.github/workflows` absent; `.travis.yml` is a stale relic testing Ruby 2.1-2.6) that would catch that gap automatically. `holidays` 8.8.0 is the newest release still supporting Ruby `>= 2.4`, and was directly verified (not assumed) to expose the identical `Holidays.between`/`:observed`/`:informal`/`InvalidRegion` surface the adapter depends on.
- **Single calendar-year date window:** `apply` builds `Date.new(year, 1, 1)` through `Date.new(year, 12, 31)` and passes both plus `region` and `:observed` to `Holidays.between` as one call — matching R5/R6's one-region-one-year-per-call contract directly onto one `Holidays.between` call.
- **Confirmed edge case: an `:observed` shift can move a holiday out of the requested year's query window entirely.** For regions whose observed-date rule shifts a Saturday-falling holiday *backward* to the preceding Friday (the common US-style rule — GB's own rule only shifts forward, to the following Monday), that shifted date can fall in the *previous* calendar year, outside `[Date.new(year,1,1), Date.new(year,12,31)]`. Confirmed directly during plan review, not assumed: `Holidays.between(Date.new(2028,1,1), Date.new(2028,12,31), :us, :observed)` (against the pinned `holidays` 8.8.0) returns zero entries for New Year's Day, because Jan 1 2028 (a Saturday) observes on Dec 31 2027 — outside that window. Calling `apply(wp, region: :us, year: 2028)` produces no resting day for that holiday at all; it only appears via a separate `apply(wp, region: :us, year: 2027)` call, dated Dec 31. Per R5's locked single-year-per-call contract this is not redesigned — it is documented, in both Key Technical Decisions and the README's Holidays callout, so callers using backward-shifting regions understand a year-boundary holiday may need the adjacent year's `apply` call to appear.
- **No LoadError wrapping (R4):** `require 'holidays'` sits as a plain top-of-file require in `lib/workpattern/holidays.rb`. No `begin/rescue LoadError` — Ruby's own `cannot load such file -- holidays (LoadError)` message is the entire error-handling surface.
- **Return value construction (R10):** `apply` maps the `Holidays.between` result to `Date` objects (via each hash's `:date` key) after calling `.resting` for each, and returns that array — giving callers a directly inspectable record of what was applied without a second query.
- **`region:` is forwarded unvalidated, matching house convention:** `apply` performs no type-check on `region:` before passing it to `Holidays.between`, consistent with R11 and this codebase's existing "trust the caller" pattern for keyword/opts arguments — `#resting`/`#working`'s unvalidated `opts` hash is the direct precedent (an invalid `:days` symbol produces a raw `NoMethodError` rather than a curated `ArgumentError`; see `lib/workpattern/workpattern.rb:145-167` and the `DAYNAMES` lookup in `lib/workpattern/constants.rb`). The codebase's only real argument-validation boundary is `Workpattern.from_h`, and that's validating a `Hash` that may have come from external/untrusted JSON deserialization — a different kind of boundary than an in-process keyword call like `apply`. One incidental consequence, confirmed during planning by inspecting `Holidays::Finder::Context::ParseOptions#parse_regions!` directly: because that method coerces any non-`Array` value into a one-element `Array`, passing `region: [:gb, :gb_sct]` will work and apply holidays for multiple regions in a single `apply` call. This is a byproduct of the wrapped `holidays` gem's own option parsing, not a feature this adapter documents, tests, or commits to preserving — it may silently stop working if a future `holidays` version changes that parsing. Callers who want guaranteed multi-region behavior should call `apply` once per region, per R6's documented one-region-per-call contract. Adding a defensive `raise ArgumentError unless region.is_a?(Symbol)` guard was considered and rejected: it would make `workpattern` more restrictive than the third-party gem it wraps, contradicting R11's "no new validation" design, and would need to be kept in sync with `holidays`' own evolving parsing behavior across version bumps — disproportionate for a ~15-line adapter method.
- **Out-of-range dates are silently absorbed, not validated (R11) — traced, not assumed:** `Workpattern#resting` → `#workpattern` → `WeekPattern#workpattern` → `Workpattern#find_weekpattern` (`lib/workpattern/workpattern.rb:294-308`) fabricates a synthetic all-working `Week` for any date outside `[@from, @to]` rather than raising. `WeekPattern#workpattern` then clones a fragment of that synthetic week, applies the requested resting state to the clone, and appends it to `@weeks` — but that entry is permanently unreachable afterward, because `find_weekpattern`'s range check runs before the `@weeks` lookup and never changes. Net effect: calling `apply` for a `year:` outside a `Workpattern`'s `base`/`span` window does not raise, silently succeeds, has zero observable effect on later `.resting?`/`.working?`/`.calc` queries for those dates, and permanently appends a small number of orphaned `Week` objects to the instance (a minor memory-growth footgun, not a correctness one). Per R11 this plan does not change that behavior — it documents it, in both the adapter's RDoc (`@raise`/`@see`-adjacent note) and the new README section, so callers aren't surprised.

---

## Open Questions

### Resolved During Planning

- Dev-dependency location: `Gemfile`, not `gemspec` (see Key Technical Decisions).
- `holidays` version pin: `~> 8.8` (see Key Technical Decisions — resolved with the user; verified compatible with the adapter's required API surface by unpacking the gem directly).
- Out-of-range-date behavior: traced fully in `find_weekpattern`/`WeekPattern#workpattern`; confirmed silent no-op, documented rather than changed (see Key Technical Decisions).
- `Holidays::InvalidRegion` confirmed as the concrete exception an unrecognized `region:` raises, letting U1's error-path test scenario be specific rather than `assert_raises(StandardError)`.

### Deferred to Implementation

- Exact RDoc wording and CHANGELOG bullet phrasing are left to the implementer's judgment, following the style precedents cited in Context & Research.
- AE1 (require without `holidays` installed raises `LoadError`) is not practically testable in-process within the normal Minitest run, since `holidays` will already be loaded as a normal dev dependency for the rest of the suite once U2 lands. If coverage is wanted, it requires a subprocess test (e.g. spawning a separate `ruby` process with a load path excluding `holidays`) — left to the implementer to judge whether that complexity is worth it; the behavior itself (`require 'holidays'` raising `LoadError` when absent) is guaranteed by Ruby's own require semantics rather than by any code this plan writes, so its risk of regressing is low regardless of test coverage.

---

## Implementation Units

- U1. **Implement `Workpattern::Holidays.apply`**

**Goal:** A working, tested adapter that translates one region/year of `holidays` gem data into `.resting` calls on a given `Workpattern`, per R1, R5-R11.

**Requirements:** R1, R4, R5, R6, R7, R8, R9, R10, R11

**Dependencies:** U2 (needs the `holidays` gem installed to write and run tests against real data)

**Files:**
- Create: `lib/workpattern/holidays.rb`
- Test: Create `test/test_workpattern_holidays.rb`

**Approach:**
- `require 'holidays'` at the top of the file (R4 — no rescue).
- Define `module Workpattern; module Holidays; def self.apply(workpattern, region:, year:); ...; end; end; end`, following the RDoc conventions in `lib/workpattern/workpattern.rb:154-167` (`@param`, `@return`, `@see`, `<tt>...</tt>` markup), including an explicit note on the out-of-range-date behavior documented in Key Technical Decisions.
- Build `start_date = Date.new(year, 1, 1)`, `end_date = Date.new(year, 12, 31)`.
- Call `Holidays.between(start_date, end_date, region, :observed)` — no `:informal` (R7, R8).
- For each returned hash, call `workpattern.resting(start: hash[:date], finish: hash[:date], days: :all)` (R9).
- Return the array of `hash[:date]` values, in the order `Holidays.between` returned them (already sorted by date) (R10).
- Add no argument validation beyond what Ruby's keyword-argument mechanism already enforces (`region:`/`year:` required) — no region-format checks, no year-range checks (R11: let `Holidays.between`'s own `InvalidRegion` and `Workpattern#resting`'s own out-of-range behavior propagate/absorb unchanged).
- No `region:` type-check (Symbol vs. Array) is added, for the same reason (R11, house convention — see Key Technical Decisions). The RDoc for `apply` should note explicitly that passing an Array happens to work today as a byproduct of `holidays`' own option parsing, but is not a supported or tested feature of this adapter, so a caller who discovers it by trial-and-error understands it's not a guarantee.

**Patterns to follow:**
- `lib/workpattern/workpattern.rb:154-167` (`#resting`/`#working`) for RDoc comment style and the exact call shape `resting(start:, finish:, days: :all)` this unit reuses.
- `test/test_workpattern_serialisation.rb` for test file shape (`class TestWorkpatternHolidays < WorkpatternTest`, `setup { Workpattern.clear }`, `require "#{File.dirname(__FILE__)}/test_helper.rb"` as the first line, then `require 'workpattern/holidays'`).

**Test scenarios:**
- Happy path. Covers AE2. Given `wp = Workpattern.new('uk-2026', 2026, 1)`, when `dates = Workpattern::Holidays.apply(wp, region: :gb, year: 2026)`, then `dates` is an `Array` of `Date` including `Date.new(2026, 1, 1)`, and `wp.resting?` is true for every date in `dates`.
- Happy path. Covers AE3. Given GB New Year's Day statutorily falls on Saturday 2028-01-01, when `Workpattern::Holidays.apply(wp, region: :gb, year: 2028)` runs, then the returned array contains the observed Monday `Date.new(2028, 1, 3)` for that holiday (not the raw Saturday), matching what `Holidays.between(..., :gb, :observed)` itself returns. This exact value was empirically re-verified during plan review by running `Holidays.between(Date.new(2028,1,1), Date.new(2028,1,10), :gb, :observed)` against the pinned `holidays` 8.8.0 gem directly — it returns `2028-01-03`, so this example does not collide with the GB substitute-day defect cited in Risks & Dependencies (holidays/holidays#396), which affects the more complex Christmas/Boxing Day cluster, not this single-rule New Year's Day computation.
- Happy path. Covers AE4. Given region `:gb`, when `apply` runs for any year, then no date whose only `holidays` gem entry is tagged `:informal` (e.g. "Mothering Sunday", "Guy Fawkes Day") appears in the returned array.
- Edge case. Given `region: :gb_sct` (a GB sub-region), when `apply` runs, then the returned array includes a Scotland-specific holiday not present when the same year is run with `region: :gb` — confirming `region:` is actually passed through to `Holidays.between` rather than hardcoded.
- Edge case. Given a `Workpattern` whose `base`/`span` does not cover the requested `year:` (e.g. a workpattern spanning 2020-2029 and `year: 2050`), when `apply` runs, then it does not raise, still returns the array of holiday dates for that year, and `wp.resting?` for those dates still reflects the workpattern's normal out-of-range behavior (working, per Key Technical Decisions) rather than resting — documenting the inherited no-op rather than asserting new behavior.
- Edge case. Given `region: :us` and `year: 2028` (New Year's Day 2028 falls on Saturday, and `:us`'s observed rule shifts it backward to Friday 2027-12-31, outside the `year: 2028` query window), when `apply` runs, then the returned array does not include a New Year's Day entry for 2028 — confirming the documented year-boundary behavior in Key Technical Decisions rather than asserting it should be included.
- Error path. Given `region: :not_a_real_region`, when `apply` runs, then `Holidays::InvalidRegion` propagates unchanged (not wrapped or rescued).
- Integration. Given a `Workpattern` with an existing resting pattern (e.g. weekends already resting) that overlaps a holiday date, when `apply` runs, then the call is a harmless no-op for that already-resting date (no error, no duplicate side effect observable via `.resting?`).

**Verification:**
- `test/test_workpattern_holidays.rb` passes.
- `Workpattern::Holidays` is not defined when only `require 'workpattern'` (the default entry point) is loaded — confirming R2's isolation holds.
- Full existing test suite still passes unchanged, confirming no shared state or require-order interaction with the rest of the library.

---

- U2. **Wire `holidays` in as a pinned development dependency**

**Goal:** `holidays ~> 8.8` is installed whenever a contributor runs `bundle install`, without becoming part of `workpattern`'s published runtime dependencies.

**Requirements:** R3, R12

**Dependencies:** None

**Files:**
- Modify: `Gemfile`

**Approach:**
- Add `gem 'holidays', '~> 8.8'` to `Gemfile` alongside the existing dev-tooling `gem` lines (`minitest`, `rake`, `rubocop`, etc.), matching the existing declaration style there. Do not add anything to `workpattern.gemspec`'s `add_dependency` or introduce its first `add_development_dependency` call (see Key Technical Decisions).

**Test scenarios:**
- Test expectation: none — this unit only changes dependency resolution; its correctness is proven indirectly by U1's test suite successfully requiring and exercising `holidays`.

**Verification:**
- `bundle install` succeeds and resolves `holidays` to a `8.8.x` version.
- `bundle exec ruby -e "require 'holidays'; puts Holidays::VERSION"` (or equivalent) confirms the resolved version is in the `8.8.x` line.

---

- U3. **Document the feature**

**Goal:** A gem consumer discovers `Workpattern::Holidays.apply` from the README, and the CHANGELOG reflects the new capability for the next release.

**Requirements:** R2 (activation is opt-in — the docs are how a caller learns that), R11 (the out-of-range behavior needs to be visible somewhere a caller would actually read it)

**Dependencies:** U1 (documents the finished behavior, including its exact call shape and the out-of-range caveat)

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`

**Approach:**
- Add a `### Holidays` section to `README.md` under the existing `## Use` heading (after `### Serialisation`, `README.md:96-116`), following that section's shape: a short intro paragraph, a fenced ` ```ruby ` example showing `require 'workpattern/holidays'` and `Workpattern::Holidays.apply(wp, region: :gb, year: 2026)`, then a short callout paragraph documenting the out-of-range-date no-op behavior (mirroring the existing `from_h`/`NameError` callout's shape). Append one further sentence to that same callout paragraph noting that holiday data quality varies by region and isn't rated by the `holidays` gem itself, so callers should spot-check `apply`'s output against their region's actual statutory calendar before relying on it for anything business-critical (see Risks & Dependencies — this keeps the caveat to one sentence rather than a new section, sized to match how lightly the origin doc itself treated this concern). Append a further sentence noting that for regions with a backward-shifting `:observed` rule (e.g. US-style "Saturday shifts to the preceding Friday"), a holiday near a year boundary may not appear in that year's `apply` call and instead appears via the adjacent year's call (see Key Technical Decisions for the confirmed example).
- Add one bullet to the already-open `## Workpattern v0.8.0 (unreleased) ##` section at the top of `CHANGELOG.md` (do not open a new version heading — that section is still unreleased and already accumulating this cycle's changes), describing the new `Workpattern::Holidays.apply` method, its soft dependency on the `holidays` gem, and that it must be explicitly required via `require 'workpattern/holidays'`.

**Test scenarios:**
- Test expectation: none — pure documentation, no executable behavior.

**Verification:**
- The README's new `### Holidays` example is copy-paste runnable against U1's actual implementation (spot-check by running it in a console).
- `CHANGELOG.md`'s unreleased section lists this change alongside the existing thread-safety bullet.

---

## System-Wide Impact

- **Interaction graph:** `Workpattern::Holidays.apply` only ever calls the existing public instance method `#resting`. It never touches `@@workpatterns`, the registry `Mutex` added in the prior plan, `Day`, `Week`, or `WeekPattern` internals directly — the only integration seam is `#resting`'s existing, unchanged public contract.
- **Error propagation:** Two independent error sources reach the caller unwrapped: `Holidays::InvalidRegion` (or any other `holidays`-gem error) from `Holidays.between`, and whatever `Workpattern#resting` already does for a given date (per R11, deliberately not touched by this plan).
- **State lifecycle risks:** Repeated `apply` calls for overlapping date ranges are idempotent from the caller's perspective (`.resting` on an already-resting day is a harmless no-op); `apply` calls for out-of-range years leave a small number of orphaned, unreachable `Week` objects inside the target `Workpattern` instance — a pre-existing `#resting` behavior this plan inherits and documents rather than introduces.
- **API surface parity:** No existing public method's signature or behavior changes. This unit is purely additive.
- **Unchanged invariants:** `Workpattern#resting`, `#working`, `#calc`, `#diff`, `#working?`, the named registry, and `to_h`/`from_h` are all untouched — confirmed by reading every code path this plan's new module calls into.

---

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| Pinning `holidays ~> 8.8` means the test suite runs against a version whose regional data is a few years staler than the 11.1.0 the origin brainstorm inspected. | The core `Holidays.between`/`:observed`/`:informal` API was directly re-verified against 8.8.0 during planning and is identical; only underlying regional *data* differs, and the test scenarios in U1 target holidays stable across versions (New Year's Day, informal-holiday exclusion) rather than one-off recent additions. |
| A contributor on Ruby 3.3+ who separately upgrades their local Gemfile.lock could silently resolve `holidays` to a newer 8.x patch with different regional data, causing a flaky test if `holidays`' own definitions change. | `~> 8.8` allows patch-level updates within 8.8.x only (not a jump to 8.9 or 9.x), which is the standard Bundler pessimistic-constraint tradeoff already used implicitly elsewhere in this Gemfile; acceptable given the alternative (exact pin) adds maintenance burden for no correctness benefit here. |
| No CI exists in this repo (`.github/workflows` absent) to automatically catch a future `holidays` version bump breaking the Ruby-floor compatibility this plan carefully resolved. | Out of scope for this plan (adding CI is a separate concern); documented explicitly here and in Key Technical Decisions so a future contributor bumping the pin understands the constraint it exists to satisfy. |
| The `holidays` gem's regional data has real, open, undocumented-severity gaps even in commonly-used regions — confirmed via open upstream issues on incorrect GB Christmas/New Year substitute days (holidays/holidays#396, open since 2022) and missing Singapore holidays (holidays/holidays#351, open since 2019) — and neither the gem nor its companion `holidays/definitions` repo rates which of its 80+ regions are reliably maintained versus sparsely covered. Notably, GB — one of this plan's own U1 test regions — is not exempt. | `apply` is a thin pass-through with no `workpattern`-side validation of holiday correctness, by design (R11). U3's README callout adds a one-sentence caveat directing callers to spot-check `apply`'s output against their region's actual statutory calendar before relying on it for anything business-critical, rather than this plan attempting to vouch for third-party data quality it has no way to verify. |
| The `holidays` gem ships regional-data changes as *minor* version bumps (per its own CHANGELOG) — "backwards compatible with your code but might give different holiday results." Any consumer running an unpinned or loosely-pinned `holidays` version can see `apply`'s output silently change dates on a routine `bundle update`, with no major-version signal. | Out of scope for `workpattern` to control (it doesn't dictate the end consumer's `holidays` pin); noted here so this is a known, surfaced characteristic of the dependency rather than a silent surprise. Consumers who need output stability should pin `holidays` precisely in their own Gemfile. |

---

## Documentation / Operational Notes

- After landing, this is a strong candidate for a `/ce-compound` write-up in `docs/solutions/` (e.g. `docs/solutions/architecture-patterns/` or `docs/solutions/tooling-decisions/`) — it's the first documented precedent in this repo for both a soft/optional third-party runtime dependency and a standalone, non-core-loaded extension module. Future features following the same "optional adapter" shape (e.g. the ideation doc's CLDR locale-preset idea) can reuse this precedent directly.
- README and CHANGELOG updates are part of this plan (U3) rather than deferred — this is a small, additive feature where documentation is cheap to land alongside the code.

---

## Sources & References

- **Origin document:** [docs/brainstorms/2026-07-28-holidays-gem-adapter-requirements.md](../brainstorms/2026-07-28-holidays-gem-adapter-requirements.md)
- Related code: `lib/workpattern/workpattern.rb`, `lib/workpattern.rb`, `lib/workpattern/week_pattern.rb`
- Related ideation: `docs/ideation/2026-04-26-open-ideation.md` (idea #3)
- Related prior plan: [docs/plans/2026-07-24-001-fix-thread-safe-registry-plan.md](2026-07-24-001-fix-thread-safe-registry-plan.md) (style precedent for this plan's format; confirmed no functional overlap)
- External: `holidays` gem source, rubygems.org (versions 11.1.0 and 8.8.0 both inspected directly during planning, not from memory)
