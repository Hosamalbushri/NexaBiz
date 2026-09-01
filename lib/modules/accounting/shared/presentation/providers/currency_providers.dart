import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/accounting/shared/data/repositories/currency_repository_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/currency.dart';
import 'package:stock_count/modules/accounting/shared/domain/repositories/currency_repository.dart';

final currencyRepositoryProvider = Provider<CurrencyRepository>((ref) {
  final db = ref.watch(accountingDatabaseProvider);
  return CurrencyRepositoryImpl(
    db,
    readCompanyId: () => ref.read(currentCompanyIdProvider),
  );
});

final allCurrenciesProvider = StreamProvider<List<Currency>>((ref) {
  final repo = ref.watch(currencyRepositoryProvider);
  return repo.watchAll(includeInactive: true);
});

final activeCurrenciesProvider = StreamProvider<List<Currency>>((ref) {
  final repo = ref.watch(currencyRepositoryProvider);
  return repo.watchAll(includeInactive: false);
});

final defaultCurrencyProvider = FutureProvider<Currency?>((ref) async {
  final repo = ref.watch(currencyRepositoryProvider);
  return repo.getDefaultCurrency();
});
