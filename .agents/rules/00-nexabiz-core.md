# 00 — NEXABIZ CORE CONSTITUTION

## 1. Operating Principle
All engineering, refactoring, and AI-assisted development across NexaBiz MUST follow the strict lifecycle:

`Inspect → Evidence → Call Graph → Plan → Implement → Test → Static Analysis → Legacy/Reachability Scan → Final Verification → Report`

No step in this operating sequence MAY be skipped, truncated, or assumed.

---

## 2. Evidence First
1. The agent and developer MUST inspect the repository and verify concrete code paths before making any architectural, structural, or business domain assumptions.
2. Unverified claims, assumed file structures, or hypothetical method signatures are STRICTLY FORBIDDEN.
3. Every engineering action MUST be grounded in verifiable repository evidence.

---

## 3. Prohibition of Invention & Defaulting
The agent and developer MUST NOT invent:
* Business rules or accounting rules
* Account codes or Chart of Accounts structures
* Currencies, exchange rates, or conversion factors
* Tenant scopes, active company boundaries, or user identity defaults
* User permissions, security roles, or authorization policies
* Entity relationships, foreign key constraints, or cardinality
* Hidden default values or silent state initializations
* Lifecycle states, document status transitions, or transaction outcomes

---

## 4. Prohibition of Silent Fallbacks
The system and codebase MUST NOT execute silent fallback behavior under any circumstance. Missing configuration, missing reference data, or unproven execution state MUST raise an explicit error.

Specifically, the following behaviors are STRICTLY FORBIDDEN:
* `missing exchange rate → 1.0`
* `missing account → arbitrary account`
* `missing company → first company`
* `missing warehouse → first warehouse`
* `missing permission → allow`

---

## 5. Canonical Authority & Production Path
1. **Single Canonical Authority**: Every business truth, accounting calculation, database mutation, currency conversion, and tenant policy MUST have exactly ONE canonical code authority.
2. **Production Path Verification**: The physical existence of a class, function, or file in the repository is NOT proof of active production use. The real production call graph MUST be proven to reach the canonical implementation from entry points (UI controllers, API endpoints, sync handlers).
3. **No Parallel Production Authorities**: Old/legacy implementations and new canonical implementations MUST NOT remain active in production simultaneously. Dual-writing or competing logic paths are forbidden.

---

## 6. Financial & Transaction Integrity
1. **Atomic Accounting**: For any operational action requiring financial posting, the `Business Posting` and `Accounting Posting` MUST commit or roll back atomically.
2. **Posting Authority**: Operational business modules (e.g., Sales, Purchases, Inventory, Cash Registers) MUST NOT directly write General Ledger (GL) entries. They MUST submit posting intents to the canonical Accounting Posting Authority.
3. **Account Posting Classification**: Account determination MUST explicitly separate *determined account posting* (resolved dynamically via system posting rules) from *explicitly specified account posting* (user-selected accounts).
4. **Currency Integrity**: Currency conversion MUST execute through the canonical exchange rate engine. Implicit rates, duplicate conversion, and silent fallback rates are prohibited.
5. **Posted Immutability**: Posted financial documents and journal entries are permanently immutable. Corrections MUST occur solely through controlled reversal or adjustment entries.
6. **Idempotency**: Retries, re-sync operations, or network reconnections MUST NOT create duplicate operational or financial effects.

---

## 7. Isolation & User Experience
1. **Tenant Isolation**: Cross-company reads, writes, memory caches, database sync, or accounting entries are strictly prohibited. Multi-company data isolation MUST be absolute.
2. **Localization**: All user-facing strings MUST use the canonical localization system (`L10n`). Hardcoded text strings in presentation widgets are prohibited.
3. **UI Consistency**: User interfaces MUST use centralized design primitives and components built on top of `shadcn_flutter`. Page-specific widget reimplementations of standard primitives are forbidden.
4. **No Duplicate Business Logic**: Business rules MUST NOT be duplicated across presentation widgets, state providers, repositories, adapters, or reports.

---

## 8. Verification & Database Safety
1. **Testing Integrity**: Existing tests MUST NOT be weakened, bypassed, commented out, or deleted merely to achieve passing build status.
2. **Database Safety**: Destructive database schema changes (e.g., column drop, table drop, column type narrowing) MUST NOT be executed without explicit authorization and documented migration safety plans.

---

## 9. Stop Conditions
The agent MUST IMMEDIATELY STOP execution and request human guidance when any of the following conditions occur:
* Required repository evidence or business rule clarity is missing.
* The canonical authority for a business domain is ambiguous or contradictory.
* Active tenant scope or company context cannot be conclusively proven.
* Transaction atomicity between operational and accounting commits cannot be guaranteed.
* Multi-currency conversion semantics or exchange rate direction are ambiguous.
* The canonical implementation path is unreachable from production entry points.
* A legacy implementation path remains active alongside a newly introduced canonical path.
* A destructive database schema modification is required without prior authorization.

---

## 10. Mandatory Final Verdicts
At the conclusion of any task, the execution report MUST state exactly one of the following canonical verdicts:
* `COMPLETE`
* `INCOMPLETE — BLOCKED`
* `PARTIALLY COMPLETE — REMAINING BLOCKERS: [Detailed list of blockers]`
