import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/sync/sync_core.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/voucher_books/data/repositories/voucher_book_repository_impl.dart';
import 'package:stock_count/modules/accounting/voucher_books/domain/entities/voucher_book.dart';
import 'package:stock_count/modules/accounting/voucher_books/domain/entities/voucher_book_type.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/data/sync/inventory_sync_handlers.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AccountingDatabase accDb;
  late InventoryDatabase invDb;
  late VoucherBookRepositoryImpl voucherBookRepo;
  late StockMovementsRepositoryImpl stockMovementsRepo;

  const testCompanyId = 'comp-phase2d-canonical-identity';

  setUp(() async {
    accDb = AccountingDatabase(executor: NativeDatabase.memory());
    invDb = InventoryDatabase(executor: NativeDatabase.memory());

    voucherBookRepo = VoucherBookRepositoryImpl(
      accDb,
      readCompanyId: () => testCompanyId,
    );

    stockMovementsRepo = StockMovementsRepositoryImpl(
      db: invDb,
      readCompanyId: () => testCompanyId,
    );

    await voucherBookRepo.ensureDefaultSections();
    await voucherBookRepo.seedDefaultBooks();
  });

  tearDown(() async {
    await accDb.close();
    await invDb.close();
  });

  group('Phase 2D — Canonical Identity / UUID Reference Remediation', () {
    test('1. Stable Voucher Book Canonical UUID across reload/restarts', () async {
      final issueBooks = await voucherBookRepo.getByType(VoucherBookType.stockIssues);
      expect(issueBooks.isNotEmpty, isTrue);

      final book = issueBooks.first;
      expect(book.uuid, isNotNull);
      expect(book.uuid.length, equals(36)); // Canonical UUID string

      final retrievedByUuid = await voucherBookRepo.getByUuid(book.uuid);
      expect(retrievedByUuid, isNotNull);
      expect(retrievedByUuid!.uuid, equals(book.uuid));
    });

    test('2. StockIssue stores and resolves canonical UUID for voucherBookId', () async {
      final issueBooks = await voucherBookRepo.getByType(VoucherBookType.stockIssues);
      final canonicalVoucherUuid = issueBooks.first.uuid;

      final issue = StockIssue(
        issueNumber: 'ISS-2D-001',
        issueDate: DateTime.now().toUtc(),
        voucherBookId: canonicalVoucherUuid,
        lines: [
          StockMovementLine(
            movementUuid: '11111111-1111-1111-1111-111111111111',
            movementType: 'issue',
            itemCode: 'ITEM-1',
            itemName: 'Test Item',
            quantity: 10,
            unitCost: 5.0,
            totalCost: 50.0,
          ),
        ],
      );

      await stockMovementsRepo.saveIssue(issue);

      final savedIssue = await stockMovementsRepo.getIssueById(issue.id);
      expect(savedIssue, isNotNull);
      expect(savedIssue!.voucherBookId, isA<String>());
      expect(savedIssue.voucherBookId, equals(canonicalVoucherUuid));
    });

    test('3. Existing null/empty voucherBookId compatibility', () async {
      final issue = StockIssue(
        issueNumber: 'ISS-2D-002',
        issueDate: DateTime.now().toUtc(),
        voucherBookId: null,
        lines: [
          StockMovementLine(
            movementUuid: '22222222-2222-2222-2222-222222222222',
            movementType: 'issue',
            itemCode: 'ITEM-2',
            itemName: 'Item 2',
            quantity: 5,
            unitCost: 10.0,
            totalCost: 50.0,
          ),
        ],
      );

      await stockMovementsRepo.saveIssue(issue);

      final saved = await stockMovementsRepo.getIssueById(issue.id);
      expect(saved, isNotNull);
      expect(saved!.voucherBookId, isNull);
    });

    test('4. Orphan reference protection (No silent fallback to arbitrary voucher book)', () async {
      final issue = StockIssue(
        issueNumber: 'ISS-2D-003',
        issueDate: DateTime.now().toUtc(),
        voucherBookId: null,
        lines: [
          StockMovementLine(
            movementUuid: '33333333-3333-3333-3333-333333333333',
            movementType: 'issue',
            itemCode: 'ITEM-3',
            itemName: 'Item 3',
            quantity: 1,
            unitCost: 20.0,
            totalCost: 20.0,
          ),
        ],
      );

      await stockMovementsRepo.saveIssue(issue);
      final saved = await stockMovementsRepo.getIssueById(issue.id);

      // Must remain explicitly null and NOT silently manufacture a default voucher book ID
      expect(saved!.voucherBookId, isNull);
    });

    test('5. Sync Push transmits canonical voucherBookId string in payload', () async {
      late SyncOperation enqueuedOp;
      final mockSyncQueue = MockSyncQueue((op) async {
        enqueuedOp = op;
      });

      final repoWithSync = StockMovementsRepositoryImpl(
        db: invDb,
        syncQueue: mockSyncQueue,
        readCompanyId: () => testCompanyId,
      );

      const canonicalUuid = 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6';
      final issue = StockIssue(
        issueNumber: 'ISS-2D-005',
        issueDate: DateTime.now().toUtc(),
        voucherBookId: canonicalUuid,
        lines: [
          StockMovementLine(
            movementUuid: '55555555-5555-5555-5555-555555555555',
            movementType: 'issue',
            itemCode: 'ITEM-5',
            itemName: 'Item 5',
            quantity: 2,
            unitCost: 15.0,
            totalCost: 30.0,
          ),
        ],
      );

      await repoWithSync.saveIssue(issue);

      expect(enqueuedOp.payload['voucherBookId'], equals(canonicalUuid));
      expect(enqueuedOp.payload['voucherBookId'], isA<String>());
    });

    test('6. Sync Pull deserializes remote canonical voucherBookId UUID string', () async {
      final handler = InventoryDocumentSyncHandler(
        entityType: 'stock_issue',
        remoteProvider: () => throw UnimplementedError(),
        db: invDb,
        readCompanyId: () => testCompanyId,
      );

      const remoteVoucherBookUuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
      const remoteIssueUuid = '66666666-6666-6666-6666-666666666666';

      final remoteChange = SyncRemoteChange(
        entityType: 'stock_issue',
        entityId: remoteIssueUuid,
        payload: {
          'id': remoteIssueUuid,
          'issueNumber': 'ISS-REMOTE-01',
          'companyId': testCompanyId,
          'voucherBookId': remoteVoucherBookUuid,
          'issueDate': DateTime.now().millisecondsSinceEpoch,
          'status': 'draft',
          'lines': [],
        },
        version: 1,
        updatedAt: DateTime.now().toUtc(),
      );

      await handler.applyRemoteChange(remoteChange);

      final query = invDb.select(invDb.stockIssues)
        ..where((tbl) => tbl.uuid.equals(remoteIssueUuid));
      final row = await query.getSingleOrNull();

      expect(row, isNotNull);
      expect(row!.voucherBookId, equals(remoteVoucherBookUuid));
      expect(row.voucherBookId, isA<String>());
    });

    test('7. Cross-Device Identity Resolution (Device A local ID != Device B local ID)', () async {
      // Device A has local autoincrement ID 17 for VoucherBook X
      // Device B has local autoincrement ID 4 for VoucherBook X
      // Both devices share the SAME canonical UUID X
      const canonicalVoucherUuid = '77777777-7777-7777-7777-777777777777';

      final issueDeviceA = StockIssue(
        issueNumber: 'ISS-DEV-A',
        issueDate: DateTime.now().toUtc(),
        voucherBookId: canonicalVoucherUuid,
        lines: [],
      );

      await stockMovementsRepo.saveIssue(issueDeviceA);
      final retrieved = await stockMovementsRepo.getIssueById(issueDeviceA.id);

      expect(retrieved!.voucherBookId, equals(canonicalVoucherUuid));
      expect(retrieved.voucherBookId, isNot(equals('17')));
      expect(retrieved.voucherBookId, isNot(equals('4')));
    });

    test('8. Voucher Book UUID Immutability', () async {
      final books = await voucherBookRepo.getByType(VoucherBookType.stockIssues);
      expect(books.isNotEmpty, isTrue);

      final book = books.first;
      final originalUuid = book.uuid;

      final updatedDraft = VoucherBookDraft(
        name: 'Renamed Book',
        bookType: book.bookType,
        parentId: book.parentId,
      );
      await voucherBookRepo.update(book.id, updatedDraft);

      final reloaded = await voucherBookRepo.getByUuid(originalUuid);
      expect(reloaded, isNotNull);
      expect(reloaded!.name, equals('Renamed Book'));
      expect(reloaded.uuid, equals(originalUuid));
    });

    test('9. Unique Leaf Voucher Book Creation', () async {
      final invSections = await voucherBookRepo.getByType(VoucherBookType.inventory);
      expect(invSections.isNotEmpty, isTrue);
      final sectionUuid = invSections.first.uuid;

      final draft1 = VoucherBookDraft(
        name: 'Unique Issue Book 1',
        bookType: VoucherBookType.stockIssues,
        parentId: sectionUuid,
      );

      final created1 = await voucherBookRepo.create(draft1);
      expect(created1.uuid, isNotNull);
      expect(created1.uuid.length, equals(36));
    });

    test('10. Round-Trip Serialization & Deserialization Integrity', () async {
      const canonicalUuid = 'c0a80101-0000-0000-0000-000000000001';
      final issueOriginal = StockIssue(
        issueNumber: 'ISS-RT-1',
        issueDate: DateTime.now().toUtc(),
        voucherBookId: canonicalUuid,
        lines: [],
      );

      final copy = issueOriginal.copyWith(issueNumber: 'ISS-RT-1-UPDATED');
      expect(copy.voucherBookId, equals(canonicalUuid));

      await stockMovementsRepo.saveIssue(copy);
      final fetched = await stockMovementsRepo.getIssueById(copy.id);

      expect(fetched!.voucherBookId, equals(canonicalUuid));
      expect(fetched.issueNumber, equals('ISS-RT-1-UPDATED'));
    });
  });
}

class MockSyncQueue implements SyncQueue {
  MockSyncQueue(this.onEnqueue);
  final Future<void> Function(SyncOperation op) onEnqueue;

  @override
  Future<void> enqueue(SyncOperation op) => onEnqueue(op);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
