import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/modules/sync/sync.dart';
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
final accountingBaseCurrencyProvider = Provider<AppCurrency>((ref) {
  final activeCurrencies = ref.watch(activeCurrenciesProvider).valueOrNull ?? [];
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

  final currencyInfo = ref.watch(functionalCurrencyStateInfoProvider).valueOrNull;
  final code = currencyInfo?.currencyCode ?? '';
  if (code.isNotEmpty) {
    return AppCurrencies.byCode(code);
  }

  return AppCurrencies.sar;
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

/// Catalog currencies from Currency Master and standard catalog that can be added to rate table.
final availableCurrenciesToAddProvider = Provider<List<AppCurrency>>((ref) {
  final base = ref.watch(accountingBaseCurrencyProvider);
  final masterCurrencies = ref.watch(activeCurrenciesProvider).valueOrNull ?? [];
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

  // 1. Currencies active in master database
  for (final c in masterCurrencies) {
    if (!enabled.contains(c.code) && addedCodes.add(c.code)) {
      result.add(AppCurrency(
        code: c.code,
        nameAr: c.nameAr,
        nameEn: c.nameEn,
        symbol: c.symbol,
        decimalDigits: c.decimalDigits,
      ));
    }
  }

  // 2. Currencies from standard platform catalog
  for (final c in AppCurrencies.all) {
    if (!enabled.contains(c.code) && addedCodes.add(c.code)) {
      result.add(c);
    }
  }

  return result;
});
