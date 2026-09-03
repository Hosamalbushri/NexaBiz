import 'package:flutter/foundation.dart';
import '../../modules/authentication/domain/entities/auth_session.dart';

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
