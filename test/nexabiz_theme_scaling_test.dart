import 'package:flutter/material.dart' hide ThemeData, Theme, ColorScheme;
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

void main() {
  Widget buildTestApp(
    Widget child, {
    shadcn.ThemeData? theme,
    shadcn.ThemeData? darkTheme,
    shadcn.ThemeMode themeMode = shadcn.ThemeMode.light,
    shadcn.AdaptiveScaling? scaling,
  }) {
    return shadcn.ShadcnApp(
      theme: theme ?? AppTheme.shadcnLight(),
      darkTheme: darkTheme ?? AppTheme.shadcnDark(),
      themeMode: themeMode,
      scaling: scaling,
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('Shadcn Theme & Scaling Foundation Behavioral Tests', () {
    testWidgets('Test 1 — Theme Context Propagation: Theme.of(context) retrieves shadcn theme', (tester) async {
      shadcn.ThemeData? capturedTheme;

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) {
              capturedTheme = shadcn.Theme.of(context);
              return Text('Theme Captured', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedTheme, isNotNull);
      expect(capturedTheme!.colorScheme.brightness, equals(Brightness.light));
      expect(capturedTheme!.colorScheme.primary, isNotNull);
    });

    testWidgets('Test 2 — Radius Inheritance: AppRadii delegates to Theme.of(context)', (tester) async {
      double? capturedRadiusSm;
      BorderRadius? capturedBorderRadiusMd;
      shadcn.ThemeData? themeInContext;

      await tester.pumpWidget(
        buildTestApp(
          theme: AppTheme.shadcnLight(radius: 0.8),
          Builder(
            builder: (context) {
              themeInContext = shadcn.Theme.of(context);
              capturedRadiusSm = AppRadii.smOf(context);
              capturedBorderRadiusMd = AppRadii.borderRadiusMdOf(context);
              return Container();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedRadiusSm, equals(themeInContext!.radiusSm));
      expect(capturedBorderRadiusMd, equals(themeInContext!.borderRadiusMd));
    });

    testWidgets('Test 3 — Light / Dark ColorScheme Switching: Mode updates background and text colors', (tester) async {
      shadcn.ColorScheme? lightScheme;
      shadcn.ColorScheme? darkScheme;

      await tester.pumpWidget(
        buildTestApp(
          themeMode: shadcn.ThemeMode.light,
          Builder(
            builder: (context) {
              lightScheme = AppColors.colorSchemeOf(context);
              return Container();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        buildTestApp(
          themeMode: shadcn.ThemeMode.dark,
          Builder(
            builder: (context) {
              darkScheme = AppColors.colorSchemeOf(context);
              return Container();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(lightScheme, isNotNull);
      expect(darkScheme, isNotNull);
      expect(lightScheme!.brightness, equals(Brightness.light));
      expect(darkScheme!.brightness, equals(Brightness.dark));
      expect(lightScheme!.background, isNot(equals(darkScheme!.background)));
    });

    testWidgets('Test 4 — Scaling Behavior: AdaptiveScaling scales radius and typography', (tester) async {
      shadcn.ThemeData? capturedScaledTheme;

      await tester.pumpWidget(
        buildTestApp(
          scaling: const shadcn.AdaptiveScaling(1.5),
          Builder(
            builder: (context) {
              capturedScaledTheme = shadcn.Theme.of(context);
              return Container();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedScaledTheme, isNotNull);
      expect(capturedScaledTheme!.scaling, equals(1.5));
      expect(capturedScaledTheme!.radiusSm, equals(0.5 * 8 * 1.5));
    });

    testWidgets('Test 5 — Surface Opacity & Blur: ThemeData propagates surface properties', (tester) async {
      shadcn.ThemeData? capturedTheme;

      await tester.pumpWidget(
        buildTestApp(
          theme: AppTheme.shadcnLight(surfaceOpacity: 0.85, surfaceBlur: 6.0),
          Builder(
            builder: (context) {
              capturedTheme = shadcn.Theme.of(context);
              return Container();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedTheme, isNotNull);
      expect(capturedTheme!.surfaceOpacity, equals(0.85));
      expect(capturedTheme!.surfaceBlur, equals(6.0));
    });
  });
}
