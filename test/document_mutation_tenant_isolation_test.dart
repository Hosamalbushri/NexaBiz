import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';

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
  }) async {
    if (isPosted == false) {
      throw Exception('Mock block unpost');
    }
  }

  @override
  Future<void> reverseAccountingEntry({
    required InventoryDocumentRef document,
  }) async {}
}

void main() {
  late InventoryDatabase db;
  late AccountingDatabase accountingDb;
  late String activeCompanyId;
  late MockAccountingPoster mockAccountingPoster;

  setUp(() async {
    db = InventoryDatabase.memory();
    accountingDb = AccountingDatabase.memory();
    activeCompanyId = 'COMPANY_A';
    mockAccountingPoster = MockAccountingPoster();
  });

  tearDown(() async {
    await db.close();
    await accountingDb.close();
  });

  PostingCoordinator createCoordinator(String Function() getCompanyId) {
    final costLayerService = CostLayerServiceImpl(
      db: db,
      readCompanyId: getCompanyId,
    );
    final postingEngine = PostingEngineImpl(
      db,
      costLayerService,
      null,
      getCompanyId,
    );
    final validationService = StockValidationServiceImpl(
      db,
      getCompanyId,
    );
    final dependencyDetector = InventoryDependencyDetectorImpl(
      db,
      getCompanyId,
    );

    return PostingCoordinatorImpl(
      db: db,
      stockValidationService: validationService,
      dependencyDetector: dependencyDetector,
      postingEngine: postingEngine,
      permissionGuard: CallbackPermissionGuard((codes) => true),
      accountingPoster: mockAccountingPoster,
      readCompanyId: getCompanyId,
    );
  }

  Future<void> seedProduct(String itemCode, String compId, double initialQty) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final prodUuid = compId == 'COMPANY_A'
        ? '10000000-0000-4000-8000-000000000001'
        : '20000000-0000-4000-8000-000000000002';
    await db.into(db.products).insertOnConflictUpdate(
          ProductsCompanion(
            id: Value(compId == 'COMPANY_A' ? 1 : 2),
            uuid: Value(prodUuid),
            itemCode: Value(itemCode),
            name: Value('Test Item $itemCode'),
            packSize: const Value(1),
            price: const Value(100.0),
            onHandQty: Value(initialQty),
            unitCost: const Value(50.0),
            companyId: Value(compId),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<InventoryDocumentRef> createDraftReceiptWithUuid(String documentUuid, String compId, String recNo) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final itemCode = 'ITEM-$compId-100';
    await seedProduct(itemCode, compId, 0.0);

    final lineUuid = compId == 'COMPANY_A'
        ? '11111111-1111-4111-8111-000000000001'
        : '22222222-2222-4222-8222-000000000002';

    await db.into(db.stockReceipts).insert(
          StockReceiptsCompanion.insert(
            uuid: documentUuid,
            receiptNumber: recNo,
            receiptDate: DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
            createdAt: now,
            updatedAt: now,
            status: const Value('draft'),
            companyId: Value(compId),
          ),
        );

    await db.into(db.stockMovementLines).insert(
          StockMovementLinesCompanion.insert(
            uuid: lineUuid,
            movementUuid: documentUuid,
            movementType: 'receipt',
            itemCode: itemCode,
            itemName: 'Test Item $itemCode',
            quantity: const Value(10.0),
            unitCost: const Value(50.0),
            totalCost: const Value(500.0),
          ),
        );

    return InventoryDocumentRef(
      documentId: documentUuid,
      documentNumber: recNo,
      documentType: InventoryDocumentType.stockReceipt,
      documentDate: DateTime.utc(2026, 1, 1),
    );
  }

  group('Document Mutation Tenant Isolation Tests', () {
    test('1. Legitimate same-tenant update continues working seamlessly', () async {
      activeCompanyId = 'COMPANY_A';
      final coordinator = createCoordinator(() => activeCompanyId);
      final docRef = await createDraftReceiptWithUuid('11111111-1111-4111-8111-111111111111', 'COMPANY_A', 'REC-A-111');

      final result = await coordinator.post(document: docRef, userId: 'user_a');
      expect(result, isA<PostSuccess>());

      final recInDb = await (db.select(db.stockReceipts)..where((tbl) => tbl.uuid.equals('11111111-1111-4111-8111-111111111111'))).getSingle();
      expect(recInDb.status, 'posted');
      expect(recInDb.companyId, 'COMPANY_A');
    });

    test('2. Company A cannot update Company B document status', () async {
      // Create Document for Company B
      await createDraftReceiptWithUuid('22222222-2222-4222-8222-222222222222', 'COMPANY_B', 'REC-B-222');

      // Attempt to post/update Company B document while active session is Company A
      activeCompanyId = 'COMPANY_A';
      final coordinatorA = createCoordinator(() => activeCompanyId);

      final docRefCompB = InventoryDocumentRef(
        documentId: '22222222-2222-4222-8222-222222222222',
        documentNumber: 'REC-B-222',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.utc(2026, 1, 1),
      );

      final result = await coordinatorA.post(document: docRefCompB, userId: 'user_a');
      expect(result, isA<PostInvalidStatus>());
      expect((result as PostInvalidStatus).reason, contains('مستند تابع لشركة أخرى'));

      // Verify Company B document remains unchanged in draft state
      final recB = await (db.select(db.stockReceipts)..where((tbl) => tbl.uuid.equals('22222222-2222-4222-8222-222222222222'))).getSingle();
      expect(recB.status, 'draft');
      expect(recB.companyId, 'COMPANY_B');
    });

    test('3. Cross-tenant mutation with Company B UUID returns 0 affected rows and does NOT mutate Company B', () async {
      const docUuidB = '33333333-3333-4333-8333-333333333333';
      const docUuidA = '33333333-3333-4333-8333-111111111111';

      // 1. Create document for Company B
      await createDraftReceiptWithUuid(docUuidB, 'COMPANY_B', 'REC-B-333');

      // 2. Create document for Company A
      await createDraftReceiptWithUuid(docUuidA, 'COMPANY_A', 'REC-A-333');

      // 3. Post Document for Company A while active session is Company A
      activeCompanyId = 'COMPANY_A';
      final coordinatorA = createCoordinator(() => activeCompanyId);

      final docRefA = InventoryDocumentRef(
        documentId: docUuidA,
        documentNumber: 'REC-A-333',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.utc(2026, 1, 1),
      );

      final resultA = await coordinatorA.post(document: docRefA, userId: 'user_a');
      expect(resultA, isA<PostSuccess>());

      // 4. Verify Company A's document was updated to posted
      final recA = await (db.select(db.stockReceipts)
            ..where((tbl) => tbl.uuid.equals(docUuidA) & tbl.companyId.equals('COMPANY_A')))
          .getSingle();
      expect(recA.status, 'posted');

      // 5. CRITICAL INVARIANT: Verify Company B's document remained untouched in 'draft'
      final recB = await (db.select(db.stockReceipts)
            ..where((tbl) => tbl.uuid.equals(docUuidB) & tbl.companyId.equals('COMPANY_B')))
          .getSingle();
      expect(recB.status, 'draft');
    });

    test('4. Company A cannot unpost/delete Company B document', () async {
      // 1. Post document in Company B session
      activeCompanyId = 'COMPANY_B';
      final coordinatorB = createCoordinator(() => activeCompanyId);
      final docRefB = await createDraftReceiptWithUuid('44444444-4444-4444-8444-444444444444', 'COMPANY_B', 'REC-B-POSTED');
      await coordinatorB.post(document: docRefB, userId: 'user_b');

      // 2. Switch session to Company A and try to unpost Company B's document
      activeCompanyId = 'COMPANY_A';
      final coordinatorA = createCoordinator(() => activeCompanyId);

      final unpostRes = await coordinatorA.unpost(document: docRefB, requestedBy: 'user_a');
      expect(unpostRes, isA<UnpostBlockedByDependencies>());
      expect((unpostRes as UnpostBlockedByDependencies).message, contains('مستند تابع لشركة أخرى'));

      // 3. Verify Company B's document remains posted
      final recB = await (db.select(db.stockReceipts)..where((tbl) => tbl.uuid.equals('44444444-4444-4444-8444-444444444444'))).getSingle();
      expect(recB.status, 'posted');
    });

    test('5. Posted documents remain immutable under cross-tenant mutation attempts', () async {
      // 1. Post Document A in Company A session
      activeCompanyId = 'COMPANY_A';
      final coordinatorA = createCoordinator(() => activeCompanyId);
      final docRefA = await createDraftReceiptWithUuid('55555555-5555-4555-8555-555555555555', 'COMPANY_A', 'REC-A-IMMUTABLE');
      await coordinatorA.post(document: docRefA, userId: 'user_a');

      // 2. Attempt to unpost/modify Document A from Company B session
      activeCompanyId = 'COMPANY_B';
      final coordinatorB = createCoordinator(() => activeCompanyId);
      final attemptResult = await coordinatorB.unpost(document: docRefA, requestedBy: 'user_b');

      expect(attemptResult, isA<UnpostBlockedByDependencies>());
      expect((attemptResult as UnpostBlockedByDependencies).message, contains('مستند تابع لشركة أخرى'));

      // 3. Verify document A remains posted in Company A
      final recA = await (db.select(db.stockReceipts)..where((tbl) => tbl.uuid.equals('55555555-5555-4555-8555-555555555555'))).getSingle();
      expect(recA.status, 'posted');
      expect(recA.companyId, 'COMPANY_A');
    });
  });
}
