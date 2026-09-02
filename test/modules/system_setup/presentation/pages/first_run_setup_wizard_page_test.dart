import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/app/bootstrap/app_bootstrap_coordinator.dart';
import 'package:stock_count/app/presentation/providers/dashboard_services_provider.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/core/database/hive_encryption_key_store.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/system_setup/domain/services/first_run_setup_coordinator.dart';
import 'package:stock_count/modules/system_setup/presentation/pages/first_run_setup_wizard_page.dart';
import 'package:stock_count/modules/system_setup/presentation/providers/system_setup_providers.dart';

class MockAppBootstrapCoordinator extends AppBootstrapCoordinator {
  MockAppBootstrapCoordinator(super.ref);

  @override
  Future<void> startBootstrap() async {}

  @override
  Future<void> onFirstRunCompleted() async {
    state = const AppBootstrapState(
      status: AppBootstrapStatus.unauthenticated,
      stageDetails: 'First-run setup completed.',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late LocalAuthStore authStore;
  late SettingsRepository settingsRepo;
  late FirstRunSetupCoordinator coordinator;

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('first_run_ui_test_');
    Hive.init(tempDir.path);
    HiveEncryptionKeyStore.debugFixedKey = Uint8List.fromList(
      List<int>.generate(32, (i) => i + 7),
    );

    authStore = LocalAuthStore();
    settingsRepo = SettingsRepository();
    coordinator = FirstRunSetupCoordinator(
      settingsRepository: settingsRepo,
      authStore: authStore,
    );
  });

  tearDown(() async {
    HiveEncryptionKeyStore.debugFixedKey = null;
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildTestWidget() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const FirstRunSetupWizardPage(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Text('Login Screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        firstRunSetupCoordinatorProvider.overrideWithValue(coordinator),
        appBootstrapCoordinatorProvider.overrideWith((ref) => MockAppBootstrapCoordinator(ref)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('Phase 4 — FirstRunSetupWizardPage UI Alignment Tests', () {
    testWidgets('UI-01 & UI-02: Form wizard contains 3 steps with zero company fields', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Step 0: Language
      expect(find.text('اللغة').first, findsOneWidget);
      expect(find.text('العربية'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // Verify no company fields exist anywhere on screen
      expect(find.text('اسم الشركة'), findsNothing);
      expect(find.text('كود الشركة'), findsNothing);
      expect(find.text('Company Name'), findsNothing);

      // Advance to Step 1: Admin Account
      await tester.tap(find.text('التالي'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Step 1: Admin Account
      expect(find.text('حساب مدير النظام'), findsOneWidget);
      expect(find.text('اسم مدير النظام *'), findsOneWidget);
      expect(find.text('البريد الإلكتروني *'), findsOneWidget);
      expect(find.text('كلمة المرور * (8 أحرف فأكثر)'), findsOneWidget);
      expect(find.text('تأكيد كلمة المرور *'), findsOneWidget);

      // Verify no company input fields on Step 1
      expect(find.text('اسم الشركة'), findsNothing);
      expect(find.text('كود الشركة'), findsNothing);
    });

    testWidgets('UI-03 & UI-07 & UI-08: Complete wizard flow creates pure System Admin with 0 companies', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Step 0 -> Step 1
      await tester.tap(find.text('التالي'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Fill Admin Credentials
      await tester.enterText(find.byType(TextFormField).at(0), 'مدير النظام الرئيسي');
      await tester.enterText(find.byType(TextFormField).at(1), 'admin@sysadmin.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'SuperAdminPass2026!');
      await tester.enterText(find.byType(TextFormField).at(3), 'SuperAdminPass2026!');

      // Advance to Step 2: Confirm
      await tester.tap(find.text('التالي'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Step 2: Manifest Review
      expect(find.text('تأكيد تهيئة النظام'), findsOneWidget);
      expect(find.text('مدير النظام الرئيسي'), findsWidgets);
      expect(find.text('admin@sysadmin.com'), findsWidgets);

      // Verify explicit note that no company is created
      expect(find.textContaining('لا يتم إنشاء أي شركة'), findsOneWidget);

      // Commit setup
      await tester.ensureVisible(find.text('اعتماد تهيئة النظام'));
      await tester.tap(find.text('اعتماد تهيئة النظام'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      final exception = tester.takeException();
      if (exception != null) {
        print('WIDGET TEST EXCEPTION: $exception');
      }

      // Verify coordinator & store state
      final isCompleted = await coordinator.isFirstRunCompleted();
      expect(isCompleted, isTrue);

      final hasAdmin = await authStore.hasConfiguredAdmin();
      expect(hasAdmin, isTrue);

      final primaryCompany = await authStore.getPrimaryCompany();
      expect(primaryCompany, isNull);
    });

    testWidgets('UI-04: Validation prevents advancing to confirmation with invalid inputs', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Step 0 -> Step 1
      await tester.tap(find.text('التالي'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Next without filling required fields
      await tester.tap(find.text('التالي'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Validation errors shown, remaining on Step 1
      expect(find.text('يرجى إدخال اسم مدير النظام'), findsOneWidget);
      expect(find.text('حساب مدير النظام'), findsOneWidget);
    });
  });
}
