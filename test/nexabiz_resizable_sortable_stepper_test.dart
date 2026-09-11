import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

void main() {
  Widget buildTestableWidget(Widget child) {
    return shadcn.ShadcnApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('AppSplitView Behavioral Tests', () {
    testWidgets('renders master and detail panes horizontally', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AppSplitView(
            initialMasterWidth: 250,
            master: Text('Master Content'),
            detail: Text('Detail Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Master Content'), findsOneWidget);
      expect(find.text('Detail Content'), findsOneWidget);
    });
  });

  group('AppSortableList<T> Behavioral Tests', () {
    testWidgets('renders all items in list with stable keys', (tester) async {
      final items = ['Item A', 'Item B', 'Item C'];

      await tester.pumpWidget(
        buildTestableWidget(
          AppSortableList<String>(
            items: items,
            itemKey: (item) => ValueKey(item),
            itemBuilder: (context, item, index) => Text(item),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Item A'), findsOneWidget);
      expect(find.text('Item B'), findsOneWidget);
      expect(find.text('Item C'), findsOneWidget);
    });

    testWidgets('renders emptyFallback when items list is empty', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AppSortableList<String>(
            items: const [],
            itemKey: (item) => ValueKey(item),
            emptyFallback: const Text('No Items Found'),
            itemBuilder: (context, item, index) => Text(item),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Items Found'), findsOneWidget);
    });
  });

  group('AppStepper Behavioral Tests', () {
    testWidgets('renders initial step and allows advancing', (tester) async {
      int activeStep = 0;
      bool nextCalled = false;

      final steps = [
        AppStepItem(
          title: const Text('Step 1 Title'),
          contentBuilder: (ctx) => const Text('Step 1 Body'),
        ),
        AppStepItem(
          title: const Text('Step 2 Title'),
          contentBuilder: (ctx) => const Text('Step 2 Body'),
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          AppStepper(
            steps: steps,
            currentStep: activeStep,
            onStepChanged: (step) => activeStep = step,
            onNext: () => nextCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 1 Title'), findsOneWidget);
      expect(find.text('Step 1 Body'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(nextCalled, isTrue);
      expect(activeStep, 1);
    });

    testWidgets('blocks step advancement when validate returns false', (tester) async {
      int activeStep = 0;

      final steps = [
        AppStepItem(
          title: const Text('Step 1 Title'),
          validate: () => false, // validation fails!
          contentBuilder: (ctx) => const Text('Step 1 Body'),
        ),
        AppStepItem(
          title: const Text('Step 2 Title'),
          contentBuilder: (ctx) => const Text('Step 2 Body'),
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          AppStepper(
            steps: steps,
            currentStep: activeStep,
            onStepChanged: (step) => activeStep = step,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Active step remains 0 because validation failed
      expect(activeStep, 0);
    });
  });
}
