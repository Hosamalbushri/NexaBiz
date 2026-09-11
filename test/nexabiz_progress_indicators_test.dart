import 'package:flutter/material.dart' hide CircularProgressIndicator, LinearProgressIndicator;
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

void main() {
  Widget buildTestableWidget(Widget child) {
    return shadcn.ShadcnApp(
      home: shadcn.Scaffold(
        child: child,
      ),
    );
  }

  group('Progress Indicators - shadcn Primitives Behavioral Tests', () {
    testWidgets('CircularProgressIndicator renders determinate value arc', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const shadcn.CircularProgressIndicator(
            value: 0.75,
            size: 32.0,
          ),
        ),
      );

      expect(find.byType(shadcn.CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('CircularProgressIndicator renders indeterminate spinning mode when value is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const shadcn.CircularProgressIndicator(
            value: null,
          ),
        ),
      );

      expect(find.byType(shadcn.CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('LinearProgressIndicator renders determinate bar and responds to lerp transitions', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const shadcn.LinearProgressIndicator(
            value: 0.4,
            showSparks: true,
          ),
        ),
      );

      expect(find.byType(shadcn.LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('Progress normalizes range between min and max correctly', (WidgetTester tester) async {
      const progressWidget = shadcn.Progress(
        progress: 50,
        min: 0,
        max: 100,
      );

      expect(progressWidget.normalizedValue, equals(0.5));

      await tester.pumpWidget(
        buildTestableWidget(progressWidget),
      );

      expect(find.byType(shadcn.Progress), findsOneWidget);
      expect(find.byType(shadcn.LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('Progress returns null normalizedValue for indeterminate state', (WidgetTester tester) async {
      const progressWidget = shadcn.Progress(
        progress: null,
      );

      expect(progressWidget.normalizedValue, isNull);

      await tester.pumpWidget(
        buildTestableWidget(progressWidget),
      );

      expect(find.byType(shadcn.Progress), findsOneWidget);
    });
  });

  group('AppLoading Level 2 Composition Tests', () {
    testWidgets('AppLoading circular style renders label and shadcn.CircularProgressIndicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AppLoading(
            style: AppLoadingStyle.circular,
            message: 'Syncing ledger...',
            progress: 0.6,
          ),
        ),
      );

      expect(find.text('Syncing ledger...'), findsOneWidget);
      expect(find.byType(shadcn.CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AppLoading linear style renders label and shadcn.Progress', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AppLoading(
            style: AppLoadingStyle.linear,
            message: 'Importing products...',
            progress: 0.85,
          ),
        ),
      );

      expect(find.text('Importing products...'), findsOneWidget);
      expect(find.byType(shadcn.Progress), findsOneWidget);
      expect(find.byType(shadcn.LinearProgressIndicator), findsOneWidget);
    });
  });
}
