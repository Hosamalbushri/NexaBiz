# PACKAGE_RECEIPTS_PAYMENTS_RP03_CASH_BANK_IMPLEMENTATION.md

## EXECUTIVE SUMMARY
This report details the integration of Receipts & Payments with Cash Registers, Bank Accounts, and Chart of Accounts.

---

## 1. CASH & BANK ACCOUNTING INTEGRATION
- **Receipt Entry:**
  - DEBIT: Cash Register / Bank Account
  - CREDIT: Customer Receivable / Counterparty Account
- **Payment Entry:**
  - DEBIT: Supplier Payable / Expense / Counterparty Account
  - CREDIT: Cash Register / Bank Account
- **Cash Register Gating & Validation:**
  - Must belong to current `companyId`.
  - Must be active and open.
  - Must have explicit link to Chart of Accounts (`account_requirements`).
  - Cross-company or unlinked register access is strictly rejected.

---

## 2. VERIFICATION & GATE STATUS
- 7 integration tests in `rp_cash_bank_integration_test.dart` passing.
- Duplicate cash movement prevention verified.

---

## 3. FINAL GATE VERDICT

```text
CLOSED
```
