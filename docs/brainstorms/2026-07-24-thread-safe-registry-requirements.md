---
date: 2026-07-24
topic: thread-safe-registry
---

# Thread-Safe Named Registry

## Problem Frame

`Workpattern::Workpattern` stores all named workpatterns in a bare class variable, `@@workpatterns = {}` (`lib/workpattern/workpattern.rb:20`), with no synchronisation anywhere in the codebase. `Workpattern.new`, `.get`, `.delete`, `.clear`, `.to_a`, and `.from_h` all read or mutate this hash without a lock.

Under concurrent access — a Rails app serving concurrent requests, a Sidekiq worker pool, or any multi-threaded deployment — this produces two classes of failure:

- **Check-then-act races.** `initialize` raises `NameError` if a name is already registered, then inserts. Two threads creating the same name concurrently can both pass the check and both insert, silently violating the uniqueness guarantee the API promises. The same pattern exists in `from_h`'s overwrite handling.
- **Concurrent-mutation hazards on the shared hash.** Reading (`to_a`, `get`) while another thread writes (`new`, `delete`, `clear`) can raise `RuntimeError` on Hash iteration, or produce inconsistent reads, depending on interleaving and Ruby engine (this is a genuine parallelism concern on JRuby/TruffleRuby, not just a GIL-interleaving concern on MRI, and the CHANGELOG shows this gem has tested against JRuby historically).

**Verified in code:** `@@workpatterns` (`lib/workpattern/workpattern.rb:20`) is read/written by `initialize` (:62, :74), `self.clear` (:91), `self.to_a` (:98), `self.get` (:106-109), `self.delete` (:118), and `self.from_h` (:190, :210-211) — none behind a lock.

**Note on the originating ideation doc:** The ideation entry that raised this (`docs/ideation/2026-04-26-open-ideation.md`, idea #2) also names `@@persist` and `@@tz` as bare, unsynchronised class variables. Both have since been removed (`@@persist` as part of the persistence-callback removal; `@@tz` in a separate cleanup commit) — verified absent from `lib/` and `test/`. `@@workpatterns` is the only remaining bare class variable this brainstorm addresses.

---

## Requirements

**Concurrency model**

- R1. The single shared registry (`@@workpatterns`) remains as-is in terms of *visibility* — a workpattern created on one thread must still be visible to `.get`/`.to_a` calls from any other thread. This brainstorm does **not** adopt thread-local storage; it makes the existing shared-registry model safe under concurrent access, matching the "safety without visibility change" direction chosen over the ideation doc's thread-local proposal.
- R2. All registry mutation (`new`, `delete`, `clear`, `from_h`) must be mutually exclusive with all other registry mutation and with registry reads (`get`, `to_a`) — no interleaving of a read with an in-progress write, and no interleaving of two writes.
- R3. The uniqueness guarantee — "a name already registered raises `NameError` on creation (or on `from_h` without `overwrite: true`)" — must hold under concurrent creation attempts for the same name. Exactly one of two concurrent `Workpattern.new("x")` calls for the same name succeeds; the other raises `NameError`, and the registry ends up with exactly one entry for that name.

**Closing the raw-hash leak**

- R4. `Workpattern.workpatterns` (and the module-level facade `Workpattern.workpatterns` in `lib/workpattern.rb`) must stop returning the live internal hash by reference. It returns a non-mutable view (e.g. a frozen duplicate) so that external callers cannot bypass the synchronised mutation methods by mutating the returned object directly.
- R5. The changed return value of `.workpatterns` must not break its existing read-only usage (`test/test_workpattern_serialisation.rb:163` calls `.keys.select` on the result) — read-only operations on the returned object continue to work unchanged.

**Testing**

- R6. In addition to normal single-threaded unit tests of the synchronised methods, add a concurrency stress test: multiple threads calling `Workpattern.new`/`.get`/`.delete`/`.clear` concurrently against shared and colliding names, asserting no exceptions escape, no entries are lost or duplicated, and R3's uniqueness guarantee holds under contention.

---

## Acceptance Examples

- AE1. **Covers R3.** Given no workpattern named `"contested"` exists, when 10 threads simultaneously call `Workpattern.new("contested")`, then exactly one thread returns successfully, the other 9 raise `NameError`, and `Workpattern.get("contested")` returns a single valid Workpattern afterward.
- AE2. **Covers R2, R6.** Given a mix of threads concurrently calling `.new` (distinct names), `.get`, `.to_a`, and `.delete`, when run under a stress test with a high iteration count, then no thread raises an unexpected `RuntimeError` (e.g. "can't add a new key into hash during iteration") and the final registry state is internally consistent (every name present maps to a real Workpattern, no orphaned entries).
- AE3. **Covers R4, R5.** Given `Workpattern.new("readonly-check")`, when `h = Workpattern.workpatterns` and the caller attempts `h["injected"] = something`, then a `FrozenError` (or equivalent) is raised and the real registry is unaffected; `h.keys.select { |k| k == "readonly-check" }` still returns `["readonly-check"]`.

---

## Success Criteria

- A multi-threaded caller (Rails with concurrent requests, Sidekiq worker pool, JRuby with real parallelism) can create, look up, and delete named workpatterns without risking silent duplicate-name corruption or hash-iteration exceptions.
- No visibility behavior changes for any existing single-threaded or thread-per-request caller — everything that works today continues to work identically.
- The raw-hash escape hatch (`Workpattern.workpatterns`) can no longer be used to bypass synchronisation.
- Planning can implement this without inventing additional concurrency behavior, lock granularity choices, or API surface that belongs in this document.

---

## Scope Boundaries

- No thread-local storage and no "shared base namespace" opt-in — the ideation doc's proposed model was explicitly declined in favor of keeping today's single shared, globally-visible registry.
- No changes to `Day`, `Week`, or `WeekPattern` internals — this is scoped to the `Workpattern` class-level registry only.
- No Ractor support and no lock-free/atomics-based redesign — a standard mutual-exclusion primitive around the registry is sufficient for this gem's scale and access pattern (registry operations are infrequent relative to `calc`/`diff`, which never touch `@@workpatterns`).
- No change to the calculation hot path (`calc`, `diff`, `working?`, `find_weekpattern`) — none of these read `@@workpatterns`; they operate entirely on the instance's own `@weeks`.
- No configurable locking strategy or pluggable backend — out of scope per the rejected "Pluggable Registry Backends" idea in the ideation doc's rejection summary.

---

## Key Decisions

- **Safety without visibility change, not thread-local-by-default:** The ideation doc's thread-local proposal would silently change which threads can see a given workpattern — a real behavioral/API change disguised as a low-risk internal fix. The chosen direction (synchronise the existing shared registry) fixes the actual defect (unsynchronised concurrent access) with zero behavior change for any current caller.
- **Close the raw-hash leak in the same pass:** `Workpattern.workpatterns` already returns the live hash by reference (used internally and by one test). Synchronising `new`/`get`/`delete`/`clear`/`from_h` alone would leave this as an unguarded bypass — anyone holding the returned hash could mutate the registry directly. Returning a frozen duplicate closes this without changing any read-only call site.
- **Stress test required, not optional:** Concurrency defects don't reliably reproduce under normal unit tests (execution order is usually deterministic on one thread). A dedicated multi-thread stress test is the only practical way to demonstrate the race is actually closed rather than merely code-reviewed.

---

## Dependencies / Assumptions

- Registry operations (`new`, `get`, `delete`, `clear`, `from_h`, `to_a`) are infrequent relative to calculation calls (`calc`, `diff`, `working?`) — verified by reading `find_weekpattern` and the calc/diff bodies, which reference only instance-level `@weeks`, `@from`, `@to`, never `@@workpatterns`. This means a straightforward mutual-exclusion primitive introduces no hot-path overhead.
- `@@persist` and `@@tz` (also named in the ideation doc's warrant) are already removed from the codebase — verified via `grep` across `lib/` and `test/`. Only `@@workpatterns` remains as a bare, unsynchronised class variable.
- The gem's `required_ruby_version` is `>= 3.1` (per `workpattern.gemspec`) and the CHANGELOG records historical JRuby testing — both support using a standard `Mutex`/`Thread::Mutex` without additional dependencies.

---

## Outstanding Questions

### Resolve Before Planning

*(none)*

### Deferred to Planning

- [Affects R2][Technical] Lock granularity: a single global `Mutex` guarding all registry operations, versus finer-grained locking (e.g. separate read/write locks). Given registry operations are infrequent (see Dependencies), planning should default to the simplest option (one global lock) unless a concrete reason emerges to do otherwise.
- [Affects R2][Technical] Where exactly to draw the critical section in `initialize` and `from_h` — these methods do more than touch the registry (e.g. building `Week`/`WeekPattern` objects). Planning decides how much of each method's body needs to be inside the lock versus only the registry check-and-insert step.
- [Affects R4][Technical] Exact mechanism for the non-mutable view: frozen shallow `dup`, `Hash#freeze` on a copy, or another read-only wrapper. Planning picks the simplest option that satisfies R5.

---

## Next Steps

→ `/ce-plan` for structured implementation planning
