# ADR-009: Customers module

## Status

Accepted

## Context

The platform needs a reusable Customers master-data module. Customers may link to Chart of Accounts posting accounts and may originate locally or from an external ERP. Modules must not import other modules.

## Decision

- Own module at `lib/modules/customers/` (not under Accounting).
- Persist with Drift (`CustomersDatabase` / `customers` table).
- Business code is sequential from the **customers parent CoA account code**
  (e.g. parent `1221` → `12210001`, `12210002`) via `CustomerCodeGenerator`
  (also supports manual/imported codes).
- Store opaque `accountId` (= Accounting `Account.uuid`). Never auto-create CoA rows.
- Configure **customers parent account** (group in CoA; default system `customers` / `1221`) via settings.
- App wires `CustomerAccountLinkPort` → `AccountingCustomerAccountLinkAdapter`.
- `CustomerDataSource.local | external` + optional `externalId`; `upsertFromExternal` for ERP imports.
- Excel bulk import via `CustomerExcelImportDatasource` + `upsertAll` (match by code / external id).
- Offline-first sync entity type `customer`.

## Consequences

- Accounting Chart of Accounts remains unchanged.
- Future Sales/invoices reference customer uuid, not local int id.
- Account pickers depend on App override of the link port.
