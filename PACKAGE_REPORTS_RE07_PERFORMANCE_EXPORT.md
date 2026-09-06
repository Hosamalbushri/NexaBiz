# RE-07 — REPORT FILTERING / PERFORMANCE / EXPORT

## 1. Unified Report Filtering Model (`ReportQueryFilter`)

All operational and financial reports in NexaBiz ERP consume the canonical `ReportQueryFilter` model (`lib/core/report_engine/domain/models/report_query_filter.dart`).

### Standardized Filter Criteria
- **Company & Tenant Isolation**: `companyId` (required, non-null data boundary)
- **Posting Scope**: `postingScope` (`postedOnly` by default, `all`, `unpostedOnly`)
- **Date Range**: `fromDate`, `toDate` (indexed timestamp ranges)
- **Currency Scope**: `currencyCode` (Base currency vs multi-currency filtering)
- **Entity Scope**: `accountUuid`, `customerUuid`, `supplierUuid`, `productUuid`, `warehouseUuid`, `registerUuid`

---

## 2. Performance Optimizations & Anti-Pattern Fixes

### Query Efficiency & Index Usage
- **N+1 Query Elimination**: Reports perform set-based SQL joins and aggregations directly via `JournalRepository.listTrialBalance` and `JournalRepository.listJournalBookLines` rather than fetching individual account movements per row.
- **Unbounded Query Protection**: Paged reports (`AccountLedgerMovement`, `JournalBookLineRow`) support keyset pagination (`lineId`, `sortOrder`, `limit`) to restrict memory overhead.
- **No Duplicate Calculations**: Cost of Goods Sold (COGS) and inventory valuations are calculated once by the authoritative Inventory Costing Engine and posted into journal lines; financial reports aggregate posted amounts directly.

---

## 3. Export Architecture (PDF, CSV, Excel)

### Single Calculation Path Guarantee
- **Export Consistency**: PDF, CSV, and Excel exports receive the exact same pre-calculated `ReportPayload` / `ReportDataset` as on-screen UI widgets.
- **Zero Dual Path Calculation**: PDF definitions (`ReportDefinition<TPayload>`) and CSV exporters (`CsvReportExporter`) formatting UTF-8 BOM CSV files use identical data instances.
- **RTL & Localization**: PDF exports utilize `pw.Directionality` with Arabic font embedding (`Amiri` / `Tajawal`) and `ReportPageFormat.a4Landscape` / `a4Portrait`.
