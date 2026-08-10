# ADR-001: Modular Architecture

## Status

Accepted (implemented)

## Context

The product must support multiple independent business services over time. Building the app as an inventory-only codebase would force rewrites when adding Sales, Purchases, and other domains.

## Decision

Adopt a modular layout:

- `app/` composition root
- `core/` generic infrastructure + `AppModule` contract
- `shared/` cross-module launcher UI
- `modules/<name>/` isolated business verticals

Modules register through `ModuleRegistry` in `lib/app/bootstrap/module_bootstrap.dart`. Core never imports modules.

## Alternatives Considered

- Feature-first folders under a single inventory-centric shell
- Package-per-module monorepo (deferred — heavier for current stage)
- Dynamic plugin loading (not required)

## Consequences

- New modules can be added by implementing `AppModule` and registering once
- Inventory remains isolated under `modules/inventory/`
- Contributors must respect dependency direction and avoid putting business types in Core
