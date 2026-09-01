import 'package:stock_count/core/domain/ports/setup_warehouse_lookup_port.dart';
import '../entities/company_inventory_config.dart';
import '../entities/company_warehouse_config.dart';
import '../repositories/company_initialization_repository.dart';

/// Exception thrown when an assigned default warehouse fails validation.
class InvalidWarehouseException implements Exception {
  const InvalidWarehouseException({
    required this.warehouseId,
    required this.reason,
  });

  final String warehouseId;
  final String reason;

  @override
  String toString() =>
      'InvalidWarehouseException: Warehouse ($warehouseId) invalid — $reason';
}

/// Domain service for company default warehouse and inventory operational settings configuration.
class CompanyWarehouseConfigService {
  CompanyWarehouseConfigService({
    required SetupWarehouseLookupPort warehouseLookupPort,
    required CompanyInitializationRepository initRepository,
  })  : _warehouseLookupPort = warehouseLookupPort,
        _initRepository = initRepository;

  final SetupWarehouseLookupPort _warehouseLookupPort;
  final CompanyInitializationRepository _initRepository;

  /// Validates that a warehouse satisfies all 4 operational invariants:
  /// 1. Exists in database
  /// 2. Belongs to active company context (No cross-company warehouse)
  /// 3. Is currently active
  /// 4. Is valid for inventory (Not deleted)
  Future<SetupWarehouseData> validateWarehouse(String warehouseId) async {
    final trimmedId = warehouseId.trim();
    if (trimmedId.isEmpty) {
      throw const InvalidWarehouseException(
        warehouseId: '',
        reason: 'Warehouse ID cannot be empty',
      );
    }

    final state = await _initRepository.getState();
    final companyId = state.companyId;

    final warehouse = await _warehouseLookupPort.getWarehouseById(trimmedId);

    // 1. Existence Check
    if (warehouse == null) {
      throw InvalidWarehouseException(
        warehouseId: trimmedId,
        reason: 'Warehouse does not exist in database',
      );
    }

    // 2. Company Scoping Validation
    if (warehouse.companyId != null &&
        warehouse.companyId!.isNotEmpty &&
        companyId.isNotEmpty &&
        warehouse.companyId != companyId) {
      throw InvalidWarehouseException(
        warehouseId: trimmedId,
        reason:
            'Cross-company violation: Warehouse belongs to company (${warehouse.companyId}), expected ($companyId)',
      );
    }

    // 3. Active Status Validation
    if (!warehouse.isActive) {
      throw InvalidWarehouseException(
        warehouseId: trimmedId,
        reason: 'Warehouse is inactive',
      );
    }

    // 4. Deleted Status Validation
    if (warehouse.isDeleted) {
      throw InvalidWarehouseException(
        warehouseId: trimmedId,
        reason: 'Warehouse has been soft-deleted',
      );
    }

    return warehouse;
  }

  /// Configures and persists default primary warehouse for active company context.
  Future<CompanyWarehouseConfig> configureDefaultWarehouse({
    required String warehouseId,
  }) async {
    final state = await _initRepository.getState();
    final companyId = state.companyId;

    if (companyId.trim().isEmpty) {
      throw StateError('Cannot configure warehouse: Active companyId is uninitialized');
    }

    // Validate warehouse invariants
    await validateWarehouse(warehouseId);

    final now = DateTime.now().toUtc();
    final config = CompanyWarehouseConfig(
      companyId: companyId,
      defaultWarehouseId: warehouseId.trim(),
      updatedAt: now,
    );

    await _initRepository.saveWarehouseConfig(config);

    // Mark initialization state flag
    final updatedState = state.copyWith(
      warehouseConfigured: true,
      updatedAt: now,
    );
    await _initRepository.saveState(updatedState);

    return config;
  }

  /// Configures and persists operational inventory settings for active company context.
  Future<CompanyInventoryConfig> configureInventoryOperationalSettings({
    bool allowNegativeStock = false,
    String defaultCostingMethod = 'FIFO',
    int quantityPrecision = 2,
    int costPrecision = 2,
    int currencyPrecision = 2,
    bool allowReturnsWithoutInvoice = false,
    bool requireStockCountApproval = true,
    bool autoPostAccountingEntries = true,
  }) async {
    final state = await _initRepository.getState();
    final companyId = state.companyId;

    if (companyId.trim().isEmpty) {
      throw StateError('Cannot configure inventory settings: Active companyId is uninitialized');
    }

    final existingInventoryConfig = await _initRepository.getInventoryConfig();
    final now = DateTime.now().toUtc();

    final config = (existingInventoryConfig ??
            CompanyInventoryConfig(
              companyId: companyId,
              inventoryBaseCurrencyId: 'YER',
            ))
        .copyWith(
      allowNegativeStock: allowNegativeStock,
      defaultCostingMethod: defaultCostingMethod.trim(),
      quantityPrecision: quantityPrecision,
      costPrecision: costPrecision,
      currencyPrecision: currencyPrecision,
      allowReturnsWithoutInvoice: allowReturnsWithoutInvoice,
      requireStockCountApproval: requireStockCountApproval,
      autoPostAccountingEntries: autoPostAccountingEntries,
      updatedAt: now,
    );

    await _initRepository.saveInventoryConfig(config);

    // Mark initialization state flag
    final updatedState = state.copyWith(
      inventorySettingsConfigured: true,
      updatedAt: now,
    );
    await _initRepository.saveState(updatedState);

    return config;
  }
}
