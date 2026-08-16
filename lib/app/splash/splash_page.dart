import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_error_state.dart';
import '../../modules/system_setup/presentation/pages/system_setup_routes.dart';
import '../../modules/system_setup/presentation/providers/system_setup_providers.dart';
import '../bootstrap/app_initialization.dart';
import '../localization/app_localizations.dart';
import '../presentation/providers/dashboard_services_provider.dart';
import '../router/app_routes.dart';
import 'widgets/splash_brand.dart';

/// Application splash: waits for [appInitializationProvider], then enters app.
///
/// First launch: onboarding → System Setup. After setup is complete: dashboard.
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final init = ref.watch(appInitializationProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AsyncValue<void>>(appInitializationProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!context.mounted) {
              return;
            }
            final location = GoRouterState.of(context).uri.path;
            if (location != AppRoutes.splash) {
              return;
            }
            final ready = await ref
                .read(systemInitializationCoordinatorProvider)
                .isReady();
            if (!context.mounted) {
              return;
            }
            if (ready) {
              context.go(AppRoutes.dashboard);
              return;
            }
            final onboardingDone = await ref
                .read(settingsRepositoryProvider)
                .loadOnboardingCompleted();
            if (!context.mounted) {
              return;
            }
            context.go(
              onboardingDone
                  ? SystemSetupRoutes.root
                  : AppRoutes.onboarding,
            );
          });
        },
      );
    });

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
            child: init.when(
              loading: () => SplashBrandContent(
                appName: l10n.appTitle,
                subtitle: l10n.splashSubtitle,
                loadingLabel: l10n.loading,
              ),
              error: (error, _) => SafeArea(
                child: AppErrorState(
                  title: l10n.splashInitErrorTitle,
                  message: l10n.splashInitErrorMessage,
                  onRetry: () => ref.invalidate(appInitializationProvider),
                ),
              ),
              data: (_) => SplashBrandContent(
                appName: l10n.appTitle,
                subtitle: l10n.splashSubtitle,
                loadingLabel: l10n.loading,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
