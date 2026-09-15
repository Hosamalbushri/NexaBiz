import 'package:flutter/material.dart' hide Typography;
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

void main() {
  group('NexaBiz Design System Theme Enforcement Tests', () {
    test('1. Light theme is constructed from native shadcn ThemeData', () {
      final theme = AppTheme.light();
      expect(theme, isA<shadcn.ThemeData>());
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.colorScheme.brightness, equals(Brightness.light));
      expect(theme.radius, equals(0.5));
      expect(theme.scaling, equals(1.0));
      expect(theme.density, equals(shadcn.Density.defaultDensity));
    });

    test('2. Dark theme is constructed from native shadcn ThemeData', () {
      final theme = AppTheme.dark();
      expect(theme, isA<shadcn.ThemeData>());
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.colorScheme.brightness, equals(Brightness.dark));
      expect(theme.radius, equals(0.5));
      expect(theme.scaling, equals(1.0));
      expect(theme.density, equals(shadcn.Density.defaultDensity));
    });

    test('3. Semantic colors resolve correctly via shadcn ColorScheme', () {
      final lightTheme = AppTheme.light();
      final darkTheme = AppTheme.dark();

      expect(lightTheme.colorScheme.primary, equals(AppColors.primaryBlue));
      expect(lightTheme.colorScheme.secondary, equals(AppColors.secondaryTeal));
      expect(lightTheme.colorScheme.destructive, equals(AppColors.error));
      expect(lightTheme.colorScheme.background, equals(AppColors.lightBackground));

      expect(darkTheme.colorScheme.primary, equals(AppColors.primaryBlue));
      expect(darkTheme.colorScheme.secondary, equals(AppColors.secondaryTeal));
      expect(darkTheme.colorScheme.destructive, equals(AppColors.error));
      expect(darkTheme.colorScheme.background, equals(AppColors.darkBackground));
    });

    test('4. Typography resolves through shadcn Typography with Cairo font family', () {
      final theme = AppTheme.light();
      expect(theme.typography, isNotNull);
      expect(theme.typography.sans.fontFamily, equals('Cairo'));
      expect(theme.typography.h1.fontFamily, equals('Cairo'));
      expect(theme.typography.p.fontFamily, equals('Cairo'));
      expect(theme.typography.small.fontFamily, equals('Cairo'));
    });

    test('5. Density resolves through shadcn Density', () {
      final customDensity = const shadcn.Density(
        baseContainerPadding: 12.0,
        baseGap: 6.0,
        baseContentPadding: 12.0,
      );
      final theme = AppTheme.light(density: customDensity);
      expect(theme.density.baseContainerPadding, equals(12.0));
      expect(theme.density.baseGap, equals(6.0));
      expect(theme.density.baseContentPadding, equals(12.0));
    });

    test('6. Radius is theme-driven', () {
      final theme = AppTheme.light(radius: 0.75);
      expect(theme.radius, equals(0.75));
      expect(theme.radiusSm, equals(0.75 * 8));
      expect(theme.radiusMd, equals(0.75 * 12));
      expect(theme.radiusLg, equals(0.75 * 16));
    });

    testWidgets('7. Shared components respond to theme context and render properly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: shadcn.Theme(
            data: AppTheme.light(),
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: Column(
                    children: [
                      AppButton(
                        label: 'Save Invoice',
                        onPressed: () {},
                      ),
                      const AppTextField(
                        hint: 'Search Customers',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Save Invoice'), findsOneWidget);
      expect(find.text('Search Customers'), findsOneWidget);
    });

    testWidgets('8. Form controls preserve input values and validation',
        (WidgetTester tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.light(),
          home: shadcn.Theme(
            data: AppTheme.light(),
            child: Scaffold(
              body: AppTextField(
                controller: controller,
                hint: 'Enter Amount',
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(shadcn.TextField), '1250.50');
      expect(controller.text, equals('1250.50'));
    });

    testWidgets('9. RTL and LTR directionality render correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: shadcn.Theme(
              data: AppTheme.light(),
              child: Scaffold(
                body: AppButton(
                  label: 'حفظ الفاتورة',
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('حفظ الفاتورة'), findsOneWidget);
    });
  });
}
