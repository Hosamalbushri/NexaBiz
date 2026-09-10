import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/sync/sync_core.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import '../../data/repositories/currency_rate_repository_impl.dart';
import '../../domain/entities/currency.dart';
import '../../domain/entities/app_currency.dart';
import '../../domain/entities/currency_rate.dart';
import '../../domain/repositories/currency_rate_repository.dart';
import 'currency_providers.dart';
import 'functional_currency_providers.dart';

final currencyRateRepositoryImplProvider = Provider<CurrencyRateRepositoryImpl>(
  (ref) {
    return CurrencyRateRepositoryImpl(
      ref.watch(accountingDatabaseProvider),
      syncQueue: ref.watch(syncQueueProvider),
      readCompanyId: () => ref.read(currentCompanyIdProvider),
    );
  },
);

final currencyRateRepositoryProvider = Provider<CurrencyRateRepository>((ref) {
  return ref.watch(currencyRateRepositoryImplProvider);
});

final currencyRatesProvider = StreamProvider<List<CurrencyRate>>((ref) {
  return ref.watch(currencyRateRepositoryProvider).watchAll();
});

/// Base currency for rates (from Currency Master / Functional Currency).
/// Returns `null` if no active currency is configured in system master data.
/// CRITICAL: Never defaults to SAR or any unconfigured currency.
final accountingBaseCurrencyProvider = Provider<AppCurrency?>((ref) {
  final activeCurrencies =
      ref.watch(activeCurrenciesProvider).valueOrNull ?? [];
  final defaultCurrency = activeCurrencies.cast<Currency?>().firstWhere(
    (c) => c?.isDefault == true,
    orElse: () => activeCurrencies.isNotEmpty ? activeCurrencies.first : null,
  );

  if (defaultCurrency != null) {
    return AppCurrency(
      code: defaultCurrency.code,
      nameAr: defaultCurrency.nameAr,
      nameEn: defaultCurrency.nameEn,
      symbol: defaultCurrency.symbol,
      decimalDigits: defaultCurrency.decimalDigits,
    );
  }

  final currencyInfo = ref
      .watch(functionalCurrencyStateInfoProvider)
      .valueOrNull;
  final code = currencyInfo?.currencyCode ?? '';
  if (code.isNotEmpty) {
    final masterMatch = activeCurrencies.cast<Currency?>().firstWhere(
      (c) => c?.code == code,
      orElse: () => null,
    );
    if (masterMatch != null) {
      return AppCurrency(
        code: masterMatch.code,
        nameAr: masterMatch.nameAr,
        nameEn: masterMatch.nameEn,
        symbol: masterMatch.symbol,
        decimalDigits: masterMatch.decimalDigits,
      );
    }
  }

  return null;
});

/// Indicates whether system base currency or active currencies state is currently loading from storage/database.
/// Prevents false-positive alert flashing during initial loading frames.
final isBaseCurrencyLoadingProvider = Provider<bool>((ref) {
  final activeCurrenciesAsync = ref.watch(activeCurrenciesProvider);
  final functionalCurrencyInfoAsync = ref.watch(functionalCurrencyStateInfoProvider);

  final activeLoading = activeCurrenciesAsync.isLoading && !activeCurrenciesAsync.hasValue;
  final functionalLoading = functionalCurrencyInfoAsync.isLoading && !functionalCurrencyInfoAsync.hasValue;

  return activeLoading || functionalLoading;
});

/// Enabled currencies for rates / future multi-currency balances.
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
      if (base == null) {
        return const AsyncData([]);
      }

      final ratesAsync = ref.watch(currencyRatesProvider);
      final activeCurrencies =
          ref.watch(activeCurrenciesProvider).valueOrNull ?? [];
      final activeCodes = {for (final c in activeCurrencies) c.code};

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
                .where((code) => code != base.code && activeCodes.contains(code))
                .toList(growable: false)
              ..sort();

        for (final code in foreignCodes) {
          final masterCurrency = activeCurrencies.cast<Currency?>().firstWhere(
            (c) => c?.code == code,
            orElse: () => null,
          );
          final appCurrency = masterCurrency != null
              ? AppCurrency(
                  code: masterCurrency.code,
                  nameAr: masterCurrency.nameAr,
                  nameEn: masterCurrency.nameEn,
                  symbol: masterCurrency.symbol,
                  decimalDigits: masterCurrency.decimalDigits,
                )
              : AppCurrencies.byCode(code);

          items.add(
            CurrencyRateListItem(
              currency: appCurrency,
              isBase: false,
              rate: byCode[code],
            ),
          );
        }
        return items;
      });
    });

/// Currencies from system Currency Master data that can be added to rate table.
/// CRITICAL: ONLY currencies configured in Currency Master database are shown.
/// Unconfigured default catalog currencies are never displayed.
final availableCurrenciesToAddProvider = Provider<List<AppCurrency>>((ref) {
  final base = ref.watch(accountingBaseCurrencyProvider);
  if (base == null) return const [];

  final masterCurrencies =
      ref.watch(activeCurrenciesProvider).valueOrNull ?? [];
  final ratesAsync = ref.watch(currencyRatesProvider);
  final enabled = <String>{base.code};
  final rates = ratesAsync.valueOrNull;
  if (rates != null) {
    for (final rate in rates) {
      enabled.add(rate.currencyCode);
    }
  }

  final addedCodes = <String>{};
  final result = <AppCurrency>[];

  // ONLY currencies active in master database
  for (final c in masterCurrencies) {
    if (!enabled.contains(c.code) && addedCodes.add(c.code)) {
      result.add(
        AppCurrency(
          code: c.code,
          nameAr: c.nameAr,
          nameEn: c.nameEn,
          symbol: c.symbol,
          decimalDigits: c.decimalDigits,
        ),
      );
    }
  }

  return result;
});
