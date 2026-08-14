# ADR-012: Reports module & shared PDF kit

## Status

Accepted — 2026-08-14

## Context

The platform needs reusable PDF report generation with in-app preview, print, export, and share — without coupling the PDF engine to Sales, Inventory, or Accounting. Existing document PDFs (sales invoice, stock-count export, barcode labels) already use `pdf` + `printing` + `share_plus` but duplicate fonts/file/share logic and lack `PdfPreview`.

## Decision

- Add a **shared kit** under `lib/core/reporting/` (page format, fonts, table RTL helpers, file actions, exceptions). Core still does not import modules.
- Add **`ReportsModule`** (`lib/modules/reports/`) as an `AppModule`: catalog UI, `ReportRunner`, `PdfPreview` page, and report definitions that consume **already-prepared payloads**.
- Cross-module data arrives via **ports** in Reports domain (e.g. `SalesPeriodReportDataPort`) wired in App (`lib/app/reports/*_adapter.dart`) to Sales/Customers/… repositories.
- First concrete report: **Sales by period** (paged `SaleRepository.searchListPaged`).
- Keep existing operational PDFs (invoice, labels) in owning modules; they may adopt Core helpers later.
- Register the module in `module_bootstrap.dart` and expose entries on the platform Reports hub.
- No new pub dependencies; use existing `pdf`, `printing`, `share_plus`.

## Consequences

- New reports = definition + payload DTO + App adapter + catalog entry — without changing the PDF engine.
- Platform `/reports` lists Inventory and Business PDF reports; module routes live under `/module-reports`.
- Multi-currency totals in period reports currently sum document amounts as stored (no FX normalization yet) — document this for future financial reports.
