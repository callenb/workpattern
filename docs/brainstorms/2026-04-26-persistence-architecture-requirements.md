---
date: 2026-04-26
topic: persistence-architecture
---

# Persistence Architecture: to_h / from_h

## Problem Frame

`Workpattern` has shipped a persistence callback API (`persistence_class=`) since at least 2012. The implementation has a confirmed naming bug: `@@persist` is set by `persistence_class=`, but `@@persistence` (a different, never-initialised variable) is read in `workpattern.rb:155`. The callback has silently done nothing in every released version.

The only open GitHub issue — open for 14 years — is a request to add persistence. Any user who attempted the documented callback got no errors and no storage.

This work replaces the broken callback with a `to_h` / `from_h` round-trip serialisation API. The approach is simpler (hash of final state, not event replay), independently testable, and composable with any storage backend the caller chooses.

---

## Requirements

**Removal**

- R1. Remove `persistence_class=`, `@@persist`, `@@persistence`, and `persistence?` from `lib/workpattern/workpattern.rb`. Remove the `persist` parameter from `WeekPattern#workpattern` in `lib/workpattern/week_pattern.rb`. No deprecation — the feature has never worked in any release, so no callers can have built a working integration.

**Serialisation API**

- R2. `Workpattern#to_h` (instance method) returns a plain Ruby hash that fully describes the workpattern's current state, sufficient to reconstruct it exactly.
- R3. The hash returned by `to_h` includes `version: 1` as a field. Planning determines the key order and exact field names.
- R4. `Workpattern.from_h(hash)` (class method) creates and registers a new Workpattern from the hash, raising `NameError` if a workpattern with the same name is already registered.
- R5. `Workpattern.from_h(hash, overwrite: true)` removes any existing workpattern with the same name before creating the new one; it does not raise on name conflict.
- R6. `from_h` raises with a clear, descriptive error message when the hash does not include a `version` key, or when the version value is not supported by the current gem.
- R7. `from_h(wp.to_h)` is an exact round-trip: the reconstructed Workpattern produces identical results to the original for `calc`, `diff`, and `working?` on any input within the original date range.

**Testing**

- R8. The test suite covers: basic round-trip (all-working baseline, resting overrides on specific days and time ranges), `NameError` on name conflict, silent replacement with `overwrite: true`, and clear error on missing or unsupported version.

---

## Acceptance Examples

- AE1. **Covers R4.** Given a Workpattern named `"uk_2026"` is registered, when `Workpattern.from_h({ name: "uk_2026", ... })` is called, a `NameError` is raised and the registry is unchanged.
- AE2. **Covers R5.** Given a Workpattern named `"uk_2026"` is registered, when `Workpattern.from_h({ name: "uk_2026", ... }, overwrite: true)` is called, the existing workpattern is replaced without error.
- AE3. **Covers R7.** Given `wp = Workpattern.new("test", 2020, 5)` with weekends set to resting and business hours 9–17 on weekdays, when `wp2 = Workpattern.from_h(wp.to_h)`, then `wp.diff(t1, t2) == wp2.diff(t1, t2)` for representative inputs covering weekday mornings, evenings, and weekend spans.

---

## Success Criteria

- Users can persist and reload workpatterns without writing custom serialisation code.
- The 14-year-old open GitHub issue is resolvable by pointing to `to_h` / `from_h`.
- The round-trip guarantee (R7) is verified by tests — no behavioral divergence between an original and a reconstructed workpattern.
- Planning can implement this without inventing additional product behavior, schema choices, or error types that belong in this document.

---

## Scope Boundaries

- No JSON or YAML convenience methods — callers convert the returned hash using whatever serialiser they already use.
- No migration path for data previously stored using the broken callback — the callback never worked, so no stored data exists.
- No changes to how workpatterns are created, configured, or calculated — `to_h` / `from_h` are additive; no existing call sites change.
- No persistence protocol, callback interface, or storage adapter — callers own the storage layer entirely.
- No changes to the `Workpattern.get`, `Workpattern.delete`, or `Workpattern.clear` registry APIs.

---

## Key Decisions

- **Remove callback rather than fix or deprecate it:** The callback has never worked, eliminating any backward-compat obligation. Keeping it alongside `to_h`/`from_h` would double the surface area for a pattern that was always architecturally wrong (it stored mutation events, not final state, making reconstruction impossible without replaying all mutations in order).
- **`version: 1` from day one:** Adding a version field now costs one hash key and two lines in `from_h`. Retrofitting it later requires all previously-stored data to be migrated or heuristically detected. The asymmetry strongly favours adding it now.
- **`overwrite:` option rather than always-raise or always-replace:** Always-raise forces callers to `delete` before `from_h`, which is safe but verbose for reload-on-restart workflows. Always-replace silently drops the current workpattern, which surprises callers who didn't intend to overwrite. An explicit `overwrite: true` makes the caller's intent unambiguous at the call site.

---

## Dependencies / Assumptions

- The broken callback has no working users — verified: `@@persistence` is never assigned in the codebase, so the callback could not have produced any stored output, and no existing data will be lost by removing it.
- `Day#pattern` is a Ruby `Integer` (Bignum for large values) whose value round-trips exactly through a Ruby hash. The serialised form (integer, hex string, or other encoding) is a planning-level choice that does not affect any requirement above.

---

## Outstanding Questions

### Resolve Before Planning

*(none)*

### Deferred to Planning

- [Affects R2, R7][Technical] What is the serialised form of `Day#pattern` in the hash? Integer (exact, but very large for JSON consumers), hex string (compact, always round-trips in any format), or another encoding? Planning should verify which encoding survives a JSON round-trip without precision loss before choosing.
- [Affects R6][Technical] What error class should `from_h` raise for an unsupported or missing `version`? `ArgumentError` is standard Ruby; a custom `Workpattern::VersionError < StandardError` would let callers rescue specifically. Either is acceptable; planning decides.
- [Affects R7][Technical] Does `from_h` need to reconstruct the exact `SortedSet` of `Week` objects including split boundaries, or only the logical bit-pattern state? If a workpattern was configured with overlapping `resting`/`working` calls that produced the same final pattern as a simpler configuration, the reconstructed workpattern must produce the same `calc`/`diff` answers — but need not reproduce the same internal `Week` split structure. Planning should confirm this is the right interpretation before implementing.

---

## Next Steps

→ `/ce-plan` for structured implementation planning
