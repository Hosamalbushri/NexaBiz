import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/tenant_database_name.dart';
import '../auth/ports/session_context_port.dart';
import 'tenant_context.dart';

/// Default fallback implementation of [SessionContextPort] when unauthenticated or unoverridden.
class UnauthenticatedSessionContextAdapter implements SessionContextPort {
  /// Creates an [UnauthenticatedSessionContextAdapter].
  const UnauthenticatedSessionContextAdapter();

  @override
  String? get currentCompanyId => null;

  @override
  String? get activeCompanyId => null;

  @override
  List<CompanyInfo> get companies => const <CompanyInfo>[];

  @override
  bool get isAuthenticated => false;

  @override
  String? get userId => null;

  @override
  String? get deviceId => null;

  @override
  bool get isStandalone => true;

  @override
  ScopeContext get scope => const SystemScope();
}

/// Provider for [SessionContextPort].
///
/// Abstract port provider for session context state. Overridden at application
/// bootstrap with concrete [SessionContextAdapter].
final sessionContextPortProvider = Provider<SessionContextPort>((ref) {
  return const UnauthenticatedSessionContextAdapter();
});

/// Provider exposing active [TenantContext].
///
/// Rule 4: No silent company fallback. An unassigned or system scope context
/// resolves to an empty company ID (''), except in offline standalone local mode
/// where [kLegacyLocalCompanyId] is used for single-tenant data isolation.
final tenantContextProvider = Provider<TenantContext>((ref) {
  final sessionContext = ref.watch(sessionContextPortProvider);

  final String activeCompanyId = sessionContext.activeCompanyId?.trim() ?? '';
  final String companyId = activeCompanyId;

  // Rule 4: No silent company fallback.
  // An unassigned context resolves to an empty company ID ('') with SystemScope or ContextualScope.

  if (!sessionContext.isAuthenticated && companyId.isEmpty) {
    return TenantContext.empty;
  }

  final ScopeContext scope = companyId.isNotEmpty
      ? CompanyScope(companyId)
      : sessionContext.scope;

  final String effectiveCompanyId = (companyId.isEmpty && scope is CompanyScope)
      ? scope.companyId
      : companyId;

  return TenantContext(
    companyId: effectiveCompanyId,
    userId: sessionContext.userId,
    deviceId: sessionContext.deviceId,
    isStandalone: sessionContext.isStandalone,
    scope: scope,
  );
});

/// Provider exposing current active company ID.
final currentCompanyIdProvider = Provider<String>((ref) {
  return ref.watch(tenantContextProvider).companyId;
});
