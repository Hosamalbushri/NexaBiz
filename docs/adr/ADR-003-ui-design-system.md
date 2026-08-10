# ADR-003: UI Design System

## Status

Accepted (implemented)

## Context

Multiple modules will share chrome and interaction patterns. Inconsistent one-off styling would make the platform feel fragmented and hard for AI/humans to extend safely.

## Decision

Standardize on:

- Material 3
- FlexColorScheme for theme construction
- Cairo via Google Fonts
- Design tokens (`AppColors`, `AppSpacing`, `AppRadius`, `AppTypography`, …)
- Reusable `App*` widgets in `lib/core/widgets/`
- Flutter Animate for subtle motion
- Skeletonizer for loading skeletons
- Syncfusion Charts/DataGrid only where advanced report UI is needed (Inventory reports)
- `pdf` package for PDF export (not Syncfusion PDF)

GetWidget is intentionally **not** adopted.

## Alternatives Considered

- Raw Material widgets only (rejected — weak consistency)
- GetWidget as primary kit (rejected — not in project; risk of sprawl)
- Syncfusion PDF (rejected — dependency conflict with `excel`/`xml`)

## Consequences

- New screens should prefer tokens + App* widgets
- Third-party UI kits must not spread into Core without approval
- Legacy widgets still exist and should be migrated gradually
