import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

void main() {
  Widget buildTestableWidget(Widget child, {TextDirection textDirection = TextDirection.rtl}) {
    return shadcn.ShadcnApp(
      theme: AppTheme.light(),
      home: Directionality(
        textDirection: textDirection,
        child: child,
      ),
    );
  }

  group('NexaBiz Canonical Layout System Hardening Tests', () {
    testWidgets('AppPage renders scrollable body correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AppPage(
            header: Text('Page Header'),
            child: Text('Page Child'),
          ),
        ),
      );

      expect(find.text('Page Header'), findsOneWidget);
      expect(find.text('Page Child'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('AppPage renders non-scrollable body without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AppPage(
            scrollable: false,
            header: Text('Fixed Header'),
            child: Column(
              children: [
                Expanded(child: Text('Expanded Content')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Fixed Header'), findsOneWidget);
      expect(find.text('Expanded Content'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    testWidgets('AppConstraints apply correct max widths', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Column(
            children: [
              AppContentConstraint(child: Text('Content')),
              AppFormConstraint(child: Text('Form')),
              AppTableConstraint(child: Text('Table')),
              AppDashboardConstraint(child: Text('Dashboard')),
              AppDetailsConstraint(child: Text('Details')),
              AppSettingsConstraint(child: Text('Settings')),
            ],
          ),
        ),
      );

      final contentBox = tester.widget<ConstrainedBox>(
        find.ancestor(of: find.text('Content'), matching: find.byType(ConstrainedBox)).first,
      );
      final formBox = tester.widget<ConstrainedBox>(
        find.ancestor(of: find.text('Form'), matching: find.byType(ConstrainedBox)).first,
      );
      final tableBox = tester.widget<ConstrainedBox>(
        find.ancestor(of: find.text('Table'), matching: find.byType(ConstrainedBox)).first,
      );
      final dashboardBox = tester.widget<ConstrainedBox>(
        find.ancestor(of: find.text('Dashboard'), matching: find.byType(ConstrainedBox)).first,
      );
      final detailsBox = tester.widget<ConstrainedBox>(
        find.ancestor(of: find.text('Details'), matching: find.byType(ConstrainedBox)).first,
      );
      final settingsBox = tester.widget<ConstrainedBox>(
        find.ancestor(of: find.text('Settings'), matching: find.byType(ConstrainedBox)).first,
      );

      expect(contentBox.constraints.maxWidth, equals(AppLayoutTokens.maxPageWidth));
      expect(formBox.constraints.maxWidth, equals(AppLayoutTokens.maxFormWidth));
      expect(tableBox.constraints.maxWidth, equals(AppLayoutTokens.maxTableWidth));
      expect(dashboardBox.constraints.maxWidth, equals(AppLayoutTokens.maxDashboardWidth));
      expect(detailsBox.constraints.maxWidth, equals(AppLayoutTokens.maxDetailsWidth));
      expect(settingsBox.constraints.maxWidth, equals(AppLayoutTokens.maxSettingsWidth));
    });

    testWidgets('AppTablePage renders table state', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AppTablePage(
            title: 'Ledger Table',
            table: const Text('Table Content'),
          ),
        ),
      );
      expect(find.text('Ledger Table'), findsOneWidget);
      expect(find.text('Table Content'), findsOneWidget);
    });

    testWidgets('AppTablePage renders loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AppTablePage(
            title: 'Ledger Table',
            isLoading: true,
            table: const Text('Table Content'),
          ),
        ),
      );
      expect(find.byType(AppLoading), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('AppTablePage renders error state', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AppTablePage(
            title: 'Ledger Table',
            errorText: 'Failed to fetch ledger rows',
            table: const Text('Table Content'),
          ),
        ),
      );
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('Failed to fetch ledger rows'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('AppTablePage renders empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AppTablePage(
            title: 'Ledger Table',
            isEmpty: true,
            table: const Text('Table Content'),
          ),
        ),
      );
      expect(find.byType(AppEmptyState), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('AppFormPage handles page loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AppFormPage(
            title: 'Customer Form',
            isPageLoading: true,
            body: const Text('Form Body'),
            onSubmit: () {},
          ),
        ),
      );
      expect(find.byType(AppLoading), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('AppFormPage handles page error state', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AppFormPage(
            title: 'Customer Form',
            errorText: 'Could not load customer data',
            body: const Text('Form Body'),
            onSubmit: () {},
          ),
        ),
      );
      expect(find.byType(AppErrorState), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('AppGrid adjusts columns dynamically based on breakpoints', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        buildTestableWidget(
          const AppGrid(
            compactColumns: 1,
            mediumColumns: 2,
            children: [Text('Item 1'), Text('Item 2')],
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
