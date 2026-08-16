import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_theme.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/app_lock/data/app_lock_repository_impl.dart';
import 'package:stock_count/modules/app_lock/data/local_auth_app_lock_biometrics.dart';
import 'package:stock_count/modules/app_lock/domain/entities/app_lock_state.dart';
import 'package:stock_count/modules/app_lock/presentation/pages/app_lock_page.dart';
import 'package:stock_count/modules/app_lock/presentation/providers/app_lock_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<dynamic> box;
  late AppLockRepositoryImpl repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('app_lock_ui_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>(HiveBoxes.appLock);
    repository = AppLockRepositoryImpl(box: box);
    await repository.setPin('1234');
    await repository.setEnabled(true);
    await repository.setPolicy(AppLockPolicy.onResume);
  });

  tearDown(() async {
    await box.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('lock screen renders title and unlock action', (tester) async {
    final container = ProviderContainer(
      overrides: [
        appLockRepositoryProvider.overrideWithValue(repository),
        appLockBiometricsProvider.overrideWithValue(
          const UnavailableAppLockBiometrics(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(appLockControllerProvider.notifier).hydrate();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppLockPage(),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('App locked'), findsOneWidget);
    expect(find.text('Unlock'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
