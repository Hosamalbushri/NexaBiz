import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

void main() {
  Widget buildTestApp(Widget child) {
    return MaterialApp(
      home: shadcn.Theme(
        data: const shadcn.ThemeData(),
        child: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('Shadcn Data Context Integration Tests', () {
    testWidgets('Test 1 — Data propagation: Deep child receives AppFormConfiguration', (tester) async {
      AppFormConfiguration? capturedConfig;

      await tester.pumpWidget(
        buildTestApp(
          AppForm(
            isSubmitting: true,
            spacing: 24,
            children: [
              Container(
                child: Builder(
                  builder: (context) {
                    capturedConfig = shadcn.Data.maybeOf<AppFormConfiguration>(context);
                    return Text('Child: ${capturedConfig?.isSubmitting}');
                  },
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(capturedConfig, isNotNull);
      expect(capturedConfig!.isSubmitting, isTrue);
      expect(capturedConfig!.enabled, isFalse);
      expect(capturedConfig!.spacing, equals(24));
      expect(find.text('Child: true'), findsOneWidget);
    });

    testWidgets('Test 2 — Intermediate widgets: Props-free container does not block lookup', (tester) async {
      AppFormConfiguration? capturedConfig;

      await tester.pumpWidget(
        buildTestApp(
          AppForm(
            isSubmitting: false,
            children: [
              // Intermediate nested structure without props
              Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Builder(
                        builder: (context) {
                          capturedConfig = shadcn.Data.maybeOf<AppFormConfiguration>(context);
                          return const Text('Deeply Nested');
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedConfig, isNotNull);
      expect(capturedConfig!.isSubmitting, isFalse);
      expect(capturedConfig!.enabled, isTrue);
    });

    testWidgets('Test 3 — Updated data: Rebuilds consumer when AppFormConfiguration changes', (tester) async {
      bool submitting = false;

      await tester.pumpWidget(
        buildTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  GestureDetector(
                    key: const ValueKey('submit_btn'),
                    onTap: () => setState(() => submitting = true),
                    child: const Text('Submit'),
                  ),
                  Expanded(
                    child: AppForm(
                      isSubmitting: submitting,
                      children: [
                        Builder(
                          builder: (ctx) {
                            final config = shadcn.Data.maybeOf<AppFormConfiguration>(ctx);
                            return Text('Status: ${config?.isSubmitting}');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Status: false'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('submit_btn')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Status: true'), findsOneWidget);
    });

    testWidgets('Test 4 — Type safety: Strong generic typing of AppFormConfiguration', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          AppForm(
            isSubmitting: false,
            children: [
              Builder(
                builder: (context) {
                  final dynamic untyped = shadcn.Data.maybeOf<AppFormConfiguration>(context);
                  expect(untyped, isA<AppFormConfiguration>());
                  expect(untyped.runtimeType, equals(AppFormConfiguration));
                  return const Text('Typed');
                },
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Typed'), findsOneWidget);
    });

    testWidgets('Test 5 — Missing context: Returns null safely outside AppForm', (tester) async {
      AppFormConfiguration? capturedConfig;

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) {
              capturedConfig = shadcn.Data.maybeOf<AppFormConfiguration>(context);
              return const Text('Outside Form');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedConfig, isNull);
      expect(find.text('Outside Form'), findsOneWidget);
    });
  });
}
