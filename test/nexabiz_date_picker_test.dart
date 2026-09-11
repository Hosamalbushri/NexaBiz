import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

Widget _wrapTestWidget(Widget child) {
  return shadcn.ShadcnApp(
    theme: AppTheme.shadcnDark(),
    home: shadcn.Scaffold(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

void main() {
  group('AppDateField Canonical Suite', () {
    testWidgets('Test 1: AppDateField renders label, required indicator and hint', (tester) async {
      await tester.pumpWidget(
        _wrapTestWidget(
          AppDateField(
            value: null,
            label: 'Posting Date',
            required: true,
            hint: 'Select posting date...',
            onChanged: (val) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Posting Date'), findsOneWidget);
      expect(find.text('*'), findsOneWidget);
      expect(find.text('Select posting date...'), findsOneWidget);
      expect(find.byType(shadcn.DatePicker), findsOneWidget);
    });

    testWidgets('Test 2: AppDateField renders with initial DateTime value', (tester) async {
      final initialDate = DateTime(2026, 9, 15);

      await tester.pumpWidget(
        _wrapTestWidget(
          AppDateField(
            value: initialDate,
            label: 'Document Date',
            onChanged: (val) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(shadcn.DatePicker), findsOneWidget);
    });

    testWidgets('Test 3: AppDateField renders error text when validation fails', (tester) async {
      await tester.pumpWidget(
        _wrapTestWidget(
          AppDateField(
            value: null,
            label: 'Due Date',
            errorText: 'Due date is required',
            onChanged: (val) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Due date is required'), findsOneWidget);
    });

    testWidgets('Test 4: AppDateField stateBuilder respects firstDate and lastDate bounds', (tester) async {
      final first = DateTime(2026, 1, 1);
      final last = DateTime(2026, 12, 31);

      final dateField = AppDateField(
        value: DateTime(2026, 6, 15),
        firstDate: first,
        lastDate: last,
        onChanged: (val) {},
      );

      await tester.pumpWidget(_wrapTestWidget(dateField));
      await tester.pumpAndSettle();

      // Retrieve stateBuilder and test boundary conditions directly
      final datePickerWidget = tester.widget<shadcn.DatePicker>(find.byType(shadcn.DatePicker));
      final builder = datePickerWidget.stateBuilder;
      expect(builder, isNotNull);

      expect(builder!(DateTime(2025, 12, 31)), equals(shadcn.DateState.disabled));
      expect(builder(DateTime(2026, 6, 15)), equals(shadcn.DateState.enabled));
      expect(builder(DateTime(2027, 1, 1)), equals(shadcn.DateState.disabled));
    });

    testWidgets('Test 5: Disabled AppDateField disables interaction', (tester) async {
      await tester.pumpWidget(
        _wrapTestWidget(
          AppDateField(
            value: DateTime(2026, 5, 1),
            enabled: false,
            label: 'Disabled Date',
            onChanged: (val) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final datePickerWidget = tester.widget<shadcn.DatePicker>(find.byType(shadcn.DatePicker));
      expect(datePickerWidget.enabled, isFalse);
    });
  });

  group('Direct shadcn Primitives Suite', () {
    testWidgets('Test 6: Direct shadcn.ColorInput renders correctly without wrapper', (tester) async {
      await tester.pumpWidget(
        _wrapTestWidget(
          shadcn.ColorInput(
            value: shadcn.ColorDerivative.fromColor(const Color(0xFF3B82F6)),
            showLabel: true,
            onChanged: (color) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(shadcn.ColorInput), findsOneWidget);
    });

    testWidgets('Test 7: Direct shadcn.FormattedInput renders correctly without wrapper', (tester) async {
      await tester.pumpWidget(
        _wrapTestWidget(
          shadcn.FormattedInput(
            initialValue: shadcn.FormattedValue([
              const shadcn.FormattedValuePart(shadcn.InputPart.static('DOC-')),
              const shadcn.FormattedValuePart(shadcn.InputPart.editable(length: 4, width: 40), '2026'),
            ]),
            onChanged: (val) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(shadcn.FormattedInput), findsOneWidget);
      expect(find.text('DOC-'), findsOneWidget);
    });
  });
}
