# ADR-005: Localization EN/AR

## Status

Accepted (implemented)

## Context

The product must support English and Arabic users, including RTL layouts, with a single codebase.

## Decision

Use Flutter gen-l10n with:

- Template `app_en.arb`
- Arabic `app_ar.arb`
- Generated `AppLocalizations` under `lib/app/localization/`
- Runtime locale override via settings (`localeProvider` + Hive)

Typography uses Cairo for both locales.

## Alternatives Considered

- `easy_localization`
- Hardcoded maps per screen
- Separate builds per language

## Consequences

- All user-facing strings must be ARB-backed
- New features require EN + AR updates together
- Modules currently depend on app-level localization generation (established pattern)
