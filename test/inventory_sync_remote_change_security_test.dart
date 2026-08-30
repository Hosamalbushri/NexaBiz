import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/data/sync/inventory_sync_handlers.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InventoryDatabase db;
  late InMemoryRemoteSyncApi remoteApi;
  const currentCompany = 'tenant-sync-company-01';
  const otherCompany = 'tenant-sync-company-02';

  setUp(() {
    db = InventoryDatabase.memory();
    remoteApi = InMemoryRemoteSyncApi();
  });

  tearDown(() async {
    await db.close();
  });

  InventoryDocumentSyncHandler createHandler(String docType) {
    return InventoryDocumentSyncHandler(
      entityType: docType,
      remoteProvider: () => remoteApi,
      db: db,
      readCompanyId: () => currentCompany,
    );
  }

  group('ROOT FIX 10 — Inventory Synchronization Remote Change Security Tests', () {
    test('1. Normal Remote Stock Receipt Application & Lines Persistence', () async {
      final handler = createHandler('stock_receipt');
      const receiptUuid = '00000000-0000-0000-0000-0000000000r1';

      final change = SyncRemoteChange(
        entityType: 'stock_receipt',
        entityId: receiptUuid,
        version: 1,
        updatedAt: DateTime.utc(2026, 8, 30),
        deleted: false,
        payload: {
          'companyId': currentCompany,
          'receiptNumber': 'REC-REMOTE-001',
          'supplier': 'Supplier Alpha',
          'receiptDate': DateTime.utc(2026, 8, 30).millisecondsSinceEpoch,
          'status': 'posted',
          'postedAt': DateTime.utc(2026, 8, 30, 10, 0).millisecondsSinceEpoch,
          'lines': [
            {
              'id': '00000000-0000-0000-0000-000000line01',
              'itemCode': 'ITEM-R1',
              'itemName': 'Remote Item 1',
              'quantity': 100.0,
              'unitCost': 15.0,
              'totalCost': 1500.0,
              'postedCost': 15.0,
              'postedAt': DateTime.utc(2026, 8, 30, 10, 0).millisecondsSinceEpoch,
            }
          ]
        },
      );

      await handler.applyRemoteChange(change);

      // Verify header persisted in database
      final receipt = await (db.select(db.stockReceipts)
            ..where((t) => t.uuid.equals(receiptUuid) & t.companyId.equals(currentCompany)))
          .getSingleOrNull();

      expect(receipt, isNotNull);
      expect(receipt!.receiptNumber, equals('REC-REMOTE-001'));
      expect(receipt.syncStatus, equals('synced'));
      expect(receipt.version, equals(1));
      expect(receipt.companyId, equals(currentCompany));

      // Verify lines persisted
      final lines = await (db.select(db.stockMovementLines)
            ..where((t) => t.movementUuid.equals(receiptUuid)))
          .get();

      expect(lines.length, equals(1));
      expect(lines.first.itemCode, equals('ITEM-R1'));
      expect(lines.first.quantity, equals(100.0));
      expect(lines.first.totalCost, equals(1500.0));
    });

    test('2. Cross-Tenant Remote Change Payload Rejection', () async {
      final handler = createHandler('stock_receipt');
      const receiptUuid = '00000000-0000-0000-0000-0000000000r2';

      final maliciousChange = SyncRemoteChange(
        entityType: 'stock_receipt',
        entityId: receiptUuid,
        version: 1,
        updatedAt: DateTime.utc(2026, 8, 30),
        deleted: false,
        payload: {
          'companyId': otherCompany, // Mismatched tenant
          'receiptNumber': 'REC-MALICIOUS-001',
          'supplier': 'Evil Corp',
          'lines': []
        },
      );

      // Must throw ArgumentError due to cross-tenant rejection
      expect(
        () => handler.applyRemoteChange(maliciousChange),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Cross-tenant sync change rejected'),
        )),
      );

      // Verify DB was NOT touched
      final receipt = await (db.select(db.stockReceipts)
            ..where((t) => t.uuid.equals(receiptUuid)))
          .getSingleOrNull();
      expect(receipt, isNull);
    });

    test('3. Idempotency — Duplicate Remote Change Is Ignored', () async {
      final handler = createHandler('stock_issue');
      const issueUuid = '00000000-0000-0000-0000-0000000000i1';

      final changeV1 = SyncRemoteChange(
        entityType: 'stock_issue',
        entityId: issueUuid,
        version: 1,
        updatedAt: DateTime.utc(2026, 8, 30),
        deleted: false,
        payload: {
          'companyId': currentCompany,
          'issueNumber': 'ISS-IDEM-001',
          'destination': 'Store A',
          'lines': [
            {
              'id': '00000000-0000-0000-0000-000000line02',
              'itemCode': 'ITEM-I1',
              'itemName': 'Issue Item 1',
              'quantity': 50.0,
              'unitCost': 10.0,
              'totalCost': 500.0,
            }
          ]
        },
      );

      // Apply first time
      await handler.applyRemoteChange(changeV1);

      var lines = await (db.select(db.stockMovementLines)
            ..where((t) => t.movementUuid.equals(issueUuid)))
          .get();
      expect(lines.length, equals(1));
      expect(lines.first.quantity, equals(50.0));

      // Apply duplicate change (same version) with modified payload to ensure local database is untouched
      final duplicateChangeV1 = SyncRemoteChange(
        entityType: 'stock_issue',
        entityId: issueUuid,
        version: 1,
        updatedAt: DateTime.utc(2026, 8, 30),
        deleted: false,
        payload: {
          'companyId': currentCompany,
          'issueNumber': 'ISS-IDEM-DUPLICATE',
          'destination': 'Store B',
          'lines': [
            {
              'id': '00000000-0000-0000-0000-000000line03',
              'itemCode': 'ITEM-I1',
              'itemName': 'Issue Item 1',
              'quantity': 999.0,
              'unitCost': 10.0,
              'totalCost': 9990.0,
            }
          ]
        },
      );

      await handler.applyRemoteChange(duplicateChangeV1);

      // Verify original issue document was preserved and duplicate payload was ignored
      final issue = await (db.select(db.stockIssues)
            ..where((t) => t.uuid.equals(issueUuid) & t.companyId.equals(currentCompany)))
          .getSingle();

      expect(issue.issueNumber, equals('ISS-IDEM-001'));
      expect(issue.destination, equals('Store A'));

      lines = await (db.select(db.stockMovementLines)
            ..where((t) => t.movementUuid.equals(issueUuid)))
          .get();
      expect(lines.length, equals(1));
      expect(lines.first.quantity, equals(50.0));
    });

    test('4. Out-of-Order / Older Remote Version Handling', () async {
      final handler = createHandler('stock_transfer');
      const transferUuid = '00000000-0000-0000-0000-0000000000t1';

      // Seed local record with version = 5
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.stockTransfers).insert(
            StockTransfersCompanion.insert(
              uuid: transferUuid,
              transferNumber: 'TR-LOCAL-V5',
              fromWarehouseId: 'WH-1',
              toWarehouseId: 'WH-2',
              transferDate: now,
              companyId: const Value(currentCompany),
              version: const Value(5),
              syncStatus: const Value('synced'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Receive older remote change (version = 3)
      final olderChange = SyncRemoteChange(
        entityType: 'stock_transfer',
        entityId: transferUuid,
        version: 3,
        updatedAt: DateTime.utc(2026, 8, 20),
        deleted: false,
        payload: {
          'companyId': currentCompany,
          'transferNumber': 'TR-REMOTE-V3-OLD',
          'fromWarehouseId': 'WH-1',
          'toWarehouseId': 'WH-3',
        },
      );

      await handler.applyRemoteChange(olderChange);

      // Verify version 5 remains untouched
      final transfer = await (db.select(db.stockTransfers)
            ..where((t) => t.uuid.equals(transferUuid) & t.companyId.equals(currentCompany)))
          .getSingle();

      expect(transfer.transferNumber, equals('TR-LOCAL-V5'));
      expect(transfer.version, equals(5));
    });

    test('5. Stock Return Remote Change Handling', () async {
      final handler = createHandler('stock_return');
      const returnUuid = '00000000-0000-0000-0000-000000000ret';

      final change = SyncRemoteChange(
        entityType: 'stock_return',
        entityId: returnUuid,
        version: 1,
        updatedAt: DateTime.utc(2026, 8, 30),
        deleted: false,
        payload: {
          'companyId': currentCompany,
          'returnNumber': 'RET-REMOTE-001',
          'returnType': 'sales_return',
          'partyName': 'Customer Beta',
          'warehouse': 'WH-MAIN',
          'status': 'posted',
          'lines': [
            {
              'id': '00000000-0000-0000-0000-000000line04',
              'itemCode': 'ITEM-RET1',
              'itemName': 'Returned Item',
              'quantity': 5.0,
              'unitCost': 10.0,
              'totalCost': 50.0,
            }
          ]
        },
      );

      await handler.applyRemoteChange(change);

      final retDoc = await (db.select(db.stockReturns)
            ..where((t) => t.uuid.equals(returnUuid) & t.companyId.equals(currentCompany)))
          .getSingleOrNull();

      expect(retDoc, isNotNull);
      expect(retDoc!.returnNumber, equals('RET-REMOTE-001'));
      expect(retDoc.status, equals('posted'));
      expect(retDoc.syncStatus, equals('synced'));
    });

    test('6. markLocalSynced & markLocalConflict Updates Database Header Correctly', () async {
      final handler = createHandler('stock_receipt');
      const receiptUuid = '00000000-0000-0000-0000-0000000000m1';

      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.stockReceipts).insert(
            StockReceiptsCompanion.insert(
              uuid: receiptUuid,
              receiptNumber: 'REC-MARK-001',
              receiptDate: now,
              companyId: const Value(currentCompany),
              syncStatus: const Value('pending'),
              version: const Value(1),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Test markLocalSynced
      await handler.markLocalSynced(
        entityId: receiptUuid,
        remoteVersion: 2,
        syncedAt: DateTime.utc(2026, 8, 30),
      );

      var receipt = await (db.select(db.stockReceipts)
            ..where((t) => t.uuid.equals(receiptUuid) & t.companyId.equals(currentCompany)))
          .getSingle();

      expect(receipt.syncStatus, equals('synced'));
      expect(receipt.version, equals(2));

      // Test markLocalConflict
      await handler.markLocalConflict(
        entityId: receiptUuid,
        message: 'Version mismatch detected during sync',
      );

      receipt = await (db.select(db.stockReceipts)
            ..where((t) => t.uuid.equals(receiptUuid) & t.companyId.equals(currentCompany)))
          .getSingle();

      expect(receipt.syncStatus, equals('conflict'));
    });
  });
}
