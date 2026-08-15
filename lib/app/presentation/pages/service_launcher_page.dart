import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../notifications/presentation/providers/notifications_provider.dart';
import '../../router/app_routes.dart';
import '../../sync/app_bar_sync_actions.dart';
import '../../../core/modules/module_providers.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../shared/widgets/service_launcher.dart';

/// Services branch: launches business modules via the module registry.
class ServiceLauncherPage extends ConsumerWidget {
  const ServiceLauncherPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final registry = ref.watch(moduleRegistryProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.navigationServices,
        centerTitle: false,
        showNotifications: true,
        notificationCount: unread,
        onNotifications: () => context.push(AppRoutes.notifications),
        actions: const [AppBarSyncActions()],
      ),
      body: SingleChildScrollView(
        padding: AppConstants.pageInsets(context),
        child: ServiceLauncher(
          title: l10n.servicesTitle,
          subtitle: l10n.servicesSubtitle,
          modules: registry.enabledModules,
          onModuleSelected: (module) {
            if (!module.isEnabled) {
              return;
            }
            // Prefer go over push — see dashboard module launch comment
            // (go_router ShellRouteMatch duplicate page keys).
            context.go(module.rootRoute);
          },
        ),
      ),
    );
  }
}
