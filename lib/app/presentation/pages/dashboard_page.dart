import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/modules/module_providers.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../notifications/presentation/providers/notifications_provider.dart';
import '../../router/app_routes.dart';
import '../../theme/app_spacing.dart';
import '../providers/dashboard_services_provider.dart';
import '../providers/quick_actions_panel_provider.dart';
import '../widgets/dashboard_recent_operations.dart';
import '../widgets/dashboard_services_panel.dart';
import 'dashboard_customize_sheet.dart';

/// Platform dashboard with user-customizable service shortcuts.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final servicesAsync = ref.watch(dashboardServicesProvider);
    final controller = ref.read(dashboardServicesProvider.notifier);
    final unread = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.dashboardTitle,
        showNotifications: true,
        notificationCount: unread,
        onNotifications: () => context.push(AppRoutes.notifications),
      ),
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
          return Padding(
            padding: AppConstants.pageInsets(context),
            child: SingleChildScrollView(
              primary: false,
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardServicesPanel(
                    modules: modules,
                    customizeLabel: l10n.dashboardCustomizeServices,
                    onCustomize: () => _openCustomize(context, ref),
                    onModuleSelected: (module) {
                      if (!module.isEnabled) {
                        return;
                      }
                      context.push(module.rootRoute);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const DashboardRecentOperations(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCustomize(BuildContext context, WidgetRef ref) async {
    // Avoid fighting the shell quick-actions panel / nested sheets.
    requestCloseQuickActions(ref);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!context.mounted) {
      return;
    }

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
