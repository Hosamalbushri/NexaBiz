# ADR-009: Customers module

## Status

Accepted — updated 2026-08-14

## Context

The platform needs a reusable Customers master-data module. Customers may link to Chart of Accounts posting accounts and may originate locally or from an external ERP. Modules must not import other modules.

## Decision

- Own module at `lib/modules/customers/` (not under Accounting).
- Persist with Drift (`CustomersDatabase` / `customers` table).
- Business code is sequential from the **customers parent CoA account code**
  (e.g. parent `1221` → `12210001`, `12210002`) via `CustomerCodeGenerator`
  (also supports manual/imported codes).
- Store opaque `accountId` (= Accounting `Account.uuid`).
- **Auto-link (default on):** when saving a customer without an account, App
  `CustomerAccountLinkPort.ensurePostingUnderParent` creates (or reuses) a
  posting account under the customers parent group, using the customer code/name.
  Toggle via `customers_auto_link_account` setting.
- Configure **customers parent account** (group in CoA; default system
  `customers` / `1221`) via module settings (`/customers/settings`) and platform Settings.
- App wires `CustomerAccountLinkPort` → `AccountingCustomerAccountLinkAdapter`.
- `CustomerDataSource.local | external` + optional `externalId`; `upsertFromExternal` for ERP imports.
- Excel bulk import via `CustomerExcelImportDatasource` + `upsertAll` (match by code / external id; does not auto-create CoA rows).
- Offline-first sync entity type `customer`.

## Consequences

- Customer create/edit can populate CoA under `1221` without manual account entry.
- Future Sales/invoices reference customer uuid, not local int id.
- Account pickers / create depend on App override of the link port.
