import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/exit/app_exit_scope.dart';
import 'package:stock_count/app/localization/app_localizations.dart';

void main() {
  Widget buildTestApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ar'),
      home: child,
    );
  }

  group('NAV-02.5 — Back Navigation & UnsavedChangesScope Tests', () {
    testWidgets('UnsavedChangesScope pops directly if no unsaved changes', (
      tester,
    ) async {
      var popped = false;
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.of(context)
                    .push(
                      MaterialPageRoute<void>(
                        builder: (context) => UnsavedChangesScope(
                          hasUnsavedChanges: () => false,
                          child: Scaffold(
                            appBar: AppBar(title: const Text('Form Page')),
                            body: const Text('Clean Form'),
                          ),
                        ),
                      ),
                    )
                    .then((_) => popped = true),
                child: const Text('Open Form'),
              ),
            ),
          ),
        ),
      );

      // Open form
      await tester.tap(find.text('Open Form'));
      await tester.pumpAndSettle();
      expect(find.text('Clean Form'), findsOneWidget);

      // Tap back button in AppBar
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pumpAndSettle();

      // Form popped directly without confirmation dialog
      expect(find.text('Clean Form'), findsNothing);
      expect(popped, isTrue);
    });

    testWidgets(
      'UnsavedChangesScope shows confirmation dialog when dirty and user cancels',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => UnsavedChangesScope(
                        hasUnsavedChanges: () => true,
                        child: Scaffold(
                          appBar: AppBar(title: const Text('Form Page')),
                          body: const Text('Dirty Form'),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Open Form'),
                ),
              ),
            ),
          ),
        );

        // Open form
        await tester.tap(find.text('Open Form'));
        await tester.pumpAndSettle();
        expect(find.text('Dirty Form'), findsOneWidget);

        // Tap back button in AppBar
        await tester.tap(find.byType(BackButton));
        await tester.pump();
        await tester.pumpAndSettle();

        // Discard confirmation dialog pops up
        expect(find.byType(Dialog), findsOneWidget);

        // Tap Cancel button in dialog ("إلغاء")
        await tester.tap(find.text('إلغاء'));
        await tester.pumpAndSettle();

        // Form remains on screen, dialog dismissed
        expect(find.byType(Dialog), findsNothing);
        expect(find.text('Dirty Form'), findsOneWidget);
      },
    );

    testWidgets('UnsavedChangesScope pops page when user confirms discard', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => UnsavedChangesScope(
                      hasUnsavedChanges: () => true,
                      child: Scaffold(
                        appBar: AppBar(title: const Text('Form Page')),
                        body: const Text('Dirty Form'),
                      ),
                    ),
                  ),
                ),
                child: const Text('Open Form'),
              ),
            ),
          ),
        ),
      );

      // Open form
      await tester.tap(find.text('Open Form'));
      await tester.pumpAndSettle();
      expect(find.text('Dirty Form'), findsOneWidget);

      // Tap back button in AppBar
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pumpAndSettle();

      // Discard confirmation dialog pops up
      expect(find.byType(Dialog), findsOneWidget);

      // Tap Discard button in dialog ("مغادرة")
      await tester.tap(find.text('مغادرة'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Form and dialog popped cleanly
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Dirty Form'), findsNothing);
      expect(find.text('Open Form'), findsOneWidget);
    });
  });
}
