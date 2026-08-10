import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/modules/module_providers.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../shared/widgets/service_grid.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_spacing.dart';
import '../providers/dashboard_services_provider.dart';
import 'dashboard_customize_sheet.dart';

/// Platform dashboard with user-customizable service shortcuts.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final servicesAsync = ref.watch(dashboardServicesProvider);
    final controller = ref.read(dashboardServicesProvider.notifier);

    return Scaffold(
      appBar: CustomAppBar(title: l10n.dashboardTitle),
      body: servicesAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.somethingWentWrong),
                const SizedBox(height: AppSpacing.md),
                AppButton(label: l10n.retry, onPressed: controller.reload),
              ],
            ),
          ),
        ),
        data: (_) {
          final modules = controller.resolveModules();
          return ListView(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            children: [
              Text(
                l10n.dashboardMyServices,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ServiceGrid(
                modules: modules,
                addLabel: l10n.dashboardCustomizeServices,
                onAddPressed: () => _openCustomize(context, ref),
                onModuleSelected: (module) {
                  if (!module.isEnabled) {
                    return;
                  }
                  context.push(module.rootRoute);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openCustomize(BuildContext context, WidgetRef ref) async {
    final registry = ref.read(moduleRegistryProvider);
    final current =
        ref.read(dashboardServicesProvider).valueOrNull ??
        [for (final module in registry.enabledModules) module.id];

    final result = await showAppBottomSheet<List<String>>(
      context: context,
      child: DashboardCustomizeSheet(
        availableModules: registry.enabledModules,
        initiallySelectedIds: current,
      ),
    );

    if (result == null || !context.mounted) {
      return;
    }

    await ref.read(dashboardServicesProvider.notifier).save(result);
  }
}
