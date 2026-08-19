# Multi-tenancy

> Experimental — not production-ready.

## Rules

1. Tenant = `companies` row (`id` UUID, `code`, `status`).
2. Session `company_id` comes from the **auth session**, never from client body/`X-Company-Id` for JWT requests.
3. Sync entities/changes/operations are scoped with `WHERE company_id = authenticated_company_id`.
4. Change-log cursors are per-company sequences.

## Flutter impact

Local Drift tables still do **not** carry `company_id`. Isolation is by
**SQLite file**: providers pass `tenantDbName(base, companyId: …)` so a
non-bootstrap company opens `{base}_{hex}` instead of the historical file
(`accounting_accounts`, `sales_master`, `inventory_products`,
`customers_master`, `receipts_payments`). The default local company
(`LocalAuthDefaults.companyId`) keeps those historical names so existing
installs are not orphaned.

Hive `sync_queue_v2`, `sync_cursors`, and `sync_metrics` use the same
`tenantScopedName` rule so queued mutations and pull sequences stay on
the company that created them. The bootstrap local company keeps the
historical box names.

Switching company closes the previous Drift connections and opens the
matching files / Hive boxes. Treat a company switch as **new local
books + re-sync**, not a row-level filter inside one database.
