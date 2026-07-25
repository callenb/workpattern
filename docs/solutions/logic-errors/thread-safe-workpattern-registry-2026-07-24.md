---
title: Thread-Safe Named Workpattern Registry
date: 2026-07-24
category: docs/solutions/logic-errors
module: "Workpattern"
problem_type: logic_error
component: tooling
symptoms:
  - "Concurrent Workpattern.new calls with the same name can both succeed, violating the documented uniqueness guarantee (check-then-act race)"
  - "Concurrent reads (to_a, get) interleaved with writes (new, delete, clear) can raise RuntimeError mid Hash iteration"
  - "Workpattern.workpatterns returned the live @@workpatterns hash by reference, letting callers mutate the registry directly and bypass any locking"
root_cause: thread_violation
resolution_type: code_fix
severity: medium
tags: [thread-safety, mutex, concurrency, registry, class-variable, gvl]
related_components: [testing_framework]
---

# Thread-Safe Named Workpattern Registry

## Problem

`Workpattern::Workpattern` stored all named workpatterns in a bare, unsynchronized class variable `@@workpatterns = {}`, with six class methods (`initialize`, `self.clear`, `self.to_a`, `self.get`, `self.delete`, `self.from_h`) reading and writing it with zero locking, and `self.workpatterns` leaking the live hash by reference to callers.

## Symptoms

This bug has no observable failure under normal single-threaded use — all symptoms require concurrent callers (a Rails app serving concurrent requests, a Sidekiq worker pool, or JRuby with true thread parallelism):

- Two threads calling `Workpattern.new("x")` for the same name can both pass the `key?(name)` check and both insert, silently violating the documented uniqueness guarantee (only one should ever succeed, the other should raise `NameError`).
- `Workpattern.from_h` has the identical check-then-act race on its `overwrite` handling.
- A thread calling `.to_a` or `.get` while another thread calls `.new`/`.delete`/`.clear` can hit `RuntimeError: can't add a new key into hash during iteration`, or read a partially-consistent view of the registry.
- Any external caller holding a reference returned by `Workpattern.workpatterns` (the live hash) can mutate the registry directly — bypassing any locking discipline the class itself tries to enforce.

## What Didn't Work

- **Plain thread racing to reproduce the uniqueness bug.** The team first tried spinning up many threads (200) calling `Workpattern.new` with the same name against the pre-fix code and asserting more than one succeeded. This produced **zero observed races**, empirically, every time. `initialize`'s body is short and allocation-light, and under MRI's GVL the scheduler rarely preempts mid-method for code this fast — so the check-then-insert window almost never actually interleaves under ordinary thread scheduling, even with a large thread count. This made the race look "safe" under naive testing despite being a genuine defect. The fix was to force a scheduler checkpoint deterministically: setting `GC.stress = true` triggers a full GC (and therefore a thread-scheduling checkpoint) on every allocation, which reliably widened the check-then-insert window enough to expose the race with just a few threads.
- **Thread-local storage for the registry.** An earlier ideation doc (`docs/ideation/2026-04-26-open-ideation.md`, idea #2) proposed making `@@workpatterns` thread-local as a "low-risk" fix. This was explicitly rejected: it would silently change which threads can see a given workpattern (a workpattern created on one thread would no longer be visible to `.get`/`.to_a` on another thread), which is a real behavioral/API change disguised as an internal safety fix. The team chose instead to keep the existing shared, globally-visible registry model and simply synchronize access to it — fixing the actual defect (unsynchronized concurrent access) with zero visibility change for any existing caller.
- **The first draft of the implementation plan had a P0 defect: a Mutex re-entrancy deadlock** (session history). Internal methods (`clear`, `to_a`, etc.) were drafted calling the locked, frozen-dup external accessor (`self.workpatterns`) from inside an already-held lock — which both deadlocks (Ruby's `Mutex` is non-reentrant) and would hand internal code a frozen duplicate it can't mutate. Three parallel document-review personas (coherence, feasibility, adversarial) independently converged on the same root cause before any code was written. Fixed by splitting internal (direct `@@workpatterns` access, no lock re-acquisition) from external (`self.workpatterns`, locked + `.dup.freeze`) access paths — this became a documented Key Technical Decision in the plan rather than a bug discovered in implementation.

## Solution

Add a single `Mutex` guarding all six registry-touching methods, hold it across the *entire* check-then-act sequence (not just the check or the insert), route all internal registry access through `@@workpatterns` directly rather than through the public accessor, and stop leaking the live hash.

Registry declaration and the external accessor (`lib/workpattern/workpattern.rb`):

```ruby
# Before
@@workpatterns = {}

def self.workpatterns
  @@workpatterns
end
```

```ruby
# After
@@workpatterns = {}
@@mutex = Mutex.new

# Returns a frozen snapshot of the registry. Reserved for external callers;
# internal registry methods read/write @@workpatterns directly since they
# already hold @@mutex, and Mutex#synchronize is not reentrant.
def self.workpatterns
  @@mutex.synchronize { @@workpatterns.dup.freeze }
end
```

`initialize` — lock held across the whole check-build-insert sequence, and `@week_pattern` reordered before the registry write so no reader can ever observe a partially-constructed object:

```ruby
# Before
def initialize(name = DEFAULT_WORKPATTERN_NAME, base = DEFAULT_BASE_YEAR, span = DEFAULT_SPAN)
  raise(NameError, "Workpattern '#{name}' already exists and can't be created again") if workpatterns.key?(name)

  # ... build @name, @base, @span, @from, @to, @weeks ...

  workpatterns[@name] = self
  @week_pattern = WeekPattern.new(self)
end
```

```ruby
# After
def initialize(name = DEFAULT_WORKPATTERN_NAME, base = DEFAULT_BASE_YEAR, span = DEFAULT_SPAN)
  @@mutex.synchronize do
    raise(NameError, "Workpattern '#{name}' already exists and can't be created again") if @@workpatterns.key?(name)

    # ... build @name, @base, @span, @from, @to, @weeks ...

    @week_pattern = WeekPattern.new(self)
    @@workpatterns[@name] = self
  end
end
```

The private `workpatterns` instance-method delegate (`self.class.workpatterns`) was removed entirely — it was the one remaining internal call site that would have reached the now-locked, now-frozen public accessor.

The other methods follow the same pattern — wrap the body in `@@mutex.synchronize`, operate on `@@workpatterns` directly:

```ruby
def self.clear
  @@mutex.synchronize { @@workpatterns.clear }
end

def self.get(name)
  @@mutex.synchronize do
    return @@workpatterns[name] if @@workpatterns.key?(name)

    raise(NameError, "Workpattern '#{name}' doesn't exist so can't be retrieved")
  end
end

def self.delete(name)
  @@mutex.synchronize do
    result = @@workpatterns.delete(name).nil?
    !result
  end
end
```

`self.from_h` gets the same treatment — the entire validate/build/existence-check/insert sequence moves inside one `@@mutex.synchronize` block, using `@@workpatterns` directly for the `key?` check, the overwrite `delete`, and the final insert.

A dedicated concurrency test (`test/test_workpattern_registry_concurrency.rb`) races threads under `GC.stress = true` against `Workpattern.new` and `Workpattern.from_h` for the same name, asserting exactly one wins and the rest raise `NameError`, plus a natural-speed mixed create/get/to_a/delete smoke test. A code-review follow-up (`1a71bdc`) broadened the per-thread `rescue` to `StandardError` and added a concurrency test for `from_h`, which had the identical race but was previously unproven.

## Why This Works

Four distinct issues, all closed by the same lock plus one accessor change:

1. **Unsynchronized check-then-act.** `key?(name)` followed later by `[name] = self` is two separate hash operations with no atomicity between them. Wrapping both inside the *same* `@@mutex.synchronize` block makes the whole sequence indivisible from any other thread's perspective — no other thread can observe the registry between the check and the insert.
2. **Concurrent mutation during iteration/read.** `to_a`, `get`, `delete`, `clear`, and `new`/`from_h`'s inserts all touch the same `Hash`. Without mutual exclusion, a write during another thread's read can corrupt the Hash's internal iteration state (`RuntimeError`) or hand back an inconsistent value. A single mutex serializes every registry-touching operation against every other one.
3. **Mutex reentrancy pitfall.** Ruby's `Mutex` is not reentrant — a thread that calls `synchronize` while it already holds the lock deadlocks (`ThreadError: deadlock; recursive locking`) rather than proceeding. Since all six methods now acquire `@@mutex` themselves, none of them can call `self.workpatterns` (which also acquires `@@mutex`) internally — that's why every internal call site was rewritten to touch `@@workpatterns` directly, and why the old private `workpatterns` delegate had to be deleted rather than left in place.
4. **The raw-hash leak.** Even with all six methods now synchronized, `Workpattern.workpatterns` previously returned `@@workpatterns` itself. Any caller holding that reference could mutate it directly — `h[:x] = 1` — completely outside the lock, silently corrupting the "protected" registry. Returning `@@workpatterns.dup.freeze` closes this: the dup breaks the reference so external mutation can't touch the real hash, and freezing turns any attempted mutation into a loud `FrozenError` instead of a silent corruption.

## Prevention

- Hold the lock across the full check-then-act sequence, not just the check or just the insert. Splitting the critical section (check inside the lock, build objects outside, re-acquire to insert) reopens the exact TOCTOU window the lock exists to close.
- Never let a locked accessor's own public reader be called from inside the lock. `Mutex#synchronize` is not reentrant in Ruby — recursive locking deadlocks immediately, not just under contention. Give internal call sites a direct path to the underlying state (here, referencing `@@workpatterns` directly) instead of routing through the public API.
- Return frozen duplicates from accessors that expose internal mutable state, not the live object — otherwise any external caller holding the reference can bypass all your synchronization by mutating it directly.
- Plain thread-racing tests are not a reliable way to reproduce short, fast-body races under MRI's GVL. Racing 200 threads against an unguarded few-line method produced zero observed failures. Use `GC.stress = true` to force a scheduler checkpoint on every allocation — it reliably widens narrow race windows enough to expose them with just a few threads, and should be restored (`GC.stress = false`) in an `ensure` block since it's a process-wide VM setting.
- Broaden per-thread rescues in concurrency tests to `StandardError`, not specific exception classes. A narrow rescue lets an unexpected exception abort `threads.each(&:join)` early, leaving background threads still mutating shared state after the test method (and any `GC.stress` reset) has already returned.
- When one method has a check-then-act race, audit siblings with the same shape. `from_h`'s `overwrite` handling had the identical unguarded `key?` + insert pattern as `initialize` but was initially left untested — code review caught it, and it needed the identical fix and an identical GC.stress-based test.
- Reorder construction so a partially-built object is never inserted into a registry others can read from. Set all instance state (including derived/secondary state like `@week_pattern`) before publishing the object into any shared, externally-visible collection.
- When adding synchronization to a set of sibling accessor methods, review the design with fresh eyes (or parallel review passes) before implementing — the Mutex re-entrancy deadlock in this fix was caught during document review, not during implementation or testing, which is a cheaper place to catch it (session history).

## Related Issues

- Origin brainstorm: `docs/brainstorms/2026-07-24-thread-safe-registry-requirements.md`
- Implementation plan: `docs/plans/2026-07-24-001-fix-thread-safe-registry-plan.md`
- Fix landed via PR #27 (`fix/thread-safe-registry`), commits `23d8436`, `28aff6c`, `1a71bdc`
- Superseded ideation: `docs/ideation/2026-04-26-open-ideation.md` (idea #2 — thread-local storage, rejected)
- This is the first entry in this repo's `docs/solutions/` knowledge store — no prior related docs existed to cross-reference.
