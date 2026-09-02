import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/sync/sync.dart';

/// Central coordinator for tenant-safe, scope-guarded sync module registration.
class SyncRegistryCoordinator {
  const SyncRegistryCoordinator({
    required this.registrars,
  });

  /// Registered module registrars.
  final List<SyncModuleRegistrar> registrars;

  /// Evaluates active scope, authentication, and tenant context to register eligible sync handlers.
  ///
  /// Prevents registration when:
  /// - Authentication is unavailable.
  /// - Tenant context is required but missing/empty.
  /// - System Scope is active while handler requires [SyncScope.companyOnly].
  List<String> synchronizeRegistration(dynamic ref) {
    final manager = ref.read(syncManagerProvider) as SyncManager;
    manager.clearHandlers();

    final authState = ref.read(authStateProvider);
    final currentCompanyId = ref.read(currentCompanyIdProvider) as String;
    final hasCompanyContext = currentCompanyId.trim().isNotEmpty;
    final isAuthenticated = authState.canUseRemoteSync || authState.isAuthenticated;
    final isSystemScopeActive = !hasCompanyContext || authState.session?.activeCompanyContext == null;

    final registeredModules = <String>[];

    for (final registrar in registrars) {
      final shouldRegister = _shouldRegisterModule(
        scope: registrar.scope,
        isAuthenticated: isAuthenticated,
        hasCompanyContext: hasCompanyContext,
        isSystemScopeActive: isSystemScopeActive,
      );

      if (shouldRegister) {
        final handlers = registrar.buildHandlers(ref);
        for (final handler in handlers) {
          manager.registerHandler(handler);
        }
        registeredModules.add(registrar.moduleId);
      }
    }

    return registeredModules;
  }

  static bool _shouldRegisterModule({
    required SyncScope scope,
    required bool isAuthenticated,
    required bool hasCompanyContext,
    required bool isSystemScopeActive,
  }) {
    if (!isAuthenticated) {
      return false;
    }

    switch (scope) {
      case SyncScope.systemOnly:
        return isSystemScopeActive;

      case SyncScope.companyOnly:
        // PREVENT registration when System Scope is active or company context is missing!
        if (isSystemScopeActive || !hasCompanyContext) {
          return false;
        }
        return true;

      case SyncScope.any:
        return true;
    }
  }
}
