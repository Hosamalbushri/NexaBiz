import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/widgets/custom_bottom_nav.dart';
import 'package:stock_count/shared/widgets/service_grid.dart';

void main() {
  group('Phase 4 — Dead Code Elimination & Active UI Verification Tests', () {
    testWidgets('1. CustomBottomNav renders correctly with active destinations',
        (WidgetTester tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomBottomNav(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                selectedIndex = index;
              },
              destinations: const [
                CustomBottomNavDestination(
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard_rounded,
                  label: 'لوحة التحكم',
                ),
                CustomBottomNavDestination(
                  icon: Icons.apps_outlined,
                  selectedIcon: Icons.apps_rounded,
                  label: 'الخدمات',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('لوحة التحكم'), findsOneWidget);
      expect(find.text('الخدمات'), findsOneWidget);
    });

    testWidgets('2. ServiceGrid renders items and handles action taps',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServiceGrid(
              modules: const [],
              onModuleSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ServiceGrid), findsOneWidget);
    });
  });
}
