# PHASE 2B DOMAIN INVARIANTS SPECIFICATION

## 1. Accounting Core & Tenancy Invariants

### JL-TENANCY-01: Header Company Assignment
Every `JournalEntry` belongs to exactly one active tenant company context (`companyId`). Cross-company header switching is forbidden.

### JL-TENANCY-02: Line Company Parity
Every `JournalLine` explicitly inherits its parent `JournalEntry.companyId`. A line cannot have a `companyId` different from its header.

### JL-TENANCY-03: Account Tenancy Alignment
Every `JournalLine.accountId` must resolve to a `FinancialAccount` owned by the same company (`account.companyId == entry.companyId`).

### JL-TENANCY-04: Atomic Tenancy Rejection
If any line in a multi-line journal entry violates company scope or references a foreign tenant account, the entire journal entry is rejected atomically. Zero lines are persisted or posted.

### JL-TENANCY-05: Reconstruction Isolation
Account balance and subject bucket reconstruction services (`FinancialProjectionReconstructionService`) filter SQL query joins double-blindly on both `journalEntries.companyId` and `journalLines.companyId`.

### JL-TENANCY-06: Reversal Tenancy Stability
Reversal journal entries (`createReversal`) copy the exact `companyId` of the original posted journal and create inverted lines scoped exclusively to that company.

### JL-TENANCY-07: Account Identity Decoupling
Technical identity is strictly defined by `FinancialAccount.id` (UUID v7). Account lookup and posting logic never rely on `code` or `number` for entity identity.

### JL-TENANCY-08: Sole Posting Gateway Authority
All postings execute exclusively through `PostingEngine` and `FinancialJournalRepository`. Operational modules create intent requests only and cannot directly write journal lines across company boundaries.
