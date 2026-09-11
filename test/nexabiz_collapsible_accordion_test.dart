import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'package:stock_count/core/widgets/app_expandable_form_section.dart';
import 'package:stock_count/app/settings/widgets/settings_chrome.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapTestWidget(Widget child) {
    return shadcn.ShadcnApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: child,
        ),
      ),
    );
  }

  group('NexaBiz Design System — Collapsible & Accordion Behavioral Suite', () {
    testWidgets('shadcn.Collapsible expands and collapses on trigger tap',
        (tester) async {
      bool expandedState = false;

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return shadcn.Collapsible(
                  isExpanded: expandedState,
                  onExpansionChanged: (val) {
                    setState(() {
                      expandedState = !val;
                    });
                  },
                  children: [
                    shadcn.CollapsibleTrigger(
                      child: const Text('Header Trigger'),
                    ),
                    const shadcn.CollapsibleContent(
                      child: Text('Collapsible Content Details'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Header Trigger'), findsOneWidget);
      expect(expandedState, isFalse);

      await tester.tap(find.byType(shadcn.GhostButton));
      await tester.pumpAndSettle();

      expect(expandedState, isTrue);
    });

    testWidgets('shadcn.Accordion displays items correctly', (tester) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: Scaffold(
            body: shadcn.Accordion(
              items: [
                shadcn.AccordionItem(
                  trigger: const Text('Accordion Section 1'),
                  content: const Text('Content 1 Body'),
                ),
                shadcn.AccordionItem(
                  trigger: const Text('Accordion Section 2'),
                  content: const Text('Content 2 Body'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Accordion Section 1'), findsOneWidget);
      expect(find.text('Accordion Section 2'), findsOneWidget);
    });

    testWidgets('AppExpandableFormSection expands and exposes child content',
        (tester) async {
      await tester.pumpWidget(
        wrapTestWidget(
          const AppExpandableFormSection(
            title: 'Advanced Options',
            subtitle: 'Configure secondary attributes',
            icon: Icons.tune_rounded,
            initiallyExpanded: false,
            child: Text('Form Child Fields'),
          ),
        ),
      );

      expect(find.text('Advanced Options'), findsOneWidget);
      expect(find.text('Configure secondary attributes'), findsOneWidget);

      await tester.tap(find.text('Advanced Options'));
      await tester.pumpAndSettle();

      expect(find.text('Form Child Fields'), findsOneWidget);
    });

    testWidgets('SettingsExpandableSection renders and expands properly',
        (tester) async {
      await tester.pumpWidget(
        wrapTestWidget(
          const SettingsExpandableSection(
            icon: Icons.settings_outlined,
            title: 'System Preferences',
            subtitle: 'Manage local app preferences',
            initiallyExpanded: false,
            children: [
              Text('Preference Setting Item 1'),
            ],
          ),
        ),
      );

      expect(find.text('System Preferences'), findsOneWidget);

      await tester.tap(find.text('System Preferences'));
      await tester.pumpAndSettle();

      expect(find.text('Preference Setting Item 1'), findsOneWidget);
    });
  });
}
