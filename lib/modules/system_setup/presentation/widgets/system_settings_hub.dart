import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/settings/widgets/settings_chrome.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/modules/app_module.dart';
import '../../../../core/modules/module_providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/system_setup_state.dart';
import '../../system_setup_module.dart';

/// Runtime settings hub hosted by the Settings module.
///
/// Composes other modules' [AppModule.buildSettingsSections] without importing
/// those modules directly.
class SystemSettingsHub extends ConsumerWidget {
  const SystemSettingsHub({
    super.key,
    required this.progress,
    this.onReviewSetup,
  });

  final SetupProgress progress;
  final VoidCallback? onReviewSetup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final modules = ref
        .watch(moduleRegistryProvider)
        .modules
        .where(
          (m) =>
              m.id != SystemSetupModule.moduleId &&
              m.isEnabled &&
              m.hasSettings,
        )
        .toList(growable: false);

    return ListView(
      padding: AppConstants.pageInsets(context),
      children: [
        Text(
          l10n.systemSettingsHubSubtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsExpandableSection(
          icon: Icons.apartment_outlined,
          title: l10n.setupSettingsTitle,
          subtitle: l10n.setupSettingsCardSubtitle,
          initiallyExpanded: true,
          children: [
            Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.business_outlined),
                title: Text(l10n.systemSetupEditCompany),
                subtitle: Text(l10n.setupSettingsSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.settingsSetup),
              ),
            ),
          ],
        ),
        if (modules.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.settingsModulesSection,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.settingsModulesSectionSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final module in modules) ...[
            _ModuleExpandableSettings(module: module),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
        SettingsExpandableSection(
          icon: Icons.rocket_launch_outlined,
          title: l10n.systemSetupInitializationSection,
          subtitle: l10n.systemSetupPercent(progress.percentComplete),
          children: [
            Text(l10n.systemSetupReadyMessage),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l10n.systemSetupReviewSteps,
              variant: AppButtonVariant.outlined,
              expand: true,
              icon: Icons.checklist_outlined,
              onPressed: onReviewSetup,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: l10n.systemSetupFinish,
              expand: true,
              icon: Icons.home_outlined,
              onPressed: () => context.go(AppRoutes.dashboard),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _ModuleExpandableSettings extends StatelessWidget {
  const _ModuleExpandableSettings({required this.module});

  final AppModule module;

  @override
  Widget build(BuildContext context) {
    final sections = module.buildSettingsSections(context);
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return SettingsExpandableSection(
      icon: module.icon,
      title: module.label(context),
      subtitle: module.description(context),
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(
              height: 1,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          sections[i],
        ],
      ],
    );
  }
}
