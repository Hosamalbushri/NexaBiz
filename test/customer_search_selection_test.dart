import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/modules/customers/directory/data/repositories/customer_repository_impl.dart';
import 'package:stock_count/modules/customers/directory/domain/entities/customer.dart';
import 'package:stock_count/modules/customers/directory/domain/usecases/customer_usecases.dart';
import 'package:stock_count/modules/customers/shared/data/database/customers_database.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CU-05 — Customer Search & Selection Consolidation', () {
    late Directory tempDir;
    late CustomersDatabase db;
    late SyncQueue queue;
    late CustomerRepositoryImpl repo;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cu05_search_test_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(SyncOperationAdapter());
      }
      final box = await Hive.openBox<SyncOperation>('sync_queue_cu05');
      queue = SyncQueue(box: box);
      db = CustomersDatabase.memory();
      repo = CustomerRepositoryImpl(
        db,
        syncQueue: queue,
        readCompanyId: () => 'comp_A',
      );

      // Seed 3 test customers
      await repo.insert(
        const CustomerDraft(
          customerCode: '12210030',
          name: 'مؤسسة الأمل التجارية',
          phone: '+966501111111',
          email: 'alamal@example.com',
          taxNumber: '300000000000001',
        ),
      );
      await repo.insert(
        const CustomerDraft(
          customerCode: '12210031',
          name: 'شركة النور للمقاولات',
          phone: '+966502222222',
          email: 'alnoor@example.com',
          taxNumber: '300000000000002',
        ),
      );
      await repo.insert(
        const CustomerDraft(
          customerCode: '12210032',
          name: 'شركة الأفق التقنية',
          phone: '+966503333333',
          email: 'alofoq@example.com',
          taxNumber: '300000000000003',
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

    test(
      '1. SEARCH: Multi-field matching by name, code, phone, email, and tax number',
      () async {
        final search = SearchCustomers(repo);

        // Match by name
        final byName = await search('الأمل');
        expect(byName.length, equals(1));
        expect(byName.first.customerCode, equals('12210030'));

        // Match by code
        final byCode = await search('12210031');
        expect(byCode.length, equals(1));
        expect(byCode.first.name, equals('شركة النور للمقاولات'));

        // Match by phone
        final byPhone = await search('503333333');
        expect(byPhone.length, equals(1));
        expect(byPhone.first.customerCode, equals('12210032'));

        // Match by email
        final byEmail = await search('alnoor@example.com');
        expect(byEmail.length, equals(1));

        // Match by tax number
        final byTax = await search('300000000000003');
        expect(byTax.length, equals(1));
      },
    );

    test('2. BOUNDED QUERY: Search respects SQL limit parameter', () async {
      final search = SearchCustomers(repo);

      // Query matching multiple rows with limit: 1
      final bounded = await repo.search('شركة', limit: 1);
      expect(bounded.length, equals(1));

      final unbounded = await search('شركة');
      expect(unbounded.length, equals(2));
    });

    testWidgets(
      '3. WIDGET: AppCustomerSearchField renders and executes selection callback',
      (tester) async {
        Customer? selectedCustomer;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppCustomerSearchField<Customer>(
                label: 'بحث عن عميل',
                minQueryLength: 1,
                debounceDuration: const Duration(milliseconds: 10),
                fetchOptions: (query) => repo.search(query, limit: 10),
                itemLabelBuilder: (c) => c.name,
                onSelected: (customer) {
                  selectedCustomer = customer;
                },
              ),
            ),
          ),
        );

        expect(find.byType(AppCustomerSearchField<Customer>), findsOneWidget);

        // Enter query 'الأمل'
        await tester.enterText(find.byType(TextField), 'الأمل');
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();

        // Verify search option appeared
        final optionTile = find.text('مؤسسة الأمل التجارية');
        expect(optionTile, findsOneWidget);

        // Tap option
        await tester.tap(optionTile);
        await tester.pumpAndSettle();

        expect(selectedCustomer, isNotNull);
        expect(selectedCustomer!.customerCode, equals('12210030'));
      },
    );
  });
}
