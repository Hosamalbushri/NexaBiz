# NEXABIZ ERP — ACCOUNTING SCHEMA SPECIFICATION (ACCOUNTING_SCHEMA.md)

## 1. Accounting Philosophy & Single Financial Posting Gateway

In accordance with `.agents/rules/30-accounting.md`, General Ledger (GL) accounting is the sole financial authority of NexaBiz ERP. 
- **Single Gateway Authority**: All GL postings MUST pass exclusively through `JournalPostingService`. Operational modules (Sales, Purchases, Inventory, Treasury) are prohibited from persisting financial postings directly.
- **Set-Level Double-Entry Invariant**: Every posted journal entry MUST satisfy the set-level invariant across all its journal lines:
$$\sum \text{Base Debits for Journal} = \sum \text{Base Credits for Journal}$$
Unbalanced entries MUST be rejected by `JournalPostingService` with a `JournalUnbalancedException`. Row-level `CHECK(debit == credit)` constraints do not apply to individual lines.

---

## 2. General Ledger Domain Entities

### 2.1 Accounts (`accounts`)
Master Chart of Accounts (COA) specifying account code, name, type (`asset`, `liability`, `equity`, `revenue`, `expense`), active status, and parent account binding.
- **Tenant Scope**: COMPANY (`company_id`)
- **Key Constraints**: Scoped unique on `(company_id, code)`
- **Identity**: Technical Primary Key `id = UUID v7` (RFC 9562) under Decision D-12.

### 2.2 Journal Entries (`journal_entries`)
Authoritative General Ledger header storing entry number, voucher type, entry date, posting status (`posted`, `reversed`), source module, and source document ID.
- **Tenant Scope**: COMPANY (`company_id`)
- **Key Constraints**: Scoped unique on `(company_id, entry_number)`
- **Identity**: Technical Primary Key `id = UUID v7` (RFC 9562) under Decision D-12.
- **Immutability**: Once inserted with status `POSTED`, rows in `journal_entries` are IMMUTABLE.

### 2.3 Journal Lines (`journal_lines`)
Detail debits and credits referencing parent `JournalEntry`, `Account`, document currency amount, exchange rate, and base currency amounts (`base_debit`, `base_credit`).
- **Tenant Scope**: INHERITED COMPANY (Inherited via parent `JournalEntry`)
- **Identity**: Technical Primary Key `id = UUID v7` (RFC 9562) under Decision D-12.
- **Immutability**: Detail lines are IMMUTABLE. Physical deletion is strictly prohibited.

---

## 3. Financial Periods & Closing Schema

### 3.1 Fiscal Years (`fiscal_years`)
Company fiscal calendar years (`year_name`, `start_date`, `end_date`, `is_closed`).
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Technical Primary Key `id = UUID v7` (RFC 9562) under Decision D-12.

### 3.2 Accounting Periods (`accounting_periods`)
Monthly fiscal period boundaries (`period_name`, `period_number`, `start_date`, `end_date`, `is_closed`).
- **Tenant Scope**: INHERITED COMPANY (Inherited via parent `FiscalYear`)
- **Identity**: Technical Primary Key `id = UUID v7` (RFC 9562) under Decision D-12.

### 3.3 Period Closing Records (`period_closing_records`)
Audit log recording period closing events, user ID, closing timestamp, and summary hash.
- **Tenant Scope**: INHERITED COMPANY (Inherited via parent `AccountingPeriod`)
- **Identity**: Technical Primary Key `id = UUID v7` (RFC 9562) under Decision D-12.

---

## 4. Lifecycle & Decision D-14 Status

### 4.1 Decision D-14 Status (Generic Non-Inventory Lifecycle)
```text
UNRESOLVED UNDER DECISION D-14
Generic non-inventory financial lifecycle behavior, generic GL void schema, 
and generic reversal structures remain UNRESOLVED under D-14.
This is physically isolated to Phase 2C-2.
```

### 4.2 Financial Posting & Reversal Governance
1. **No Physical Deletion**: Financial ledger rows MUST NOT be deleted.
2. **Reversal Posting**: When a journal entry is reversed, `JournalPostingService` generates an explicit reversing journal entry with swapped debit/credit values and links back to the original entry ID (`reversal_entry_id`).
3. **Idempotency**: All posting requests supply an explicit `idempotency_key` (UUID v7 or deterministic SHA256 action hash decoupled from source_document_id under Decision D-12). Duplicate posting requests return the existing posted journal entry without creating duplicate GL lines.
