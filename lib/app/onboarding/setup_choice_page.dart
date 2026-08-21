import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_localizations.dart';
import '../router/app_routes.dart';
import '../theme/app_spacing.dart';
import '../constants/app_constants.dart';
import '../../modules/system_setup/presentation/pages/system_setup_routes.dart';

/// First-launch setup mode choice: connect to server or use locally.
///
/// Shown after the welcome tour, before any setup begins.
class SetupChoicePage extends ConsumerStatefulWidget {
  const SetupChoicePage({super.key});

  @override
  ConsumerState<SetupChoicePage> createState() => _SetupChoicePageState();
}

class _SetupChoicePageState extends ConsumerState<SetupChoicePage> {
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
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: AppConstants.pageInsets(context),
                      child: Column(
                        children: [
                          const Spacer(flex: 2),
                          Icon(
                            Icons.settings_input_component_outlined,
                            size: 56,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            l10n.setupChoiceTitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.setupChoiceSubtitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                          const Spacer(flex: 2),
                          _SetupChoiceCard(
                            icon: Icons.cloud_outlined,
                            title: l10n.setupChoiceServerTitle,
                            subtitle: l10n.setupChoiceServerSubtitle,
                            onTap: () => context.go(AppRoutes.serverSetup),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _SetupChoiceCard(
                            icon: Icons.phone_android_outlined,
                            title: l10n.setupChoiceLocalTitle,
                            subtitle: l10n.setupChoiceLocalSubtitle,
                            onTap: () => context.go(AppRoutes.login),
                          ),
                          const Spacer(flex: 2),
                        ],
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

class _SetupChoiceCard extends StatelessWidget {
  const _SetupChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
