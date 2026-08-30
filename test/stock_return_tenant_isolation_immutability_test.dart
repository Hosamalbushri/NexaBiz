import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';

import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_returns_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_return.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';

import 'helpers/journal_posting_test_helper.dart';

void main() {
  late AccountingDatabase db;
  late AccountRepositoryImpl accountRepo;
  late JournalRepositoryImpl journalRepo;
  late JournalPostingService postingService;

  late InventoryDatabase invDb;
  late CostLayerServiceImpl costLayerService;
  late PostingEngineImpl postingEngine;
  late PostingCoordinatorImpl postingCoordinator;
  late StockReturnsRepositoryImpl stockReturnsRepo;

  late String companyA;
  late String companyB;
  late String activeCompanyId;

  setUp(() async {
    companyA = 'company_A';
    companyB = 'company_B';
    activeCompanyId = companyA;

    db = AccountingDatabase(executor: NativeDatabase.memory());
    accountRepo = AccountRepositoryImpl(
      db,
      readCompanyId: () => activeCompanyId,
    );
    journalRepo = JournalRepositoryImpl(
      db,
      accounts: accountRepo,
      periodValidator: legacyPeriodValidator(),
      readCompanyId: () => activeCompanyId,
    );
    postingService = JournalPostingService(
      journals: journalRepo,
      periodValidator: legacyPeriodValidator(),
    );

    invDb = InventoryDatabase(executor: NativeDatabase.memory());
    costLayerService = CostLayerServiceImpl(
      db: invDb,
      readCompanyId: () => activeCompanyId,
    );
    postingEngine = PostingEngineImpl(
      invDb,
      costLayerService,
      null,
      () => activeCompanyId,
    );
    stockReturnsRepo = StockReturnsRepositoryImpl(
      db: invDb,
      costLayerService: costLayerService,
      readCompanyId: () => activeCompanyId,
    );

    final validationService = StockValidationServiceImpl(
      invDb,
      () => activeCompanyId,
    );
    final dependencyDetector = InventoryDependencyDetectorImpl(
      invDb,
      () => activeCompanyId,
    );

    postingCoordinator = PostingCoordinatorImpl(
      db: invDb,
      stockValidationService: validationService,
      dependencyDetector: dependencyDetector,
      postingEngine: postingEngine,
      readCompanyId: () => activeCompanyId,
    );

    activeCompanyId = companyA;
  });

  tearDown(() async {
    await db.close();
    await invDb.close();
  });

  group('ROOT FIX 04 — Stock Return Tenant Isolation & Posted Immutability', () {
    test('1. Cross-Tenant Read Isolation: Company B cannot read Company A stock returns', () async {
      activeCompanyId = companyA;
      final returnAId = generateUuidV4();
      final returnA = StockReturn(
        id: returnAId,
        returnNumber: 'RET-COMP-A-01',
        returnType: StockReturnType.salesReturn,
        returnDate: DateTime.now(),
        companyId: companyA,
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: returnAId,
            movementType: 'sales_return',
            itemCode: 'ITEM-1',
            itemName: 'Item 1',
            quantity: 5,
            unitCost: 100,
            totalCost: 500,
          ),
        ],
      );

      await stockReturnsRepo.saveReturn(returnA);

      // Verify Company A can read it
      final readByA = await stockReturnsRepo.getReturnById(returnAId);
      expect(readByA, isNotNull);
      expect(readByA!.returnNumber, equals('RET-COMP-A-01'));

      final allA = await stockReturnsRepo.getAllReturns();
      expect(allA.length, equals(1));

      // Switch context to Company B
      activeCompanyId = companyB;

      // Verify Company B CANNOT read it
      final readByB = await stockReturnsRepo.getReturnById(returnAId);
      expect(readByB, isNull);

      final allB = await stockReturnsRepo.getAllReturns();
      expect(allB, isEmpty);
    });

    test('2. Cross-Tenant Update Rejection: Company B saving Company A stock return throws notFound', () async {
      activeCompanyId = companyA;
      final returnAId = generateUuidV4();
      final returnA = StockReturn(
        id: returnAId,
        returnNumber: 'RET-COMP-A-02',
        returnType: StockReturnType.salesReturn,
        returnDate: DateTime.now(),
        companyId: companyA,
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: returnAId,
            movementType: 'sales_return',
            itemCode: 'ITEM-1',
            itemName: 'Item 1',
            quantity: 10,
            unitCost: 50,
            totalCost: 500,
          ),
        ],
      );

      await stockReturnsRepo.saveReturn(returnA);

      // Switch context to Company B
      activeCompanyId = companyB;

      // Attempt to overwrite Company A's return from Company B context
      final tamperedReturn = returnA.copyWith(
        partyName: 'Tampered Party by Company B',
        companyId: companyB,
      );

      await expectLater(
        () async => stockReturnsRepo.saveReturn(tamperedReturn),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', JournalException.notFound)),
      );

      // Verify Company A data was NOT modified
      activeCompanyId = companyA;
      final originalCheck = await stockReturnsRepo.getReturnById(returnAId);
      expect(originalCheck!.partyName, isNot(equals('Tampered Party by Company B')));
    });

    test('3. Cross-Tenant Delete Rejection: Company B deleting Company A stock return throws notFound', () async {
      activeCompanyId = companyA;
      final returnAId = generateUuidV4();
      final returnA = StockReturn(
        id: returnAId,
        returnNumber: 'RET-COMP-A-03',
        returnType: StockReturnType.purchaseReturn,
        returnDate: DateTime.now(),
        companyId: companyA,
      );

      await stockReturnsRepo.saveReturn(returnA);

      // Switch context to Company B
      activeCompanyId = companyB;

      await expectLater(
        () async => stockReturnsRepo.deleteReturn(returnAId),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', JournalException.notFound)),
      );

      // Switch back to Company A and verify it is not deleted
      activeCompanyId = companyA;
      final checkA = await stockReturnsRepo.getReturnById(returnAId);
      expect(checkA, isNotNull);
      expect(checkA!.deletedAt, isNull);
    });

    test('4. Cross-Tenant Post Rejection: Company B posting Company A stock return is rejected', () async {
      activeCompanyId = companyA;
      final returnAId = generateUuidV4();
      final lineUuid = generateUuidV4();
      final now = DateTime.now();

      final returnA = StockReturn(
        id: returnAId,
        returnNumber: 'RET-COMP-A-04',
        returnType: StockReturnType.salesReturn,
        returnDate: now,
        companyId: companyA,
        lines: [
          StockMovementLine(
            id: lineUuid,
            movementUuid: returnAId,
            movementType: 'sales_return',
            itemCode: 'ITEM-X',
            itemName: 'Item X',
            quantity: 2,
            unitCost: 150,
            totalCost: 300,
          ),
        ],
      );

      await stockReturnsRepo.saveReturn(returnA);

      final docRef = InventoryDocumentRef(
        documentId: returnAId,
        documentNumber: 'RET-COMP-A-04',
        documentType: InventoryDocumentType.stockReturn,
        documentDate: now,
      );

      // Switch context to Company B
      activeCompanyId = companyB;

      final postResult = await postingCoordinator.post(document: docRef);
      expect(postResult, isA<PostInvalidStatus>());

      // Switch back to Company A and verify it remains draft
      activeCompanyId = companyA;
      final checkA = await stockReturnsRepo.getReturnById(returnAId);
      expect(checkA!.isPosted, isFalse);
    });

    test('5. Posted Return Save Immutability: Attempting saveReturn on posted return throws postedImmutable', () async {
      activeCompanyId = companyA;
      final returnId = generateUuidV4();
      final postedReturn = StockReturn(
        id: returnId,
        returnNumber: 'RET-POSTED-05',
        returnType: StockReturnType.salesReturn,
        returnDate: DateTime.now(),
        status: InventoryDocumentStatus.posted,
        postedAt: DateTime.now(),
        companyId: companyA,
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: returnId,
            movementType: 'sales_return',
            itemCode: 'ITEM-5',
            itemName: 'Item 5',
            quantity: 3,
            unitCost: 200,
            totalCost: 600,
          ),
        ],
      );

      await stockReturnsRepo.saveReturn(postedReturn);

      final checkPosted = await stockReturnsRepo.getReturnById(returnId);
      expect(checkPosted!.isPosted, isTrue);

      // Attempt to modify posted return
      final editedReturn = checkPosted.copyWith(notes: 'Trying to modify posted return');

      await expectLater(
        () async => stockReturnsRepo.saveReturn(editedReturn),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', JournalException.postedImmutable)),
      );
    });

    test('6. Posted Return Delete Immutability: Attempting deleteReturn on posted return throws postedImmutable', () async {
      activeCompanyId = companyA;
      final returnId = generateUuidV4();
      final postedReturn = StockReturn(
        id: returnId,
        returnNumber: 'RET-POSTED-06',
        returnType: StockReturnType.purchaseReturn,
        returnDate: DateTime.now(),
        status: InventoryDocumentStatus.posted,
        postedAt: DateTime.now(),
        companyId: companyA,
      );

      await stockReturnsRepo.saveReturn(postedReturn);

      await expectLater(
        () async => stockReturnsRepo.deleteReturn(returnId),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', JournalException.postedImmutable)),
      );

      final checkIntact = await stockReturnsRepo.getReturnById(returnId);
      expect(checkIntact, isNotNull);
      expect(checkIntact!.deletedAt, isNull);
    });

    test('7. Duplicate Return Posting Protection: Re-posting posted return is idempotent without duplicating layers', () async {
      activeCompanyId = companyA;
      final returnId = generateUuidV4();
      final lineUuid = generateUuidV4();
      final now = DateTime.now();

      final salesReturnDoc = StockReturn(
        id: returnId,
        returnNumber: 'RET-IDEM-07',
        returnType: StockReturnType.salesReturn,
        returnDate: now,
        companyId: companyA,
        lines: [
          StockMovementLine(
            id: lineUuid,
            movementUuid: returnId,
            movementType: 'sales_return',
            itemCode: 'ITEM-IDEM',
            itemName: 'Idempotent Item',
            quantity: 5,
            unitCost: 80,
            totalCost: 400,
          ),
        ],
      );

      await stockReturnsRepo.saveReturn(salesReturnDoc);

      final docRef = InventoryDocumentRef(
        documentId: returnId,
        documentNumber: 'RET-IDEM-07',
        documentType: InventoryDocumentType.stockReturn,
        documentDate: now,
      );

      // First post
      final result1 = await postingCoordinator.post(document: docRef);
      expect(result1, isA<PostSuccess>());

      final layers1 = await costLayerService.getOpenLayers('ITEM-IDEM');
      expect(layers1.length, equals(1));
      expect(layers1.single.receivedQty, equals(5));

      // Duplicate second post
      final result2 = await postingCoordinator.post(document: docRef);
      expect(result2, isA<PostSuccess>());

      // Verify NO duplicate cost layers were created
      final layers2 = await costLayerService.getOpenLayers('ITEM-IDEM');
      expect(layers2.length, equals(1));
      expect(layers2.single.receivedQty, equals(5));
    });

    test('8. Inventory & Accounting Consistency: Sales Return post creates cost layer, reversal restores balance', () async {
      activeCompanyId = companyA;
      final returnId = generateUuidV4();
      final lineUuid = generateUuidV4();
      final now = DateTime.now();

      final salesReturnDoc = StockReturn(
        id: returnId,
        returnNumber: 'RET-CONS-08',
        returnType: StockReturnType.salesReturn,
        returnDate: now,
        companyId: companyA,
        lines: [
          StockMovementLine(
            id: lineUuid,
            movementUuid: returnId,
            movementType: 'sales_return',
            itemCode: 'ITEM-CONS',
            itemName: 'Consistent Item',
            quantity: 10,
            unitCost: 25,
            totalCost: 250,
          ),
        ],
      );

      await stockReturnsRepo.saveReturn(salesReturnDoc);

      final docRef = InventoryDocumentRef(
        documentId: returnId,
        documentNumber: 'RET-CONS-08',
        documentType: InventoryDocumentType.stockReturn,
        documentDate: now,
      );

      // Post Sales Return -> increases inventory cost layer by 10 units
      await postingCoordinator.post(document: docRef);

      var layers = await costLayerService.getOpenLayers('ITEM-CONS');
      expect(layers.single.remainingQty, equals(10));

      // Reverse Sales Return posting via PostingEngine
      await postingEngine.reversePosting(document: docRef);

      // Cost layer should be reversed/closed
      layers = await costLayerService.getOpenLayers('ITEM-CONS');
      expect(layers, isEmpty);
    });
  });
}
