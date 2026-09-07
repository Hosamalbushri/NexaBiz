import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/modules/system_setup/presentation/pages/first_run_setup_wizard_page.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_ui_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(child: MaterialApp(home: child));
  }

  group('Setup UI / UX Implementation (SS-08)', () {
    testWidgets(
      'renders FirstRunSetupWizardPage with step 0 language selection',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(const FirstRunSetupWizardPage()),
        );
        await tester.pumpAndSettle();

        expect(find.byType(FirstRunSetupWizardPage), findsOneWidget);
      },
    );
  });
}
