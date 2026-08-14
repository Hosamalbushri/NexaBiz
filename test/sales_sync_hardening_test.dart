import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sqlite3/open.dart';
import 'package:stock_count/core/sync/sync_operation.dart';
import 'package:stock_count/core/sync/sync_operation_adapter.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/core/sync/sync_status.dart';
import 'package:stock_count/modules/sales/data/database/sales_database.dart';
import 'package:stock_count/modules/sales/data/repositories/sale_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  open.overrideFor(OperatingSystem.linux, () {
    return DynamicLibrary.open('libsqlite3.so.0');
  });

  group('SyncQueue coalesce', () {
    late Directory tempDir;
    late Box<SyncOperation> syncBox;
    late SyncQueue queue;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sync_queue_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(SyncOperationAdapter());
      }
      syncBox = await Hive.openBox<SyncOperation>('sync_queue');
      queue = SyncQueue(box: syncBox);
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('create then update keeps create type with latest payload', () async {
      await queue.enqueue(
        SyncOperation.create(
          entityType: 'sale',
          entityId: 'sale-1',
          type: SyncOperationType.create,
          payload: const {'v': 1},
        ),
      );
      await queue.enqueue(
        SyncOperation.create(
          entityType: 'sale',
          entityId: 'sale-1',
          type: SyncOperationType.update,
          payload: const {'v': 2},
        ),
      );

      final all = await queue.all();
      expect(all, hasLength(1));
      expect(all.single.type, SyncOperationType.create);
      expect(all.single.payload['v'], 2);
      expect(all.single.status, SyncStatus.pending);
    });

    test('create then delete drops pending ops (never uploaded)', () async {
      await queue.enqueue(
        SyncOperation.create(
          entityType: 'sale',
          entityId: 'sale-2',
          type: SyncOperationType.create,
          payload: const {'v': 1},
        ),
      );
      await queue.enqueue(
        SyncOperation.create(
          entityType: 'sale',
          entityId: 'sale-2',
          type: SyncOperationType.delete,
          payload: const {'v': 1},
        ),
      );

      final all = await queue.all();
      expect(all, isEmpty);
    });

    test('update then update keeps a single update', () async {
      await queue.enqueue(
        SyncOperation.create(
          entityType: 'sale',
          entityId: 'sale-3',
          type: SyncOperationType.update,
          payload: const {'v': 1},
        ),
      );
      await queue.enqueue(
        SyncOperation.create(
          entityType: 'sale',
          entityId: 'sale-3',
          type: SyncOperationType.update,
          payload: const {'v': 3},
        ),
      );

      final all = await queue.all();
      expect(all, hasLength(1));
      expect(all.single.type, SyncOperationType.update);
      expect(all.single.payload['v'], 3);
    });
  });

  group('SaleRepository applyRemotePayload', () {
    late SalesDatabase db;
    late SaleRepositoryImpl repository;

    setUp(() async {
      db = SalesDatabase.memory();
      repository = SaleRepositoryImpl(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('applies header + items atomically', () async {
      const uuid = '11111111-1111-4111-8111-111111111111';
      await repository.applyRemotePayload({
        'uuid': uuid,
        'saleNumber': '99',
        'saleDate': DateTime.utc(2026, 8, 13).millisecondsSinceEpoch,
        'settlementType': 'cash',
        'currencyCode': 'SAR',
        'baseCurrencyCode': 'SAR',
        'exchangeRate': 1,
        'subtotal': 20,
        'total': 20,
        'paidAmount': 20,
        'remainingAmount': 0,
        'paymentStatus': 'paid',
        'paymentMethod': 'cash',
        'saleStatus': 'confirmed',
        'version': 2,
        'items': [
          {
            'uuid': '22222222-2222-4222-8222-222222222222',
            'productId': 'p1',
            'productName': 'Milk',
            'productCode': 'M1',
            'quantity': 2,
            'mainQuantity': 2,
            'unitPrice': 10,
            'subtotal': 20,
            'total': 20,
          },
        ],
        'payments': [
          {
            'uuid': '33333333-3333-4333-8333-333333333333',
            'amount': 20,
            'method': 'cash',
            'paidAt': DateTime.utc(2026, 8, 13).millisecondsSinceEpoch,
          },
        ],
      });

      final sale = await repository.getByUuid(uuid);
      expect(sale, isNotNull);
      expect(sale!.saleNumber, '99');
      expect(sale.items, hasLength(1));
      expect(sale.items.single.productName, 'Milk');
      expect(sale.payments, hasLength(1));
      expect(sale.syncStatus, SyncStatus.synced);
    });
  });
}
