import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/modules/customers/directory/data/repositories/customer_repository_impl.dart';
import 'package:stock_count/modules/customers/directory/domain/entities/customer.dart';
import 'package:stock_count/modules/customers/directory/domain/entities/customer_status.dart';
import 'package:stock_count/modules/customers/directory/presentation/pages/customer_details_page.dart';
import 'package:stock_count/modules/customers/directory/presentation/pages/customer_form_page.dart';
import 'package:stock_count/modules/customers/directory/presentation/pages/customers_list_page.dart';
import 'package:stock_count/modules/customers/directory/presentation/providers/customer_providers.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/sync/sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CU-06 — Customer UI / UX / Localization / RTL Audit', () {
    late Directory tempDir;
    late NexabizDatabase db;
    late SyncQueue queue;
    late CustomerRepositoryImpl repo;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cu06_ui_test_');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(SyncOperationAdapter());
      }
      final box = await Hive.openBox<SyncOperation>('sync_queue_cu06');
      queue = SyncQueue(box: box);
      db = NexabizDatabase.memory();
      repo = CustomerRepositoryImpl(
        db,
        syncQueue: queue,
        readCompanyId: () => 'comp_A',
      );
    });

    tearDown(() async {
      await db.close();
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    Widget createTestableWidget({
      required Widget child,
      Locale locale = const Locale('ar'),
    }) {
      return ProviderScope(
        overrides: [
          customerRepositoryProvider.overrideWithValue(repo),
          customersProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );
    }

    testWidgets(
      '1. LOCALIZATION & RTL: CustomersListPage renders in Arabic with empty state',
      (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            child: const CustomersListPage(),
            locale: const Locale('ar'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CustomersListPage), findsOneWidget);
      },
    );

    testWidgets(
      '2. LOCALIZATION: CustomersListPage renders in English locale',
      (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            child: const CustomersListPage(),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CustomersListPage), findsOneWidget);
      },
    );

    testWidgets(
      '3. FORM RENDERING: CustomerFormPage renders form sections and fields',
      (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            child: const CustomerFormPage(),
            locale: const Locale('ar'),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(CustomerFormPage), findsOneWidget);
        expect(find.byType(TextFormField), findsAtLeastNWidgets(3));
      },
    );

    testWidgets(
      '4. DETAILS PAGE: CustomerDetailsPage renders customer details',
      (tester) async {
        final customer = await repo.insert(
          const CustomerDraft(
            customerCode: '12210040',
            name: 'عميل اختبار الواجهة',
            phone: '+966504444444',
            email: 'ui@example.com',
            status: CustomerStatus.active,
            creditLimit: 5000.0,
            currencyCode: 'SAR',
          ),
        );

        await tester.pumpWidget(
          createTestableWidget(
            child: CustomerDetailsPage(customerId: customer.id),
            locale: const Locale('ar'),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('عميل اختبار الواجهة'), findsOneWidget);
        expect(find.text('12210040'), findsOneWidget);
      },
    );
  });
}
