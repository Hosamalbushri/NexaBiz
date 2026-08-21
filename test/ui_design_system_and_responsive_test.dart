import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/theme/app_breakpoints.dart';
import 'package:stock_count/core/widgets/app_amount_field.dart';
import 'package:stock_count/core/widgets/app_data_table.dart';
import 'package:stock_count/core/widgets/app_responsive.dart';

void main() {
  group('AppBreakpoints Tests', () {
    test('Correctly identifies compact, medium, and expanded tiers', () {
      expect(AppBreakpoints.getTier(390), AppBreakpointTier.compact);
      expect(AppBreakpoints.getTier(800), AppBreakpointTier.medium);
      expect(AppBreakpoints.getTier(1280), AppBreakpointTier.expanded);

      expect(AppBreakpoints.isMobile(390), isTrue);
      expect(AppBreakpoints.isTablet(800), isTrue);
      expect(AppBreakpoints.isDesktop(1280), isTrue);
    });
  });

  group('AppResponsiveLayout Widget Tests', () {
    testWidgets('Renders mobile widget when width < 600', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: AppResponsiveLayout(
            mobile: (_) => const Text('Mobile Layout'),
            tablet: (_) => const Text('Tablet Layout'),
            desktop: (_) => const Text('Desktop Layout'),
          ),
        ),
      );

      expect(find.text('Mobile Layout'), findsOneWidget);
      expect(find.text('Desktop Layout'), findsNothing);
    });

    testWidgets('Renders desktop widget when width >= 1000', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: AppResponsiveLayout(
            mobile: (_) => const Text('Mobile Layout'),
            tablet: (_) => const Text('Tablet Layout'),
            desktop: (_) => const Text('Desktop Layout'),
          ),
        ),
      );

      expect(find.text('Desktop Layout'), findsOneWidget);
    });
  });

  group('AppDataTable Responsive Behavior Tests', () {
    testWidgets('Renders card list on mobile and DataTable on desktop', (tester) async {
      final items = ['Item A', 'Item B'];

      // Mobile
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDataTable<String>(
              items: items,
              columns: const [DataColumn(label: Text('Name'))],
              rowBuilder: (item) => DataRow(cells: [DataCell(Text(item))]),
              cardBuilder: (_, item) => Text('Card: $item'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Card: Item A'), findsOneWidget);
      expect(find.byType(DataTable), findsNothing);

      // Desktop
      tester.view.physicalSize = const Size(1200, 800);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDataTable<String>(
              items: items,
              columns: const [DataColumn(label: Text('Name'))],
              rowBuilder: (item) => DataRow(cells: [DataCell(Text(item))]),
              cardBuilder: (_, item) => Text('Card: $item'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DataTable), findsOneWidget);

      addTearDown(tester.view.reset);
    });
  });

  group('AppAmountField Financial Formatting Tests', () {
    testWidgets('Formats thousands separator correctly', (tester) async {
      var val = 1250000.5;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppAmountField(
              value: val,
              onChanged: (v) => val = v,
              decimalPlaces: 2,
              trimTrailingZeros: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1,250,000.50'), findsOneWidget);
    });
  });
}


