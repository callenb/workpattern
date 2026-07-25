---
title: "Thread-Safe Named Registry"
type: fix
status: completed
date: 2026-07-24
origin: docs/brainstorms/2026-07-24-thread-safe-registry-requirements.md
---

# Thread-Safe Named Registry

## Overview

`Workpattern::Workpattern` keeps every named workpattern in a bare class variable, `@@workpatterns = {}` (`lib/workpattern/workpattern.rb:20`), with no synchronisation. Six class methods read or mutate it (`initialize`, `self.clear`, `self.to_a`, `self.get`, `self.delete`, `self.from_h`) and one method (`self.workpatterns`) leaks the live hash by reference. This plan adds a single `Mutex` guarding all registry access, fixes an incidental ordering bug in `initialize` uncovered while designing the critical section, and changes `self.workpatterns` to return a frozen duplicate instead of the live hash. No public visibility semantics change — a workpattern created on one thread remains visible to every other thread, matching today's behavior.

---

## Problem Frame

Concurrent callers (Rails serving concurrent requests, a Sidekiq worker pool, or JRuby with real thread parallelism — this gem has historically been tested under JRuby, per `.travis.yml:9-10`) can race on `@@workpatterns` in two ways:

- **Check-then-act races**: `initialize` (`workpattern.rb:62`) and `from_h` (`workpattern.rb:190`) each check `workpatterns.key?(name)` then insert afterward, with no atomicity between the two steps. Two threads racing to create the same name can both pass the check.
- **Concurrent-mutation hazards**: reading (`to_a`, `get`) while another thread writes (`new`, `delete`, `clear`) can raise `RuntimeError` on Hash iteration or produce inconsistent reads.

Separately, `self.workpatterns` (`workpattern.rb:22-24`, facade re-exported at `lib/workpattern.rb:92-94`) returns `@@workpatterns` itself, not a copy. Any caller holding that reference can mutate the registry directly, which would defeat any locking added around the class's own methods.

(See origin: `docs/brainstorms/2026-07-24-thread-safe-registry-requirements.md` for the full problem frame, including why thread-local storage — the ideation doc's original proposal — was explicitly rejected in favor of keeping the existing shared-registry visibility model.)

---

## Requirements Trace

- R1. Registry stays a single shared structure visible to all threads — no thread-local storage, no opt-in shared namespace.
- R2. All registry mutation (`new`, `delete`, `clear`, `from_h`) is mutually exclusive with all other registry mutation and with registry reads (`get`, `to_a`).
- R3. The uniqueness guarantee holds under concurrent creation: exactly one of two concurrent `Workpattern.new("x")` calls for the same name succeeds; the registry ends with exactly one entry for that name.
- R4. `Workpattern.workpatterns` stops returning the live internal hash; it returns a non-mutable view.
- R5. The changed return value of `.workpatterns` does not break its existing read-only usage (`test/test_workpattern_serialisation.rb:163`).
- R6. A concurrency stress test demonstrates R2/R3 hold under real multi-threaded contention, not just single-threaded unit tests.

---

## Scope Boundaries

- No thread-local storage, no opt-in "shared base namespace" — explicitly rejected in the origin brainstorm.
- No changes to `Day`, `Week`, or `WeekPattern` — scoped to the `Workpattern` class-level registry only.
- No Ractor support, no lock-free/atomics redesign — a single stdlib `Mutex` is sufficient given registry operations are infrequent relative to the calculation hot path.
- No change to `calc`, `diff`, `working?`, or `find_weekpattern` — none of these touch `@@workpatterns` (confirmed by reading the full file; they operate only on the instance's own `@weeks`/`@from`/`@to`).
- No new external dependency — `concurrent-ruby` is only a transitive dependency of `tzinfo` (`Gemfile.lock:9,54`), not declared in the gemspec; adding it as a direct dependency for this fix is unjustified when stdlib `Mutex` is sufficient.
- No new Rubocop `Style/ClassVars` category introduced — `@@workpatterns` is already a known, currently-flagged offense (`Style/ClassVars`, unexcluded in `.rubocop_todo.yml:438-441` despite the commented-out exclude line) that the team has deliberately deferred (commit `7ba57b4`: "class variables ... require refactoring"). A `@@mutex` class variable is one more instance of the same accepted offense, not a new problem.

---

## Context & Research

### Relevant Code and Patterns

- `lib/workpattern/workpattern.rb:18-24` — `@@workpatterns` declaration and the existing `self.workpatterns` reader to be changed.
- `lib/workpattern/workpattern.rb:61-76` — `initialize`: check-then-insert race, and the ordering issue described in Key Technical Decisions below.
- `lib/workpattern/workpattern.rb:90-120` — `self.clear`, `self.to_a`, `self.get`, `self.delete`: straightforward reads/writes to guard.
- `lib/workpattern/workpattern.rb:175-213` — `self.from_h`: validation, then the same check-then-insert/overwrite race as `initialize`.
- `lib/workpattern.rb:92-94` — module-level facade delegating `self.workpatterns` straight to the class method; no change needed here since it only forwards the return value.
- `test/test_workpattern_module.rb` — existing registry-behavior tests (`test_must_raise_error_when_creating_workpattern_with_existing_name`, `test_must_return_an_array_of_all_known_workpattern_objects`, etc.); each test's `setup` calls `Workpattern.clear`, confirming tests run sequentially with no shared-state teardown hazard for a module-level `Mutex` constant.
- `test/test_workpattern_serialisation.rb:163` — the one existing caller of `Workpattern.workpatterns` that must keep working against a frozen dup.
- Style conventions confirmed by reading the file: no `attr_accessor`/`attr_writer` in `lib/`, `public`/`private` used as bare section markers, plain `raise ExceptionClass, "message"` with no custom exception classes — the Mutex addition should follow the same plain-Ruby style with no new abstractions.

### Institutional Learnings

- No `docs/solutions/` directory exists in this repo — no prior learnings to build on for concurrency, class variables, or registry patterns. This is a new category of change for the codebase (the team's recent commits have been readability/rubocop hygiene, not thread-safety work). Worth documenting under `docs/solutions/` after landing, per the project's compounding convention — noted under Documentation / Operational Notes below.

### External References

- None consulted — stdlib `Mutex` usage is well-established Ruby, and the codebase's own conventions (confirmed above) are sufficient to guide a house-style-consistent implementation.

---

## Key Technical Decisions

- **A single global `Mutex` constant, not per-operation or reader/writer locks:** Registry operations (`new`, `get`, `delete`, `clear`, `to_a`, `from_h`) are infrequent relative to the calculation hot path (`calc`/`diff`/`working?` never touch `@@workpatterns`). A single lock adds negligible overhead and avoids the complexity of finer-grained locking for no measurable benefit at this gem's scale.
- **Hold the lock across the entire check-and-build-and-insert sequence in `initialize` and `from_h`, not just the check+insert:** Splitting the critical section (check name inside the lock, build the `Week`/`WeekPattern` objects outside it, then re-acquire to insert) reopens exactly the TOCTOU race the lock exists to close — a second thread could pass the name check in the gap. Since registry operations are not hot-path, the simplest and only fully-correct option is to hold the lock for the full method body from the name check through the final registry write.
- **Incidental fix: construct `@week_pattern` before inserting into the registry, not after.** Reading `initialize` closely (`workpattern.rb:74-75`) shows `workpatterns[@name] = self` happens *before* `@week_pattern = WeekPattern.new(self)`. Under the new lock, a concurrent reader could theoretically... no — since the whole method body is now inside the lock, no reader can observe the object mid-construction at all. But since this plan is already touching this exact code (line ordering falls naturally out of designing the critical section), reorder so `@week_pattern` is set before the registry insert, matching the general principle "never publish a partially-constructed object" and removing what would otherwise be a latent single-threaded footgun if the lock boundary is ever narrowed later. Low cost (swap two lines), meaningfully more correct.
- **Two distinct accessor paths — internal direct access vs. external locked-and-frozen access:** `initialize`, `self.clear`, `self.to_a`, `self.get`, `self.delete`, and `self.from_h` all read/write the registry from *inside* their own `@@mutex.synchronize` block (per the previous decision). None of them may reach the registry through `self.workpatterns` (the public accessor U2 changes) or route through it indirectly, for two independent reasons verified against real Ruby semantics: (1) `Mutex` is not reentrant — a thread calling `@@mutex.synchronize` again while it already holds the lock raises `ThreadError: deadlock; recursive locking` (confirmed with `ruby -e 'm=Mutex.new; m.synchronize{ m.synchronize{} }'`), so every one of the six methods would deadlock on its very first call, not just under contention; (2) once `self.workpatterns` returns a frozen duplicate, any internal write attempted through it (`workpatterns[@name] = self`, `workpatterns.clear`, `workpatterns.delete(name)`, `workpatterns[name] = wp`) raises `FrozenError`. The fix is to give the registry two distinct access paths: inside the six locked methods, read/write the `@@workpatterns` class variable directly (it's already reachable from both class and instance methods of the same class — no accessor call needed); `self.workpatterns` becomes the sole external-facing entry point, used only by callers who are not already holding the lock.
- **`self.workpatterns` returns `@@workpatterns.dup.freeze`, not the live hash:** A shallow frozen duplicate satisfies the one existing read-only caller (`test/test_workpattern_serialisation.rb:163`, a `.keys.select` call) while making direct mutation attempts raise `FrozenError` instead of silently corrupting the real registry. Values (the `Workpattern` objects themselves) are not frozen — only the hash structure — since nothing requires deep-freezing the workpattern objects themselves. This method is reserved exclusively for external callers per the decision above.
- **Plain stdlib `Mutex`, not `concurrent-ruby`:** `concurrent-ruby` is present only transitively via `tzinfo` (`Gemfile.lock:9,54`) and is not declared in the gemspec. Adding it as a direct dependency for one `Mutex` is unjustified; stdlib `Mutex` requires no new dependency and matches the gemspec's implicit "no new deps without reason" posture (no dependencies have been added since `tzinfo`/`sorted_set`).

---

## Open Questions

### Resolved During Planning

- Lock granularity: single global `Mutex` (see Key Technical Decisions).
- Critical section boundaries in `initialize`/`from_h`: whole method body, not just check+insert (see Key Technical Decisions).
- Non-mutable view mechanism: `@@workpatterns.dup.freeze` (see Key Technical Decisions).
- Accessor split to avoid Mutex re-entrancy and `FrozenError`: internal call sites reference `@@workpatterns` directly; `self.workpatterns` is reserved exclusively for external callers (see Key Technical Decisions, "Two distinct accessor paths" — surfaced during document review, since a naive reading of the original U1/U2 draft would have every internal call site route through the same accessor U2 locks and freezes, deadlocking on the first call).

### Deferred to Implementation

- Exact assertion style for the stress-test unit (thread count, iteration count) is left to the implementer — enough to reliably exercise contention without making the test suite slow. A few dozen threads with a few hundred iterations each is typically sufficient to surface a check-then-act race if one exists; the implementer should tune for a fast, reliable, non-flaky test rather than hit a specific number.

---

## Implementation Units

- U1. **Guard registry mutation and lookup with a single Mutex**

**Goal:** All six registry-touching methods (`initialize`, `self.clear`, `self.to_a`, `self.get`, `self.delete`, `self.from_h`) become mutually exclusive with each other, closing both the check-then-act race and the concurrent-mutation hazard.

**Requirements:** R1, R2, R3

**Dependencies:** None

**Files:**
- Modify: `lib/workpattern/workpattern.rb`
- Test: `test/test_workpattern_module.rb`, `test/test_workpattern_serialisation.rb`

**Approach:**
- Add a `@@mutex = Mutex.new` class variable near the existing `@@workpatterns = {}` declaration (`workpattern.rb:20`), matching the codebase's existing bare class-variable style (already an accepted, deliberately-deferred Rubocop `Style/ClassVars` offense — see Scope Boundaries).
- Inside every locked method body below, read and write the registry via the `@@workpatterns` class variable **directly** — never through `self.workpatterns` or the private instance-level `workpatterns` helper (`workpattern.rb:82-84`). Calling `self.workpatterns` from inside an already-held `@@mutex.synchronize` block deadlocks (Ruby's `Mutex` is not reentrant), and after U2 that method also returns a frozen duplicate, so a write through it would raise `FrozenError`. See Key Technical Decisions ("Two distinct accessor paths").
- Wrap the full body of `initialize` (name-check through registry insert, `workpattern.rb:62-75`) in `@@mutex.synchronize`, checking and inserting via `@@workpatterns` directly, and reordering so `@week_pattern = WeekPattern.new(self)` happens before the registry insert (see Key Technical Decisions).
- Wrap `self.clear`, `self.to_a`, `self.get`, `self.delete` bodies in `@@mutex.synchronize`, each operating on `@@workpatterns` directly instead of calling `workpatterns`.
- Wrap the full body of `self.from_h` (name/version/field validation through registry insert or overwrite, `workpattern.rb:175-213`) in `@@mutex.synchronize`, using `@@workpatterns` directly for the existence check, the delete-on-overwrite, and the final insert.
- Remove or repurpose the private instance method `workpatterns` (`workpattern.rb:82-84`) — with `initialize` now referencing `@@workpatterns` directly, this delegation to `self.class.workpatterns` is no longer needed and would otherwise reintroduce the same deadlock/FrozenError risk if left calling the public accessor.
- Do not change any method's raised exception types or messages — only add synchronisation around existing logic.

**Patterns to follow:**
- `lib/workpattern/workpattern.rb` existing bare `raise(NameError, "...")` / `raise ArgumentError, "..."` style — no new exception classes.
- Existing `public`/`private` bare section markers (`workpattern.rb:80,86`) — keep the Mutex declaration and any newly-private helpers consistent with this.

**Test scenarios:**
- Happy path: existing single-threaded tests in `test/test_workpattern_module.rb` (create, get, delete, clear, to_a) continue passing unmodified — no behavior change for sequential callers.
- Edge case: `test_must_raise_error_when_creating_workpattern_with_existing_name` (already exists) continues to pass, confirming the lock doesn't change single-threaded `NameError` behavior.
- Integration: round-trip `from_h` tests in `test/test_workpattern_serialisation.rb` (overwrite: true/false paths) continue to pass with the full method body now locked.

**Verification:**
- Full existing test suite passes unchanged (`121 runs, 0 failures, 0 errors` baseline before this plan) — this is the concrete signal that no deadlock or `FrozenError` was introduced, since any nested lock/frozen-write bug would fail every test that creates, clears, deletes, or reloads a workpattern, not just a concurrent one.
- Grep confirms none of the six locked methods calls `self.workpatterns` or the removed private `workpatterns` helper — all six reference `@@workpatterns` directly.
- Reading `initialize`, no path exists where a `Workpattern` is inserted into `@@workpatterns` before its `@week_pattern` is set.

---

- U2. **Close the raw-hash leak in `Workpattern.workpatterns`**

**Goal:** `Workpattern.workpatterns` (and the module facade that re-exports it) returns a frozen duplicate rather than the live registry hash, so external callers can no longer bypass U1's synchronisation by mutating the returned object directly.

**Requirements:** R4, R5

**Dependencies:** U1 (touches the same accessor region; land after the Mutex exists so the accessor read itself can also be guarded)

**Files:**
- Modify: `lib/workpattern/workpattern.rb`
- Test: `test/test_workpattern_serialisation.rb`

**Approach:**
- Change `self.workpatterns` (`workpattern.rb:22-24`) to acquire `@@mutex.synchronize` and return `@@workpatterns.dup.freeze` instead of `@@workpatterns` directly.
- This method is exclusively the external-facing entry point from this point on — per U1's revised Approach, no internal call site inside the six locked methods may call it (doing so would deadlock, since `Mutex` is not reentrant, and after this change would also raise `FrozenError` on any write attempt). U1 removes the private instance method `workpatterns` (`workpattern.rb:82-84`) that previously delegated to this accessor, closing off the one internal call site that would otherwise still reach it.
- No change needed in `lib/workpattern.rb:92-94` — it only forwards the return value of `Workpattern::Workpattern.workpatterns`, so the frozen-dup change propagates automatically through the facade.

**Test scenarios:**
- Happy path: `test/test_workpattern_serialisation.rb:163`'s existing `.keys.select` usage continues to pass unmodified against the frozen dup.
- Covers AE3. Edge case: after `Workpattern.new("readonly-check")`, `h = Workpattern.workpatterns; h["injected"] = 1` raises `FrozenError`, and a subsequent `Workpattern.workpatterns` call does not include `"injected"` — the real registry was unaffected.

**Verification:**
- `test/test_workpattern_serialisation.rb:163` passes unchanged.
- A new test confirms mutating the returned hash raises `FrozenError` and leaves the real registry untouched.

---

- U3. **Concurrency stress test**

**Goal:** Demonstrate, under real multi-threaded contention, that the uniqueness guarantee (R3) and mutual-exclusion property (R2) actually hold — not just that the code compiles with a Mutex added.

**Requirements:** R6

**Dependencies:** U1, U2

**Files:**
- Create or modify: `test/test_workpattern_module.rb` (or a new `test/test_workpattern_registry_concurrency.rb` if the implementer judges the scenarios substantial enough to warrant a dedicated file — either is acceptable; follow the `Minitest::Test` style used throughout `test/`)

**Approach:**
- Spawn multiple `Thread` instances that concurrently call `Workpattern.new` with a shared, colliding name; assert exactly one succeeds and the rest raise `NameError` (covers AE1).
- Spawn a mixed workload of threads concurrently calling `.new` (distinct names), `.get`, `.to_a`, `.delete`, and `.clear`; assert no thread raises an unexpected `RuntimeError` (e.g. "can't add a new key into hash during iteration") and the registry ends in an internally consistent state (covers AE2).
- Use `Thread#join` on all spawned threads before asserting, and re-raise any exception captured from a thread body (Minitest won't see exceptions raised inside a `Thread` unless they're surfaced back to the main thread) — a standard pattern for this kind of test, left to the implementer to express idiomatically.

**Test scenarios:**
- Covers AE1. Concurrency: 10+ threads simultaneously call `Workpattern.new("contested")` — exactly one succeeds, the other 9 raise `NameError`, and `Workpattern.get("contested")` afterward returns a single valid Workpattern.
- Covers AE2. Concurrency: a mixed-operation thread pool (create/get/to_a/delete on various names) run for enough iterations to reliably exercise interleaving — no unexpected exception escapes, and post-run registry state has no orphaned or duplicated entries.

**Verification:**
- The new test(s) fail if U1's `Mutex.synchronize` wrapping is removed (a reasonable manual check during review: temporarily comment out the lock and confirm the stress test now fails or flakes) and pass reliably (non-flaky across repeated runs) with it in place.
- Full test suite still passes with the new test(s) included.

---

## System-Wide Impact

- **Interaction graph:** Only the six registry-touching class methods are affected. `calc`, `diff`, `working?`, and `find_weekpattern` — the calculation hot path — never read or write `@@workpatterns` (confirmed by reading the full file), so no performance-sensitive code path is affected by the new lock.
- **State lifecycle risks:** The `initialize` reordering (U1) removes the only window where a `Workpattern` could be visible in the registry before being fully constructed. No other partial-construction paths exist (`from_h` already builds the object fully via `instance_variable_set` before inserting).
- **API surface parity:** `Workpattern.workpatterns` is re-exported unchanged in signature by the module facade (`lib/workpattern.rb:92-94`); only its return value's mutability changes, which is the intended fix (R4).
- **Unchanged invariants:** `calc`, `diff`, `working?`, `resting`, `working`, `to_h`, `from_h`'s validation/error behavior, and the `NameError`/`ArgumentError` contracts are all untouched — this plan only adds synchronisation and changes one accessor's return value from mutable to frozen.

---

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| A global `Mutex` held across `initialize`'s full body (including `Week.new`/`WeekPattern.new` construction) could, in principle, allow one slow construction to block other unrelated registry reads. | Registry operations are infrequent and construction is fast (no I/O); the origin brainstorm's own Dependencies section confirms this is not a hot path. Acceptable tradeoff for correctness (see Key Technical Decisions). |
| The stress test (U3) could be flaky if thread scheduling doesn't reliably interleave. | Implementer tunes thread/iteration counts for reliable, repeatable failure-without-the-fix rather than a fixed magic number (see Open Questions — Deferred to Implementation). |
| Freezing `self.workpatterns`'s return value could break an undiscovered caller beyond the one known test. | Confirmed via repo research: `test/test_workpattern_serialisation.rb:163` is the only external caller found in `lib/`, `test/`, and `README.md`; its usage is read-only (`.keys.select`) and unaffected by freezing. |

---

## Documentation / Operational Notes

- **Done:** [docs/solutions/logic-errors/thread-safe-workpattern-registry-2026-07-24.md](../solutions/logic-errors/thread-safe-workpattern-registry-2026-07-24.md) documents the Mutex approach and the rationale for a frozen-dup accessor over the raw hash — the first entry in this codebase's `docs/solutions/` and a reference point for any future registry changes.
- No CHANGELOG entry is strictly required for behavior correctness (no public API shape changes), but noting the fix under the next unreleased version section (following the existing `CHANGELOG.md` convention used for the `to_h`/`from_h` work) is reasonable given it closes a real correctness gap for concurrent callers.

---

## Sources & References

- **Origin document:** [docs/brainstorms/2026-07-24-thread-safe-registry-requirements.md](../brainstorms/2026-07-24-thread-safe-registry-requirements.md)
- Related code: `lib/workpattern/workpattern.rb`, `lib/workpattern.rb`
- Related ideation: `docs/ideation/2026-04-26-open-ideation.md` (idea #2 — thread-local proposal, rejected in favor of this approach)
