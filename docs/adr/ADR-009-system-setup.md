# ADR-009: System Setup / Initialization Module

## Status

Accepted — 2026-08-14

## Context

The platform already has runtime Settings (theme, locale, company profile, module panels) and lazy module seeds (Chart of Accounts, voucher books). There was no versioned first-launch gate: splash always entered the dashboard.

We need a **System Setup** flow that prepares the business environment once (and can resume), without becoming a second Settings screen or owning Accounting/Sales internals.

## Decision

- Add `SystemSetupModule` under `lib/modules/system_setup/` as an `AppModule` with `showInLauncher: false`.
- Persist versioned setup state in the existing Hive settings box (`system_setup_*` keys) via `SettingsRepository`.
- Own readiness + step lifecycle in `SystemInitializationCoordinator`.
- Required step order (v2): **language → base currency (locked) → mode → company → local seeds**.
- Base currency is persisted on `CompanyProfile` and locked via `system_base_currency_locked` (cannot be changed in Setup or company editor).
- Orchestrate CoA / voucher seeds through App-wired `SystemSetupSeedPort` (`AccountingSystemSetupSeedAdapter`).
- Compose **other modules' settings** in the Settings hub via `AppModule.buildSettingsSections` (no module→module imports).
- Platform Settings (bottom tab) keeps theme/locale, sync, about, and reset only.
- Splash routes to `/system-setup` when not ready; otherwise dashboard.
- **Grandfather:** installs that already have other settings keys are marked ready at current setup version without forcing the wizard (currency locked).

### Setup vs Settings

| System Setup (launcher card) | Settings |
|---|---|
| First-run / resume initialization | Day-to-day preferences |
| Language + immutable base currency | Theme, pins, sync controls |
| Company / mode / seeds | Module operational panels |
| Entry for company details editor | No separate “Setup” accordion |

## Consequences

- Existing users are not blocked after upgrade.
- New installs must complete required steps before the main shell.
- Future schema bumps can add required steps by increasing `SystemSetupSchema.currentVersion`.
- Business modules stay independent; Setup never imports Accounting/Sales packages.
