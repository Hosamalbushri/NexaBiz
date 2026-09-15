# PHASE 2B FORENSIC EVIDENCE REPORT (GATE-02)

## 1. Executive Summary
This document records the forensic physical evidence establishing Phase 2B GATE-02 (JournalLine Tenancy Model) compliance in NexaBiz ERP.

## 2. Physical Database Schema Evidence
Inspected physical tables in `lib/packages/financial/database/tables/`:

### 2.1 `FinancialAccounts` (`financial_accounts_table.dart`)
- Primary Key: `id` (TEXT(36), UUID v7)
- Columns: `companyId`, `code`, `nameAr`, `nameEn`, `accountType`, `currencyPolicy`, `fixedCurrencyCode`, `parentAccountId`, `level`, `isGroup`, `isSystemAccount`, `isActive`
- Unique Constraints: `(companyId, id)`, `(companyId, code)`

### 2.2 `FinancialJournalEntries` (`financial_journal_entries_table.dart`)
- Primary Key: `id` (TEXT(36), UUID v7)
- Columns: `companyId`, `entryNumber`, `baseCurrencyCode`, `postingDate`, `status`, `description`, `sourceModule`, `sourceDocumentId`, `postedAt`, `createdById`
- Unique Constraints: `(companyId, id)`, `(companyId, entryNumber)`

### 2.3 `FinancialJournalLines` (`financial_journal_lines_table.dart`)
- Primary Key: `id` (TEXT(36), UUID v7)
- Columns: `companyId`, `journalEntryId`, `lineNumber`, `accountId`, `side`, `transactionCurrencyCode`, `transactionAmountScaled`, `exchangeRateScaled`, `baseAmountScaled`, `description`, `subjectId`
- Unique Constraints: `(companyId, journalEntryId, lineNumber)`

## 3. Code Evidence
- **Posting Engine Validation**: `PostingEngine.prepareAndValidateForPosting` checks `line.companyId == entry.companyId` and `account.companyId == entry.companyId` for every line. Throws `TENANCY_VIOLATION` if any line fails.
- **Repository Persistence Validation**: `DriftFinancialJournalRepository.saveEntry` checks `line.companyId == entry.companyId` inside an atomic SQLite transaction.
- **Projection Reconstruction Isolation**: `FinancialProjectionReconstructionService` explicitly guards SQL queries with `db.financialJournalLines.companyId.equals(companyId)`.
- **Reversal Isolation**: `JournalEntry.createReversal` produces draft reversal entries preserving exact `companyId` tenancy across all lines.

## 4. Test Evidence
- **Suite**: `test/packages/financial/financial_gate02_tenancy_model_test.dart`
- **Result**: 9/9 PASSED. Full package test suite: 53/53 PASSED (100%).
