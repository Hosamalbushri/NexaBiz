import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tenant_context.dart';

/// Session company used to isolate on-device Drift/Hive files.
///
/// Reflected from the active [currentCompanyIdProvider].
/// Default `null` keeps historical (bootstrap) storage names.
final sessionCompanyIdProvider = Provider<String?>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider);
  return companyId.isEmpty ? null : companyId;
});
