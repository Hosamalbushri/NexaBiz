import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/presentation/patterns/app_detail_page_pattern.dart';
import 'package:stock_count/core/presentation/patterns/app_list_page_pattern.dart';

void main() {
  group('Phase 3 — Page Pattern Standardization Tests', () {
    testWidgets('1. AppListPagePattern renders title, search bar, and empty state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AppListPagePattern<String>(
              title: 'اختبار القائمة',
              searchHint: 'بحث...',
              emptyTitle: 'لا توجد بيانات',
              emptySubtitle: 'القائمة فارغة حالياً',
              items: const [],
              contentBuilder: (context, items) => Column(
                children: items.map(Text.new).toList(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('اختبار القائمة'), findsOneWidget);
      expect(find.text('لا توجد بيانات'), findsOneWidget);
    });

    testWidgets('2. AppDetailPagePattern renders header, summary banner, and surface cards', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AppDetailPagePattern(
              title: 'تفاصيل العميل',
              summaryBanner: const Chip(label: Text('نشط')),
              body: const Card(child: Text('معلومات إضافية')),
            ),
          ),
        ),
      );

      expect(find.text('تفاصيل العميل'), findsOneWidget);
      expect(find.text('نشط'), findsOneWidget);
      expect(find.text('معلومات إضافية'), findsOneWidget);
    });
  });
}
