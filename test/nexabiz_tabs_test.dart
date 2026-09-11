import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'package:nexabiz_ui/nexabiz_ui.dart';

void main() {
  Widget buildTestApp(Widget child) {
    return shadcn.ShadcnApp(
      home: shadcn.Scaffold(
        child: child,
      ),
    );
  }

  group('AppTabs Behavioral Tests', () {
    testWidgets('renders active tab content and switches active tab on selection', (tester) async {
      int activeIndex = 0;

      await tester.pumpWidget(
        buildTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                height: 400,
                width: 600,
                child: AppTabs(
                  index: activeIndex,
                  onChanged: (newIndex) {
                    setState(() {
                      activeIndex = newIndex;
                    });
                  },
                  items: const [
                    AppTabItem(
                      label: 'Overview',
                      child: Text('Overview Content'),
                    ),
                    AppTabItem(
                      label: 'Details',
                      child: Text('Details Content'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Overview Content'), findsOneWidget);

      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();

      expect(activeIndex, equals(1));
      expect(find.text('Details Content'), findsOneWidget);
    });

    testWidgets('supports underline style', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 400,
            width: 600,
            child: AppTabs(
              index: 0,
              onChanged: (_) {},
              style: AppTabStyle.underline,
              items: const [
                AppTabItem(
                  label: 'Tab 1',
                  child: Text('Content 1'),
                ),
                AppTabItem(
                  label: 'Tab 2',
                  child: Text('Content 2'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(shadcn.TabList), findsOneWidget);
      expect(find.text('Content 1'), findsOneWidget);
    });
  });

  group('AppTabWorkspace Behavioral Tests', () {
    testWidgets('renders workspace tabs and triggers close and add actions', (tester) async {
      String? closedItem;
      bool addTapped = false;
      int focused = 0;

      final items = [
        const shadcn.TabPaneData<String>('Doc1'),
        const shadcn.TabPaneData<String>('Doc2'),
      ];

      await tester.pumpWidget(
        buildTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                height: 400,
                width: 600,
                child: AppTabWorkspace<String>(
                  items: items,
                  focused: focused,
                  onFocused: (newFocus) {
                    setState(() {
                      focused = newFocus;
                    });
                  },
                  titleBuilder: (item) => item,
                  onCloseTab: (item) {
                    closedItem = item;
                  },
                  onAddTab: () {
                    addTapped = true;
                  },
                  child: Text('Active: ${items[focused].data}'),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Doc1'), findsOneWidget);
      expect(find.text('Doc2'), findsOneWidget);
      expect(find.text('Active: Doc1'), findsOneWidget);

      // Tap close button on Doc1
      final closeIcons = find.byIcon(Icons.close_rounded);
      expect(closeIcons, findsNWidgets(2));
      await tester.tap(closeIcons.first);
      await tester.pumpAndSettle();

      expect(closedItem, equals('Doc1'));

      // Tap add tab button
      final addIcon = find.byIcon(Icons.add_rounded);
      expect(addIcon, findsOneWidget);
      await tester.tap(addIcon);
      await tester.pumpAndSettle();

      expect(addTapped, isTrue);
    });
  });
}
