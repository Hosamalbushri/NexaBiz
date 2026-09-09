import 'package:stock_count/app/settings/company/functional_currency_service.dart';
import 'package:stock_count/shared/contracts/errors/currency_exception.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/currency.dart';
import 'package:stock_count/modules/accounting/shared/domain/repositories/currency_repository.dart';
import 'package:stock_count/modules/currency/domain/repositories/currency_rate_repository.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';

/// Service responsible for resolving and validating the explicit inventory valuation currency
/// per company / inventory book scope.
class InventoryValuationCurrencyService {
  InventoryValuationCurrencyService({
    required FunctionalCurrencyService functionalCurrencyService,
    CurrencyRepository? currencyRepository,
    CurrencyRateRepository? currencyRateRepository,
    CompanyInitializationRepository? initRepository,
  }) : _functionalCurrencyService = functionalCurrencyService,
       _currencyRepository = currencyRepository,
       _currencyRateRepository = currencyRateRepository,
       _initRepository = initRepository;

  final FunctionalCurrencyService _functionalCurrencyService;
  final CurrencyRepository? _currencyRepository;
  final CurrencyRateRepository? _currencyRateRepository;
  final CompanyInitializationRepository? _initRepository;

  /// Resolves the explicit inventory valuation currency for [companyId].
  ///
  /// Rule:
  /// - If an explicit inventory base currency is configured (via [CompanyInventoryConfig]):
  ///   1. Resolves the currency from master data.
  ///   2. If inventory currency != system functional currency:
  ///      MUST verify that an exchange rate exists in [CurrencyRateRepository].
  ///      If missing, throws [CurrencyRateRequiredException].
  /// - Otherwise, defaults to system functional currency.
  Future<Currency> getValuationCurrency([String? companyId]) async {
    final functionalCurrency = await _functionalCurrencyService
        .getFunctionalCurrency(companyId);

    if (_initRepository == null) {
      return functionalCurrency;
    }

    final inventoryConfig = await _initRepository.getInventoryConfig();
    final inventoryCurrencyCode = inventoryConfig?.inventoryBaseCurrencyId
        .trim()
        .toUpperCase();

    if (inventoryCurrencyCode == null ||
        inventoryCurrencyCode.isEmpty ||
        inventoryCurrencyCode == functionalCurrency.code.toUpperCase()) {
      return functionalCurrency;
    }

    // Inventory currency differs from system functional currency!
    if (_currencyRepository != null) {
      final inventoryCurrency = await _currencyRepository.getByCode(
        inventoryCurrencyCode,
      );
      if (inventoryCurrency == null || !inventoryCurrency.isActive) {
        throw InvalidFunctionalCurrencyException(
          'عملة تقييم المخزون المحددة ($inventoryCurrencyCode) غير موجودة أو غير نشطة في سجلات المنشأة.',
        );
      }

      // MANDATORY FX RATE CHECK:
      // Verify that an exchange rate exists between inventory currency and functional currency
      if (_currencyRateRepository != null) {
        final rate = await _currencyRateRepository.getByCode(
          inventoryCurrencyCode,
        );
        final rateValue = rate?.rateToBase ?? 0;
        if (rateValue <= 0) {
          throw CurrencyRateRequiredException(
            'عملة تقييم المخزون ($inventoryCurrencyCode) تختلف عن عملة النظام الأساسية (${functionalCurrency.code}). يجب إدخال سعر الصرف بينهما في شاشة أسعار الصرف أولاً.',
            currencyCode: inventoryCurrencyCode,
            baseCurrencyCode: functionalCurrency.code,
          );
        }
      }

      return inventoryCurrency;
    }

    return functionalCurrency;
  }
}
