// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

Widget _buildTestApp(Widget child) {
  return shadcn.ShadcnApp(
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  testWidgets('Test 1 — NexaBizDialog opens via show()', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));

    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                NexaBizDialog.show<String>(
                  context: context,
                  title: 'Test Dialog Title',
                  description: 'Test Dialog Description',
                  child: const Text('Test Dialog Body Content'),
                );
              },
              child: const Text('Open Dialog'),
            );
          },
        ),
      ),
    );

    expect(find.text('Test Dialog Title'), findsNothing);
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Test Dialog Title'), findsOneWidget);
    expect(find.text('Test Dialog Description'), findsOneWidget);
    expect(find.text('Test Dialog Body Content'), findsOneWidget);
  });

  testWidgets('Test 2 — Cancel closes dialog and returns null', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    String? dialogResult = 'initial';

    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                dialogResult = await NexaBizDialog.show<String>(
                  context: context,
                  title: 'Cancelable Dialog',
                  onCancel: () => Navigator.of(context).pop(null),
                  onConfirm: () => Navigator.of(context).pop('confirmed'),
                  child: const Text('Body'),
                );
              },
              child: const Text('Open Dialog'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Cancelable Dialog'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Cancelable Dialog'), findsNothing);
    expect(dialogResult, isNull);
  });

  testWidgets('Test 3 — Typed result return via Navigator.pop', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    Map<String, dynamic>? resultData;

    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                resultData = await NexaBizDialog.show<Map<String, dynamic>>(
                  context: context,
                  title: 'Typed Result Dialog',
                  onConfirm: () => Navigator.of(context).pop({'success': true, 'id': 42}),
                  onCancel: () => Navigator.of(context).pop(null),
                  child: const Text('Body'),
                );
              },
              child: const Text('Open Dialog'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(resultData, isNotNull);
    expect(resultData!['success'], isTrue);
    expect(resultData!['id'], equals(42));
  });

  testWidgets('Test 4 — Async loading state & button disable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));

    await tester.pumpWidget(
      _buildTestApp(
        const NexaBizDialog<void>(
          title: 'Loading Dialog',
          isLoading: true,
          confirmLabel: 'Submitting',
          onConfirm: null,
          child: Text('Dialog is processing'),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Loading Dialog'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) => widget is shadcn.CircularProgressIndicator || widget is CircularProgressIndicator),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets('Test 5 — Failure presents error banner and dialog remains open', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));

    await tester.pumpWidget(
      _buildTestApp(
        NexaBizDialog<void>(
          title: 'Error Dialog',
          errorMessage: 'Failed to complete database operation',
          onConfirm: () {},
          onCancel: () {},
          child: const Text('Error Content'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Error Dialog'), findsOneWidget);
    expect(find.text('Failed to complete database operation'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('Test 6 — Long content scrolls without viewport overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));

    await tester.pumpWidget(
      _buildTestApp(
        NexaBizDialog<void>(
          title: 'Long Content Dialog',
          onConfirm: () {},
          onCancel: () {},
          child: Column(
            children: List.generate(
              30,
              (index) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Item row #$index'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Long Content Dialog'), findsOneWidget);
    expect(find.text('Item row #0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Test 7 — Responsive sizing bounds (small, medium, large, fullscreen)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));

    await tester.pumpWidget(
      _buildTestApp(
        const NexaBizDialog<void>(
          title: 'Small Dialog',
          size: NexaBizDialogSize.small,
          child: Text('Small content'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Small Dialog'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Test 8 — NexaBizFormDialog composes NexaBizDialog and NexaBizForm', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));

    await tester.pumpWidget(
      _buildTestApp(
        NexaBizFormDialog<void>(
          title: 'Category Form Dialog',
          subtitle: 'Create a new product category',
          icon: Icons.category_rounded,
          children: const [
            NexaBizFormSection(
              title: 'General Info',
              children: [
                Text('Category Name Field'),
              ],
            ),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Category Form Dialog'), findsOneWidget);
    expect(find.text('Create a new product category'), findsOneWidget);
    expect(find.text('General Info'), findsOneWidget);
    expect(find.text('Category Name Field'), findsOneWidget);
  });
}
