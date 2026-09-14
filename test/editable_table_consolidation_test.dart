import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/discount_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_item.dart';
import 'package:stock_count/modules/sales/invoices/presentation/widgets/sale_products_table.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

void main() {
  group('Phase 2 — Editable Line-Item Table Architecture Tests', () {
    testWidgets('1. AppEditableTableShell renders empty state card and add row button', (
      WidgetTester tester,
    ) async {
      var addTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AppEditableTableShell<String>(
              items: const [],
              columns: const [
                AppEditableTableColumn(label: 'Item', width: 200),
              ],
              emptyLabel: 'الجدول فارغ',
              addLabel: 'إضافة عنصر',
              onAddRow: () => addTapped = true,
              rowCellBuilder: (context, index, item, column) => Text(item),
            ),
          ),
        ),
      );

      expect(find.text('الجدول فارغ'), findsOneWidget);
      expect(find.text('إضافة عنصر'), findsOneWidget);

      await tester.tap(find.text('إضافة عنصر'));
      expect(addTapped, isTrue);
    });

    testWidgets('2. AppEditableTableShell renders items, index column, and headers', (
      WidgetTester tester,
    ) async {
      final items = ['Product A', 'Product B'];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AppEditableTableShell<String>(
              items: items,
              columns: const [
                AppEditableTableColumn(label: 'الاسم', width: 200),
              ],
              rowCellBuilder: (context, index, item, column) => Text(item),
            ),
          ),
        ),
      );

      expect(find.text('الاسم'), findsOneWidget);
      expect(find.text('Product A'), findsOneWidget);
      expect(find.text('Product B'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('3. SaleProductsTable renders filled product rows and triggers callbacks', (
      WidgetTester tester,
    ) async {
      const items = [
        SaleItemDraft(
          productId: 'prod_1',
          productName: 'صنف أختبار 1',
          productCode: 'P01',
          mainQuantity: 2.0,
          subQuantity: 0.0,
          unitPrice: 50.0,
          baseUnitPrice: 50.0,
        ),
      ];

      var removedIndex = -1;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: SaleProductsTable(
                  items: items,
                  onProductSelected: (_) {},
                  onQuantitiesChanged: (i, main, sub) {},
                  onUnitPriceChanged: (i, price) => true,
                  minUnitPriceOf: (item) => 10.0,
                  onUnitPriceBelowMin: () {},
                  onRemove: (i) => removedIndex = i,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('صنف أختبار 1'), findsOneWidget);

      // Verify row actions removal icon button
      final deleteIcon = find.byIcon(Icons.delete_outline_rounded);
      expect(deleteIcon, findsOneWidget);
      await tester.tap(deleteIcon);
      expect(removedIndex, equals(0));
    });

    testWidgets('4. SaleProductsReadonlyTable renders items in read-only mode', (
      WidgetTester tester,
    ) async {
      final items = <SaleItem>[
        const SaleItem(
          id: '00000000-0000-0000-0000-000000000001',
          saleUuid: '00000000-0000-0000-0000-000000000010',
          productId: 'p1',
          productName: 'صنف للقراءة فقط',
          productCode: 'P100',
          quantity: 5.0,
          mainQuantity: 5.0,
          subQuantity: 0.0,
          packSize: 1,
          unitPrice: 100.0,
          baseUnitPrice: 100.0,
          discountType: DiscountType.fixed,
          discountValue: 0.0,
          discountAmount: 0.0,
          taxAmount: 0.0,
          subtotal: 500.0,
          total: 500.0,
          lineOrder: 1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SaleProductsReadonlyTable(items: items),
            ),
          ),
        ),
      );

      expect(find.text('صنف للقراءة فقط'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    });
  });
}
