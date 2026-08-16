import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../authentication/presentation/widgets/permission_gate.dart';
import '../../permissions/receipts_payments_permission_package.dart';
import 'receipts_payments_routes.dart';

/// Receipts & Payments module hub — one entry per service.
class ReceiptsPaymentsHomePage extends ConsumerWidget {
  const ReceiptsPaymentsHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
        } else {
          router.go(AppRoutes.services);
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        appBar: CustomAppBar(
          title: l10n.moduleReceiptsPayments,
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
              l10n.moduleReceiptsPaymentsDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PermissionGate(
              anyOf: ReceiptsPaymentsPermissions.receiptsView,
              child: _HubCard(
                    icon: Icons.call_received_outlined,
                    title: l10n.rpServiceReceiptsTitle,
                    subtitle: l10n.rpServiceReceiptsSubtitle,
                    onTap: () => ReceiptsPaymentsRoutes.pushReceiptsMenu(context),
                  )
                  .animate()
                  .fadeIn(duration: 280.ms)
                  .slideY(begin: 0.04, end: 0, duration: 280.ms),
            ),
            const SizedBox(height: AppSpacing.md),
            PermissionGate(
              anyOf: ReceiptsPaymentsPermissions.paymentsView,
              child: _HubCard(
                    icon: Icons.call_made_outlined,
                    title: l10n.rpServicePaymentsTitle,
                    subtitle: l10n.rpServicePaymentsSubtitle,
                    onTap: () => ReceiptsPaymentsRoutes.pushPaymentsMenu(context),
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
          ],
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
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
