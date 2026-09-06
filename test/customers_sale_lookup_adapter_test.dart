import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/app/sales/customers_sale_lookup_adapter.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/modules/customers/accounts/domain/services/customer_account_link_port.dart';
import 'package:stock_count/modules/customers/directory/data/repositories/customer_repository_impl.dart';
import 'package:stock_count/modules/customers/directory/domain/entities/customer.dart';
import 'package:stock_count/modules/customers/shared/data/database/customers_database.dart';
import 'package:stock_count/modules/sync/sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomersSaleLookupAdapter Tests', () {
    late Directory tempDir;
    late CustomersDatabase db;
    late SyncQueue queue;
    late CustomerRepositoryImpl repo;
    late CustomersSaleLookupAdapter adapter;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sale_lookup_test_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(SyncOperationAdapter());
      }
      final box = await Hive.openBox<SyncOperation>('sync_queue_lookup');
      queue = SyncQueue(box: box);
      db = CustomersDatabase.memory();
      repo = CustomerRepositoryImpl(
        db,
        syncQueue: queue,
        readCompanyId: () => 'comp_A',
      );

      adapter = CustomersSaleLookupAdapter(
        repository: repo,
        accountLinkPort: const NoOpCustomerAccountLinkPort(),
        settings: SettingsRepository(),
      );

      await repo.insert(
        const CustomerDraft(
          customerCode: 'CUST-001',
          name: 'العميل الأول',
          phone: '0501234567',
        ),
      );
      await repo.insert(
        const CustomerDraft(
          customerCode: 'CUST-002',
          name: 'العميل الثاني',
          phone: '0507654321',
        ),
      );
    });

    tearDown(() async {
      await db.close();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('search with empty query returns all active customers', () async {
      final results = await adapter.search('');
      expect(results.length, equals(2));
      expect(results.first.name, equals('العميل الأول'));
    });

    test('search with specific query filters customers', () async {
      final results = await adapter.search('الثاني');
      expect(results.length, equals(1));
      expect(results.first.name, equals('العميل الثاني'));
    });

    test('findById returns mapped SaleCustomerRef', () async {
      final all = await adapter.search('');
      expect(all, isNotEmpty);
      final found = await adapter.findById(all.first.customerId);
      expect(found, isNotNull);
      expect(found!.customerCode, equals('CUST-001'));
    });
  });
}
