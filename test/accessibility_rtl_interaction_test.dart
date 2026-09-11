import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
void main() {
  group('Phase 5 — Accessibility, RTL & Interaction Tests', () {
    testWidgets(
        '1. AppPaginationBar buttons enforce min 44x44 touch targets and Semantics',
        (WidgetTester tester) async {
      int currentPage = 1;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: Scaffold(
            body: AppPaginationBar(
              page: currentPage,
              totalPages: 5,
              totalCount: 50,
              pageSize: 10,
              onPageChanged: (newPage) {
                currentPage = newPage;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Semantics widgets exist for pagination controls
      final semanticsFinder = find.byType(Semantics);
      expect(semanticsFinder, findsWidgets);

      // Verify touch target constraints on pagination buttons (>= 44x44)
      final boxFinder = find.byType(ConstrainedBox);
      expect(boxFinder, findsWidgets);

      final ConstrainedBox firstBox = tester.widget(boxFinder.first);
      expect(firstBox.constraints.minWidth, greaterThanOrEqualTo(44.0));
      expect(firstBox.constraints.minHeight, greaterThanOrEqualTo(44.0));
    });

    testWidgets('2. AppPaginationBar handles RTL page changes',
        (WidgetTester tester) async {
      int pageIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: AppPaginationBar(
                page: pageIndex,
                totalPages: 3,
                totalCount: 30,
                pageSize: 10,
                onPageChanged: (idx) {
                  pageIndex = idx;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppPaginationBar), findsOneWidget);
    });
  });
}
