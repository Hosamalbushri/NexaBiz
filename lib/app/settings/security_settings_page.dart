import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/custom_app_bar.dart';
import '../../modules/app_lock/presentation/providers/app_lock_providers.dart';
import '../../modules/app_lock/presentation/widgets/app_lock_settings_section.dart';
import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';
import '../theme/app_spacing.dart';
import 'widgets/settings_chrome.dart';

/// Dedicated security settings (App Lock / PIN).
class SecuritySettingsPage extends ConsumerStatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  ConsumerState<SecuritySettingsPage> createState() =>
      _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends ConsumerState<SecuritySettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(appLockControllerProvider.notifier)
          .refreshBiometricAvailability();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lock = ref.watch(appLockControllerProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.appLockSettingsSection,
        centerTitle: false,
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context).copyWith(
          top: AppSpacing.sm,
          bottom: AppSpacing.lg,
        ),
        children: [
          Text(
            lock.enabled
                ? l10n.appLockSettingsEnabledHint
                : l10n.appLockSettingsDisabledHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SettingsGroup(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: AppLockSettingsSection(embedded: true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
