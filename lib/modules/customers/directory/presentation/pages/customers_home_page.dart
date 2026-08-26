import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/authentication/presentation/widgets/permission_gate.dart';
import 'package:stock_count/modules/customers/permissions/customers_permission_package.dart';
import '../providers/customer_providers.dart';
import 'package:stock_count/modules/customers/shared/presentation/pages/customers_routes.dart';

/// Customers module hub.
class CustomersHomePage extends ConsumerWidget {
  const CustomersHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.moduleCustomers,
        showBackButton: true,
      ),
      body: ListView(
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
              l10n.moduleCustomersDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...[
              ref
                  .watch(customersParentAccountProvider)
                  .when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (parent) {
                      if (parent == null) {
                        return Text(
                          l10n.customersParentAccountNotSet,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        );
                      }
                      return Text(
                        l10n.customersParentAccountCurrent(
                          parent.code,
                          parent.name,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      );
                    },
                  ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _CustomersHubCard(
                  icon: Icons.people_outline,
                  title: l10n.customersListTitle,
                  subtitle: l10n.customersListCardSubtitle,
                  onTap: () => CustomersRoutes.goList(context),
                )
                .animate()
                .fadeIn(duration: 280.ms)
                .slideY(begin: 0.04, end: 0, duration: 280.ms),
            const SizedBox(height: AppSpacing.md),
            PermissionGate(
              anyOf: CustomersPermissions.accountsView,
              child: _CustomersHubCard(
                    icon: Icons.account_balance_outlined,
                    title: l10n.customersAccountsTitle,
                    subtitle: l10n.customersAccountsCardSubtitle,
                    onTap: () => CustomersRoutes.pushAccounts(context),
                  )
                  .animate()
                  .fadeIn(delay: 40.ms, duration: 280.ms)
                  .slideY(
                    begin: 0.04,
                    end: 0,
                    delay: 40.ms,
                    duration: 280.ms,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            PermissionGate(
              anyOf: CustomersPermissions.importOp,
              child: _CustomersHubCard(
                    icon: Icons.upload_file_outlined,
                    title: l10n.customersImportTitle,
                    subtitle: l10n.customersImportSubtitle,
                    onTap: () => CustomersRoutes.pushImport(context),
                  )
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 280.ms)
                  .slideY(
                    begin: 0.04,
                    end: 0,
                    delay: 80.ms,
                    duration: 280.ms,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            PermissionGate(
              anyOf: CustomersPermissions.settingsView,
              child: _CustomersHubCard(
                    icon: Icons.settings_outlined,
                    title: l10n.customersSettingsTitle,
                    subtitle: l10n.customersSettingsCardSubtitle,
                    onTap: () => CustomersRoutes.pushSettings(context),
                  )
                  .animate()
                  .fadeIn(delay: 120.ms, duration: 280.ms)
                  .slideY(
                    begin: 0.04,
                    end: 0,
                    delay: 120.ms,
                    duration: 280.ms,
                  ),
            ),
          ],
        ),
    );
  }
}

class _CustomersHubCard extends StatelessWidget {
  const _CustomersHubCard({
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

    return Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: AppSpacing.md),
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
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
