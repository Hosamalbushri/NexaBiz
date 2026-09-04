import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/inventory/stock_movements/presentation/widgets/stock_posting_error_dialog.dart';

void main() {
  group('StockPostingErrorDetails Taxonomy & Formatting', () {
    testWidgets('classifies unconfigured account role error into configuration category with setup action', (tester) async {
      late StockPostingErrorDetails details;

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/settings/setup': (context) => const Scaffold(body: Text('Setup Screen')),
          },
          home: Builder(
            builder: (context) {
              details = StockPostingErrorDetails.fromReason(
                context: context,
                reason: 'خطأ محاسبي: لم يتم إعداد حساب (الموردين / الحسابات الدائنة) لتهيئة الشركة. يرجى ربط الحسابات المحاسبية من التهيئة المحاسبية أولاً.',
              );
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showStockPostingErrorDialog(
                    context,
                    title: details.title,
                    message: details.message,
                    subtitle: details.subtitle,
                    category: details.category,
                    actionLabel: details.actionLabel,
                    onAction: details.onAction,
                  ),
                  child: const Text('Show Dialog'),
                ),
              );
            },
          ),
        ),
      );

      expect(details.category, equals(StockPostingErrorCategory.configuration));
      expect(details.title, equals('التهيئة المحاسبية غير مكتملة'));
      expect(details.actionLabel, equals('الذهاب للتهيئة المحاسبية'));

      // Tap to open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('التهيئة المحاسبية غير مكتملة'), findsOneWidget);
      expect(find.textContaining('الموردين / الحسابات الدائنة'), findsOneWidget);
      expect(find.text('الذهاب للتهيئة المحاسبية'), findsOneWidget);

      // Tap action button -> navigates to /settings/setup
      await tester.tap(find.text('الذهاب للتهيئة المحاسبية'));
      await tester.pumpAndSettle();

      expect(find.text('Setup Screen'), findsOneWidget);
    });

    testWidgets('classifies zero cost error into zeroCost category with edit action', (tester) async {
      late StockPostingErrorDetails details;
      bool editRequested = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              details = StockPostingErrorDetails.fromReason(
                context: context,
                reason: 'لا يمكن ترحيل المستند بتكلفة صفرية للصنف (حاسوب محمول). يرجى إدخال التكلفة أولاً.',
                onEditRequested: () => editRequested = true,
              );
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showStockPostingErrorDialog(
                    context,
                    title: details.title,
                    message: details.message,
                    subtitle: details.subtitle,
                    category: details.category,
                    actionLabel: details.actionLabel,
                    onAction: details.onAction,
                  ),
                  child: const Text('Show Cost Error'),
                ),
              );
            },
          ),
        ),
      );

      expect(details.category, equals(StockPostingErrorCategory.zeroCost));
      expect(details.title, equals('تكلفة أصناف غير مكتملة'));
      expect(details.actionLabel, equals('تعديل المستند'));

      await tester.tap(find.text('Show Cost Error'));
      await tester.pumpAndSettle();

      expect(find.text('تكلفة أصناف غير مكتملة'), findsOneWidget);
      expect(find.textContaining('تكلفة صفرية للصنف'), findsOneWidget);

      await tester.tap(find.text('تعديل المستند'));
      await tester.pumpAndSettle();

      expect(editRequested, isTrue);
    });

    testWidgets('classifies closed accounting period error', (tester) async {
      late StockPostingErrorDetails details;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              details = StockPostingErrorDetails.fromReason(
                context: context,
                reason: 'لا يمكن ترحيل المستند: الفترة المحاسبية مغلقة للمستند بتاريخ 2026-01-01',
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(details.category, equals(StockPostingErrorCategory.closedPeriod));
      expect(details.title, equals('الفترة المحاسبية مغلقة'));
    });

    testWidgets('classifies uninitialized company guard errors including primary warehouse and completion flag', (tester) async {
      late StockPostingErrorDetails details;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              details = StockPostingErrorDetails.fromReason(
                context: context,
                reason: 'فشل الترحيل: لم يتم تهيئة المستودع الرئيسي. يرجى إكمال إعدادات التهيئة أولاً.',
              );
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showStockPostingErrorDialog(
                    context,
                    title: details.title,
                    message: details.message,
                    subtitle: details.subtitle,
                    category: details.category,
                    actionLabel: details.actionLabel,
                    onAction: details.onAction,
                  ),
                  child: const Text('Show Uninitialized Error'),
                ),
              );
            },
          ),
        ),
      );

      expect(details.category, equals(StockPostingErrorCategory.configuration));
      expect(details.title, equals('التهيئة المحاسبية غير مكتملة'));
      expect(details.actionLabel, equals('الذهاب للتهيئة المحاسبية'));

      await tester.tap(find.text('Show Uninitialized Error'));
      await tester.pumpAndSettle();

      expect(find.text('التهيئة المحاسبية غير مكتملة'), findsOneWidget);
      expect(find.textContaining('المستودع الرئيسي'), findsOneWidget);
    });

    testWidgets('classifies missing company profile requirement error into configuration category', (tester) async {
      late StockPostingErrorDetails details;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              details = StockPostingErrorDetails.fromReason(
                context: context,
                reason: 'فشل الترحيل: لم يتم إنشاء ملف بيانات الشركة. يرجى إكمال إعدادات التهيئة أولاً.',
              );
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showStockPostingErrorDialog(
                    context,
                    title: details.title,
                    message: details.message,
                    subtitle: details.subtitle,
                    category: details.category,
                    actionLabel: details.actionLabel,
                    onAction: details.onAction,
                  ),
                  child: const Text('Show Profile Error'),
                ),
              );
            },
          ),
        ),
      );

      expect(details.category, equals(StockPostingErrorCategory.configuration));
      expect(details.title, equals('التهيئة المحاسبية غير مكتملة'));

      await tester.tap(find.text('Show Profile Error'));
      await tester.pumpAndSettle();

      expect(find.textContaining('بيانات الشركة'), findsOneWidget);
    });

    testWidgets('renders dialog actions cleanly without overflow on narrow width constraint (280px)', (tester) async {
      tester.view.physicalSize = const Size(280 * 2.0, 600 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final details = StockPostingErrorDetails.fromReason(
                context: context,
                reason: 'فشل الترحيل: التهيئة الأولية للنظام غير مكتملة. لم يتم إنشاء ملف بيانات الشركة.',
              );
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => showStockPostingErrorDialog(
                    context,
                    title: details.title,
                    message: details.message,
                    subtitle: details.subtitle,
                    category: details.category,
                    actionLabel: details.actionLabel,
                    onAction: details.onAction,
                  ),
                  child: const Text('Show Dialog'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('إغلاق'), findsOneWidget);
      expect(find.text('الذهاب للتهيئة المحاسبية'), findsOneWidget);
    });
  });
}
