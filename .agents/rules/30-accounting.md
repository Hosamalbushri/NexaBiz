# 30 — ACCOUNTING DOMAIN & GENERAL LEDGER GOVERNANCE

## 1. Accounting Philosophy & Core Authority
1. **Single Posting Authority**: All General Ledger (GL) mutations, journal entries, and subledger updates MUST execute strictly through the canonical Accounting Posting Authority.
2. **Operational Separation**: Accounting modules MUST NOT create, edit, or own operational business documents (e.g., invoices, receipts, stock transfers). Operational modules MUST NOT directly write GL records.
3. **Canonical Flow**:

```text
Business Event
      ↓
Posting Intent
      ↓
Determination / Explicit Accounts
      ↓
Canonical Accounting Validation
      ↓
Journal Build
      ↓
Accounting Posting Authority
      ↓
GL
```

---

## 2. Chart of Accounts & Subledgers
1. **Chart of Accounts (COA)**: The COA structure, account codes, account types (Asset, Liability, Equity, Revenue, Expense), and account currencies are owned exclusively by `accounting`.
2. **Subledger Authority**:
   * Inventory valuation & COGS: Determined via `inventory` cost layers and posted to inventory GL accounts.
   * Accounts Receivable (AR): Tracks customer balances reconciled with Sales.
   * Accounts Payable (AP): Tracks vendor balances reconciled with Purchases.
   * Cash & Bank: Tracks cash register and bank account balances.
3. **Source Traceability**: Every journal entry MUST maintain immutable metadata referencing its source business document (`source_module`, `source_entity_type`, `source_entity_id`, `company_id`).

---

## 3. Account Determination vs. Explicit Accounts
1. **Posting Intent**: Operational modules submit a `PostingIntent` containing financial amounts, currencies, event types, and optional user-selected accounts.
2. **Determined Accounts**: Accounts resolved automatically via system posting rules (e.g., default sales revenue account, inventory asset account, default tax liability account).
3. **Explicit Accounts**: Accounts explicitly chosen by the user in operational forms (e.g., specific bank account, custom expense account).
4. **Determination Precedence**:
   * Step 1: Explicitly provided valid account override.
   * Step 2: Entity-level account configuration (e.g., customer/vendor default account, product category account).
   * Step 3: Global company posting rule default account.
5. **Ambiguity Resolution**: If account determination fails or resolves to an ambiguous/missing account code, posting MUST fail immediately. Fallback to arbitrary accounts is FORBIDDEN.

---

## 4. Validation, Balancing & Immutability
1. **Journal Balancing**: Every journal entry MUST satisfy strict debit-credit balance constraints:
   * `SUM(debit_amount) == SUM(credit_amount)` in transaction currency.
   * `SUM(debit_base_amount) == SUM(credit_base_amount)` in company base currency.
2. **Period Validation**: Journal posting MUST validate that the accounting period corresponding to `posting_date` is OPEN. Posting to closed or locked financial periods is FORBIDDEN.
3. **Posted Immutability**: Once a journal entry is committed with status `POSTED`, it is permanently immutable. Deletion or direct SQL update of posted journals is forbidden.
4. **Reversal Semantics**: Document cancellations or adjustments MUST generate explicit reversal journal entries (`reversal_of_journal_id`) with equal and opposite debit/credit lines.

---

## 5. Accounting Integration State
1. **Integration Configurations**: Accounting integration MAY be configured per company as `REQUIRED`, `OPTIONAL`, or `DISABLED`.
2. **Required Integration**: When accounting is `REQUIRED`, operational document posting and journal creation form a single atomic transaction governed by `40-transaction-integrity.md`.
3. **Disabled / Misconfigured Accounting**: When accounting is `DISABLED` or misconfigured, operational posting behavior MUST adhere strictly to configured transaction rules without producing partial accounting records.

---

## 6. Currency & Rounding
1. **Multi-Currency Posting**: Journal lines support multi-currency amounts governed by `60-currency.md`.
2. **Rounding Rules**: Currency conversion and line item calculations MUST apply exact, consistent monetary rounding at the line item level. Rounding imbalances MUST be allocated according to canonical balancing rules.
