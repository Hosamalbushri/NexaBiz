import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/database/hive_boxes.dart';
import '../../../authentication/data/local_auth_store.dart';
import '../../domain/entities/company_accounting_config.dart';
import '../../domain/entities/company_initialization_state.dart';
import '../../domain/entities/company_inventory_config.dart';
import '../../domain/entities/company_warehouse_config.dart';
import '../../domain/repositories/company_initialization_repository.dart';
import '../../domain/services/initialization_validator.dart';

/// Durable Hive-backed implementation of [CompanyInitializationRepository].
/// Enforces mandatory company isolation via `readCompanyId`.
class CompanyInitializationRepositoryImpl
    implements CompanyInitializationRepository {
  CompanyInitializationRepositoryImpl({
    Box<dynamic>? box,
    String Function()? readCompanyId,
  })  : _box = box,
        _readCompanyId = readCompanyId;

  Box<dynamic>? _box;
  final String Function()? _readCompanyId;

  String get _currentCompanyId =>
      _readCompanyId?.call() ?? LocalAuthDefaults.companyId;

  Future<Box<dynamic>> get _initBox async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    _box = await Hive.openBox<dynamic>(HiveBoxes.settings);
    return _box!;
  }

  String _stateKey(String companyId) => 'init_state_$companyId';
  String _inventoryKey(String companyId) => 'init_inventory_config_$companyId';
  String _accountingKey(String companyId) => 'init_accounting_config_$companyId';
  String _warehouseKey(String companyId) => 'init_warehouse_config_$companyId';

  @override
  Future<CompanyInitializationState> getState() async {
    final companyId = _currentCompanyId;
    final box = await _initBox;
    final raw = box.get(_stateKey(companyId));

    if (raw is Map) {
      return CompanyInitializationState.fromJson(
        Map<dynamic, dynamic>.from(raw),
      );
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return CompanyInitializationState.fromJson(
            Map<dynamic, dynamic>.from(decoded),
          );
        }
      } catch (_) {}
    }

    return CompanyInitializationState(companyId: companyId);
  }

  @override
  Future<void> saveState(CompanyInitializationState state) async {
    final companyId = _currentCompanyId;
    final scopedState = state.copyWith(
      companyId: companyId,
      updatedAt: DateTime.now().toUtc(),
    );
    final box = await _initBox;
    await box.put(_stateKey(companyId), scopedState.toJson());
  }

  @override
  Future<CompanyInventoryConfig?> getInventoryConfig() async {
    final companyId = _currentCompanyId;
    final box = await _initBox;
    final raw = box.get(_inventoryKey(companyId));

    if (raw is Map) {
      return CompanyInventoryConfig.fromJson(Map<dynamic, dynamic>.from(raw));
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return CompanyInventoryConfig.fromJson(
            Map<dynamic, dynamic>.from(decoded),
          );
        }
      } catch (_) {}
    }

    return null;
  }

  @override
  Future<void> saveInventoryConfig(CompanyInventoryConfig config) async {
    final companyId = _currentCompanyId;
    final existing = await getInventoryConfig();

    // Invariant constraint check: ONE inventory base currency per tenant.
    if (existing != null &&
        existing.inventoryBaseCurrencyId.isNotEmpty &&
        existing.inventoryBaseCurrencyId !=
            config.inventoryBaseCurrencyId.toUpperCase()) {
      throw StateError(
        'Inventory base currency cannot be modified once set for company ($companyId). Existing: ${existing.inventoryBaseCurrencyId}, Attempted: ${config.inventoryBaseCurrencyId}',
      );
    }

    final scopedConfig = config.copyWith(
      companyId: companyId,
      inventoryBaseCurrencyId: config.inventoryBaseCurrencyId.toUpperCase(),
      updatedAt: DateTime.now().toUtc(),
    );

    final box = await _initBox;
    await box.put(_inventoryKey(companyId), scopedConfig.toJson());

    // Update initialization state flag
    final state = await getState();
    await saveState(
      state.copyWith(
        inventoryCurrencyConfigured: true,
        inventorySettingsConfigured: true,
      ),
    );
  }

  @override
  Future<CompanyAccountingConfig?> getAccountingConfig() async {
    final companyId = _currentCompanyId;
    final box = await _initBox;
    final raw = box.get(_accountingKey(companyId));

    if (raw is Map) {
      return CompanyAccountingConfig.fromJson(Map<dynamic, dynamic>.from(raw));
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return CompanyAccountingConfig.fromJson(
            Map<dynamic, dynamic>.from(decoded),
          );
        }
      } catch (_) {}
    }

    return null;
  }

  @override
  Future<void> saveAccountingConfig(CompanyAccountingConfig config) async {
    final companyId = _currentCompanyId;
    final scopedConfig = config.copyWith(
      companyId: companyId,
      updatedAt: DateTime.now().toUtc(),
    );

    final box = await _initBox;
    await box.put(_accountingKey(companyId), scopedConfig.toJson());

    // Update initialization state flag
    final state = await getState();
    await saveState(
      state.copyWith(accountingConfigured: scopedConfig.isComplete),
    );
  }

  @override
  Future<CompanyWarehouseConfig?> getWarehouseConfig() async {
    final companyId = _currentCompanyId;
    final box = await _initBox;
    final raw = box.get(_warehouseKey(companyId));

    if (raw is Map) {
      return CompanyWarehouseConfig.fromJson(Map<dynamic, dynamic>.from(raw));
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return CompanyWarehouseConfig.fromJson(
            Map<dynamic, dynamic>.from(decoded),
          );
        }
      } catch (_) {}
    }

    return null;
  }

  @override
  Future<void> saveWarehouseConfig(CompanyWarehouseConfig config) async {
    final companyId = _currentCompanyId;
    final scopedConfig = config.copyWith(
      companyId: companyId,
      updatedAt: DateTime.now().toUtc(),
    );

    final box = await _initBox;
    await box.put(_warehouseKey(companyId), scopedConfig.toJson());

    // Update initialization state flag
    final state = await getState();
    await saveState(
      state.copyWith(warehouseConfigured: scopedConfig.isValid),
    );
  }

  @override
  Future<CompanyInitializationState> finalizeInitialization() async {
    final companyId = _currentCompanyId;
    final state = await getState();
    final invConfig = await getInventoryConfig();
    final accConfig = await getAccountingConfig();
    final whConfig = await getWarehouseConfig();

    // Prepare candidate state with initializationCompleted = true for structural validation
    final candidateState = state.copyWith(
      companyId: companyId,
      initializationCompleted: true,
    );

    const validator = InitializationValidator();
    final result = validator.validate(
      state: candidateState,
      inventoryConfig: invConfig,
      accountingConfig: accConfig,
      warehouseConfig: whConfig,
    );

    if (!result.isReady) {
      throw StateError(
        'Cannot finalize initialization for company ($companyId) — Missing setup: ${result.missingRequirements.join(', ')}',
      );
    }

    await saveState(candidateState);
    return candidateState;
  }
}
