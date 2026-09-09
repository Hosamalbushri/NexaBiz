import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/app/settings/company/functional_currency_providers.dart';
import 'package:stock_count/shared/contracts/errors/currency_exception.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/currency.dart';
import 'package:stock_count/modules/accounting/shared/presentation/providers/currency_providers.dart';
import 'package:stock_count/core/auth/presentation/providers/auth_state_core.dart';
import 'package:stock_count/modules/currency/presentation/providers/currency_rate_providers.dart';
import 'package:stock_count/modules/inventory/products/presentation/providers/product_providers.dart';
import 'package:stock_count/modules/system_setup/presentation/providers/system_setup_providers.dart';

import '../../domain/services/inventory_valuation_currency_service.dart';

/// Service provider for InventoryValuationCurrencyService.
final inventoryValuationCurrencyServiceProvider =
    Provider<InventoryValuationCurrencyService>((ref) {
      final functionalService = ref.watch(functionalCurrencyServiceProvider);
      final currencyRepo = ref.watch(currencyRepositoryProvider);
      final currencyRateRepo = ref.watch(currencyRateRepositoryProvider);
      final initRepo = ref.watch(companyInitializationRepositoryProvider);
      return InventoryValuationCurrencyService(
        functionalCurrencyService: functionalService,
        currencyRepository: currencyRepo,
        currencyRateRepository: currencyRateRepo,
        initRepository: initRepo,
      );
    });

/// Holds reactive UI state for inventory valuation currency configuration.
class InventoryValuationCurrencyStateInfo {
  const InventoryValuationCurrencyStateInfo({
    required this.currency,
    required this.currencyCode,
    required this.configState,
    required this.scopeLabel,
    required this.isLocked,
    required this.canModify,
    this.errorMessage,
  });

  final Currency? currency;
  final String currencyCode;
  final FunctionalCurrencyConfigState configState;
  final String scopeLabel;
  final bool isLocked;
  final bool canModify;
  final String? errorMessage;

  bool get isConfigured =>
      configState == FunctionalCurrencyConfigState.configured;
  bool get isNotConfigured =>
      configState == FunctionalCurrencyConfigState.notConfigured;
  bool get isInvalid =>
      configState == FunctionalCurrencyConfigState.invalidConfig;
  bool get isInactive =>
      configState == FunctionalCurrencyConfigState.currencyInactive;
  bool get isChangeRestricted =>
      configState == FunctionalCurrencyConfigState.changeRestricted || isLocked;
}

/// Provider watching state information for Inventory Valuation Currency.
final inventoryValuationCurrencyStateProvider =
    FutureProvider<InventoryValuationCurrencyStateInfo>((ref) async {
      final authState = ref.watch(authStateProvider);
      final hasCompanyPermission =
          authState.hasPermission('platform.company.manage') ||
          authState.hasPermission('accounting.fiscal_years.configure_fx') ||
          authState.session?.user.isSuperAdmin == true;

      final service = ref.watch(inventoryValuationCurrencyServiceProvider);
      final db = ref.watch(inventoryDatabaseProvider);

      const scopeLabel = 'سجل المخزون / نطاق الشركة (Company Inventory Book)';

      // Check lock status: whether inventory cost layers or posted stock movements exist in SQLite database
      bool isLocked = false;
      try {
        final costLayers = await db.select(db.inventoryCostLayers).get();
        final stockReceipts = await db.select(db.stockReceipts).get();
        final stockIssues = await db.select(db.stockIssues).get();
        final hasPostedReceipts = stockReceipts.any(
          (r) => r.status == 'posted',
        );
        final hasPostedIssues = stockIssues.any((i) => i.status == 'posted');

        if (costLayers.isNotEmpty || hasPostedReceipts || hasPostedIssues) {
          isLocked = true;
        }
      } catch (_) {
        // Table fallback if uninitialized
      }

      try {
        final currency = await service.getValuationCurrency();
        if (!currency.isActive) {
          return InventoryValuationCurrencyStateInfo(
            currency: currency,
            currencyCode: currency.code,
            configState: FunctionalCurrencyConfigState.currencyInactive,
            scopeLabel: scopeLabel,
            isLocked: isLocked,
            canModify: false,
            errorMessage: 'عملة تقييم المخزون المحددة غير نشطة حالياً.',
          );
        }

        return InventoryValuationCurrencyStateInfo(
          currency: currency,
          currencyCode: currency.code,
          configState: isLocked
              ? FunctionalCurrencyConfigState.changeRestricted
              : FunctionalCurrencyConfigState.configured,
          scopeLabel: scopeLabel,
          isLocked: isLocked,
          canModify: hasCompanyPermission && !isLocked,
        );
      } on CurrencyRequiredException catch (e) {
        return InventoryValuationCurrencyStateInfo(
          currency: null,
          currencyCode: '',
          configState: FunctionalCurrencyConfigState.notConfigured,
          scopeLabel: scopeLabel,
          isLocked: isLocked,
          canModify: hasCompanyPermission && !isLocked,
          errorMessage: e.message,
        );
      } on InvalidFunctionalCurrencyException catch (e) {
        return InventoryValuationCurrencyStateInfo(
          currency: null,
          currencyCode: '',
          configState: FunctionalCurrencyConfigState.invalidConfig,
          scopeLabel: scopeLabel,
          isLocked: isLocked,
          canModify: hasCompanyPermission && !isLocked,
          errorMessage: e.message,
        );
      } on CurrencyRateRequiredException catch (e) {
        return InventoryValuationCurrencyStateInfo(
          currency: null,
          currencyCode: e.currencyCode,
          configState: FunctionalCurrencyConfigState.invalidConfig,
          scopeLabel: scopeLabel,
          isLocked: isLocked,
          canModify: hasCompanyPermission && !isLocked,
          errorMessage: e.message,
        );
      } catch (e) {
        return InventoryValuationCurrencyStateInfo(
          currency: null,
          currencyCode: '',
          configState: FunctionalCurrencyConfigState.invalidConfig,
          scopeLabel: scopeLabel,
          isLocked: isLocked,
          canModify: false,
          errorMessage: e.toString(),
        );
      }
    });
