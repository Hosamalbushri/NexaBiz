import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_constants.dart';
import '../../localization/app_localizations.dart';
import '../../router/app_routes.dart';
import '../../theme/app_breakpoints.dart';
import '../../../core/modules/module_providers.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../shared/widgets/service_launcher.dart';

/// Platform home: launches business modules via the module registry.
class ServiceLauncherPage extends ConsumerWidget {
  const ServiceLauncherPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final registry = ref.watch(moduleRegistryProvider);
    final width = MediaQuery.sizeOf(context).width;
    final showSettingsAction = AppBreakpoints.isMobile(width);

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.appTitle,
        actions: [
          if (showSettingsAction)
            CustomAppBarAction(
              icon: Icons.settings_outlined,
              tooltip: l10n.settingsTitle,
              onPressed: () => context.push(AppRoutes.settings),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: ServiceLauncher(
          title: l10n.servicesTitle,
          subtitle: l10n.servicesSubtitle,
          modules: registry.enabledModules,
          onModuleSelected: (module) {
            if (!module.isEnabled) {
              return;
            }
            context.push(module.rootRoute);
          },
        ),
      ),
    );
  }
}
