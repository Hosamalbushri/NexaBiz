import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:stock_count/app/bootstrap/app_initialization.dart';
import 'package:stock_count/app/bootstrap/app_initialization_state.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/presentation/providers/dashboard_services_provider.dart';
import 'package:stock_count/app/router/app_routes.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/app/splash/splash_page.dart';
import 'package:stock_count/app/theme/app_theme.dart';
import 'package:stock_count/core/di/app_providers.dart';
import 'package:stock_count/core/errors/app_error_domain.dart';
import 'package:stock_count/core/widgets/app_dialog.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/local_permissions.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/modules/system_setup/domain/entities/system_setup_state.dart';
import 'package:stock_count/modules/system_setup/domain/ports/system_setup_seed_port.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/system_setup_state_repository.dart';
import 'package:stock_count/modules/system_setup/domain/services/system_initialization_coordinator.dart';
import 'package:stock_count/modules/system_setup/presentation/pages/system_setup_routes.dart';
import 'package:stock_count/modules/system_setup/presentation/providers/system_setup_providers.dart';

class _FakeAuthController extends StateNotifier<AuthState>
    implements AuthController {
  _FakeAuthController(AuthState initial) : super(initial);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FixedSetupStateRepository implements SystemSetupStateRepository {
  _FixedSetupStateRepository(this.progress);

  final SetupProgress progress;

  @override
  Future<SetupProgress> load() async => progress;

  @override
  Future<void> save(SetupProgress progress) async {}
}

class _FakeSettingsRepository extends SettingsRepository {
  _FakeSettingsRepository({this.onboardingCompleted = false});

  final bool onboardingCompleted;

  @override
  Future<bool> loadOnboardingCompleted() async => onboardingCompleted;

  @override
  Future<void> saveOnboardingCompleted(bool completed) async {}
}

SetupProgress _readyProgress() {
  final now = DateTime.utc(2026, 8, 14);
  return SetupProgress(
    schemaVersion: SystemSetupSchema.currentVersion,
    status: SystemSetupStatus.ready,
    steps: {
      for (final id in SetupStepId.allIds)
        id: SetupStepState(
          id: id,
          status: SetupStepStatus.completed,
          updatedAt: now,
        ),
    },
    lastUpdated: now,
  );
}

SetupProgress _freshProgress() {
  return SetupProgress(
    schemaVersion: SystemSetupSchema.currentVersion,
    status: SystemSetupStatus.notStarted,
    steps: {
      for (final id in SetupStepId.allIds)
        id: SetupStepState(id: id, status: SetupStepStatus.pending),
    },
  );
}

class _TestAppInitializationCoordinator extends AppInitializationCoordinator {
  _TestAppInitializationCoordinator(
    Ref ref, {
    this.shouldFail = false,
    this.initialState,
  }) : super(ref) {
    attempts = 1;
    if (initialState != null) {
      state = initialState!;
    } else if (shouldFail) {
      state = const InitializationState(
        status: InitializationStatus.failed,
        stage: InitializationStage.coreBootstrap,
        error: AppError(
          category: AppErrorCategory.initialization,
          message: 'Unable to start application',
        ),
      );
    } else {
      state = const InitializationState(
        status: InitializationStatus.ready,
        stage: InitializationStage.applicationReady,
      );
    }
  }

  final bool shouldFail;
  final InitializationState? initialState;
  int attempts = 0;

  @override
  Future<void> initialize() async {
    attempts++;
    if (shouldFail && attempts == 1) {
      state = const InitializationState(
        status: InitializationStatus.failed,
        stage: InitializationStage.coreBootstrap,
        error: AppError(
          category: AppErrorCategory.initialization,
          message: 'Unable to start application',
        ),
      );
    } else {
      state = const InitializationState(
        status: InitializationStatus.ready,
        stage: InitializationStage.applicationReady,
      );
    }
  }

  @override
  Future<void> retry() async {
    await initialize();
  }
}

List<Override> setupOverrides(
  SetupProgress progress, {
  bool onboardingCompleted = false,
  bool isFirstLaunch = true,
  InitializationState? initState,
  bool failInit = false,
}) {
  return [
    startupStateProvider.overrideWithValue(
      AppStartupState(
        themeMode: ThemeMode.system,
        isFirstLaunch: isFirstLaunch,
      ),
    ),
    settingsRepositoryProvider.overrideWithValue(
      _FakeSettingsRepository(onboardingCompleted: onboardingCompleted),
    ),
    systemSetupStateRepositoryProvider.overrideWithValue(
      _FixedSetupStateRepository(progress),
    ),
    systemInitializationCoordinatorProvider.overrideWith((ref) {
      return SystemInitializationCoordinator(
        stateRepository: ref.watch(systemSetupStateRepositoryProvider),
        seedPort: const NoOpSystemSetupSeedPort(),
      );
    }),
    appInitializationControllerProvider.overrideWith((ref) {
      return _TestAppInitializationCoordinator(
        ref,
        initialState: initState,
        shouldFail: failInit,
      );
    }),
  ];
}

AuthState _testAuthenticatedState() {
  return AuthState(
    status: AuthStatus.authenticated,
    session: AuthSessionSnapshot(
      user: const AuthUser(
        id: LocalAuthDefaults.adminUserId,
        name: LocalAuthDefaults.adminName,
        email: LocalAuthDefaults.adminEmail,
        isSuperAdmin: true,
      ),
      companies: const [
        AuthCompany(
          id: LocalAuthDefaults.companyId,
          name: LocalAuthDefaults.companyName,
          code: LocalAuthDefaults.companyCode,
          role: LocalAuthDefaults.adminRole,
        ),
      ],
      roles: const [LocalAuthDefaults.adminRole],
      permissions: {...kAllLocalPermissions},
      capturedAt: DateTime.utc(2026, 8, 14),
      currentCompanyId: LocalAuthDefaults.companyId,
      deviceId: 'test-device',
      sessionId: 'test-session',
    ),
  );
}



void main() {
  Widget wrapDialog({
    required Widget child,
    Locale locale = const Locale('en'),
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return ProviderScope(
      child: MaterialApp(
        locale: locale,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  Widget wrapSplash({required List<Override> overrides}) {
    final router = GoRouter(
      initialLocation: AppRoutes.splash,
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) =>
              const Scaffold(body: Text('LoginShell')),
        ),
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) =>
              const Scaffold(body: Text('DashboardShell')),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) =>
              const Scaffold(body: Text('OnboardingShell')),
        ),
        GoRoute(
          path: AppRoutes.setupChoice,
          builder: (context, state) =>
              const Scaffold(body: Text('SetupChoiceShell')),
        ),
        GoRoute(
          path: SystemSetupRoutes.firstRun,
          builder: (context, state) =>
              const Scaffold(body: Text('FirstRunSetupShell')),
        ),
        GoRoute(
          path: SystemSetupRoutes.root,
          builder: (context, state) =>
              const Scaffold(body: Text('FirstRunSetupShell')),
        ),
      ],
    );

    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  group('SplashPage', () {
    testWidgets('shows brand and loading while initializing', (tester) async {
      await tester.pumpWidget(
        wrapSplash(
          overrides: [
            ...setupOverrides(
              _readyProgress(),
              isFirstLaunch: false,
              initState: const InitializationState(
                status: InitializationStatus.initializing,
                stage: InitializationStage.coreBootstrap,
                stageDetails: 'Loading...',
              ),
            ),
          ],
        ),
      );

      await tester.pump();

      expect(find.text('NexaBiz'), findsOneWidget);
      expect(find.text('Business Management Platform'), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('navigates to dashboard when initialization succeeds and user is authenticated', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapSplash(
          overrides: [
            ...setupOverrides(_readyProgress(), isFirstLaunch: false, onboardingCompleted: true),
            authStateProvider.overrideWith((ref) => _FakeAuthController(_testAuthenticatedState())),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('DashboardShell'), findsOneWidget);
      expect(find.byType(SplashPage), findsNothing);
    });

    testWidgets('navigates to first-run setup when onboarding is not completed', (tester) async {
      await tester.pumpWidget(
        wrapSplash(
          overrides: [
            ...setupOverrides(_freshProgress(), onboardingCompleted: false),
            authStateProvider.overrideWith((ref) => _FakeAuthController(_testAuthenticatedState())),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('FirstRunSetupShell'), findsOneWidget);
      expect(find.text('DashboardShell'), findsNothing);
    });

    testWidgets('shows error state with retry on failure', (tester) async {
      late _TestAppInitializationCoordinator coordinator;

      await tester.pumpWidget(
        wrapSplash(
          overrides: [
            ...setupOverrides(_readyProgress(), isFirstLaunch: false, onboardingCompleted: true),
            appInitializationControllerProvider.overrideWith((ref) {
              coordinator = _TestAppInitializationCoordinator(ref, shouldFail: true);
              return coordinator;
            }),
            authStateProvider.overrideWith((ref) => _FakeAuthController(_testAuthenticatedState())),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to start application'), findsAtLeastNWidgets(1));
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(coordinator.attempts, 2);
      expect(find.text('DashboardShell'), findsOneWidget);
    });

    testWidgets('navigates to login when unauthenticated', (tester) async {
      await tester.pumpWidget(
        wrapSplash(
          overrides: [
            ...setupOverrides(_readyProgress(), onboardingCompleted: true),
            authStateProvider.overrideWith(
              (ref) => _FakeAuthController(
                const AuthState(status: AuthStatus.unauthenticated),
              ),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('LoginShell'), findsOneWidget);
      expect(find.text('DashboardShell'), findsNothing);
    });
  });

  group('Exit confirmation dialog', () {
    testWidgets('shows localized cancel and exit actions', (tester) async {
      await tester.pumpWidget(
        wrapDialog(
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      showAppDialog(
                        context: context,
                        title: AppLocalizations.of(context).exitAppTitle,
                        message: AppLocalizations.of(context).exitAppMessage,
                        confirmLabel: AppLocalizations.of(
                          context,
                        ).exitAppConfirm,
                        isDestructive: true,
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Exit Application?'), findsOneWidget);
      expect(
        find.text('Are you sure you want to exit the application?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Exit'), findsOneWidget);
    });

    testWidgets('supports Arabic RTL copy', (tester) async {
      await tester.pumpWidget(
        wrapDialog(
          locale: const Locale('ar'),
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      showAppDialog(
                        context: context,
                        title: AppLocalizations.of(context).exitAppTitle,
                        message: AppLocalizations.of(context).exitAppMessage,
                        confirmLabel: AppLocalizations.of(
                          context,
                        ).exitAppConfirm,
                        isDestructive: true,
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('هل تريد الخروج؟'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.text('خروج'), findsOneWidget);
    });

    testWidgets('cancel dismisses dialog without confirming', (tester) async {
      bool? result;

      await tester.pumpWidget(
        wrapDialog(
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () async {
                      result = await showAppDialog(
                        context: context,
                        title: 'Exit Application?',
                        message: 'Sure?',
                        confirmLabel: 'Exit',
                        cancelLabel: 'Cancel',
                        isDestructive: true,
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('works in dark theme', (tester) async {
      await tester.pumpWidget(
        wrapDialog(
          themeMode: ThemeMode.dark,
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      showAppDialog(
                        context: context,
                        title: AppLocalizations.of(context).exitAppTitle,
                        message: AppLocalizations.of(context).exitAppMessage,
                        confirmLabel: AppLocalizations.of(
                          context,
                        ).exitAppConfirm,
                        isDestructive: true,
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Exit Application?'), findsOneWidget);
      expect(
        Theme.of(tester.element(find.text('Exit Application?'))).brightness,
        Brightness.dark,
      );
    });
  });
}
