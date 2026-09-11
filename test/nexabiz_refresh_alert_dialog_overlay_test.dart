import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

void main() {
  testWidgets('RefreshTrigger renders child and handles programmatic refresh', (WidgetTester tester) async {
    bool refreshed = false;
    final refreshKey = GlobalKey<shadcn.RefreshTriggerState>();

    await tester.pumpWidget(
      shadcn.ShadcnApp(
        home: shadcn.Scaffold(
          child: shadcn.RefreshTrigger(
            key: refreshKey,
            onRefresh: () async {
              refreshed = true;
            },
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) => Text('Item $index'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 9'), findsOneWidget);

    // Programmatic refresh trigger
    await refreshKey.currentState!.refresh();
    await tester.pumpAndSettle();

    expect(refreshed, isTrue);
  });

  testWidgets('Alert renders title, content, leading icon, and trailing action', (WidgetTester tester) async {
    bool actionTapped = false;

    await tester.pumpWidget(
      shadcn.ShadcnApp(
        home: shadcn.Scaffold(
          child: Center(
            child: shadcn.Alert(
              leading: const Icon(Icons.info),
              title: const Text('Info Alert'),
              content: const Text('This is an informational alert.'),
              trailing: shadcn.OutlineButton(
                onPressed: () {
                  actionTapped = true;
                },
                child: const Text('Action'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Info Alert'), findsOneWidget);
    expect(find.text('This is an informational alert.'), findsOneWidget);
    expect(find.byIcon(Icons.info), findsOneWidget);
    expect(find.text('Action'), findsOneWidget);

    await tester.tap(find.text('Action'));
    await tester.pump();

    expect(actionTapped, isTrue);
  });

  testWidgets('Alert.destructive applies destructive styling correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const shadcn.ShadcnApp(
        home: shadcn.Scaffold(
          child: Center(
            child: shadcn.Alert.destructive(
              leading: Icon(Icons.warning),
              title: Text('Destructive Warning'),
              content: Text('Irreversible action warning.'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Destructive Warning'), findsOneWidget);
    expect(find.text('Irreversible action warning.'), findsOneWidget);
    expect(find.byIcon(Icons.warning), findsOneWidget);
  });

  testWidgets('AlertDialog presents via showOverlay with DialogConfiguration', (WidgetTester tester) async {
    bool confirmed = false;

    await tester.pumpWidget(
      shadcn.ShadcnApp(
        home: shadcn.Scaffold(
          child: Builder(
            builder: (context) {
              return shadcn.PrimaryButton(
                onPressed: () {
                  shadcn.showOverlay(
                    context,
                    shadcn.DialogConfiguration(
                      builder: (dialogCtx) => shadcn.AlertDialog(
                        title: const Text('Confirm Action'),
                        content: const Text('Are you sure you want to proceed?'),
                        actions: [
                          shadcn.OutlineButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          shadcn.PrimaryButton(
                            onPressed: () {
                              confirmed = true;
                              Navigator.of(dialogCtx).pop(true);
                            },
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      ),
    );

    // Tap button to launch overlay
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Action'), findsOneWidget);
    expect(find.text('Are you sure you want to proceed?'), findsOneWidget);

    // Tap confirm action
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
    expect(find.text('Confirm Action'), findsNothing);
  });

  testWidgets('AlertDialog barrier dismissal handles user cancellation', (WidgetTester tester) async {
    await tester.pumpWidget(
      shadcn.ShadcnApp(
        home: shadcn.Scaffold(
          child: Builder(
            builder: (context) {
              return shadcn.PrimaryButton(
                onPressed: () {
                  shadcn.showOverlay(
                    context,
                    shadcn.DialogConfiguration(
                      barrierDismissible: true,
                      builder: (dialogCtx) => const shadcn.AlertDialog(
                        title: Text('Dismissible Dialog'),
                        content: Text('Tap outside to dismiss.'),
                      ),
                    ),
                  );
                },
                child: const Text('Open Dismissible Dialog'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dismissible Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Dismissible Dialog'), findsOneWidget);

    // Tap outside dialog to dismiss
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Dismissible Dialog'), findsNothing);
  });
}
