import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/audit/domain/ports/audit_repository_port.dart';
import 'package:stock_count/core/audit/domain/services/audit_trail_service.dart';
import 'package:stock_count/core/tenancy/tenant_providers.dart';

/// Provider for [AuditRepositoryPort].
/// Unimplemented by default; overridden at application bootstrap via [AppBootstrap.auditRepositoryPortOverride].
final auditRepositoryPortProvider = Provider<AuditRepositoryPort>((ref) {
  throw UnimplementedError(
    'auditRepositoryPortProvider has not been overridden',
  );
});

/// Provider for [AuditTrailService].
final auditTrailServiceProvider = Provider<AuditTrailService>((ref) {
  final repo = ref.watch(auditRepositoryPortProvider);
  final sessionContext = ref.watch(sessionContextPortProvider);
  return AuditTrailService(repository: repo, sessionContext: sessionContext);
});
