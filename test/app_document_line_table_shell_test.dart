import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/widgets/app_document_line_table_shell.dart';

void main() {
  group('AppDocumentLineTableShell Widget Tests', () {
    testWidgets('renders rows and index column correctly', (WidgetTester tester) async {
      final items = ['Item 1', 'Item 2', 'Item 3'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDocumentLineTableShell<String>(
              items: items,
              rowBuilder: (context, index, item) => Text(item),
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('renders empty state when items list is empty and calls onAddRow', (WidgetTester tester) async {
      var addCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDocumentLineTableShell<String>(
              items: const [],
              rowBuilder: (context, index, item) => Text(item),
              onAddRow: () {
                addCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('إضافة سطر جديد'), findsOneWidget);
      await tester.tap(find.text('إضافة سطر جديد'));
      expect(addCalled, isTrue);
    });
  });
}
