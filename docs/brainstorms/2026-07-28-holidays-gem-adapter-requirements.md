---
date: 2026-07-28
topic: holidays-gem-adapter
---

# holidays Gem Adapter

## Problem Frame

Every `workpattern` consumer who needs region-specific public holidays currently writes their own translation loop: fetch holiday dates from somewhere, then call `.resting(start:, finish:, days: :all)` once per date — and redo it every year as calendars change. The ideation doc (`docs/ideation/2026-04-26-open-ideation.md`, idea #3) identifies this as the most complained-about manual configuration step across Ruby business-time gems, and notes no existing gem in the space bridges `Workpattern` to a maintained holiday-data source.

The `holidays` gem (rubygems.org, latest 11.1.0, verified during this brainstorm) already solves the holiday-data problem — 80+ region definition files behind a stable `Holidays.between(start_date, end_date, *options)` API that returns `[{date:, name:, regions: [...]}, ...]`. The gap is purely the translation step. This brainstorm designs a small adapter, `Workpattern::Holidays.apply`, that performs that translation in one call.

---

## Requirements

**Activation and dependency isolation**

- R1. `Workpattern::Holidays.apply(workpattern, region:, year:)` is a standalone module method, not an instance method mixed into the core `Workpattern` class.
- R2. The adapter lives in its own file (`lib/workpattern/holidays.rb`) that is **not** required by `lib/workpattern.rb`. Callers must explicitly `require 'workpattern/holidays'` to activate it; the core class and its default require chain are untouched.
- R3. `holidays` is **not** added to the gemspec's runtime dependencies (`spec.add_dependency`). It remains a soft dependency the caller's own Gemfile must provide.
- R4. If the `holidays` gem is not installed, `require 'workpattern/holidays'` raises Ruby's standard `LoadError` — no custom rescue or wrapped error message.

**Call shape and defaults**

- R5. `apply` accepts exactly one `year:` (Integer) per call. Multi-year workpatterns require one `apply` call per year.
- R6. `apply` accepts exactly one `region:` (Symbol) per call, passed through to `Holidays.between`. Multi-region calendars (e.g. a UK-wide calendar plus Scotland-specific days) require one `apply` call per region.
- R7. `apply` requests observed dates from the `holidays` gem (passes `:observed`) by default, with no option to opt out in v1. A holiday that statutorily falls on a weekend is applied on its observed weekday instead.
- R8. `apply` excludes informal holidays (does not pass `:informal`) with no override in v1 — matches the underlying gem's own default (e.g. "Mothering Sunday" and "Guy Fawkes Day" are not applied).
- R9. For each date `Holidays.between` returns, `apply` calls `workpattern.resting(start: date, finish: date, days: :all)`, marking the whole day resting.
- R10. `apply` returns the array of `Date` objects it applied as resting days.
- R11. `apply` adds no new validation of its own for out-of-range dates, unknown regions, or other failures from `.resting` or `Holidays.between` — whatever error each underlying call raises today propagates unchanged.

**Testing**

- R12. `holidays` is added to the gemspec as a development dependency (`spec.add_development_dependency`) so the test suite can exercise `Workpattern::Holidays.apply` against real region data for at least one region (e.g. `:gb`), not just stubbed fixtures.

---

## Acceptance Examples

- AE1. **Covers R1, R2, R4.** Given the `holidays` gem is not installed, when a caller runs `require 'workpattern/holidays'`, then a `LoadError` is raised and `Workpattern::Holidays` is never defined.
- AE2. **Covers R5, R6, R9, R10.** Given `wp = Workpattern.new('uk-2026', 2026, 1)` and `require 'workpattern/holidays'`, when `dates = Workpattern::Holidays.apply(wp, region: :gb, year: 2026)` is called, then `dates` is an `Array` of `Date` objects (including `Date.new(2026, 1, 1)` for New Year's Day) and `wp.resting?` is `true` for every date in `dates`.
- AE3. **Covers R7.** Given GB New Year's Day statutorily falls on Saturday 2028-01-01, when `Workpattern::Holidays.apply(wp, region: :gb, year: 2028)` runs, then the observed Monday (2028-01-03), not the Saturday, is the date marked resting.
- AE4. **Covers R8.** Given region `:gb` where "Mothering Sunday" and "Guy Fawkes Day" are defined as informal holidays, when `apply` runs for any year, then neither date appears in the returned array or is marked resting (unless already resting for an unrelated reason).

---

## Success Criteria

- A gem consumer can replace their own hand-rolled, year-by-year holiday-to-`.resting` translation loop with one `Workpattern::Holidays.apply` call per region/year — without `workpattern`'s gemspec gaining a new mandatory runtime dependency.
- Planning can implement this without inventing the API shape, activation mechanism, default observed/informal behavior, region/year cardinality, return value, or error-handling strategy — all are decided here.

---

## Scope Boundaries

- No CLDR/locale weekend-structure presets (ideation idea #4) — this covers specific-date holidays only, not which weekdays count as weekend.
- No calendar inheritance/composition (ideation idea #5) — `apply` mutates a single named `Workpattern` directly.
- No custom/company-specific holiday definitions beyond what the `holidays` gem provides — a `Holidays.load_custom` passthrough is not part of v1.
- No caching or memoization of `Holidays.between` results across repeated `apply` calls.
- No opt-out for `:observed` or opt-in for `:informal` in v1 (R7, R8) — fixed defaults, not configurable options.
- No multi-region or multi-year batch call in v1 (R5, R6) — one region, one year, per `apply` call.

---

## Key Decisions

- **Module method, not instance method or monkey-patch (R1):** Keeps the `holidays` soft dependency fully isolated to `lib/workpattern/holidays.rb`. The core `Workpattern` class and its always-loaded require chain (`lib/workpattern.rb`) stay untouched until a caller explicitly opts in.
- **Single region + single year per call (R5, R6):** Keeps the v1 surface small and the mapping from "one `apply` call" to "one `Holidays.between` call" obvious. Adding array/multi-value support later is backward compatible if demand appears.
- **Default to observed, exclude informal (R7, R8):** Matches what most business/scheduling callers actually want marked as a day off, without adding configuration surface in v1.
- **Plain `LoadError` over a custom wrapper (R4):** Avoids new error-handling code to write and maintain; Ruby's own message already names the missing file.
- **`holidays` as a development dependency (R12):** Without it, the test suite could only exercise the `LoadError` path and would need hand-maintained fixture data that silently drifts from the real gem's output.

---

## Dependencies / Assumptions

- Assumes the `holidays` gem's public API — `Holidays.between(start_date, end_date, *options)` returning `[{date:, name:, regions: [...]}, ...]`, with `:observed`/`:informal` options and region symbols like `:gb`, `:gb_sct` — remains stable. Verified against `holidays` 11.1.0 (current latest on rubygems.org) during this brainstorm by inspecting its source directly.
- Assumes `Workpattern#resting(start:, finish:, days: :all)` continues to accept single-date ranges as it does today (`lib/workpattern/workpattern.rb:154`, confirmed against current README usage).
- Assumes whatever `.resting` does today for a date outside a `Workpattern`'s `base`/`span` window is acceptable as this adapter's behavior too — no new validation is being added (R11).

---

## Outstanding Questions

### Deferred to Planning

- [Affects R9][Technical] Confirm `Workpattern#resting`'s current behavior (error type, if any) for a date outside the target `Workpattern`'s `base`/`span` window, so it can be documented as this adapter's inherited behavior per R11.
- [Affects R12][Needs research] Confirm a minimum-supported `holidays` version range compatible with `workpattern`'s `required_ruby_version` (`>= 3.1`), for the development-dependency constraint.

---

## Next Steps

-> `/ce-plan` for structured implementation planning
