import '../entities/company_accounting_config.dart';
import '../entities/company_initialization_state.dart';
import '../entities/company_inventory_config.dart';
import '../entities/company_warehouse_config.dart';

/// Repository interface for company initialization state and sub-configurations.
/// Implementations must enforce company scoping using active company context.
abstract class CompanyInitializationRepository {
  /// Loads initialization state for the active company context.
  Future<CompanyInitializationState> getState();

  /// Saves initialization state for the active company context.
  Future<void> saveState(CompanyInitializationState state);

  /// Loads inventory configuration for the active company context.
  Future<CompanyInventoryConfig?> getInventoryConfig();

  /// Saves inventory configuration for the active company context.
  /// Enforces single base currency per company invariant.
  Future<void> saveInventoryConfig(CompanyInventoryConfig config);

  /// Loads accounting configuration for the active company context.
  Future<CompanyAccountingConfig?> getAccountingConfig();

  /// Saves accounting configuration for the active company context.
  Future<void> saveAccountingConfig(CompanyAccountingConfig config);

  /// Loads warehouse configuration for the active company context.
  Future<CompanyWarehouseConfig?> getWarehouseConfig();

  /// Saves warehouse configuration for the active company context.
  Future<void> saveWarehouseConfig(CompanyWarehouseConfig config);

  /// Validates all required sub-configurations for the active company context
  /// and atomically marks initialization as completed.
  /// Throws [StateError] if any mandatory configuration is missing.
  Future<CompanyInitializationState> finalizeInitialization();
}
