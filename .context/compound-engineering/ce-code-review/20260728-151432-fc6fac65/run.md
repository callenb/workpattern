# Code Review Run — 20260728-151432-fc6fac65

**Scope:** feat/holidays-gem-adapter vs merge-base 2d588b5fd57ff6aebb8a3c2fd490981e09c135cb (development)
**Intent:** Add `Workpattern::Holidays.apply(workpattern, region:, year:)` — an opt-in adapter bridging the third-party `holidays` gem to bulk-apply a region's public holidays as resting days on a Workpattern in one call. Soft dependency (never required by `workpattern.rb`); `holidays ~> 8.8` pinned as a dev-only Gemfile dependency for Ruby >= 3.1 compatibility. Documents (rather than works around) two confirmed edge cases: out-of-range-year silent no-op, and a backward-shifting `:observed` rule crossing a year boundary.
**Plan:** docs/plans/2026-07-28-001-feat-holidays-gem-adapter-plan.md (plan_source: explicit)
**Mode:** autofix

**Reviewers:** correctness (always), testing (always), maintainability (always), project-standards (always), ce-agent-native-reviewer (always), ce-learnings-researcher (always), api-contract (new public method signature), reliability (deliberate error-propagation design), adversarial (80 non-test changed lines + external-gem integration)

## Requirements Completeness

Plan found explicitly (plan: argument). Checked Requirements Trace (R1-R12) and Implementation Units (U1-U3) against the diff:

| Req | Status |
|-----|--------|
| R1-R11 | Met — `lib/workpattern/holidays.rb` implements all locked decisions (module method, opt-in file, no gemspec dep, LoadError passthrough, single region/year, observed default, informal exclusion, resting() call, Date array return, no new validation) |
| R12 | Met — `holidays ~> 8.8` in Gemfile (not gemspec, per the plan's researched deviation from the origin doc's literal wording) |
| U1-U3 | Met — adapter + tests (U1), Gemfile pin (U2), README + CHANGELOG (U3) all present in diff |

No unaddressed requirements.

## Findings

### P2 — Moderate

| # | File | Issue | Reviewer(s) | Confidence | Route |
|---|------|-------|-------------|------------|-------|
| 1 | lib/workpattern/holidays.rb:48 | `@return` doc says "the dates applied" but the array includes dates fetched for out-of-range years that `#resting` silently didn't apply | api-contract | 75 (validated) | gated_auto -> downstream-resolver |

### P3 — Low

| # | File | Issue | Reviewer(s) | Confidence | Route |
|---|------|-------|-------------|------------|-------|
| 2 | test/test_workpattern_holidays.rb:63 | `refute_includes dates, Date.new(2027, 12, 31)` is structurally vacuous — the query window can never return a prior-year date, so the assertion can't fail regardless of correctness | testing | 75 (validated) | gated_auto -> downstream-resolver |

## Validator-Rejected (Stage 5b)

Autofix mode runs Stage 5b validation eagerly. 5 findings reached the confidence-75 actionable tier; validators rejected 3:

- **testing** "Documented 'sorted' return contract has no test coverage" (holidays.rb:48) — REJECTED. `Holidays.between` calls `.sort_by { |a| a[:date] }` as its own last step (confirmed in the installed 8.8.0 source), so "sorted" is true by construction, not a fragile untested assumption.
- **adversarial** "Cascade: exception partway through the holiday loop leaves the workpattern half-mutated" (holidays.rb:57) — REJECTED. Traced the full `#resting` call chain; it contains no `raise` for well-formed `Date` input (out-of-range dates are absorbed, not rejected). The only real exception source, `Holidays::InvalidRegion`, fires once before the loop starts. Also contradicts the plan's deliberate R11 "no new validation" decision.
- **adversarial** "Concurrent mutation: two threads racing on the unguarded `@weeks` SortedSet" (holidays.rb:59) — REJECTED. The race is real but pre-existing in `#resting` since 2012, and was explicitly scoped out of the prior thread-safe-registry plan ("No change to `calc`, `diff`, `working?`, or `find_weekpattern`"). This diff adds a new caller of unchanged `#resting`, not a new hazard.

## Suppressed at Confidence Gate (below anchor 75)

- **maintainability** "Redundant `assert refute(...)` pattern" (P3, anchor 50) — this is the codebase's existing convention (used throughout `test/test_workpattern_serialisation.rb` etc.), not a defect this diff introduced.
- **api-contract** "`Holidays::InvalidRegion` leaks as part of the public error contract" (P2, anchor 50) — this is a deliberate, already-reasoned architectural decision from the plan's Key Technical Decisions section (R11), not an oversight.

## Pre-existing

None flagged.

## Learnings & Past Solutions

No prior `docs/solutions/` entries apply — this is the first documented instance of a soft/optional gem dependency and a standalone opt-in module in this repo. `ce-learnings-researcher` flagged two genuinely new, capture-worthy patterns discovered during this diff's implementation, both good `/ce-compound` candidates:
1. `module Workpattern::Holidays` vs the top-level `::Holidays` gem — a real Ruby lexical-scoping collision (bare `Holidays.between` inside the nested module would resolve to itself, not the gem); the fix (`::Holidays.between`) is already applied in the shipped code.
2. `Workpattern#working?`/`#resting` expect `Time`/`DateTime` built via `Time.gm`, not bare `Date` objects — `Date#to_time` uses the local timezone and can shift day boundaries (discovered while writing this diff's tests, under BST).

## Agent-Native Gaps

None. `ce-agent-native-reviewer` returned PASS — this is a pure Ruby library with no UI/agent-tool layer; the public method itself is the programmatic interface, agent-accessible by construction.

## Coverage

- Suppressed: 2 findings below anchor 75 (both P2/P3, no P0-at-50+ exception applicable)
- Validator drops: 3 findings rejected by Stage 5b (reasons above)
- Untracked files excluded: none
- Failed/timed-out reviewers: none — all 9 returned successfully
- Residual risks noted by reviewers (non-actionable, FYI): unsynchronized concurrent per-instance mutation (pre-existing, noted by 3 independent reviewers as residual/finding), orphaned-Week growth from repeated out-of-range `apply` calls (documented plan risk), stitching multiple years' `apply` calls requires unioning the adjacent year's tail for backward-shifting regions (not currently documented — worth a future doc pass, not blocking)

## Verdict

**Ready with fixes.** Two small, well-understood findings (1 P2 doc-precision fix, 1 P3 test-assertion fix) remain unresolved per autofix mode policy. Both are gated_auto / downstream-resolver — no P0/P1, no correctness bugs, full test suite green (133 runs, 0 failures), rubocop clean on new files.
