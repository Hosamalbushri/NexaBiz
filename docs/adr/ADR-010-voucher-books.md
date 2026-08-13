# ADR-010: Voucher books (sequential numbering)

## Status

Accepted — 2026-08-13 (hierarchy update)

## Context

Operational documents (sales, receipts, payments, purchases, journals) need
stable sequential voucher numbers. A section such as **Sales** needs multiple
child books (e.g. sales invoices **and** sales returns), and each section may
open more than one book.

## Decision

- Own voucher-book master data in the Accounting module (`voucher_books` on
  `AccountingDatabase`, schema **v4**).
- Default section groups (Sales, Receipts, Payments, Purchases, Journal) are
  seeded, plus **one starter leaf book per kind** (`DefaultVoucherBooks`) when
  that kind has no books yet under its section.
- Leaf kinds include `salesReturns` / `purchaseReturns` under their section.
- Numbering is **sequential integers** with a **current** and **end** number
  per leaf book (no display pad width). Allocation fails when exhausted.
- Repository exposes `allocateNextNumber` for atomic allocation on **leaf**
  books only (groups do not issue numbers).
- Local master data only for now (no sync queue), same stance as currency rates.
- This slice configures books only — it does **not** create vouchers/journals.

## Consequences

- Future Sales / Receipts / etc. pick a child book under the right section.
- Multiple series per section (main + returns + extra branches) without
  colliding counters.
- Pad length can be adjusted without changing the stored sequence.
