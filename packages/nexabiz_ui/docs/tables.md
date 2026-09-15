# Data Table & Pagination Guidelines

## High-Performance ERP Tables

1. **Virtualization & Pagination**: Accounting tables must never render unbounded list views. Use `AppPaginationBar` and database-backed limit/offset pagination.
2. **Dense Table Layout**: Use `AppTablePage` to provide a fixed height table container with header toolbars and bottom pagination.
3. **Column Formatting**:
   - Monospace font for account codes and document numbers.
   - Right-aligned text for financial figures (Debit, Credit, Total).
   - Colored status badges using `AppStatusBadge`.
