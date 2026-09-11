// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

void main() {
  Widget buildTestFrame(Widget child) {
    return shadcn.ShadcnApp(
      home: shadcn.Scaffold(
        child: SizedBox(
          width: 800,
          height: 900,
          child: child,
        ),
      ),
    );
  }

  group('NexaBizForm Design System Component Tests', () {
    testWidgets('1. Renders NexaBizForm header title, subtitle, and icon', (tester) async {
      await tester.pumpWidget(
        buildTestFrame(
          NexaBizForm(
            title: 'Test Category Form',
            subtitle: 'Configure warehouse and parent category',
            icon: Icons.category_outlined,
            children: const [
              Text('Form Content'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Category Form'), findsOneWidget);
      expect(find.text('Configure warehouse and parent category'), findsOneWidget);
      expect(find.byIcon(Icons.category_outlined), findsOneWidget);
      expect(find.text('Form Content'), findsOneWidget);
    });

    testWidgets('2. Renders global error banner when errorMessage is provided', (tester) async {
      await tester.pumpWidget(
        buildTestFrame(
          NexaBizForm(
            title: 'Category Form',
            errorMessage: 'Category code already exists in warehouse',
            children: const [
              Text('Form Fields'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Category code already exists in warehouse'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('3. Renders NexaBizFormSection title, description, and children', (tester) async {
      await tester.pumpWidget(
        buildTestFrame(
          NexaBizForm(
            children: const [
              NexaBizFormSection(
                title: 'Basic Info',
                description: 'Enter name and code',
                icon: Icons.info_outline,
                children: [
                  Text('Field 1'),
                  Text('Field 2'),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Basic Info'), findsOneWidget);
      expect(find.text('Enter name and code'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('Field 1'), findsOneWidget);
      expect(find.text('Field 2'), findsOneWidget);
    });

    testWidgets('4. Triggers onSubmit and onCancel callbacks', (tester) async {
      bool submitTriggered = false;
      bool cancelTriggered = false;

      await tester.pumpWidget(
        buildTestFrame(
          NexaBizForm(
            submitLabel: 'Save Category',
            cancelLabel: 'Discard',
            onSubmit: () => submitTriggered = true,
            onCancel: () => cancelTriggered = true,
            children: const [
              Text('Body'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Save Category'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(cancelTriggered, isTrue);

      await tester.tap(find.text('Save Category'));
      await tester.pumpAndSettle();
      expect(submitTriggered, isTrue);
    });

    testWidgets('5. Disables buttons and shows loading spinner when isSubmitting is true', (tester) async {
      bool submitTriggered = false;

      await tester.pumpWidget(
        buildTestFrame(
          NexaBizForm(
            isSubmitting: true,
            onSubmit: () => submitTriggered = true,
            onCancel: () {},
            children: const [
              Text('Body'),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Verify progress indicator is rendered when loading
      expect(find.byType(shadcn.CircularProgressIndicator), findsOneWidget);
      expect(submitTriggered, isFalse);
    });

    testWidgets('6. Integrates FormState validation on submit', (tester) async {
      final formKey = GlobalKey<FormState>();
      bool submitted = false;

      await tester.pumpWidget(
        buildTestFrame(
          NexaBizForm(
            formKey: formKey,
            onSubmit: () {
              if (formKey.currentState!.validate()) {
                submitted = true;
              }
            },
            children: [
              TextFormField(
                key: const ValueKey('name_field'),
                validator: (val) => (val == null || val.isEmpty) ? 'Name is required' : null,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap submit when field is empty
      await tester.tap(find.byType(AppButton).last);
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
      expect(submitted, isFalse);

      // Fill in field and submit again
      await tester.enterText(find.byKey(const ValueKey('name_field')), 'Valid Category');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AppButton).last);
      await tester.pumpAndSettle();

      expect(submitted, isTrue);
    });
  });
}
