import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_mapping_resolver_impl.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_validation_service_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_binding_safety_gate.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_usage_analyzer.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_validation_service.dart';
import 'package:stock_count/modules/system_setup/presentation/providers/system_setup_providers.dart';

final accountValidationServiceProvider = Provider<AccountValidationService>((
  ref,
) {
  final repo = ref.watch(accountRepositoryProvider);
  return AccountValidationServiceImpl(repo);
});

final accountUsageAnalyzerProvider = Provider<AccountUsageAnalyzer>((ref) {
  return AccountUsageAnalyzerImpl();
});

final accountBindingSafetyGateProvider = Provider<AccountBindingSafetyGate>((
  ref,
) {
  final repo = ref.watch(accountRepositoryProvider);
  final usageAnalyzer = ref.watch(accountUsageAnalyzerProvider);
  return AccountBindingSafetyGate(
    accountRepository: repo,
    usageAnalyzer: usageAnalyzer,
  );
});

final accountMappingResolverProvider = Provider<AccountMappingResolver>((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  final validation = ref.watch(accountValidationServiceProvider);
  final initRepo = ref.watch(companyInitializationRepositoryProvider);
  return AccountMappingResolverImpl(
    accountRepository: repo,
    validationService: validation,
    initRepository: initRepo,
  );
});
