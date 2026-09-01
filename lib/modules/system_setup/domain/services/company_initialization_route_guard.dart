import 'package:flutter/foundation.dart';

/// Decisions produced by the CompanyInitializationRouteGuard.
enum RouteRedirectDecision {
  allow,
  redirectToLogin,
  redirectToSetup,
  redirectToDashboard,
  accessDenied,
}

/// Pure domain route guard for enforcing authentication, initialization completeness,
/// and authorization before accessing inventory and protected application routes.
@immutable
class CompanyInitializationRouteGuard {
  const CompanyInitializationRouteGuard();

  /// Evaluates routing redirection rules for any requested path.
  ///
  /// Flow:
  /// Application Start -> Authentication -> Current User -> Current Company -> Initialization State
  RouteRedirectDecision evaluateRoute({
    required String path,
    required bool isAuthenticated,
    required bool isInitializationComplete,
    required bool isPublicRoute,
    required bool canAccessSetup,
  }) {
    final trimmedPath = path.trim();

    // 1. Mandatory Authentication Gate
    if (!isAuthenticated) {
      if (isPublicRoute) {
        return RouteRedirectDecision.allow;
      }
      return RouteRedirectDecision.redirectToLogin;
    }

    // 2. Setup Route Access Gate
    if (trimmedPath == '/setup' || trimmedPath.startsWith('/setup/')) {
      if (!canAccessSetup) {
        return RouteRedirectDecision.accessDenied;
      }
      return RouteRedirectDecision.allow;
    }

    // 3. Initialization Completeness Gate for Protected & Inventory Routes
    if (!isInitializationComplete) {
      if (trimmedPath != '/setup' && !isPublicRoute) {
        return canAccessSetup
            ? RouteRedirectDecision.redirectToSetup
            : RouteRedirectDecision.accessDenied;
      }
    }

    return RouteRedirectDecision.allow;
  }
}
