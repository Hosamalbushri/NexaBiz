import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/warehouse_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/warehouse.dart';

class MockAccountingPoster implements InventoryAccountingPoster {
  @override
  Future<void> postAccountingEntry({
    required InventoryDocumentRef document,
    required double totalAmount,
    double? valuationAmount,
    String? accountId,
    bool isPosted = true,
    bool useBaseCurrencyForPosting = false,
  }) async {}

  @override
  Future<void> setAccountingEntryPostingStatus({
    required InventoryDocumentRef document,
    required bool isPosted,
  }) async {}

  @override
  Future<void> reverseAccountingEntry({
    required InventoryDocumentRef document,
  }) async {}
}

void main() {
  late InventoryDatabase db;
  late String currentCompanyId;

  setUp(() async {
    db = InventoryDatabase(executor: NativeDatabase.memory());
    currentCompanyId = 'comp_in03_test';
  });

  tearDown(() async {
    await db.close();
  });

  group('IN-03 — Default Warehouse Removal & Initialization Tests', () {
    test('1. Company initializes successfully with 0 warehouses', () async {
      final repo = WarehouseRepositoryImpl(db, null, () => currentCompanyId);

      final warehouses = await repo.getAllWarehouses();
      expect(warehouses.isEmpty, isTrue);

      final defaultWh = await repo.getDefaultWarehouse();
      expect(defaultWh, isNull);

      final ensured = await repo.ensureDefaultWarehouse();
      expect(ensured, isNull);
    });

    test(
      '2. Company with 1 warehouse creates entity explicitly without global auto-defaulting',
      () async {
        final repo = WarehouseRepositoryImpl(db, null, () => currentCompanyId);

        final wh1 = Warehouse(
          id: generateUuidV4(),
          code: 'WH-01',
          name: 'Warehouse North',
          companyId: currentCompanyId,
          isActive: true,
        );
        await repo.saveWarehouse(wh1);

        final list = await repo.getAllWarehouses();
        expect(list.length, equals(1));
        expect(list.first.code, equals('WH-01'));

        final defaultWh = await repo.getDefaultWarehouse();
        expect(defaultWh, isNull);
      },
    );

    test(
      '3. Company with 2 warehouses manages independent warehouse balances',
      () async {
        final repo = WarehouseRepositoryImpl(db, null, () => currentCompanyId);

        final wh1 = Warehouse(
          id: generateUuidV4(),
          code: 'WH-ALPHA',
          name: 'Alpha Warehouse',
          companyId: currentCompanyId,
        );
        final wh2 = Warehouse(
          id: generateUuidV4(),
          code: 'WH-BETA',
          name: 'Beta Warehouse',
          companyId: currentCompanyId,
        );

        await repo.saveWarehouse(wh1);
        await repo.saveWarehouse(wh2);

        final list = await repo.getAllWarehouses();
        expect(list.length, equals(2));
        expect(list.map((w) => w.code), containsAll(['WH-ALPHA', 'WH-BETA']));
      },
    );

    test(
      '4. Posting with NO warehouse specified is BLOCKED at domain layer',
      () async {
        final costLayerService = CostLayerServiceImpl(
          db: db,
          readCompanyId: () => currentCompanyId,
        );
        final validationService = StockValidationServiceImpl(
          db,
          () => currentCompanyId,
        );
        final dependencyDetector = InventoryDependencyDetectorImpl(
          db,
          () => currentCompanyId,
        );
        final postingEngine = PostingEngineImpl(
          db,
          costLayerService,
          null,
          () => currentCompanyId,
        );
        final coordinator = PostingCoordinatorImpl(
          db: db,
          stockValidationService: validationService,
          dependencyDetector: dependencyDetector,
          postingEngine: postingEngine,
          permissionGuard: CallbackPermissionGuard((codes) => true),
          accountingPoster: MockAccountingPoster(),
          readCompanyId: () => currentCompanyId,
        );

        final docWithoutWh = InventoryDocumentRef(
          documentId: generateUuidV4(),
          documentNumber: 'REC-NO-WH',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now().toUtc(),
          status: InventoryDocumentStatus.draft,
          warehouseId: null,
        );

        final result = await coordinator.post(document: docWithoutWh);

        expect(result, isA<PostInvalidStatus>());
        final invalid = result as PostInvalidStatus;
        expect(invalid.reason, contains('تحديد المستودع الخاص بالمستند أولاً'));
      },
    );

    test(
      '5. Posting with EXPLICIT warehouse specified proceeds to line verification',
      () async {
        final repo = WarehouseRepositoryImpl(db, null, () => currentCompanyId);

        final whId = generateUuidV4();
        final wh = Warehouse(
          id: whId,
          code: 'WH-EXP',
          name: 'Explicit Warehouse',
          companyId: currentCompanyId,
        );
        await repo.saveWarehouse(wh);

        final costLayerService = CostLayerServiceImpl(
          db: db,
          readCompanyId: () => currentCompanyId,
        );
        final validationService = StockValidationServiceImpl(
          db,
          () => currentCompanyId,
        );
        final dependencyDetector = InventoryDependencyDetectorImpl(
          db,
          () => currentCompanyId,
        );
        final postingEngine = PostingEngineImpl(
          db,
          costLayerService,
          null,
          () => currentCompanyId,
        );
        final coordinator = PostingCoordinatorImpl(
          db: db,
          stockValidationService: validationService,
          dependencyDetector: dependencyDetector,
          postingEngine: postingEngine,
          permissionGuard: CallbackPermissionGuard((codes) => true),
          accountingPoster: MockAccountingPoster(),
          readCompanyId: () => currentCompanyId,
        );

        final docWithWh = InventoryDocumentRef(
          documentId: generateUuidV4(),
          documentNumber: 'REC-WITH-WH',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now().toUtc(),
          status: InventoryDocumentStatus.draft,
          warehouseId: whId,
        );

        final result = await coordinator.post(document: docWithWh);

        expect(result, isA<PostInvalidStatus>());
        final invalid = result as PostInvalidStatus;
        expect(invalid.reason, contains('لا يحتوي على أصناف للترحيل'));
      },
    );
  });
}
