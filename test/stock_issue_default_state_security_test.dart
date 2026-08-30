import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/inventory/products/data/repositories/product_repository_impl.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';

void main() {
  late InventoryDatabase db;
  late StockMovementsRepositoryImpl stockRepo;
  late ProductRepositoryImpl productRepo;
  late CostLayerServiceImpl costLayerService;
  late StockValidationServiceImpl validationService;
  late PostingEngineImpl postingEngine;
  late InventoryDependencyDetectorImpl dependencyDetector;
  late PostingCoordinatorImpl postingCoordinator;

  const testCompanyId = LocalAuthDefaults.companyId;

  setUp(() async {
    db = InventoryDatabase.memory();

    stockRepo = StockMovementsRepositoryImpl(
      db: db,
      readCompanyId: () => testCompanyId,
    );

    productRepo = ProductRepositoryImpl(
      db,
      readCompanyId: () => testCompanyId,
    );

    costLayerService = CostLayerServiceImpl(
      db: db,
      readCompanyId: () => testCompanyId,
    );

    validationService = StockValidationServiceImpl(
      db,
      () => testCompanyId,
    );

    postingEngine = PostingEngineImpl(
      db,
      costLayerService,
      null,
      () => testCompanyId,
    );

    dependencyDetector = InventoryDependencyDetectorImpl(
      db,
      () => testCompanyId,
    );

    postingCoordinator = PostingCoordinatorImpl(
      db: db,
      stockValidationService: validationService,
      dependencyDetector: dependencyDetector,
      postingEngine: postingEngine,
      readCompanyId: () => testCompanyId,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('ROOT FIX 12: Newly created Stock Issue defaults to DRAFT status in DB and domain model', () async {
    final issueUuid = generateUuidV4();
    final issue = StockIssue(
      id: issueUuid,
      issueNumber: 'ISS-TEST-001',
      issueDate: DateTime.now().toUtc(),
      warehouse: 'WH-MAIN',
      lines: [
        StockMovementLine(
          movementUuid: issueUuid,
          movementType: 'issue',
          itemCode: 'ITEM-001',
          itemName: 'Item 001',
          quantity: 5,
          unitCost: 10,
          totalCost: 50,
        ),
      ],
      companyId: testCompanyId,
    );

    // Initial domain entity status must be draft
    expect(issue.status, equals(InventoryDocumentStatus.draft));
    expect(issue.isDraft, isTrue);
    expect(issue.isPosted, isFalse);

    await stockRepo.saveIssue(issue);

    // Retrieve from repository
    final savedIssue = await stockRepo.getIssueById(issueUuid);
    expect(savedIssue, isNotNull);
    expect(savedIssue!.status, equals(InventoryDocumentStatus.draft));
    expect(savedIssue.isDraft, isTrue);
    expect(savedIssue.isPosted, isFalse);
    expect(savedIssue.postedAt, isNull);

    // Query raw DB row to confirm default constraint
    final rawRow = await (db.select(db.stockIssues)..where((t) => t.uuid.equals(issueUuid))).getSingle();
    expect(rawRow.status, equals('draft'));
    expect(rawRow.postedAt, isNull);
  });

  test('ROOT FIX 12: Draft Stock Issue does NOT perform cost layer consumption or stock deduction', () async {
    final receiptUuid = generateUuidV4();

    // 1. Create Inbound Stock Receipt and Post it to create cost layer
    final receipt = StockReceipt(
      id: receiptUuid,
      receiptNumber: 'REC-001',
      receiptDate: DateTime.now().toUtc(),
      lines: [
        StockMovementLine(
          movementUuid: receiptUuid,
          movementType: 'receipt',
          itemCode: 'ITEM-VAL-001',
          itemName: 'Valuation Item',
          quantity: 20,
          unitCost: 15.0,
          totalCost: 300.0,
        ),
      ],
      companyId: testCompanyId,
    );
    await stockRepo.saveReceipt(receipt);

    final receiptDocRef = InventoryDocumentRef(
      documentId: receiptUuid,
      documentNumber: 'REC-001',
      documentType: InventoryDocumentType.stockReceipt,
      documentDate: receipt.receiptDate,
      status: InventoryDocumentStatus.draft,
    );
    await postingCoordinator.post(document: receiptDocRef);

    // Verify Cost Layer exists with 20 remaining
    final layersBefore = await (db.select(db.inventoryCostLayers)..where((t) => t.itemCode.equals('ITEM-VAL-001'))).get();
    expect(layersBefore.length, equals(1));
    expect(layersBefore.first.remainingQty, equals(20.0));

    // 2. Create Draft Stock Issue
    final issueUuid = generateUuidV4();
    final issue = StockIssue(
      id: issueUuid,
      issueNumber: 'ISS-VAL-001',
      issueDate: DateTime.now().toUtc(),
      lines: [
        StockMovementLine(
          movementUuid: issueUuid,
          movementType: 'issue',
          itemCode: 'ITEM-VAL-001',
          itemName: 'Valuation Item',
          quantity: 5,
          unitCost: 15.0,
          totalCost: 75.0,
        ),
      ],
      companyId: testCompanyId,
    );
    await stockRepo.saveIssue(issue);

    // 3. Confirm NO cost layer consumption occurred for DRAFT issue
    final consumptions = await db.select(db.inventoryCostConsumptions).get();
    expect(consumptions, isEmpty);

    final layersAfter = await (db.select(db.inventoryCostLayers)..where((t) => t.itemCode.equals('ITEM-VAL-001'))).get();
    expect(layersAfter.first.remainingQty, equals(20.0));
  });

  test('ROOT FIX 12: Posting transitions status DRAFT -> POSTED and executes cost layer consumption', () async {
    final receiptUuid = generateUuidV4();

    // 1. Create and post Receipt
    final receipt = StockReceipt(
      id: receiptUuid,
      receiptNumber: 'REC-POST-001',
      receiptDate: DateTime.now().toUtc(),
      lines: [
        StockMovementLine(
          movementUuid: receiptUuid,
          movementType: 'receipt',
          itemCode: 'ITEM-POST-001',
          itemName: 'Post Test Item',
          quantity: 10,
          unitCost: 20.0,
          totalCost: 200.0,
        ),
      ],
      companyId: testCompanyId,
    );
    await stockRepo.saveReceipt(receipt);
    await postingCoordinator.post(
      document: InventoryDocumentRef(
        documentId: receiptUuid,
        documentNumber: 'REC-POST-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: receipt.receiptDate,
        status: InventoryDocumentStatus.draft,
      ),
    );

    // 2. Save Draft Stock Issue
    final issueUuid = generateUuidV4();
    final issue = StockIssue(
      id: issueUuid,
      issueNumber: 'ISS-POST-001',
      issueDate: DateTime.now().toUtc(),
      lines: [
        StockMovementLine(
          movementUuid: issueUuid,
          movementType: 'issue',
          itemCode: 'ITEM-POST-001',
          itemName: 'Post Test Item',
          quantity: 4,
          unitCost: 20.0,
          totalCost: 80.0,
        ),
      ],
      companyId: testCompanyId,
    );
    await stockRepo.saveIssue(issue);

    // 3. Post Stock Issue via PostingCoordinator
    final postResult = await postingCoordinator.post(
      document: InventoryDocumentRef(
        documentId: issueUuid,
        documentNumber: 'ISS-POST-001',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: issue.issueDate,
        status: InventoryDocumentStatus.draft,
      ),
    );

    expect(postResult, isA<PostSuccess>());
    expect((postResult as PostSuccess).postedValue, equals(80.0));

    // 4. Verify DB status is updated to POSTED
    final postedIssue = await stockRepo.getIssueById(issueUuid);
    expect(postedIssue!.status, equals(InventoryDocumentStatus.posted));
    expect(postedIssue.isPosted, isTrue);
    expect(postedIssue.postedAt, isNotNull);

    // 5. Verify Cost Layer remaining quantity deducted
    final layers = await (db.select(db.inventoryCostLayers)..where((t) => t.itemCode.equals('ITEM-POST-001'))).get();
    expect(layers.first.remainingQty, equals(6.0));
  });

  test('ROOT FIX 12: Failed posting (shortage) retains DRAFT status without false POSTED state', () async {
    // 1. Save Draft Stock Issue for 100 units when stock is 0
    final issueUuid = generateUuidV4();
    final issue = StockIssue(
      id: issueUuid,
      issueNumber: 'ISS-SHORTAGE-001',
      issueDate: DateTime.now().toUtc(),
      lines: [
        StockMovementLine(
          movementUuid: issueUuid,
          movementType: 'issue',
          itemCode: 'ITEM-SHORTAGE-001',
          itemName: 'Shortage Item',
          quantity: 100,
          unitCost: 50.0,
          totalCost: 5000.0,
        ),
      ],
      companyId: testCompanyId,
    );
    await stockRepo.saveIssue(issue);

    // 2. Attempt to post
    final result = await postingCoordinator.post(
      document: InventoryDocumentRef(
        documentId: issueUuid,
        documentNumber: 'ISS-SHORTAGE-001',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: issue.issueDate,
        status: InventoryDocumentStatus.draft,
      ),
    );

    expect(result, isA<PostStockShortage>());

    // 3. Verify status remains DRAFT in database (NOT falsely POSTED!)
    final unpostedIssue = await stockRepo.getIssueById(issueUuid);
    expect(unpostedIssue!.status, equals(InventoryDocumentStatus.draft));
    expect(unpostedIssue.isDraft, isTrue);
    expect(unpostedIssue.isPosted, isFalse);
    expect(unpostedIssue.postedAt, isNull);

    final rawRow = await (db.select(db.stockIssues)..where((t) => t.uuid.equals(issueUuid))).getSingle();
    expect(rawRow.status, equals('draft'));
    expect(rawRow.postedAt, isNull);
  });
}
