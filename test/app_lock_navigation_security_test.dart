import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_theme.dart';
import 'package:stock_count/modules/app_lock/domain/app_lock_biometrics.dart';
import 'package:stock_count/modules/app_lock/domain/entities/app_lock_state.dart';
import 'package:stock_count/modules/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:stock_count/modules/app_lock/presentation/pages/app_lock_page.dart';
import 'package:stock_count/modules/app_lock/presentation/providers/app_lock_providers.dart';
import 'package:stock_count/modules/app_lock/presentation/widgets/app_lock_gate_barrier.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';

class _FakeAuthController extends StateNotifier<AuthState>
    implements AuthController {
  _FakeAuthController(super.initial);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAppLockBiometrics implements AppLockBiometrics {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> authenticate({required String localizedReason}) async => false;
}

class _FakeAppLockRepository implements AppLockRepository {
  bool _enabled = true;
  bool _hasPin = true;
  String? _pin = '1234';
  AppLockPolicy _policy = AppLockPolicy.onResume;
  bool _biometric = false;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  @override
  Future<bool> isEnabled() async => _enabled;
  @override
  Future<void> setEnabled(bool enabled) async => _enabled = enabled;
  @override
  Future<bool> isBiometricEnabled() async => _biometric;
  @override
  Future<void> setBiometricEnabled(bool enabled) async => _biometric = enabled;
  @override
  Future<bool> hasPin() async => _hasPin && _pin != null;
  @override
  Future<AppLockPolicy> getPolicy() async => _policy;
  @override
  Future<void> setPolicy(AppLockPolicy policy) async => _policy = policy;
  @override
  Future<void> setPin(String pin) async {
    _pin = pin;
    _hasPin = true;
  }

  @override
  Future<bool> verifyPin(String pin) async => pin == _pin;
  @override
  Future<void> clearPin() async {
    _pin = null;
    _hasPin = false;
  }

  @override
  Future<int> loadFailedAttempts() async => _failedAttempts;
  @override
  Future<void> saveFailedAttempts(int count) async => _failedAttempts = count;
  @override
  Future<DateTime?> loadLockoutUntil() async => _lockoutUntil;
  @override
  Future<void> saveLockoutUntil(DateTime? until) async => _lockoutUntil = until;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAppLockRepository repository;

  setUp(() {
    repository = _FakeAppLockRepository();
  });

  Widget buildTestApp({
    required AuthState authState,
    required AppLockController lockController,
    required Widget child,
  }) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => _FakeAuthController(authState)),
        appLockControllerProvider.overrideWith((ref) => lockController),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppLockGateBarrier(child: child),
      ),
    );
  }

  group('NAV-02.2 App Lock Navigation Security Hardening Tests', () {
    testWidgets(
      'Protected Page → Lock: AppLockGateBarrier obscures protected content',
      (tester) async {
        final controller = AppLockController(
          repository: repository,
          biometrics: MockAppLockBiometrics(),
          onChanged: () {},
        );
        await controller.hydrate(lockOnColdStart: false);

        final authState = AuthState(
          status: AuthStatus.authenticated,
          session: AuthSessionSnapshot(
            user: const AuthUser(
              id: 'u1',
              email: 'admin@nexabiz.local',
              name: 'Admin',
            ),
            companies: const [
              AuthCompany(id: 'c1', name: 'Company 1', code: 'C1'),
            ],
            roles: const ['Admin'],
            permissions: const {'all'},
            capturedAt: DateTime.now().toUtc(),
            currentCompanyId: 'c1',
          ),
        );

        await tester.pumpWidget(
          buildTestApp(
            authState: authState,
            lockController: controller,
            child: const Scaffold(
              body: Text('CONFIDENTIAL BUSINESS DASHBOARD DATA'),
            ),
          ),
        );
        await tester.pump();

        // Verify page content is visible when unlocked
        expect(
          find.text('CONFIDENTIAL BUSINESS DASHBOARD DATA'),
          findsOneWidget,
        );
        expect(find.byType(AppLockPage), findsNothing);

        // Lock app
        controller.lock();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify AppLockPage is rendered over the content
        expect(find.byType(AppLockPage), findsOneWidget);
        expect(
          find.byKey(const ValueKey('app_lock_gate_barrier_active')),
          findsOneWidget,
        );

        // Unlock
        await controller.unlock('1234');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify content is restored intact
        expect(find.byType(AppLockPage), findsNothing);
        expect(
          find.text('CONFIDENTIAL BUSINESS DASHBOARD DATA'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Page → Dialog → Lock: Dialog is obscured behind barrier and preserved on unlock',
      (tester) async {
        final controller = AppLockController(
          repository: repository,
          biometrics: MockAppLockBiometrics(),
          onChanged: () {},
        );
        await controller.hydrate(lockOnColdStart: false);

        final authState = AuthState(
          status: AuthStatus.authenticated,
          session: AuthSessionSnapshot(
            user: const AuthUser(
              id: 'u1',
              email: 'admin@nexabiz.local',
              name: 'Admin',
            ),
            companies: const [
              AuthCompany(id: 'c1', name: 'Company 1', code: 'C1'),
            ],
            roles: const ['Admin'],
            permissions: const {'all'},
            capturedAt: DateTime.now().toUtc(),
            currentCompanyId: 'c1',
          ),
        );

        await tester.pumpWidget(
          buildTestApp(
            authState: authState,
            lockController: controller,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => const AlertDialog(
                          title: Text('SENSITIVE CONFIRMATION DIALOG'),
                        ),
                      );
                    },
                    child: const Text('Open Dialog'),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pump();

        // Tap button to open dialog
        await tester.tap(find.text('Open Dialog'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('SENSITIVE CONFIRMATION DIALOG'), findsOneWidget);

        // Lock app
        controller.lock();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // AppLockPage must obscure the screen
        expect(find.byType(AppLockPage), findsOneWidget);

        // Unlock app
        await controller.unlock('1234');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Barrier removed and dialog state intact
        expect(find.byType(AppLockPage), findsNothing);
        expect(find.text('SENSITIVE CONFIRMATION DIALOG'), findsOneWidget);
      },
    );

    testWidgets(
      'Page → BottomSheet → Lock: BottomSheet is obscured behind barrier and preserved on unlock',
      (tester) async {
        final controller = AppLockController(
          repository: repository,
          biometrics: MockAppLockBiometrics(),
          onChanged: () {},
        );
        await controller.hydrate(lockOnColdStart: false);

        final authState = AuthState(
          status: AuthStatus.authenticated,
          session: AuthSessionSnapshot(
            user: const AuthUser(
              id: 'u1',
              email: 'admin@nexabiz.local',
              name: 'Admin',
            ),
            companies: const [
              AuthCompany(id: 'c1', name: 'Company 1', code: 'C1'),
            ],
            roles: const ['Admin'],
            permissions: const {'all'},
            capturedAt: DateTime.now().toUtc(),
            currentCompanyId: 'c1',
          ),
        );

        await tester.pumpWidget(
          buildTestApp(
            authState: authState,
            lockController: controller,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (_) => const SizedBox(
                          height: 200,
                          child: Text('SECRET ACCOUNT PICKER SHEET'),
                        ),
                      );
                    },
                    child: const Text('Open Sheet'),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pump();

        // Tap button to open bottom sheet
        await tester.tap(find.text('Open Sheet'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('SECRET ACCOUNT PICKER SHEET'), findsOneWidget);

        // Lock app
        controller.lock();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // AppLockPage must obscure the screen
        expect(find.byType(AppLockPage), findsOneWidget);

        // Unlock app
        await controller.unlock('1234');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Barrier removed and bottom sheet state intact
        expect(find.byType(AppLockPage), findsNothing);
        expect(find.text('SECRET ACCOUNT PICKER SHEET'), findsOneWidget);
      },
    );
  });
}
