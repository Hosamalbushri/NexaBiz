import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

void main() {
  group('AppTheme Tests', () {
    test('AppTheme light and dark return valid shadcn ThemeData', () {
      final lightTheme = AppTheme.light();
      final darkTheme = AppTheme.dark();

      expect(lightTheme, isNotNull);
      expect(darkTheme, isNotNull);
      expect(lightTheme.colorScheme.primary, equals(AppColors.primaryBlue));
      expect(darkTheme.colorScheme.primary, equals(AppColors.primaryBlue));
    });

    test('AppTheme material themes preserve ERP colors and typography', () {
      final matLight = AppTheme.materialLight();
      final matDark = AppTheme.materialDark();

      expect(matLight.colorScheme.primary, equals(AppColors.primaryBlue));
      expect(matDark.colorScheme.primary, equals(AppColors.primaryBlue));
    });
  });

  group('NexaBiz UI Component Widgets Test', () {
    testWidgets('AppButton renders label and triggers callback', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: AppButton(
              label: 'Save Invoice',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Save Invoice'), findsOneWidget);
      await tester.tap(find.text('Save Invoice'));
      expect(pressed, isTrue);
    });

    testWidgets('AppTextField renders placeholder and receives text', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              hint: 'Enter Customer Name',
            ),
          ),
        ),
      );

      expect(find.text('Enter Customer Name'), findsOneWidget);
      await tester.enterText(find.byType(shadcn.TextField), 'NexaBiz Corporation');
      expect(controller.text, equals('NexaBiz Corporation'));
    });

    testWidgets('AppPaginationBar renders page numbers and page-size selector', (tester) async {
      int currentPage = 0;
      int selectedSize = 10;

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: AppPaginationBar(
              page: currentPage,
              totalPages: 5,
              totalCount: 50,
              pageSize: selectedSize,
              pageSizeOptions: const [10, 25, 50],
              onPageChanged: (p) => currentPage = p,
              onPageSizeChanged: (s) => selectedSize = s,
            ),
          ),
        ),
      );

      expect(find.byType(AppPaginationBar), findsOneWidget);
      expect(find.byType(shadcn.Pagination), findsOneWidget);
      expect(find.byType(shadcn.Select<int>), findsOneWidget);
    });

    testWidgets('AppPageHeader renders title, subtitle, and breadcrumbs', (tester) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: AppPageHeader(
              title: 'General Ledger',
              subtitle: 'Chart of Accounts Overview',
              breadcrumbs: ['Finance', 'General Ledger'],
            ),
          ),
        ),
      );

      expect(find.text('General Ledger'), findsNWidgets(2));
      expect(find.text('Chart of Accounts Overview'), findsOneWidget);
      expect(find.text('Finance'), findsOneWidget);
    });
  });
}
