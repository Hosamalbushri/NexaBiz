import 'package:flutter/foundation.dart';

import '../../app/exit/app_exit_scope.dart';
import '../../app/presentation/providers/dashboard_services_provider.dart';
import '../../app/router/app_router.dart';
import '../../app/router/app_routes.dart';
import '../../app/settings/company/company_profile_providers.dart';
import '../../modules/authentication/domain/entities/auth_session.dart';
import '../../modules/authentication/presentation/providers/auth_providers.dart';
import '../auth/presentation/providers/auth_context_providers.dart';
import '../entitlements/presentation/providers/entitlement_providers.dart';

/// Strongly typed result of a company context switch operation.
@immutable
class CompanySwitchResult {
  const CompanySwitchResult._({
    required this.isSuccess,
    required this.companyId,
    required this.previousCompanyId,
    this.session,
    this.failureReason,
    this.isNoOp = false,
  });

  /// Successful switch to target company.
  factory CompanySwitchResult.success({
    required String companyId,
    required String previousCompanyId,
    required AuthSessionSnapshot session,
    bool isNoOp = false,
  }) {
    return CompanySwitchResult._(
      isSuccess: true,
      companyId: companyId,
      previousCompanyId: previousCompanyId,
      session: session,
      isNoOp: isNoOp,
    );
  }

  /// Failed switch attempt — previous context preserved.
  factory CompanySwitchResult.failure(String failureReason) {
    return CompanySwitchResult._(
      isSuccess: false,
      companyId: '',
      previousCompanyId: '',
      failureReason: failureReason,
    );
  }

  final bool isSuccess;
  final bool isNoOp;
  final String companyId;
  final String previousCompanyId;
  final AuthSessionSnapshot? session;
  final String? failureReason;

  @override
  String toString() {
    if (isSuccess) {
      return 'CompanySwitchResult.success(companyId: $companyId, previousCompanyId: $previousCompanyId, isNoOp: $isNoOp)';
    }
    return 'CompanySwitchResult.failure(reason: $failureReason)';
  }
}

/// Lifecycle event payload emitted when active tenant context changes.
@immutable
class TenantContextChangeEvent {
  const TenantContextChangeEvent({
    required this.previousCompanyId,
    required this.newCompanyId,
    required this.userId,
    required this.timestamp,
  });

  final String previousCompanyId;
  final String newCompanyId;
  final String userId;
  final DateTime timestamp;
}

/// Performs complete tenant isolation reset on company switch:
/// 1. Resets shell navigation history stack to root Dashboard
/// 2. Resets GoRouter location to clean Dashboard state
/// 3. Invalidates company-scoped providers
void performTenantContextReset(dynamic ref) {
  // 1. Reset shell navigation history stack
  try {
    ref.read(shellHistoryProvider.notifier).reset();
  } catch (_) {}

  // 2. Invalidate company-scoped providers
  try {
    ref.invalidate(currentEntitlementProvider);
    ref.invalidate(currentPermissionsProvider);
    ref.invalidate(authorizationContextProvider);
    ref.invalidate(companyProfileProvider);
    ref.invalidate(dashboardServicesProvider);
  } catch (_) {}

  // 3. Reset router location to clean Dashboard state
  try {
    ref.read(appRouterProvider).go(AppRoutes.dashboard);
  } catch (_) {}
}
