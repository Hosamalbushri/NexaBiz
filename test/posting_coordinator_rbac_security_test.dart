import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/inventory/stock_movements/presentation/providers/stock_movements_providers.dart';
import 'package:stock_count/core/utils/id_generator.dart';

class MockAccountingPoster implements InventoryAccountingPoster {
  @override
  Future<void> postAccountingEntry({
    required InventoryDocumentRef document,
    required double totalAmount,
    String? accountId,
    bool isPosted = true,
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
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late StockValidationServiceImpl validationService;
  late InventoryDependencyDetectorImpl dependencyDetector;
  late MockAccountingPoster mockAccountingPoster;
  const companyId = 'SECURITY_TEST_COMPANY';

  setUp(() async {
    db = InventoryDatabase.memory();
    mockAccountingPoster = MockAccountingPoster();
    costLayerService = CostLayerServiceImpl(
      db: db,
      readCompanyId: () => companyId,
    );
    postingEngine = PostingEngineImpl(
      db,
      costLayerService,
      null,
      () => companyId,
    );
    validationService = StockValidationServiceImpl(
      db,
      () => companyId,
    );
    dependencyDetector = InventoryDependencyDetectorImpl(
      db,
      () => companyId,
    );

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.into(db.products).insert(
          ProductsCompanion(
            id: const Value(1),
            uuid: const Value('00000000-0000-4000-8000-000000000001'),
            itemCode: const Value('SEC-ITEM-1'),
            name: const Value('Security Test Item'),
            packSize: const Value(1),
            price: const Value(100.0),
            onHandQty: const Value(0.0),
            unitCost: const Value(50.0),
            companyId: const Value(companyId),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  Future<InventoryDocumentRef> createDraftReceipt(String receiptUuid) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.into(db.stockReceipts).insert(
          StockReceiptsCompanion.insert(
            uuid: receiptUuid,
            receiptNumber: 'REC-SEC-001',
            receiptDate: DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
            createdAt: now,
            updatedAt: now,
            status: const Value('draft'),
            companyId: const Value(companyId),
          ),
        );

    await db.into(db.stockMovementLines).insert(
          StockMovementLinesCompanion.insert(
            uuid: generateUuidV4(),
            movementUuid: receiptUuid,
            movementType: 'receipt',
            itemCode: 'SEC-ITEM-1',
            itemName: 'Security Test Item',
            quantity: const Value(10.0),
            unitCost: const Value(50.0),
            totalCost: const Value(500.0),
          ),
        );

    return InventoryDocumentRef(
      documentId: receiptUuid,
      documentNumber: 'REC-SEC-001',
      documentType: InventoryDocumentType.stockReceipt,
      documentDate: DateTime.utc(2026, 1, 1),
    );
  }

  group('PostingCoordinator Security Hardening & Mandatory PermissionGuard Tests', () {
    test('1. Unauthorized post attempt throws PermissionDeniedException and logs audit event', () async {
      final denyingGuard = CallbackPermissionGuard((codes) => false);

      final coordinator = PostingCoordinatorImpl(
        db: db,
        stockValidationService: validationService,
        dependencyDetector: dependencyDetector,
        postingEngine: postingEngine,
        permissionGuard: denyingGuard,
        accountingPoster: mockAccountingPoster,
        readCompanyId: () => companyId,
      );

      final docRef = await createDraftReceipt(generateUuidV4());

      try {
        await coordinator.post(document: docRef, userId: 'unauthorized_user');
        fail('Should have thrown PermissionDeniedException');
      } catch (e) {
        expect(e, isA<PermissionDeniedException>());
      }

      final dbAuditRows = await db.select(db.inventoryAuditTrail).get();
      expect(dbAuditRows.length, 1);
      expect(dbAuditRows.first.eventType, 'unauthorized_attempt');
      expect(dbAuditRows.first.userId, 'unauthorized_user');
    });

    test('2. Unauthorized unpost attempt throws PermissionDeniedException and logs audit event', () async {
      final allowingGuard = CallbackPermissionGuard((codes) => true);

      final coordinator = PostingCoordinatorImpl(
        db: db,
        stockValidationService: validationService,
        dependencyDetector: dependencyDetector,
        postingEngine: postingEngine,
        permissionGuard: allowingGuard,
        accountingPoster: mockAccountingPoster,
        readCompanyId: () => companyId,
      );

      final docRef = await createDraftReceipt(generateUuidV4());
      final postRes = await coordinator.post(document: docRef, userId: 'authorized_user');
      expect(postRes, isA<PostSuccess>());

      final denyingCoordinator = PostingCoordinatorImpl(
        db: db,
        stockValidationService: validationService,
        dependencyDetector: dependencyDetector,
        postingEngine: postingEngine,
        permissionGuard: CallbackPermissionGuard((codes) => false),
        accountingPoster: mockAccountingPoster,
        readCompanyId: () => companyId,
      );

      try {
        await denyingCoordinator.unpost(document: docRef, requestedBy: 'unauthorized_user');
        fail('Should have thrown PermissionDeniedException');
      } catch (e) {
        expect(e, isA<PermissionDeniedException>());
      }

      final dbAuditRows = await db.select(db.inventoryAuditTrail).get();
      final unauthAttempt = dbAuditRows.firstWhere((e) => e.eventType == 'unauthorized_attempt');
      expect(unauthAttempt.userId, 'unauthorized_user');
    });

    test('3. Authorized user post & unpost operations succeed', () async {
      final allowingGuard = CallbackPermissionGuard((codes) => true);

      final coordinator = PostingCoordinatorImpl(
        db: db,
        stockValidationService: validationService,
        dependencyDetector: dependencyDetector,
        postingEngine: postingEngine,
        permissionGuard: allowingGuard,
        accountingPoster: mockAccountingPoster,
        readCompanyId: () => companyId,
      );

      final docRef = await createDraftReceipt(generateUuidV4());

      final postRes = await coordinator.post(document: docRef, userId: 'auth_user');
      expect(postRes, isA<PostSuccess>());

      final unpostRes = await coordinator.unpost(document: docRef, requestedBy: 'auth_user');
      expect(unpostRes, isA<UnpostSuccess>());
    });

    test('4. postingCoordinatorProvider wires permissionGuardProvider correctly in Riverpod', () {
      final container = ProviderContainer(
        overrides: [
          permissionGuardProvider.overrideWithValue(
            CallbackPermissionGuard((codes) => false),
          ),
        ],
      );

      final coordinator = container.read(postingCoordinatorProvider);
      expect(coordinator, isA<PostingCoordinatorImpl>());
      expect(coordinator, isNotNull);
    });
  });
}
