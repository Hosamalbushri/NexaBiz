import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';

void main() {
  late InventoryDatabase db;

  setUp(() async {
    db = InventoryDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  StockMovementsRepositoryImpl createRepoForCompany(String companyId) {
    return StockMovementsRepositoryImpl(
      db: db,
      readCompanyId: () => companyId,
    );
  }

  group('Stock Movements Multi-Tenant Isolation Security Tests', () {
    test('Test 1 — Read isolation: getAllReceipts and getAllIssues return only current tenant records', () async {
      final repoA = createRepoForCompany('company-A');
      final repoB = createRepoForCompany('company-B');

      final receiptA = StockReceipt(
        id: generateUuidV4(),
        receiptNumber: 'REC-A-01',
        receiptDate: DateTime.utc(2026, 1, 1),
        companyId: 'company-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: 'm1',
            movementType: 'receipt',
            itemCode: 'ITEM-1',
            itemName: 'Item 1',
            quantity: 10,
            unitCost: 100,
            totalCost: 1000,
          ),
        ],
      );

      final receiptB = StockReceipt(
        id: generateUuidV4(),
        receiptNumber: 'REC-B-01',
        receiptDate: DateTime.utc(2026, 1, 1),
        companyId: 'company-B',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: 'm2',
            movementType: 'receipt',
            itemCode: 'ITEM-2',
            itemName: 'Item 2',
            quantity: 5,
            unitCost: 200,
            totalCost: 1000,
          ),
        ],
      );

      await repoA.saveReceipt(receiptA);
      await repoB.saveReceipt(receiptB);

      // Query as Company A
      final receiptsA = await repoA.getAllReceipts();
      expect(receiptsA.length, 1);
      expect(receiptsA.first.id, receiptA.id);
      expect(receiptsA.first.receiptNumber, 'REC-A-01');

      final watchedReceiptsA = await repoA.watchAllReceipts().first;
      expect(watchedReceiptsA.length, 1);
      expect(watchedReceiptsA.first.id, receiptA.id);

      // Query as Company B
      final receiptsB = await repoB.getAllReceipts();
      expect(receiptsB.length, 1);
      expect(receiptsB.first.id, receiptB.id);

      // Issues isolation check
      final issueA = StockIssue(
        id: generateUuidV4(),
        issueNumber: 'ISS-A-01',
        issueDate: DateTime.utc(2026, 1, 1),
        companyId: 'company-A',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: 'm3',
            movementType: 'issue',
            itemCode: 'ITEM-1',
            itemName: 'Item 1',
            quantity: 2,
            unitCost: 100,
            totalCost: 200,
          ),
        ],
      );

      final issueB = StockIssue(
        id: generateUuidV4(),
        issueNumber: 'ISS-B-01',
        issueDate: DateTime.utc(2026, 1, 1),
        companyId: 'company-B',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: 'm4',
            movementType: 'issue',
            itemCode: 'ITEM-2',
            itemName: 'Item 2',
            quantity: 1,
            unitCost: 200,
            totalCost: 200,
          ),
        ],
      );

      await repoA.saveIssue(issueA);
      await repoB.saveIssue(issueB);

      final issuesA = await repoA.getAllIssues();
      expect(issuesA.length, 1);
      expect(issuesA.first.id, issueA.id);

      final issuesB = await repoB.getAllIssues();
      expect(issuesB.length, 1);
      expect(issuesB.first.id, issueB.id);
    });

    test('Test 2 — Get-by-ID isolation: getReceiptById and getIssueById return null for other tenant records', () async {
      final repoA = createRepoForCompany('company-A');
      final repoB = createRepoForCompany('company-B');

      final receiptB = StockReceipt(
        id: generateUuidV4(),
        receiptNumber: 'REC-B-02',
        receiptDate: DateTime.utc(2026, 1, 1),
        companyId: 'company-B',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: 'm5',
            movementType: 'receipt',
            itemCode: 'ITEM-1',
            itemName: 'Item 1',
            quantity: 10,
            unitCost: 100,
            totalCost: 1000,
          ),
        ],
      );
      await repoB.saveReceipt(receiptB);

      final issueB = StockIssue(
        id: generateUuidV4(),
        issueNumber: 'ISS-B-02',
        issueDate: DateTime.utc(2026, 1, 1),
        companyId: 'company-B',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: 'm6',
            movementType: 'issue',
            itemCode: 'ITEM-1',
            itemName: 'Item 1',
            quantity: 5,
            unitCost: 100,
            totalCost: 500,
          ),
        ],
      );
      await repoB.saveIssue(issueB);

      // Company A attempts to get Company B's receipt and issue by ID
      final fetchReceipt = await repoA.getReceiptById(receiptB.id);
      expect(fetchReceipt, isNull);

      final fetchIssue = await repoA.getIssueById(issueB.id);
      expect(fetchIssue, isNull);
    });

    test('Test 3 — Update isolation: attempting to update Company B record with Company A repo leaves Company B data unchanged', () async {
      final repoA = createRepoForCompany('company-A');
      final repoB = createRepoForCompany('company-B');

      final receiptB = StockReceipt(
        id: generateUuidV4(),
        receiptNumber: 'REC-B-ORIGINAL',
        supplier: 'Original Supplier B',
        receiptDate: DateTime.utc(2026, 1, 1),
        companyId: 'company-B',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: 'm7',
            movementType: 'receipt',
            itemCode: 'ITEM-1',
            itemName: 'Item 1',
            quantity: 10,
            unitCost: 100,
            totalCost: 1000,
          ),
        ],
      );
      await repoB.saveReceipt(receiptB);

      // Attempt to overwrite Company B's receipt using repoA with matching receipt.id but modified supplier & companyId=company-A
      final tamperedReceipt = receiptB.copyWith(
        receiptNumber: 'REC-A-ATTEMPT',
        supplier: 'HACKED SUPPLIER',
        companyId: 'company-A',
      );

      // Save attempt using repoA (which is scoped to company-A) must fail (either rejected by cross-tenant check or primary key collision)
      expect(
        () => repoA.saveReceipt(tamperedReceipt),
        throwsA(anything),
      );

      // Company B's record in DB must remain unchanged with supplier = 'Original Supplier B'
      final actualB = await repoB.getReceiptById(receiptB.id);
      expect(actualB, isNotNull);
      expect(actualB!.supplier, 'Original Supplier B');
      expect(actualB.companyId, 'company-B');
    });

    test('Test 4 — Delete isolation: attempting to delete Company B record with Company A repo leaves Company B data intact', () async {
      final repoA = createRepoForCompany('company-A');
      final repoB = createRepoForCompany('company-B');

      final receiptB = StockReceipt(
        id: generateUuidV4(),
        receiptNumber: 'REC-B-DELETE-TEST',
        receiptDate: DateTime.utc(2026, 1, 1),
        companyId: 'company-B',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: 'm8',
            movementType: 'receipt',
            itemCode: 'ITEM-1',
            itemName: 'Item 1',
            quantity: 10,
            unitCost: 100,
            totalCost: 1000,
          ),
        ],
      );
      await repoB.saveReceipt(receiptB);

      final issueB = StockIssue(
        id: generateUuidV4(),
        issueNumber: 'ISS-B-DELETE-TEST',
        issueDate: DateTime.utc(2026, 1, 1),
        companyId: 'company-B',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: 'm9',
            movementType: 'issue',
            itemCode: 'ITEM-1',
            itemName: 'Item 1',
            quantity: 2,
            unitCost: 100,
            totalCost: 200,
          ),
        ],
      );
      await repoB.saveIssue(issueB);

      // Repo A attempts to delete Company B's receipt and issue
      await repoA.deleteReceipt(receiptB.id);
      await repoA.deleteIssue(issueB.id);

      // Verify Company B records still exist and are NOT soft deleted
      final bReceipt = await repoB.getReceiptById(receiptB.id);
      expect(bReceipt, isNotNull);
      expect(bReceipt!.deletedAt, isNull);

      final bIssue = await repoB.getIssueById(issueB.id);
      expect(bIssue, isNotNull);
      expect(bIssue!.deletedAt, isNull);
    });

    test('Test 5 — Insert isolation: saving a stock movement with cross-tenant companyId is rejected', () async {
      final repoA = createRepoForCompany('company-A');

      final receiptForB = StockReceipt(
        id: generateUuidV4(),
        receiptNumber: 'REC-ATTACK-01',
        receiptDate: DateTime.utc(2026, 1, 1),
        companyId: 'company-B',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: 'm10',
            movementType: 'receipt',
            itemCode: 'ITEM-1',
            itemName: 'Item 1',
            quantity: 10,
            unitCost: 100,
            totalCost: 1000,
          ),
        ],
      );

      final issueForB = StockIssue(
        id: generateUuidV4(),
        issueNumber: 'ISS-ATTACK-01',
        issueDate: DateTime.utc(2026, 1, 1),
        companyId: 'company-B',
        lines: [
          StockMovementLine(
            id: generateUuidV4(),
            movementUuid: 'm11',
            movementType: 'issue',
            itemCode: 'ITEM-1',
            itemName: 'Item 1',
            quantity: 5,
            unitCost: 100,
            totalCost: 500,
          ),
        ],
      );

      expect(() => repoA.saveReceipt(receiptForB), throwsA(isA<ArgumentError>()));
      expect(() => repoA.saveIssue(issueForB), throwsA(isA<ArgumentError>()));
    });

    test('Test 6 — Null company ID: records with companyId = null cannot become visible to any company tenant', () async {
      final repoA = createRepoForCompany('company-A');

      final now = DateTime.now().millisecondsSinceEpoch;
      final rawUuid = generateUuidV4();

      // Directly insert raw DB row with companyId = null
      await db.into(db.stockReceipts).insert(
            StockReceiptsCompanion(
              uuid: Value(rawUuid),
              receiptNumber: const Value('REC-NULL-COMPANY'),
              receiptDate: Value(now),
              createdAt: Value(now),
              updatedAt: Value(now),
              status: const Value('draft'),
              companyId: const Value(null),
            ),
          );

      // Query with repoA
      final receipts = await repoA.getAllReceipts();
      expect(receipts.any((r) => r.id == rawUuid), isFalse);

      final fetchById = await repoA.getReceiptById(rawUuid);
      expect(fetchById, isNull);
    });
  });
}
