# RP-03 — CASH REGISTER & BANK ACCOUNT INTEGRATION SPECIFICATION REPORT

## EXECUTIVE SUMMARY
This report details the architectural integration between Receipts & Payments and the existing Cash Registers and Accounting General Ledger infrastructure. The integration strictly avoids secondary/duplicate cash balance storage by leveraging authoritative GL double-entry journal entries and company-scoped cash register configurations.

---

## 1. PAYMENT ACCOUNT RESOLUTION & VALIDATION

### Payment Account Types
Every posted receipt or payment must explicitly designate a valid destination or source financial account:
1. **Cash Register Account:** Linked directly to a company-scoped `CashRegister` entity and its corresponding Chart of Accounts asset account.
2. **Bank Account:** Linked to a designated Bank account in the Chart of Accounts (`SetupAccountType.asset`).
3. **Other Configured Financial Account:** Any active, company-scoped account with `canPost == true`.

### Cash Register Gatekeeper Validation
Before a receipt or payment referencing a Cash Register can be created or posted, the system enforces five mandatory validations:
1. **Existence:** The Cash Register entity must exist in the database.
2. **Company Isolation:** `register.companyId == transaction.companyId`.
3. **Active Status:** `register.isActive == true`.
4. **User Authorization:** Active user possesses valid operational permissions (`ReceiptsPaymentsPermissions.create` / `.post`).
5. **Chart of Accounts Linking:** Register MUST be explicitly linked to a valid CoA account (`register.chartOfAccountId != null`). Fallbacks/inferences are strictly forbidden.

---

## 2. AUTHORITATIVE DOUBLE-ENTRY ACCOUNTING MAPPING

Receipts and Payments integrate with the existing `AccountingRpLedgerAdapter` to emit balanced General Ledger journal entries.

### 2.1 RECEIPT DOCUMENT (Money Inflow)
- **Accounting Entry:**
  - **DEBIT:** Treasury / Cash / Bank Asset Account (`cashAccountId`)
  - **CREDIT:** Customer Receivable / Revenue / Counterparty Account (`counterAccountId`)
- **Formula:**
  $$\text{Debit (Cash/Bank)} = \text{Credit (Counterparty)} = \text{Transaction Amount}$$

### 2.2 PAYMENT DOCUMENT (Money Outflow)
- **Accounting Entry:**
  - **DEBIT:** Supplier Payable / Expense / Counterparty Account (`counterAccountId`)
  - **CREDIT:** Treasury / Cash / Bank Asset Account (`cashAccountId`)
- **Formula:**
  $$\text{Debit (Counterparty)} = \text{Credit (Cash/Bank)} = \text{Transaction Amount}$$

---

## 3. CASH BALANCE DERIVATION & FINANCIAL INTEGRITY

- **No Duplicate Balance Storage:** The Receipts & Payments module does NOT maintain a separate, mutable `balance` field in `financial_transactions` or cash registers.
- **Authoritative Balance Calculation:**
  $$\text{Register/Bank Balance} = \sum \text{Posted Debits (Money In)} - \sum \text{Posted Credits (Money Out)}$$
- **Audit Traceability:** Every change in cash/bank balance is traceable to an immutable, posted `FinancialTransaction` and its linked `JournalEntry`.

---

## 4. MULTI-REGISTER ISOLATION & CONCURRENCY

- **Isolation Invariant:** Transactions posted to **Register A** affect ONLY **Register A**'s linked GL account balance.
- **Cross-Register Protection:** Register B's balance remains strictly unchanged by Register A operations.
- **Company Multi-Tenant Isolation:** Cross-company register selection is rejected at both domain validation and database constraint levels (`CrossCompanyAccountBindingException` / `FinancialTransactionException`).

---

## 5. INTEGRATION TEST SUITE ARCHITECTURE

The accompanying test matrix (`test/modules/receipts_payments/rp_cash_bank_integration_test.dart`) verifies:
1. **Cash Receipt:** Correct Debit Cash / Credit Counterparty mapping.
2. **Cash Payment:** Correct Debit Counterparty / Credit Cash mapping.
3. **Bank Receipt:** Correct Debit Bank / Credit Counterparty mapping.
4. **Bank Payment:** Correct Debit Counterparty / Credit Bank mapping.
5. **Multi-Register Isolation:** Register A vs Register B independent balances.
6. **Validation Guards:** Controlled rejection of inactive or cross-company registers.
7. **Idempotency Guard:** Blocked duplicate GL posting.
