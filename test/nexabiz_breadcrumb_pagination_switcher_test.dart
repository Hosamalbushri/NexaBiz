import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'package:nexabiz_ui/nexabiz_ui.dart';

void main() {
  Widget buildTestApp(Widget child) {
    return shadcn.ShadcnApp(
      home: shadcn.Scaffold(
        child: child,
      ),
    );
  }

  group('AppBreadcrumb Behavioral Tests', () {
    testWidgets('renders breadcrumb items and triggers navigation callback', (tester) async {
      bool homeTapped = false;

      await tester.pumpWidget(
        buildTestApp(
          AppBreadcrumb(
            items: [
              AppBreadcrumbItem(
                label: 'Home',
                onTap: () {
                  homeTapped = true;
                },
              ),
              const AppBreadcrumbItem(
                label: 'Products',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(homeTapped, isTrue);
    });
  });

  group('AppPaginationBar Behavioral Tests', () {
    testWidgets('translates 0-based index to shadcn 1-based Pagination and triggers onPageChanged', (tester) async {
      int activePage = 0;

      await tester.pumpWidget(
        buildTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              return AppPaginationBar(
                page: activePage,
                totalPages: 5,
                totalCount: 50,
                pageSize: 10,
                onPageChanged: (newPage) {
                  setState(() {
                    activePage = newPage;
                  });
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(shadcn.Pagination), findsOneWidget);

      // Tap on page 2 button in pagination bar
      final page2Finder = find.text('2');
      expect(page2Finder, findsOneWidget);

      await tester.tap(page2Finder);
      await tester.pumpAndSettle();

      expect(activePage, equals(1)); // 0-based page 1 = page 2
    });
  });

  group('AppContentSwitcher Behavioral Tests', () {
    testWidgets('renders current index child and clamps out-of-bound indexes safely', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppContentSwitcher(
            index: 1,
            children: [
              Text('Child Zero'),
              Text('Child One'),
              Text('Child Two'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Child One'), findsOneWidget);

      // Verify out-of-bounds index is clamped safely
      await tester.pumpWidget(
        buildTestApp(
          const AppContentSwitcher(
            index: 99,
            children: [
              Text('Child Zero'),
              Text('Child One'),
              Text('Child Two'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Child Two'), findsOneWidget);
    });
  });
}
