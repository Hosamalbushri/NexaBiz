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
  group('AppCheckbox Behavioral Suite', () {
    testWidgets('Test 1: AppCheckbox renders checked state natively via shadcn', (tester) async {
      await tester.pumpWidget(
        _wrapTestWidget(
          AppCheckbox(
            value: true,
            label: 'Checked Option',
            onChanged: (val) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(shadcn.Checkbox), findsOneWidget);
      expect(find.text('Checked Option'), findsOneWidget);
      final cb = tester.widget<shadcn.Checkbox>(find.byType(shadcn.Checkbox));
      expect(cb.state, equals(shadcn.CheckboxState.checked));
    });

    testWidgets('Test 2: AppCheckbox renders unchecked state natively via shadcn', (tester) async {
      await tester.pumpWidget(
        _wrapTestWidget(
          AppCheckbox(
            value: false,
            label: 'Unchecked Option',
            onChanged: (val) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cb = tester.widget<shadcn.Checkbox>(find.byType(shadcn.Checkbox));
      expect(cb.state, equals(shadcn.CheckboxState.unchecked));
    });

    testWidgets('Test 3: AppCheckbox renders indeterminate state when value is null', (tester) async {
      await tester.pumpWidget(
        _wrapTestWidget(
          AppCheckbox(
            value: null,
            label: 'Indeterminate Option',
            onChanged: (val) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cb = tester.widget<shadcn.Checkbox>(find.byType(shadcn.Checkbox));
      expect(cb.state, equals(shadcn.CheckboxState.indeterminate));
    });

    testWidgets('Test 4: AppCheckbox tap triggers onChanged callback', (tester) async {
      bool? updatedValue;
      await tester.pumpWidget(
        _wrapTestWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppCheckbox(
                value: updatedValue ?? false,
                label: 'Click Me',
                onChanged: (val) {
                  setState(() {
                    updatedValue = val;
                  });
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(shadcn.Checkbox));
      await tester.pumpAndSettle();

      expect(updatedValue, isTrue);
    });

    testWidgets('Test 5: AppCheckbox tristate cycling (checked -> unchecked -> indeterminate)', (tester) async {
      shadcn.CheckboxState currentState = shadcn.CheckboxState.checked;

      await tester.pumpWidget(
        _wrapTestWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppCheckbox(
                state: currentState,
                tristate: true,
                label: 'Tristate Option',
                onStateChanged: (newState) {
                  setState(() {
                    currentState = newState;
                  });
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(currentState, equals(shadcn.CheckboxState.checked));

      // Tap 1: checked -> unchecked
      await tester.tap(find.byType(shadcn.Checkbox));
      await tester.pumpAndSettle();
      expect(currentState, equals(shadcn.CheckboxState.unchecked));

      // Tap 2: unchecked -> indeterminate
      await tester.tap(find.byType(shadcn.Checkbox));
      await tester.pumpAndSettle();
      expect(currentState, equals(shadcn.CheckboxState.indeterminate));

      // Tap 3: indeterminate -> checked
      await tester.tap(find.byType(shadcn.Checkbox));
      await tester.pumpAndSettle();
      expect(currentState, equals(shadcn.CheckboxState.checked));
    });
  });

  group('AppChipInput Behavioral Suite', () {
    testWidgets('Test 6: AppChipInput renders initial chips', (tester) async {
      await tester.pumpWidget(
        _wrapTestWidget(
          AppChipInput<String>(
            initialChips: const ['Tag1', 'Tag2'],
            chipBuilder: (context, chip) => Text(chip),
            onChipSubmitted: (text) => text,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tag1'), findsOneWidget);
      expect(find.text('Tag2'), findsOneWidget);
    });

    testWidgets('Test 7: AppChipInput notifies onChipsChanged when chip is removed', (tester) async {
      List<String> currentChips = ['Alpha', 'Beta'];

      await tester.pumpWidget(
        _wrapTestWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppChipInput<String>(
                initialChips: currentChips,
                chipBuilder: (context, chip) => Text(chip),
                onChipSubmitted: (text) => text,
                onChipsChanged: (chips) {
                  setState(() {
                    currentChips = chips;
                  });
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);

      // Tap close button on the first chip
      final closeIcon = find.byIcon(shadcn.LucideIcons.x).first;
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();

      expect(currentChips, equals(['Beta']));
    });
  });

  group('AppChipAutocomplete Behavioral Suite', () {
    testWidgets('Test 8: AppChipAutocomplete renders wrapped AutoComplete and ChipInput', (tester) async {
      await tester.pumpWidget(
        _wrapTestWidget(
          AppChipAutocomplete<String>(
            suggestions: const ['Apple', 'Banana', 'Cherry'],
            initialChips: const ['SelectedChip'],
            chipBuilder: (context, chip) => Text(chip),
            onChipSubmitted: (text) => text,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(shadcn.AutoComplete), findsOneWidget);
      expect(find.byType(AppChipInput<String>), findsOneWidget);
      expect(find.text('SelectedChip'), findsOneWidget);
    });
  });
}
