# PHASE 2B CUSTOMER & SUPPLIER ACCOUNTING MODEL DECISION

## 1. Selected Model
```text
SELECTED MODEL: MODEL B — DEDICATED FINANCIAL ACCOUNT PER CUSTOMER / SUPPLIER
```

## 2. Customer Accounting Model
```text
Customer (Master Entity)
   ↓
AccountingSubject (Sub-ledger Identity)
   ↓
Dedicated FinancialAccount (CoA Node under Configured Customer Parent Account)
```
- Every customer automatically provisions a dedicated `FinancialAccount` under the company's configured Customer Parent Account (e.g. `1200 Customers` -> `120001 Customer A`).
- `FinancialAccount.id` (UUID v7) is the authoritative technical identity.
- `FinancialAccount.code` (e.g., `"120001"`) is the human-readable account number.

## 3. Supplier Accounting Model
```text
Supplier (Master Entity)
   ↓
AccountingSubject (Sub-ledger Identity)
   ↓
Dedicated FinancialAccount (CoA Node under Configured Supplier Parent Account)
```
- Every supplier automatically provisions a dedicated `FinancialAccount` under the company's configured Supplier Parent Account (e.g. `2100 Suppliers` -> `210001 Supplier X`).
- `FinancialAccount.id` (UUID v7) is the authoritative technical identity.
- `FinancialAccount.code` (e.g., `"210001"`) is the human-readable account number.

## 4. Rationale (Why Model B Was Selected)
1. **General Ledger Granularity**: Model B allows direct GL balance tracking and trial balance audit per customer/supplier without requiring sub-ledger aggregation joins for basic ledger reports.
2. **Account Hierarchy Integration**: Fits naturally into the Chart of Accounts tree structure under parent group accounts (`1200 Receivables / Customers`, `2100 Payables / Suppliers`).
3. **Multi-Currency Support**: Each customer/supplier account can hold functional currency base amounts while line-level `subjectId` tracks transaction currency buckets per subject.
4. **Independent Account Code Policy**: Allows company-scoped, collision-safe account number generation for human display while preserving strict UUID identity.
5. **Compliance with User Requirements**: Fulfills the explicit user requirement that creating a customer/supplier automatically provisions a dedicated account in the background without user intervention.

## 5. Rejected Model & Why
```text
REJECTED MODEL: MODEL A — SHARED CONTROL ACCOUNT ONLY
```
- **Why Rejected**: Model A forces all customers to share a single GL Control Account (e.g., `1200 Accounts Receivable`), relying solely on `JournalLine.subjectId` for balance separation. This prevents individual GL account tree nodes per customer, complicates traditional trial balance reports, and violates NexaBiz's operational requirement for dedicated customer/supplier CoA account numbers.

## 6. Accounting Identity Invariants
1. `FinancialAccount.id != FinancialAccount.code`. Technical identity is strictly UUID v7.
2. Changing `FinancialAccount.code` (e.g. `120001` -> `121001`) modifies display code only; `id`, historical journals, and balances remain unchanged.
3. Moving a customer/supplier account to a new parent is a structural metadata operation. It creates **NO** `JournalEntry`, **NO** balance transfer, and modifies **NO** historical `JournalLine` records.
4. Provisioning must be **atomic** (Customer + Subject + FinancialAccount + Binding committed together or rolled back completely) and **idempotent** (re-provisioning returns existing technical IDs without creating duplicate accounts).
