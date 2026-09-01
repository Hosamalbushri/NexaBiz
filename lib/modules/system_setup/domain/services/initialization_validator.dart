import 'package:flutter/foundation.dart';
import '../entities/company_accounting_config.dart';
import '../entities/company_initialization_state.dart';
import '../entities/company_inventory_config.dart';
import '../entities/company_warehouse_config.dart';

/// Result of evaluating company initialization readiness invariants.
@immutable
class InitializationValidationResult {
  const InitializationValidationResult({
    required this.isReady,
    required this.missingRequirements,
    required this.state,
  });

  final bool isReady;
  final List<String> missingRequirements;
  final CompanyInitializationState state;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InitializationValidationResult &&
          runtimeType == other.runtimeType &&
          isReady == other.isReady &&
          listEquals(missingRequirements, other.missingRequirements) &&
          state == other.state;

  @override
  int get hashCode =>
      isReady.hashCode ^ missingRequirements.hashCode ^ state.hashCode;
}

/// Evaluates whether a company has completed all mandatory initialization requirements.
class InitializationValidator {
  const InitializationValidator();

  InitializationValidationResult validate({
    required CompanyInitializationState state,
    CompanyInventoryConfig? inventoryConfig,
    CompanyAccountingConfig? accountingConfig,
    CompanyWarehouseConfig? warehouseConfig,
  }) {
    final missing = <String>[];

    if (!state.companyCreated || state.companyId.trim().isEmpty) {
      missing.add('Company profile has not been created');
    }

    if (!state.inventoryCurrencyConfigured ||
        inventoryConfig == null ||
        inventoryConfig.inventoryBaseCurrencyId.trim().isEmpty) {
      missing.add('Inventory base currency is not configured');
    }

    if (!state.accountingConfigured ||
        accountingConfig == null ||
        !accountingConfig.isComplete) {
      missing.add('System chart of accounts mappings are incomplete');
    }

    if (!state.warehouseConfigured ||
        warehouseConfig == null ||
        !warehouseConfig.isValid) {
      missing.add('Default primary warehouse is not configured');
    }

    if (!state.inventorySettingsConfigured) {
      missing.add('Inventory operational settings are not configured');
    }

    if (!state.initializationCompleted) {
      missing.add('Initialization completion flag is not finalized');
    }

    final isReady = missing.isEmpty;
    return InitializationValidationResult(
      isReady: isReady,
      missingRequirements: missing,
      state: state,
    );
  }
}
