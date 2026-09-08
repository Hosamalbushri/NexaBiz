import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_widgets.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/authentication/presentation/widgets/permission_gate.dart';
import 'package:stock_count/modules/sales/permissions/sales_permission_package.dart';
import 'package:stock_count/modules/sales/shared/presentation/pages/sales_routes.dart';

/// Sales module hub.
class SalesHomePage extends ConsumerWidget {
  const SalesHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.moduleSales,
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => context.push('/sales/settings'),
          ),
        ],
      ),
      body: AppContentConstraint(
        child: ListView(
          padding: AppConstants.pageInsets(context),
          children: [
            Text(
              l10n.servicesTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.moduleSalesDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppModuleHubCard(
                  icon: Icons.receipt_long_outlined,
                  title: l10n.salesListTitle,
                  subtitle: l10n.salesListCardSubtitle,
                  onTap: () => SalesRoutes.goList(context),
                )
                .animate()
                .fadeIn(duration: 280.ms)
                .slideY(begin: 0.04, end: 0, duration: 280.ms),
            const SizedBox(height: AppSpacing.md),
            PermissionGate(
              anyOf: SalesPermissions.create,
              child:
                  AppModuleHubCard(
                        icon: Icons.add_shopping_cart_outlined,
                        title: l10n.salesCreateTitle,
                        subtitle: l10n.salesCreateCardSubtitle,
                        onTap: () => SalesRoutes.pushCreate(context),
                      )
                      .animate()
                      .fadeIn(delay: 60.ms, duration: 280.ms)
                      .slideY(
                        begin: 0.04,
                        end: 0,
                        delay: 60.ms,
                        duration: 280.ms,
                      ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppModuleHubCard(
                  icon: Icons.tune_outlined,
                  title: l10n.localeName == 'ar' ? 'إعدادات المبيعات' : 'Sales Settings',
                  subtitle: l10n.localeName == 'ar'
                      ? 'ربط الحسابات وإعدادات موديول المبيعات'
                      : 'Account bindings and sales master settings',
                  onTap: () => context.push('/sales/settings'),
                )
                .animate()
                .fadeIn(delay: 120.ms, duration: 280.ms)
                .slideY(
                  begin: 0.04,
                  end: 0,
                  delay: 120.ms,
                  duration: 280.ms,
                ),
          ],
        ),
      ),
    );
  }
}

