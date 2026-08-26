import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/accounting_mode.dart';
import '../../domain/services/accounting_integration_port.dart';
import '../../domain/services/accounting_mode_policy.dart';

/// Platform accounting always runs as local/standalone (no mode switch).
final accountingModePolicyProvider = Provider<AccountingModePolicy>((ref) {
  return const AccountingModePolicy(AccountingMode.standalone);
});

/// Integration gateway — reserved for a future connector; unused by default.
final accountingIntegrationPortProvider = Provider<AccountingIntegrationPort>((
  ref,
) {
  return const NoOpAccountingIntegrationPort();
});
