import 'dart:math';
import '../entities/company_inventory_config.dart';
import '../repositories/company_initialization_repository.dart';

/// Exceptions thrown during currency operations.
class CompanyCurrencyException implements Exception {
  const CompanyCurrencyException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Service managing Company Inventory Base Currency configuration,
/// independent document currency conversions, and transaction immutability checks.
class CompanyCurrencyService {
  CompanyCurrencyService({
    required CompanyInitializationRepository initRepository,
    Future<bool> Function(String companyId)? transactionChecker,
  })  : _initRepository = initRepository,
        _transactionChecker = transactionChecker;

  final CompanyInitializationRepository _initRepository;
  final Future<bool> Function(String companyId)? _transactionChecker;

  /// Returns the configured inventory base currency for the company.
  /// Defaults to 'YER' if not yet configured.
  Future<String> getInventoryBaseCurrency([String? companyId]) async {
    final config = await _initRepository.getInventoryConfig();
    if (config != null && config.inventoryBaseCurrencyId.isNotEmpty) {
      return config.inventoryBaseCurrencyId.toUpperCase();
    }
    return 'YER';
  }

  /// Sets or updates the inventory base currency for the active company.
  ///
  /// Constraints:
  /// 1. Enforces ONE base currency per company.
  /// 2. If transactions (inventory/financial) exist for the company: REJECT modifications.
  Future<void> configureInventoryBaseCurrency({
    required String currencyCode,
    bool allowNegativeStock = false,
    String defaultCostingMethod = 'FIFO',
  }) async {
    final normalizedCurrency = currencyCode.trim().toUpperCase();
    if (normalizedCurrency.isEmpty) {
      throw const CompanyCurrencyException('Currency code cannot be empty');
    }

    final existingConfig = await _initRepository.getInventoryConfig();
    final state = await _initRepository.getState();
    final companyId = state.companyId;

    // Currency Immutability Guard: Check if transactions already exist
    final hasTx = _transactionChecker != null && companyId.isNotEmpty
        ? await _transactionChecker(companyId)
        : false;

    if (hasTx &&
        existingConfig != null &&
        existingConfig.inventoryBaseCurrencyId.isNotEmpty &&
        existingConfig.inventoryBaseCurrencyId != normalizedCurrency) {
      throw StateError(
        'Cannot change inventory base currency to ($normalizedCurrency) because transactions already exist for company ($companyId). Current currency: ${existingConfig.inventoryBaseCurrencyId}',
      );
    }

    final newConfig = CompanyInventoryConfig(
      companyId: companyId,
      inventoryBaseCurrencyId: normalizedCurrency,
      allowNegativeStock: allowNegativeStock,
      defaultCostingMethod: defaultCostingMethod,
      updatedAt: DateTime.now().toUtc(),
    );

    await _initRepository.saveInventoryConfig(newConfig);
  }

  /// Converts a document amount in document currency to inventory base currency.
  ///
  /// Formula: `inventoryCost = documentAmount * exchangeRate`
  /// Standard rounding to [decimalPlaces] (default: 2).
  ///
  /// Example:
  /// Document: 100 SAR, Exchange Rate: 145 -> Cost: 14,500 YER
  double convertToInventoryBaseCurrency({
    required double documentAmount,
    required double exchangeRate,
    int decimalPlaces = 2,
  }) {
    if (exchangeRate <= 0) {
      throw const CompanyCurrencyException(
        'Exchange rate must be a positive non-zero value',
      );
    }
    final rawCost = documentAmount * exchangeRate;
    final mod = pow(10, decimalPlaces).toDouble();
    return (rawCost * mod).round() / mod;
  }
}
