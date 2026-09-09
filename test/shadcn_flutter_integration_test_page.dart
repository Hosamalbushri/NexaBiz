import 'package:flutter/material.dart'
    hide TextField, Checkbox, Switch, Button, AlertDialog, Scaffold;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Component test suite verifying actual `shadcn_flutter` APIs.
void main() {
  testWidgets('shadcn_flutter primitives render and interact correctly',
      (WidgetTester tester) async {
    bool switchVal = false;
    shadcn.CheckboxState checkboxVal = shadcn.CheckboxState.unchecked;

    await tester.pumpWidget(
      shadcn.ShadcnApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Material(
              child: Column(
                children: [
                  shadcn.TextField(
                    placeholder: const Text('Enter text...'),
                  ),
                  shadcn.Button.primary(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const shadcn.AlertDialog(
                          title: Text('Test Dialog'),
                          content: Text('Dialog content text'),
                        ),
                      );
                    },
                    child: const Text('Open Dialog'),
                  ),
                  shadcn.Checkbox(
                    state: checkboxVal,
                    onChanged: (newState) {
                      setState(() => checkboxVal = newState);
                    },
                    trailing: const Text('Agree'),
                  ),
                  shadcn.Switch(
                    value: switchVal,
                    onChanged: (newVal) {
                      setState(() => switchVal = newVal);
                    },
                    trailing: const Text('Notifications'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify widgets rendered
    expect(find.byType(shadcn.TextField), findsOneWidget);
    expect(find.byType(shadcn.Button), findsOneWidget);
    expect(find.byType(shadcn.Checkbox), findsOneWidget);
    expect(find.byType(shadcn.Switch), findsOneWidget);

    // Tap button to verify dialog interaction
    await tester.tap(find.byType(shadcn.Button));
    await tester.pumpAndSettle();

    expect(find.text('Test Dialog'), findsOneWidget);
    expect(find.text('Dialog content text'), findsOneWidget);
  });
}
