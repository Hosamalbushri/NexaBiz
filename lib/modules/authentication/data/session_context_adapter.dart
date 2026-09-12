import 'package:stock_count/core/auth/ports/session_context_port.dart';

import '../domain/entities/auth_user.dart';
import '../presentation/providers/auth_providers.dart';
import 'local_auth_store.dart';

import 'package:stock_count/core/tenancy/scope_context.dart';
import 'package:stock_count/core/database/tenant_database_name.dart';

/// Adapter implementation of [SessionContextPort] for the authentication module.
///
/// Converts module-level authentication state and [LocalAuthStore] data into
/// the abstract core [SessionContextPort] interface.
class SessionContextAdapter implements SessionContextPort {
  /// Creates a [SessionContextAdapter] with the provided [authState] and optional [localAuthStore].
  const SessionContextAdapter({required this.authState, this.localAuthStore});

  /// The current authentication state snapshot.
  final AuthState authState;

  /// Optional local auth store reference.
  final LocalAuthStore? localAuthStore;

  @override
  bool get isAuthenticated =>
      authState.isAuthenticated && authState.session != null;

  @override
  String? get currentCompanyId => authState.session?.currentCompanyId;

  @override
  String? get activeCompanyId => authState.session?.activeCompanyId;

  @override
  List<CompanyInfo> get companies {
    final List<AuthCompany> sessionCompanies =
        authState.session?.companies ?? const <AuthCompany>[];
    return sessionCompanies
        .map(
          (AuthCompany company) =>
              CompanyInfo(id: company.id, name: company.name),
        )
        .toList(growable: false);
  }

  @override
  String? get userId => authState.session?.user.id;

  @override
  String? get deviceId => authState.session?.deviceId;

  @override
  bool get isStandalone => authState.session?.user.isSuperAdmin ?? false;

  @override
  ScopeContext get scope {
    final String activeId = activeCompanyId?.trim() ?? currentCompanyId?.trim() ?? '';
    if (activeId.isNotEmpty) {
      return CompanyScope(activeId);
    }
    if (companies.length == 1) {
      return CompanyScope(companies.first.id.trim());
    }
    if (isStandalone && companies.isEmpty) {
      return const CompanyScope(kLegacyLocalCompanyId);
    }
    return const SystemScope();
  }
}
