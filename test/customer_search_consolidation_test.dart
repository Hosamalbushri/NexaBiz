import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/widgets/app_customer_search_field.dart';
import 'package:stock_count/modules/sales/invoices/presentation/widgets/sale_customer_search_field.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_customer_lookup_port.dart';
import 'package:stock_count/modules/sales/invoices/presentation/providers/sale_providers.dart';

class FakeSaleCustomerLookupPort implements SaleCustomerLookupPort {
  FakeSaleCustomerLookupPort(this.customers);

  final List<SaleCustomerRef> customers;

  @override
  Future<SaleCustomerRef?> findById(String customerId) async {
    try {
      return customers.firstWhere((c) => c.customerId == customerId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<SaleCustomerRef>> search(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return const [];
    final q = query.trim().toLowerCase();
    return customers
        .where((c) => c.name.toLowerCase().contains(q))
        .take(limit)
        .toList();
  }

  @override
  Future<SaleCustomerRef> ensureAccountLinked(SaleCustomerRef customer) async {
    return customer;
  }
}

void main() {
  const c1 = SaleCustomerRef(
    customerId: 'c-101',
    customerCode: 'C101',
    name: 'مؤسسة الأمل التجارية',
    phone: '0501234567',
  );
  const c2 = SaleCustomerRef(
    customerId: 'c-102',
    customerCode: 'C102',
    name: 'شركة النور للمقاولات',
    phone: '0559876543',
  );

  late FakeSaleCustomerLookupPort fakeLookup;

  setUp(() {
    fakeLookup = FakeSaleCustomerLookupPort([c1, c2]);
  });

  group('Phase 1C: Customer Search Consolidation Tests', () {
    testWidgets('1. Canonical AppCustomerSearchField executes async search and selection', (tester) async {
      SaleCustomerRef? selected;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AppCustomerSearchField<SaleCustomerRef>(
              label: 'عميل',
              fetchOptions: (q) => fakeLookup.search(q),
              itemLabelBuilder: (c) => c.name,
              onSelected: (c) => selected = c,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final input = find.byType(TextField);
      expect(input, findsOneWidget);

      await tester.enterText(input, 'الأمل');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('مؤسسة الأمل التجارية'), findsWidgets);

      await tester.tap(find.text('مؤسسة الأمل التجارية').first);
      await tester.pumpAndSettle();

      expect(selected, c1);
    });

    testWidgets('2. SaleCustomerSearchField wrapper resolves options via Riverpod saleCustomerLookupPortProvider', (tester) async {
      SaleCustomerRef? selectedCustomer;
      String? queryText;
      var canceled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            saleCustomerLookupPortProvider.overrideWithValue(fakeLookup),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SaleCustomerSearchField(
                onCustomerSelected: (c) => selectedCustomer = c,
                onQueryChanged: (q) => queryText = q,
                onCancel: () => canceled = true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final input = find.byType(TextField);
      expect(input, findsOneWidget);

      await tester.enterText(input, 'النور');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('شركة النور للمقاولات'), findsWidgets);
      expect(find.text('0559876543'), findsOneWidget);

      await tester.tap(find.text('شركة النور للمقاولات').first);
      await tester.pumpAndSettle();

      expect(selectedCustomer, c2);
      expect(queryText, 'شركة النور للمقاولات');

      // Test cancel button
      final closeIcon = find.byIcon(Icons.close_rounded);
      expect(closeIcon, findsOneWidget);
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();

      expect(canceled, isTrue);
    });
  });
}
