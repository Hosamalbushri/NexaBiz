import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../modules/system_setup/presentation/pages/system_setup_routes.dart';
import '../localization/app_localizations.dart';
import '../presentation/providers/dashboard_services_provider.dart';
import '../router/app_routes.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// First-launch welcome screen shown after splash, before setup choice.
///
/// Replaces the old 3-slide product tour with a clean, focused welcome
/// that leads directly to the system setup page.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const _iconAsset = 'assets/branding/nexabiz_app_icon.png';

  Future<void> _finish() async {
    await ref.read(settingsRepositoryProvider).saveOnboardingCompleted(true);
    if (!mounted) return;
    context.go(SystemSetupRoutes.root);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: colorScheme.surface,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
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
            child: SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(l10n.onboardingSkip),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.xl,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.shadow.withValues(
                                          alpha: isDark ? 0.35 : 0.12,
                                        ),
                                        blurRadius: 28,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.xl,
                                    ),
                                    child: Image.asset(
                                      _iconAsset,
                                      width: 96,
                                      height: 96,
                                      filterQuality: FilterQuality.high,
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .scale(
                                  begin: const Offset(0.92, 0.92),
                                  end: const Offset(1, 1),
                                  duration: 500.ms,
                                  curve: Curves.easeOutCubic,
                                ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                                  l10n.onboardingWelcomeTitle,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    height: 1.15,
                                  ),
                                )
                                .animate()
                                .fadeIn(
                                  delay: 80.ms,
                                  duration: 400.ms,
                                )
                                .moveY(
                                  begin: 12,
                                  end: 0,
                                  delay: 80.ms,
                                  duration: 400.ms,
                                ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                                  l10n.onboardingWelcomeSubtitle,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    height: 1.5,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                )
                                .animate()
                                .fadeIn(
                                  delay: 160.ms,
                                  duration: 400.ms,
                                )
                                .moveY(
                                  begin: 10,
                                  end: 0,
                                  delay: 160.ms,
                                  duration: 400.ms,
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _finish,
                        child: Text(l10n.onboardingGetStarted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
