import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/app_providers.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/auth/presentation/providers/auth_state_core.dart';
import '../../modules/system_setup/presentation/pages/system_setup_routes.dart';
import '../bootstrap/app_initialization.dart';
import '../bootstrap/app_initialization_state.dart';
import '../localization/app_localizations.dart';
import '../presentation/providers/dashboard_services_provider.dart';
import '../router/app_routes.dart';
import 'widgets/splash_brand.dart';

/// Application splash: waits for [appInitializationProvider], then enters app.
///
/// Uses [startupStateProvider] to detect first-launch vs returning user and
/// routes to the appropriate flow:
/// - First launch: onboarding → setup choice → server/local setup
/// - Returning user: dashboard (when setup is ready) or system setup
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final initState = ref.watch(appInitializationControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<InitializationState>(appInitializationControllerProvider, (
      previous,
      next,
    ) {
      if (next.canOperate) {
        _navigateAfterInit(context, ref);
      }
    });

    if (initState.canOperate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateAfterInit(context, ref);
      });
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: colorScheme.surface,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.surface,
                  colorScheme.surface,
                  Color.alphaBlend(
                    colorScheme.primary.withValues(alpha: 0.05),
                    colorScheme.surface,
                  ),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: initState.isFailed
                ? SafeArea(
                    child: AppErrorState(
                      title: l10n.splashInitErrorTitle,
                      message:
                          initState.error?.message ??
                          l10n.splashInitErrorMessage,
                      onRetry: () => ref
                          .read(appInitializationControllerProvider.notifier)
                          .retry(),
                    ),
                  )
                : SplashBrandContent(
                    appName: l10n.appTitle,
                    subtitle: l10n.splashSubtitle,
                    loadingLabel: initState.stageDetails.isNotEmpty
                        ? initState.stageDetails
                        : l10n.loading,
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateAfterInit(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    final location = GoRouterState.of(context).uri.path;
    if (location != AppRoutes.splash) return;

    final auth = ref.read(authStateProvider);

    final onboardingDone = await ref
        .read(settingsRepositoryProvider)
        .loadOnboardingCompleted();
    if (!context.mounted) return;

    // 1. First-Run Setup / Onboarding check
    if (!onboardingDone) {
      context.go(AppRoutes.onboarding);
      return;
    }


    // 2. Authentication check
    if (!auth.isAuthenticated) {
      context.go(AppRoutes.login);
      return;
    }

    context.go(AppRoutes.dashboard);
  }
}
