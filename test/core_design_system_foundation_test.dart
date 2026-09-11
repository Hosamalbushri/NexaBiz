import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'package:stock_count/app/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSurface Widget Test Suite', () {
    testWidgets('AppSurface renders child and respects variants & onTap', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSurface(
              variant: AppSurfaceVariant.outlined,
              onTap: () {
                tapped = true;
              },
              child: const Text('Surface Content'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Surface Content'), findsOneWidget);

      await tester.tap(find.text('Surface Content'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(tapped, isTrue);
    });

    testWidgets('AppSurface applies flat and raised variants', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppSurface(
                  variant: AppSurfaceVariant.flat,
                  child: Text('Flat Surface'),
                ),
                AppSurface(
                  variant: AppSurfaceVariant.raised,
                  child: Text('Raised Surface'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Flat Surface'), findsOneWidget);
      expect(find.text('Raised Surface'), findsOneWidget);
    });
  });

  group('AppButton Enhanced Test Suite', () {
    testWidgets(
      'AppButton renders destructive variant and handles tap & loading',
      (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          shadcn.ShadcnApp(
            theme: AppTheme.shadcnLight(),
            home: Scaffold(
              body: AppButton(
                label: 'حذف العنصر',
                variant: AppButtonVariant.destructive,
                onPressed: () {
                  tapped = true;
                },
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.text('حذف العنصر'), findsOneWidget);

        await tester.tap(find.text('حذف العنصر'));
        await tester.pump(const Duration(milliseconds: 250));

        expect(tapped, isTrue);
      },
    );

    testWidgets('AppButton handles compact height constraint', (tester) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.shadcnLight(),
          home: Scaffold(
            body: AppButton(
              label: 'زر مدمج',
              isCompact: true,
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      final box = tester.getRect(find.byType(AppButton));
      expect(box.height, equals(AppDimensions.buttonHeightCompact));
    });

    testWidgets('AppButton prevents tap when isLoading is true', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.shadcnLight(),
          home: Scaffold(
            body: AppButton(
              label: 'حفظ',
              isLoading: true,
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(shadcn.CircularProgressIndicator), findsOneWidget);
      expect(tapped, isFalse);
    });
  });

  group('AppIconButton Test Suite', () {
    testWidgets('AppIconButton renders icon, tooltip, and handles onPressed', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.shadcnLight(),
          home: Scaffold(
            body: AppIconButton(
              icon: Icons.add,
              tooltip: 'إضافة',
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('AppIconButton enforces WCAG 48px minimum touch target', (
      tester,
    ) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.shadcnLight(),
          home: Scaffold(
            body: AppIconButton(
              icon: Icons.edit,
              onPressed: () {},
            ),
          ),
        ),
      );

      final box = tester.getRect(find.byType(AppIconButton));
      expect(box.width, greaterThanOrEqualTo(AppDimensions.minTouchTarget));
      expect(box.height, greaterThanOrEqualTo(AppDimensions.minTouchTarget));
    });

    testWidgets('AppIconButton renders badge count when badgeCount > 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.shadcnLight(),
          home: Scaffold(
            body: AppIconButton(
              icon: Icons.notifications,
              badgeCount: 5,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });
  });
}

