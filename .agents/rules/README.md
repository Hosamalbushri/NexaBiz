# NexaBiz Antigravity Rules System — Documentation & Index

> [!NOTE]
> `README.md` is a documentation index and operational guide. It is NOT itself a Rule authority.
> The non-negotiable project constitution is defined in [`00-nexabiz-core.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/00-nexabiz-core.md).

---

## 1. Rule System Inventory

The NexaBiz Antigravity Rules system consists of exactly 11 normative Rule files plus this documentation index:

| Rule File | Authority Domain | Primary Ownership Focus |
| :--- | :--- | :--- |
| [`00-nexabiz-core.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/00-nexabiz-core.md) | Core Constitution | Project-wide non-negotiables, evidence-first, stop conditions, verdicts |
| [`10-architecture.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/10-architecture.md) | Architecture & Layering | Clean Modular + Hexagonal architecture, module boundaries, layers, ports |
| [`20-database.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/20-database.md) | Database & Schema | Drift / SQLite, SQLCipher, entity ownership, immutability, migration safety |
| [`30-accounting.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/30-accounting.md) | Accounting Domain | COA, GL, journal posting authority, account determination, balance rules |
| [`40-transaction-integrity.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/40-transaction-integrity.md) | Transaction Integrity | Operational + accounting commit atomicity, idempotency, rollback invariants |
| [`50-tenancy.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/50-tenancy.md) | Multi-Tenancy | Company isolation, session context, tenant query/write safety, permission gates |
| [`60-currency.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/60-currency.md) | Multi-Currency | Exchange rate engine, currency flags, conversion rules, anti-double-conversion |
| [`70-localization.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/70-localization.md) | Localization & Formatting | L10n keys, RTL/LTR layout, locale-aware formatting, domain error independence |
| [`80-ui.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/80-ui.md) | UI & Components | Centralized `shadcn_flutter` primitives, design tokens, responsive view states |
| [`90-testing.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/90-testing.md) | Testing & Verification | 8-layer testing model, negative testing, production call-graph reachability proof |
| [`99-legacy-removal.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/99-legacy-removal.md) | Legacy Migration | 7-step migration lifecycle (Discover → Scan), eliminating parallel authorities |

---

## 2. Rule Hierarchy

The architecture follows a strict constitutional hierarchy:

```text
00-nexabiz-core.md (Project Constitution)
        │
        ├── 10-architecture.md
        ├── 20-database.md
        ├── 30-accounting.md
        ├── 40-transaction-integrity.md
        ├── 50-tenancy.md
        ├── 60-currency.md
        ├── 70-localization.md
        ├── 80-ui.md
        ├── 90-testing.md
        └── 99-legacy-removal.md
```

### Hierarchy Governance Rules
1. **Constitution Primacy**: `00-nexabiz-core.md` is the supreme project authority. Specialized Rules (`10` through `99`) supplement `00-nexabiz-core.md` with domain-specific engineering requirements.
2. **Non-Contradiction**: A specialized Rule MUST NOT contradict `00-nexabiz-core.md`.
3. **Conflict Resolution**: If two specialized Rules appear to conflict:
   * Identify the conflicting authority files.
   * Do not invent an arbitrary resolution.
   * Document that the conflict requires architectural resolution.

---

## 3. Canonical Ownership Matrix

To prevent duplication and maintain single-point authority, rules are strictly partitioned according to this canonical ownership matrix:

| Concern / Concept | Canonical Rule Owner |
| :--- | :--- |
| Global engineering principles & core operating cycle | [`00-nexabiz-core.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/00-nexabiz-core.md) |
| Evidence-first execution & prohibition of silent defaults/fallbacks | [`00-nexabiz-core.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/00-nexabiz-core.md) |
| Clean modular architecture, ports, adapters, dependency inversion | [`10-architecture.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/10-architecture.md) |
| Database schemas, Drift tables, SQLite constraints, migration safety | [`20-database.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/20-database.md) |
| Chart of accounts, GL journal entries, account determination precedence | [`30-accounting.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/30-accounting.md) |
| Operational & accounting transaction atomicity, idempotency, rollback | [`40-transaction-integrity.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/40-transaction-integrity.md) |
| Tenant isolation (`company_id`), active company context, multi-tenancy | [`50-tenancy.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/50-tenancy.md) |
| Exchange rate engines, currency conversion, anti-double-conversion | [`60-currency.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/60-currency.md) |
| Localization (`L10n`), translation keys, RTL/LTR, locale formatting | [`70-localization.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/70-localization.md) |
| Centralized UI components (`shadcn_flutter`), design tokens, view states | [`80-ui.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/80-ui.md) |
| Testing layers, negative verification, production reachability proofs | [`90-testing.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/90-testing.md) |
| Legacy code discovery, 7-step migration lifecycle, code deletion | [`99-legacy-removal.md`](file:///home/hosam/StudioProjects/untitled2/.agents/rules/99-legacy-removal.md) |

---

## 4. Execution Protocol for Agents & Engineers

All work conducted in the NexaBiz codebase MUST strictly follow the operating cycle:

```text
Inspect → Evidence → Call Graph → Plan → Implement → Test → Static Analysis → Legacy/Reachability Scan → Final Verification → Report
```

1. **Step 1 — Inspect & Gather Evidence**: Read repository code and existing test suites to establish concrete ground truth before planning or modifying code.
2. **Step 2 — Verify Production Call Graph**: Trace entry points (UI buttons, providers, API routes) to verify active production paths.
3. **Step 3 — Formulate Plan**: Document proposed changes ensuring strict adherence to Rules 00–99.
4. **Step 4 — Implement Canonical Code**: Write clean, hexagonal-compliant Dart code without inventing unproven business logic or silent fallbacks.
5. **Step 5 — Test & Validate**: Run automated unit, integration, and negative test suites.
6. **Step 6 — Perform Static Analysis & Legacy Scan**: Verify code passes Dart analyzer checks and remove/deprecate legacy bypasses.
7. **Step 7 — Report Final Verdict**: Issue a final report stating one of the mandatory verdicts (`COMPLETE`, `INCOMPLETE — BLOCKED`, or `PARTIALLY COMPLETE — REMAINING BLOCKERS`).
