import '../../tenancy/scope_context.dart';

/// Company information data transfer object for session context.
class CompanyInfo {
  /// Creates an immutable [CompanyInfo] instance.
  const CompanyInfo({required this.id, required this.name});

  /// Unique company identifier.
  final String id;

  /// Display name of the company.
  final String name;
}

/// Abstract port interface for accessing session authentication context.
///
/// Decouples core infrastructure (such as tenancy resolution) from concrete
/// authentication presentation providers.
abstract class SessionContextPort {
  /// Unique identifier of the current active company in session, if any.
  String? get currentCompanyId;

  /// Unique identifier of the active company context, if any.
  String? get activeCompanyId;

  /// List of companies accessible in the current session.
  List<CompanyInfo> get companies;

  /// Whether a valid user session is currently authenticated.
  bool get isAuthenticated;

  /// Unique identifier of the authenticated user, if any.
  String? get userId;

  /// Unique identifier of the active device, if any.
  String? get deviceId;

  /// Whether the session is operating as standalone / super admin mode.
  bool get isStandalone;

  /// Active operational scope context (System, Company, Global, or Contextual).
  ScopeContext get scope;
}

