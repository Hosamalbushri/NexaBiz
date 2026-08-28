import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_mapping_resolver_impl.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_validation_service_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_validation_service.dart';

final accountValidationServiceProvider = Provider<AccountValidationService>((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return AccountValidationServiceImpl(repo);
});

final accountMappingResolverProvider = Provider<AccountMappingResolver>((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  final validation = ref.watch(accountValidationServiceProvider);
  return AccountMappingResolverImpl(
    accountRepository: repo,
    validationService: validation,
  );
});
