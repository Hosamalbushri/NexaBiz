import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/app/presentation/providers/dashboard_services_provider.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import '../../data/repositories/currency_repository_impl.dart';
import '../../domain/entities/currency.dart';
import '../../domain/repositories/currency_repository.dart';
import '../../domain/services/functional_currency_service.dart';

final currencyRepositoryProvider = Provider<CurrencyRepository>((ref) {
  final db = ref.watch(accountingDatabaseProvider);
  return CurrencyRepositoryImpl(
    db,
    readCompanyId: () => ref.read(currentCompanyIdProvider),
  );
});

final allCurrenciesProvider = StreamProvider<List<Currency>>((ref) async* {
  final repo = ref.watch(currencyRepositoryProvider);
  yield await repo.getAll(includeInactive: true);
  yield* repo.watchAll(includeInactive: true);
});

final activeCurrenciesProvider = StreamProvider<List<Currency>>((ref) async* {
  final repo = ref.watch(currencyRepositoryProvider);
  yield await repo.getAll(includeInactive: false);
  yield* repo.watchAll(includeInactive: false);
});

final defaultCurrencyProvider = FutureProvider<Currency?>((ref) async {
  final repo = ref.watch(currencyRepositoryProvider);
  return repo.getDefaultCurrency();
});

final functionalCurrencyServiceProvider = Provider<FunctionalCurrencyService>((
  ref,
) {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final currencyRepo = ref.watch(currencyRepositoryProvider);
  final db = ref.watch(accountingDatabaseProvider);
  return FunctionalCurrencyService(
    settingsRepository: settingsRepo,
    currencyRepository: currencyRepo,
    db: db,
  );
});

final functionalCurrencyProvider = FutureProvider<Currency>((ref) async {
  final service = ref.watch(functionalCurrencyServiceProvider);
  final companyId = ref.watch(currentCompanyIdProvider);
  return service.getFunctionalCurrency(companyId);
});
