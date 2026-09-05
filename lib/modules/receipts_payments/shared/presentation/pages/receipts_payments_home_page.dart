import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_widgets.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/authentication/presentation/widgets/permission_gate.dart';
import 'package:stock_count/modules/receipts_payments/permissions/receipts_payments_permission_package.dart';
import 'receipts_payments_routes.dart';

/// Receipts & Payments module hub — one entry per service.
class ReceiptsPaymentsHomePage extends ConsumerWidget {
  const ReceiptsPaymentsHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
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
              child: AppModuleHubCard(
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
              child: AppModuleHubCard(
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
            const SizedBox(height: AppSpacing.md),
            PermissionGate(
              anyOf: ReceiptsPaymentsPermissions.transfersView,
              child: AppModuleHubCard(
                    icon: Icons.swap_horiz_outlined,
                    title: l10n.rpServiceTransfersTitle,
                    subtitle: l10n.rpServiceTransfersSubtitle,
                    onTap: () =>
                        ReceiptsPaymentsRoutes.pushTransfersMenu(context),
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
            const SizedBox(height: AppSpacing.md),
            PermissionGate(
              anyOf: ReceiptsPaymentsPermissions.exchangesView,
              child: AppModuleHubCard(
                    icon: Icons.currency_exchange_outlined,
                    title: l10n.rpServiceExchangesTitle,
                    subtitle: l10n.rpServiceExchangesSubtitle,
                    onTap: () =>
                        ReceiptsPaymentsRoutes.pushExchangesMenu(context),
                  )
                  .animate()
                  .fadeIn(delay: 180.ms, duration: 280.ms)
                  .slideY(
                    begin: 0.04,
                    end: 0,
                    delay: 180.ms,
                    duration: 280.ms,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            PermissionGate(
              anyOf: ReceiptsPaymentsPermissions.anyPost,
              child: AppModuleHubCard(
                    icon: Icons.fact_check_outlined,
                    title: l10n.rpPostingServiceTitle,
                    subtitle: l10n.rpPostingServiceHubSubtitle,
                    onTap: () =>
                        ReceiptsPaymentsRoutes.pushPostingService(context),
                  )
                  .animate()
                  .fadeIn(delay: 240.ms, duration: 280.ms)
                  .slideY(
                    begin: 0.04,
                    end: 0,
                    delay: 240.ms,
                    duration: 280.ms,
                  ),
            ),
          ],
        ),
    );
  }
}

