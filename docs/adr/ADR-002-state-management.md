# ADR-002: State Management with Riverpod

## Status

Accepted (implemented)

## Context

The platform needs dependency injection, reactive UI updates, and clear separation between ephemeral UI state and async workflows (import, save, export).

## Decision

Use **flutter_riverpod** as the sole state-management and DI approach.

Patterns in use:

- `Provider` for services/repositories/use cases
- `StreamProvider` for watched collections
- `StateProvider` for simple UI state
- `StateNotifier` / `StateNotifierProvider` for multi-step flows

Bootstrap uses `ProviderContainer` + `UncontrolledProviderScope` to preload theme/locale.

## Alternatives Considered

- `provider` package only
- Bloc/Cubit
- GetX
- Riverpod code generation / `Notifier` migration (possible future; not required now)

## Consequences

- Consistent DI without `get_it`
- Business logic can live in notifiers/domain instead of widgets
- Contributors should follow existing Riverpod 2.x patterns already in Inventory
