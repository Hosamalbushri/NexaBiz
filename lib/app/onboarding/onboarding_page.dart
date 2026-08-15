import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../modules/system_setup/presentation/pages/system_setup_routes.dart';
import '../localization/app_localizations.dart';
import '../presentation/providers/dashboard_services_provider.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// First-launch welcome tour shown after splash, before System Setup.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _iconAsset = 'assets/branding/nexabiz_app_icon.png';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(settingsRepositoryProvider).saveOnboardingCompleted(true);
    if (!mounted) return;
    context.go(SystemSetupRoutes.root);
  }

  void _next(int pageCount) {
    if (_index >= pageCount - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final pages = <_OnboardingSlideData>[
      _OnboardingSlideData(
        icon: Icons.handshake_outlined,
        title: l10n.onboardingPage1Title,
        body: l10n.onboardingPage1Body,
      ),
      _OnboardingSlideData(
        icon: Icons.cloud_off_outlined,
        title: l10n.onboardingPage2Title,
        body: l10n.onboardingPage2Body,
      ),
      _OnboardingSlideData(
        icon: Icons.tune_outlined,
        title: l10n.onboardingPage3Title,
        body: l10n.onboardingPage3Body,
      ),
    ];

    final isLast = _index >= pages.length - 1;

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
                      onPressed: isLast ? null : _finish,
                      child: Text(l10n.onboardingSkip),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: pages.length,
                      onPageChanged: (value) => setState(() => _index = value),
                      itemBuilder: (context, index) {
                        final page = pages[index];
                        return _OnboardingSlide(
                          iconAsset: _iconAsset,
                          data: page,
                          showBrandIcon: index == 0,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < pages.length; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                height: 8,
                                width: i == _index ? 22 : 8,
                                decoration: BoxDecoration(
                                  color: i == _index
                                      ? colorScheme.primary
                                      : colorScheme.outlineVariant,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => _next(pages.length),
                            child: Text(
                              isLast
                                  ? l10n.onboardingStart
                                  : l10n.onboardingNext,
                            ),
                          ),
                        ),
                      ],
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

class _OnboardingSlideData {
  const _OnboardingSlideData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({
    required this.iconAsset,
    required this.data,
    required this.showBrandIcon,
  });

  final String iconAsset;
  final _OnboardingSlideData data;
  final bool showBrandIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const Spacer(flex: 2),
          if (showBrandIcon)
            DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
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
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: Image.asset(
                      iconAsset,
                      width: 88,
                      height: 88,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 360.ms)
                .scale(
                  begin: const Offset(0.94, 0.94),
                  end: const Offset(1, 1),
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                )
          else
            Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Icon(
                    data.icon,
                    size: 40,
                    color: colorScheme.onPrimaryContainer,
                  ),
                )
                .animate()
                .fadeIn(duration: 320.ms)
                .moveY(begin: 10, end: 0, duration: 360.ms),
          const SizedBox(height: AppSpacing.xl),
          Text(
                data.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.2,
                  color: colorScheme.onSurface,
                ),
              )
              .animate()
              .fadeIn(delay: 60.ms, duration: 360.ms)
              .moveY(begin: 10, end: 0, delay: 60.ms, duration: 360.ms),
          const SizedBox(height: AppSpacing.md),
          Text(
                data.body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.45,
                  color: colorScheme.onSurfaceVariant,
                ),
              )
              .animate()
              .fadeIn(delay: 120.ms, duration: 360.ms)
              .moveY(begin: 8, end: 0, delay: 120.ms, duration: 360.ms),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
