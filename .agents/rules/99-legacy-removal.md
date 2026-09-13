# 99 — LEGACY REMOVAL & MIGRATION GOVERNANCE

## 1. Migration Philosophy
1. **No Parallel Authorities**: Old/legacy implementations and new canonical implementations MUST NOT co-exist in production indefinitely.
2. **Complete Lifecycle**: Every architectural migration MUST follow the explicit 7-step lifecycle:

```text
Discover
   ↓
Classify
   ↓
Introduce
   ↓
Migrate
   ↓
Verify
   ↓
Remove
   ↓
Scan
```

---

## 2. Migration Step Governance
1. **Discover**: Identify all existing legacy implementations, duplicated business logic, parallel authorities, hardcoded defaults, and direct database bypasses across the repository.
2. **Classify**: Categorize discovered legacy patterns (e.g., deprecated accounting builders, direct GL writers, hardcoded exchange rates, legacy repositories).
3. **Introduce**: Build and verify the new canonical implementation adhering strictly to Clean Modular Hexagonal architecture and Rules 00–90.
4. **Migrate**: Re-route all active production callers (UI widgets, Riverpod providers, API controllers, sync handlers) to point to the new canonical implementation.
5. **Verify**: Execute comprehensive integration tests and static analysis proving that the production call graph uses the new canonical path.
6. **Remove**: Delete the legacy implementation classes, deprecated methods, obsolete tests, and unused imports from the codebase.
7. **Scan**: Perform a reachability and static analysis scan across the repository to verify zero remaining references or imports to the removed legacy items.

---

## 3. Targeted Legacy Anti-Patterns
The migration process MUST systematically eliminate:
* Hardcoded account codes or fallback account resolvers.
* Hardcoded exchange rates or `1.0` silent missing-rate fallbacks.
* Direct GL database writes from operational modules (Sales, Purchases, Cash Registers, Inventory).
* Legacy accounting entry builders and duplicated tax/pricing calculators.
* Bypasses of multi-tenant `company_id` filter checks.
* Parallel provider state authorities holding business truth outside the database.
* Obsolete unit tests that mock or assert deprecated legacy behaviors.

---

## 4. Verification & Clean Repository Gate
1. **Proof of Elimination**: A migration task CANNOT be marked `COMPLETE` until the legacy code is either completely deleted or proven unreachable in the production call graph.
2. **Clean Build Gate**: Following legacy removal, the project MUST compile cleanly with zero static analysis errors, zero missing import errors, and 100% passing test suites.
