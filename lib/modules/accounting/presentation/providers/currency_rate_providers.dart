import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/settings/company/app_currency.dart';
import '../../../../app/settings/company/company_profile.dart';
import '../../../../app/settings/company/company_profile_providers.dart';
import 'package:stock_count/modules/sync/sync.dart';
import '../../../../core/tenancy/tenant_context.dart';
import '../../data/repositories/currency_rate_repository_impl.dart';
import '../../domain/entities/currency_rate.dart';
import '../../domain/repositories/currency_rate_repository.dart';
import 'account_providers.dart';

final currencyRateRepositoryImplProvider =
    Provider<CurrencyRateRepositoryImpl>((ref) {
  return CurrencyRateRepositoryImpl(
    ref.watch(accountingDatabaseProvider),
    syncQueue: ref.watch(syncQueueProvider),
    readCompanyId: () => ref.read(currentCompanyIdProvider),
  );
});

final currencyRateRepositoryProvider = Provider<CurrencyRateRepository>((ref) {
  return ref.watch(currencyRateRepositoryImplProvider);
});

final currencyRatesProvider = StreamProvider<List<CurrencyRate>>((ref) {
  return ref.watch(currencyRateRepositoryProvider).watchAll();
});

/// Base currency for rates (from company setup).
final accountingBaseCurrencyProvider = Provider<AppCurrency>((ref) {
  final profile =
      ref.watch(companyProfileProvider).valueOrNull ?? const CompanyProfile();
  return profile.defaultCurrency;
});

/// Enabled currencies for rates / future multi-currency balances.
///
/// Only the company base currency and currencies the user has explicitly
/// added (rows in `currency_rates`) appear — not the full catalog.
class CurrencyRateListItem {
  const CurrencyRateListItem({
    required this.currency,
    required this.isBase,
    this.rate,
  });

  final AppCurrency currency;
  final bool isBase;
  final CurrencyRate? rate;

  double get displayRate => isBase ? 1 : (rate?.rateToBase ?? 0);
  bool get hasRate => isBase || rate != null;
}

final currencyRateListProvider =
    Provider<AsyncValue<List<CurrencyRateListItem>>>((ref) {
      final base = ref.watch(accountingBaseCurrencyProvider);
      final ratesAsync = ref.watch(currencyRatesProvider);
      return ratesAsync.whenData((rates) {
        final byCode = {for (final r in rates) r.currencyCode: r};
        final items = <CurrencyRateListItem>[
          CurrencyRateListItem(
            currency: base,
            isBase: true,
            rate: byCode[base.code],
          ),
        ];

        final foreignCodes =
            byCode.keys
                .where((code) => code != base.code)
                .toList(growable: false)
              ..sort();

        for (final code in foreignCodes) {
          items.add(
            CurrencyRateListItem(
              currency: AppCurrencies.byCode(code),
              isBase: false,
              rate: byCode[code],
            ),
          );
        }
        return items;
      });
    });

/// Catalog currencies that can still be enabled (not base, not already added).
final availableCurrenciesToAddProvider = Provider<List<AppCurrency>>((ref) {
  final base = ref.watch(accountingBaseCurrencyProvider);
  final ratesAsync = ref.watch(currencyRatesProvider);
  final enabled = <String>{base.code};
  final rates = ratesAsync.valueOrNull;
  if (rates != null) {
    for (final rate in rates) {
      enabled.add(rate.currencyCode);
    }
  }
  return [
    for (final currency in AppCurrencies.all)
      if (!enabled.contains(currency.code)) currency,
  ];
});
