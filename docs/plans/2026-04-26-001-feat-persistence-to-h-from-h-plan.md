---
title: "Persistence: to_h / from_h Round-Trip Serialisation"
date: 2026-04-26
status: completed
origin: docs/brainstorms/2026-04-26-persistence-architecture-requirements.md
---

# Persistence: to_h / from_h Round-Trip Serialisation

## Problem Frame

`Workpattern` has shipped a persistence callback API (`persistence_class=`) since at least 2012. The callback stores to `@@persist` but the `workpattern()` method reads `@@persistence` — a different, never-initialised variable. The feature has silently done nothing in every released version.

This plan replaces the broken callback with a `to_h` / `from_h` round-trip serialisation API: a plain Ruby hash of final state, independently testable, composable with any storage backend the caller chooses (see origin: `docs/brainstorms/2026-04-26-persistence-architecture-requirements.md`).

---

## Resolved Planning Questions

Three questions were deferred from the requirements document to planning. All are resolved here:

**Day#pattern encoding → hex string.**
`Day#pattern` is a Bignum (up to 1440 bits). Ruby hashes round-trip integers exactly, but JSON silently corrupts integers larger than 2^53. Using `pattern.to_s(16)` / `pattern.to_i(16)` is safe through every serialiser without special handling by callers.

**Error class for bad version → `ArgumentError`.**
Standard Ruby, descriptive message sufficient. A custom `Workpattern::VersionError` would let callers rescue specifically but adds a type callers have no other reason to reference. `ArgumentError` is the right fit for "you passed a hash with unsupported content."

**from_h reconstruction depth → logical bit-pattern state only.**
`from_h` must reproduce the `calc`/`diff`/`working?` answers — not the exact `Week` split boundaries. `find_weekpattern` only needs the correct `Day` for any date, so reconstructing each `Week` from its serialised start/finish dates and day patterns is sufficient. Simpler configurations and overlapping `resting`/`working` calls that produce the same final bit pattern will reconstruct identically.

---

## Implementation Units

### U1 — Remove the broken persistence callback

**Files:**
- `lib/workpattern/workpattern.rb`
- `lib/workpattern/week_pattern.rb`

**Scope:** Remove dead code only. No behaviour change for any working caller.

**Changes in `lib/workpattern/workpattern.rb`:**
- Remove the `persistence_class=` class method (lines 41–45) and the `persistence?` class method (lines 47–49).
- Simplify `#workpattern` (lines 153–159): remove the `if self.class.persistence?` branch; call `week_pattern.workpattern(opts)` unconditionally.
- Remove the `@@persistence` reference — it was never assigned and can simply be deleted as part of simplifying the method body.

**Changes in `lib/workpattern/week_pattern.rb`:**
- Remove the `persist` parameter from `WeekPattern#workpattern` (line 43): `def workpattern(opts = {})`.
- Remove the dead `persist.store(...)` call (line 46). Note: `@name` referenced there was never assigned in `WeekPattern`; this is doubly dead code.

**Test scenarios (in `test/test_workpattern.rb` or a new `test/test_workpattern_persistence_removal.rb`):**
- `Workpattern` does not respond to `.persistence_class=`.
- `Workpattern` does not respond to `.persistence?`.
- `wp.resting(...)` and `wp.working(...)` continue to apply patterns correctly (regression guard).

---

### U2 — Upgrade `Day#pattern=` and add `Day#to_h`

**Files:**
- `lib/workpattern/day.rb`

**Scope:** Fix a latent cache-coherence bug and add serialisation.

**Background:** `attr_accessor :pattern` generates a bare setter that does not call `set_first_and_last_minutes`. `Week#duplicate` (line 53) uses this setter directly:
```ruby
duplicate_week.days[i].pattern = @days[i].pattern
```
After this assignment, `first_working_minute` and `last_working_minute` are stale. The bug has no known symptom yet (duplicate is only called during configuration, before any calc/diff call re-enters the same day) but `from_h` would trigger it reliably. Fix it here.

**Changes in `lib/workpattern/day.rb`:**
- Replace the single `attr_accessor :pattern, :hours_per_day, :first_working_minute, :last_working_minute` line with a selective writer upgrade. The replacement declares three attributes via `attr_accessor` and adds a custom writer for `pattern`:
  ```ruby
  attr_accessor :hours_per_day, :first_working_minute, :last_working_minute
  attr_reader :pattern
  def pattern=(value)
    @pattern = value
    set_first_and_last_minutes
  end
  ```
- Add `Day#to_h` (public):
  ```ruby
  def to_h
    { pattern: @pattern.to_s(16), hours_per_day: @hours_per_day }
  end
  ```
- Add `Day.from_h(h)` (class method, public):
  ```ruby
  def self.from_h(h)
    day = allocate
    day.hours_per_day = h[:hours_per_day]
    day.pattern = h[:pattern].to_i(16)   # setter calls set_first_and_last_minutes
    day
  end
  ```
  Use `allocate` to bypass `initialize` (which would set a default pattern we immediately overwrite).

**Test scenarios (in `test/test_day.rb`):**
- `Day#to_h` returns a hash with `:pattern` (hex string) and `:hours_per_day`.
- `Day#to_h` round-trips: `Day.from_h(day.to_h).pattern == day.pattern`.
- `Day.from_h` sets `first_working_minute` and `last_working_minute` correctly (cache coherence).
- `pattern=` setter on an existing Day calls `set_first_and_last_minutes` (cache updated).
- All-resting day (pattern == 0): `to_h`/`from_h` round-trips to a day where `working_minutes == 0`.
- All-working day: round-trips correctly.

---

### U3 — Add `Week#to_h` and `Week.from_h`

**Files:**
- `lib/workpattern/week.rb`

**Scope:** Serialise one week's date range and all 7 day patterns.

**Background:** `@days` is indexed 0 (Sunday) through 6 (Saturday), filled by `FIRST_DAY_OF_WEEK.upto(LAST_DAY_OF_WEEK)`. The array always has exactly 7 entries after initialisation.

**Changes in `lib/workpattern/week.rb`:**
- Add `Week#to_h` (public):
  ```ruby
  def to_h
    { start:  { year: @start.year,  month: @start.month,  day: @start.day },
      finish: { year: @finish.year, month: @finish.month, day: @finish.day },
      days:   (FIRST_DAY_OF_WEEK..LAST_DAY_OF_WEEK).map { |i| @days[i].to_h } }
  end
  ```
- Add `Week.from_h(h)` (class method, public):
  ```ruby
  def self.from_h(h)
    s = h[:start];  f = h[:finish]
    week = allocate
    week.hours_per_day = HOURS_IN_DAY
    week.start  = Time.gm(s[:year], s[:month], s[:day])
    week.finish = Time.gm(f[:year], f[:month], f[:day])
    week.days   = Array.new(LAST_DAY_OF_WEEK + 1)   # size 7: indices 0 (Sun) through 6 (Sat)
    h[:days].each_with_index { |dh, i| week.days[i] = Day.from_h(dh) }
    week
  end
  ```
  `LAST_DAY_OF_WEEK` is `SATURDAY = 6`. `Array.new(6)` would create only 6 elements (indices 0–5), losing Saturday. Use `LAST_DAY_OF_WEEK + 1` (7) to match the 0..6 index range. The existing `Week#initialize` avoids this by assigning via `upto` which auto-extends; `from_h` must be explicit.

  `week.hours_per_day` is hardcoded to `HOURS_IN_DAY = 24`. The Week-level field is only used during `initialize` to create Days; `from_h` creates Days directly from their serialised hashes (each of which carries its own `hours_per_day`). The Week-level field is never read by `calc`, `diff`, or `working?`. Since `hours_per_day` is always 24 in the current codebase, hardcoding it here is safe and keeps the serialised hash simpler. If non-24-hour days are added in a future version, this assumption must be revisited and `hours_per_day` added to the `Week#to_h` schema.

**Note on `Week#duplicate`:** Now that `Day#pattern=` refreshes the cache, `Week#duplicate` gets the cache fix for free: `duplicate_week.days[i].pattern = @days[i].pattern` will now call `set_first_and_last_minutes`. This results in a redundant second cache computation (the cloned Day already has a valid cache from `clone`), but produces the correct result. No change needed in `week.rb`.

**Test scenarios (in `test/test_week.rb`):**
- `Week#to_h` returns a hash with `:start`, `:finish` (each with `:year`, `:month`, `:day`), and `:days` (7-element array).
- Each element of `:days` has `:pattern` (hex string) and `:hours_per_day`.
- `Week.from_h(week.to_h)` reconstructs a week whose `working?` and `working_minutes` return the same values as the original for each day of the week.
- Round-trip with resting weekends (indices 0 and 6 all zeros): correct after from_h.

---

### U4 — Add `Workpattern#to_h`

**Files:**
- `lib/workpattern/workpattern.rb`

**Scope:** Compose Week serialisations into a complete top-level hash.

**Changes:**
- Add `Workpattern#to_h` (public instance method):
  ```ruby
  def to_h
    { version:     1,
      name:        @name,
      base:        @base,
      span:        @span,
      weeks:       @weeks.map(&:to_h) }
  end
  ```
  `@weeks` is a `SortedSet` ordered by `Week#start`, so `map` enumerates weeks chronologically — no explicit sort needed.

**Test scenarios (in `test/test_workpattern_serialisation.rb`):**
- `wp.to_h` includes `:version => 1`.
- `:name`, `:base`, `:span` match the constructor arguments.
- `:weeks` is an array; each element has `:start`, `:finish`, `:days`.
- Calling `to_h` twice returns an equal hash (idempotent).

---

### U5 — Add `Workpattern.from_h`

**Files:**
- `lib/workpattern/workpattern.rb`

**Scope:** Validate, optionally overwrite, reconstruct, and register a Workpattern from a hash.

**Changes:**
- Add `Workpattern.from_h(hash, overwrite: false)` (public class method):

```ruby
def self.from_h(hash, overwrite: false)
  unless hash.key?(:version)
    raise ArgumentError, "from_h: hash is missing a :version key " \
                         "(if deserialising from JSON, use symbolize_names: true)"
  end
  unless hash[:version] == 1
    raise ArgumentError, "from_h: unsupported version #{hash[:version].inspect} " \
                         "(supported: 1)"
  end

  name = hash[:name]
  if workpatterns.key?(name)
    if overwrite
      workpatterns.delete(name)
    else
      raise NameError, "Workpattern '#{name}' already exists and can't be created again"
    end
  end

  wp = allocate
  wp.instance_variable_set(:@name, name)
  wp.instance_variable_set(:@base, hash[:base])
  wp.instance_variable_set(:@span, hash[:span])

  offset = hash[:span] < 0 ? hash[:span].abs - 1 : 0
  base_abs = hash[:base].abs
  from_time = Time.gm(base_abs - offset)
  to_time   = Time.gm(from_time.year + hash[:span].abs - 1, 12, 31, 23, 59)
  wp.instance_variable_set(:@from, from_time)
  wp.instance_variable_set(:@to,   to_time)

  weeks = SortedSet.new
  hash[:weeks].each { |wh| weeks << Week.from_h(wh) }
  wp.instance_variable_set(:@weeks, weeks)
  wp.instance_variable_set(:@week_pattern, WeekPattern.new(wp))

  workpatterns[name] = wp
  wp
end
```

  Use `allocate` to bypass `initialize` (which raises on duplicate name and creates a default Week we don't need).

**Test scenarios (in `test/test_workpattern_serialisation.rb`):**
- `from_h(wp.to_h)` succeeds and returns a Workpattern registered under the same name (after `Workpattern.delete(name)` to clear the original, or use `overwrite: true`).
- `from_h({})` raises `ArgumentError` with a message mentioning `:version`.
- `from_h({ version: 99, name: "x", ... })` raises `ArgumentError` mentioning the unsupported version.
- `from_h(hash)` when name already registered raises `NameError` (covers R4 / AE1).
- `from_h(hash, overwrite: true)` when name already registered succeeds silently (covers R5 / AE2).
- After overwrite, the old workpattern is replaced in the registry.
- Round-trip `calc` agreement: create `wp`, configure weekends resting + business hours 09:00–17:00 on weekdays, call `wp2 = Workpattern.from_h(wp.to_h, overwrite: true)`, assert `wp.diff(t1, t2) == wp2.diff(t1, t2)` for representative inputs (covers R7 / AE3).

---

### U6 — Test file

**File:** `test/test_workpattern_serialisation.rb`

New file. Contains all scenarios from U4 and U5 plus the cross-unit round-trip scenarios. Follows the `Minitest::Test` style used in `test/test_workpattern.rb` and `test/test_day.rb`.

**Scenarios (complete list):**

1. `to_h` basic structure — all fields present, version is 1.
2. `to_h` is idempotent — two calls return equal hashes.
3. `from_h` missing `:version` — raises `ArgumentError`.
4. `from_h` unsupported version — raises `ArgumentError` with version value in message.
5. `from_h` name conflict — raises `NameError` (AE1).
6. `from_h` name conflict with `overwrite: true` — succeeds, registry updated (AE2).
7. Round-trip on all-working workpattern — `diff`, `calc`, `working?` agree.
8. Round-trip on workpattern with resting weekends — weekend days show 0 working minutes.
9. Round-trip on workpattern with business-hours restriction (09:00–17:00 weekdays) — `diff` and `calc` agree for weekday morning, evening, and cross-weekend inputs (AE3).
10. `from_h` registers the reconstructed workpattern — `Workpattern.get(name)` returns it.
11. `from_h` with `overwrite: true` replaces rather than duplicates — registry has exactly one entry for the name.
12. `from_h` with string-keyed hash (JSON default) — raises `ArgumentError` and the message mentions `symbolize_names: true`.

---

## Sequencing

```
U1 (remove callback) → independent, can land first
U2 (Day#to_h + pattern= fix)
U3 (Week#to_h) — depends on U2
U4 (Workpattern#to_h) — depends on U3
U5 (Workpattern.from_h) — depends on U2, U3, U4
U6 (test file) — written alongside U4/U5, run after U5
```

U1 is purely subtractive and carries no risk. Implement it first and verify the existing test suite passes before adding serialisation code.

---

## Decisions

- **`allocate` for `from_h` constructors:** `Day.from_h`, `Week.from_h`, and `Workpattern.from_h` all use `allocate` to bypass `initialize`. This avoids the duplicate-name guard in `Workpattern#initialize`, the default-pattern creation in `Day#initialize`, and the default-week creation in `Week#initialize`. Each `from_h` is responsible for setting all instance variables the class depends on.
- **`Day#pattern=` upgrade:** The cache fix (calling `set_first_and_last_minutes`) belongs in the setter rather than every call site. This fixes `from_h`, fixes the latent bug in `Week#duplicate`, and makes the invariant hold for any future writer.
- **Hash keys are symbols:** The serialised hash uses symbol keys throughout (`:version`, `:name`, `:pattern`, etc.). `from_h` accesses hash values by symbol key. Callers who round-trip through JSON must use `JSON.parse(json, symbolize_names: true)` before passing the hash to `from_h`. The version-missing error message explicitly names this requirement to prevent a misleading "corrupt data" impression when the real problem is string vs symbol keys.
- **`SortedSet` preserved via ordered reconstruction:** The `weeks` SortedSet is rebuilt by inserting `Week.from_h` objects one at a time; `Week#<=>` orders by `start`, so the ordering is preserved without extra sorting.
- **No changes to public API surface beyond additions:** `calc`, `diff`, `working?`, `resting`, `working`, `get`, `delete`, `clear`, `to_a` are untouched. The only removals are the broken `persistence_class=` and `persistence?`, which have never functioned and have no working users (see origin).

---

## Risks

- **`allocate` coupling:** `from_h` bypasses `initialize` and sets instance variables directly. If `initialize` is changed later to set new instance variables, `from_h` must be updated in sync. The test suite's round-trip scenarios will catch divergence.
- **`Week#duplicate` latent bug:** The `pattern=` fix (U2) also fixes `Week#duplicate`. There is a small risk that something depended on the broken caching behaviour — unlikely, since `first_working_minute` / `last_working_minute` were silently wrong, not intentionally wrong. The existing test suite exercises `duplicate` (called by `WeekPattern#workpattern` during configuration), so any regression will surface immediately.
- **Symbol key contract:** Callers who deserialise from JSON must use `symbolize_names: true`. The `from_h` error message for a missing `:version` key explicitly names this. A test scenario (U6 scenario 12) confirms the error message is actionable. Worth a note in the CHANGELOG or README.

---

## Test Files

| Implementation Unit | Test File |
|---|---|
| U1 – callback removal | `test/test_workpattern.rb` (regression only; no new file needed) |
| U2 – Day#to_h + pattern= | `test/test_day.rb` |
| U3 – Week#to_h | `test/test_week.rb` |
| U4 – Workpattern#to_h | `test/test_workpattern_serialisation.rb` |
| U5 – Workpattern.from_h | `test/test_workpattern_serialisation.rb` |
| U6 – round-trip scenarios | `test/test_workpattern_serialisation.rb` |
