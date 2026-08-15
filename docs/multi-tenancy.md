# Multi-tenancy

> Experimental — not production-ready.

## Rules

1. Tenant = `companies` row (`id` UUID, `code`, `status`).
2. Session `company_id` comes from the **auth session**, never from client body/`X-Company-Id` for JWT requests.
3. Sync entities/changes/operations are scoped with `WHERE company_id = authenticated_company_id`.
4. Change-log cursors are per-company sequences.

## Flutter impact

Local Drift tables do **not** yet carry `company_id`. Until per-tenant
local DBs (or row filters) land, treat multi-company on one device as
**switch + re-sync**, and avoid concurrent use of two companies' data
on the same install without clearing/isolating storage.
