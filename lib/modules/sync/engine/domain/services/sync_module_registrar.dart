import 'sync_entity_handler.dart';

/// Scope requirement for sync module registration.
enum SyncScope {
  /// Registrable only when System Scope is active (e.g. system setup, global administration).
  systemOnly,

  /// Registrable only when an active Company Scope with valid tenant ID is established.
  companyOnly,

  /// Registrable in any active scope (e.g. company profile, user settings).
  any,
}

/// Interface contract for registering sync handlers for a specific business module.
abstract class SyncModuleRegistrar {
  /// Unique identifier of the business module (e.g. 'inventory', 'accounting').
  String get moduleId;

  /// Required execution scope for this module's sync handlers.
  SyncScope get scope;

  /// Builds and returns the list of sync entity handlers for this module.
  List<SyncEntityHandler> buildHandlers(dynamic ref);
}
