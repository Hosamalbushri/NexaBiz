import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/product_warehouse_stock.dart';

import 'package:stock_count/modules/inventory/warehouses/domain/entities/warehouse.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/repositories/warehouse_repository.dart';
import 'package:stock_count/modules/system_setup/data/repositories/company_initialization_repository_impl.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_warehouse_config_service.dart';

class FakeWarehouseRepository implements WarehouseRepository {
  FakeWarehouseRepository(this.warehouses);

  final List<Warehouse> warehouses;

  @override
  Future<List<Warehouse>> getAllWarehouses() async => warehouses;

  @override
  Stream<List<Warehouse>> watchAllWarehouses() => Stream.value(warehouses);

  @override
  Future<Warehouse?> getWarehouseById(String id) async {
    for (final w in warehouses) {
      if (w.id == id) return w;
    }
    return null;
  }

  @override
  Future<Warehouse?> getDefaultWarehouse() async =>
      warehouses.firstWhere((w) => w.isDefault, orElse: () => warehouses.first);

  @override
  Future<Warehouse> ensureDefaultWarehouse() async =>
      (await getDefaultWarehouse())!;

  @override
  Future<void> saveWarehouse(Warehouse warehouse) async {
    final index = warehouses.indexWhere((w) => w.id == warehouse.id);
    if (index >= 0) {
      warehouses[index] = warehouse;
    } else {
      warehouses.add(warehouse);
    }
  }

  @override
  Future<void> deleteWarehouse(String id) async {
    warehouses.removeWhere((w) => w.id == id);
  }

  @override
  Future<List<ProductWarehouseStock>> getStocksForWarehouse(String warehouseId) async => [];

  @override
  Future<ProductWarehouseStock?> getStock(String itemCode, String warehouseId) async => null;

  @override
  Future<void> updateWarehouseStock(String itemCode, String warehouseId, double deltaQty) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> settingsBox;
  late CompanyInitializationRepositoryImpl initRepository;
  late FakeWarehouseRepository fakeWarehouseRepo;
  late CompanyWarehouseConfigService warehouseConfigService;

  const currentCompanyId = 'company-tenant-alpha';
  final now = DateTime.utc(2026, 8, 31);

  setUp(() async {
    Hive.init('./test_hive_temp_p4');
    if (!Hive.isBoxOpen(HiveBoxes.settings)) {
      settingsBox = await Hive.openBox<dynamic>(HiveBoxes.settings);
    } else {
      settingsBox = Hive.box<dynamic>(HiveBoxes.settings);
    }
    await settingsBox.clear();

    initRepository = CompanyInitializationRepositoryImpl(
      box: settingsBox,
      readCompanyId: () => currentCompanyId,
    );

    // Initialize state for current company
    await initRepository.saveState(
      (await initRepository.getState()).copyWith(companyId: currentCompanyId),
    );
  });

  tearDown(() async {
    await settingsBox.clear();
  });

  group('Phase 4 — Warehouse & Inventory Operational Configuration Tests', () {
    test('1. Valid Default Warehouse Assignment', () async {
      final validWarehouse = Warehouse(
        id: 'wh-main-001',
        code: 'WH01',
        name: 'Main Central Warehouse',
        companyId: currentCompanyId,
        isActive: true,
        isDefault: true,
      );

      fakeWarehouseRepo = FakeWarehouseRepository([validWarehouse]);
      warehouseConfigService = CompanyWarehouseConfigService(
        warehouseRepository: fakeWarehouseRepo,
        initRepository: initRepository,
      );

      final config = await warehouseConfigService.configureDefaultWarehouse(
        warehouseId: 'wh-main-001',
      );

      expect(config.defaultWarehouseId, equals('wh-main-001'));
      expect(config.companyId, equals(currentCompanyId));

      final state = await initRepository.getState();
      expect(state.warehouseConfigured, isTrue);
    });

    test('2. Cross-Company Warehouse Selection Rejection', () async {
      final foreignWarehouse = Warehouse(
        id: 'wh-foreign-002',
        code: 'WH02',
        name: 'Foreign Company Warehouse',
        companyId: 'company-tenant-beta', // Different tenant!
        isActive: true,
      );

      fakeWarehouseRepo = FakeWarehouseRepository([foreignWarehouse]);
      warehouseConfigService = CompanyWarehouseConfigService(
        warehouseRepository: fakeWarehouseRepo,
        initRepository: initRepository,
      );

      expect(
        () async => await warehouseConfigService.configureDefaultWarehouse(
          warehouseId: 'wh-foreign-002',
        ),
        throwsA(isA<InvalidWarehouseException>().having(
          (e) => e.reason,
          'reason',
          contains('Cross-company violation'),
        )),
      );
    });

    test('3. Inactive Warehouse Selection Rejection', () async {
      final inactiveWarehouse = Warehouse(
        id: 'wh-inactive-003',
        code: 'WH03',
        name: 'Inactive Warehouse',
        companyId: currentCompanyId,
        isActive: false, // Inactive!
      );

      fakeWarehouseRepo = FakeWarehouseRepository([inactiveWarehouse]);
      warehouseConfigService = CompanyWarehouseConfigService(
        warehouseRepository: fakeWarehouseRepo,
        initRepository: initRepository,
      );

      expect(
        () async => await warehouseConfigService.configureDefaultWarehouse(
          warehouseId: 'wh-inactive-003',
        ),
        throwsA(isA<InvalidWarehouseException>().having(
          (e) => e.reason,
          'reason',
          contains('inactive'),
        )),
      );
    });

    test('4. Non-Existent Warehouse Selection Rejection', () async {
      fakeWarehouseRepo = FakeWarehouseRepository([]);
      warehouseConfigService = CompanyWarehouseConfigService(
        warehouseRepository: fakeWarehouseRepo,
        initRepository: initRepository,
      );

      expect(
        () async => await warehouseConfigService.configureDefaultWarehouse(
          warehouseId: 'wh-missing-999',
        ),
        throwsA(isA<InvalidWarehouseException>().having(
          (e) => e.reason,
          'reason',
          contains('does not exist'),
        )),
      );
    });

    test('5. Soft-Deleted Warehouse Selection Rejection', () async {
      final deletedWarehouse = Warehouse(
        id: 'wh-deleted-004',
        code: 'WH04',
        name: 'Deleted Warehouse',
        companyId: currentCompanyId,
        isActive: true,
        deletedAt: now, // Deleted!
      );

      fakeWarehouseRepo = FakeWarehouseRepository([deletedWarehouse]);
      warehouseConfigService = CompanyWarehouseConfigService(
        warehouseRepository: fakeWarehouseRepo,
        initRepository: initRepository,
      );

      expect(
        () async => await warehouseConfigService.configureDefaultWarehouse(
          warehouseId: 'wh-deleted-004',
        ),
        throwsA(isA<InvalidWarehouseException>().having(
          (e) => e.reason,
          'reason',
          contains('soft-deleted'),
        )),
      );
    });

    test('6. Inventory Operational Settings Persistence', () async {
      fakeWarehouseRepo = FakeWarehouseRepository([]);
      warehouseConfigService = CompanyWarehouseConfigService(
        warehouseRepository: fakeWarehouseRepo,
        initRepository: initRepository,
      );

      final invConfig = await warehouseConfigService.configureInventoryOperationalSettings(
        allowNegativeStock: true,
        defaultCostingMethod: 'AVCO',
      );

      expect(invConfig.allowNegativeStock, isTrue);
      expect(invConfig.defaultCostingMethod, equals('AVCO'));

      final state = await initRepository.getState();
      expect(state.inventorySettingsConfigured, isTrue);
    });

    test('7. Multi-Tenant Isolation for Warehouse Configurations', () async {
      fakeWarehouseRepo = FakeWarehouseRepository([]);

      // Company Alpha repo
      final repoAlpha = CompanyInitializationRepositoryImpl(
        box: settingsBox,
        readCompanyId: () => 'company-alpha',
      );
      final serviceAlpha = CompanyWarehouseConfigService(
        warehouseRepository: fakeWarehouseRepo,
        initRepository: repoAlpha,
      );

      // Company Beta repo
      final repoBeta = CompanyInitializationRepositoryImpl(
        box: settingsBox,
        readCompanyId: () => 'company-beta',
      );

      // Initialize company states
      await repoAlpha.saveState(
        (await repoAlpha.getState()).copyWith(companyId: 'company-alpha'),
      );
      await repoBeta.saveState(
        (await repoBeta.getState()).copyWith(companyId: 'company-beta'),
      );

      await serviceAlpha.configureInventoryOperationalSettings(
        allowNegativeStock: true,
        defaultCostingMethod: 'FIFO',
      );

      final configBeta = await repoBeta.getInventoryConfig();
      expect(configBeta, isNull);
    });
  });
}
