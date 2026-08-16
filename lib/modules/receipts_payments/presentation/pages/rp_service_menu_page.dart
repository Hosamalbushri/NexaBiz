import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../authentication/presentation/widgets/permission_gate.dart';
import '../../domain/entities/transaction_type.dart';
import '../../permissions/receipts_payments_permission_package.dart';
import 'receipts_payments_routes.dart';

/// Sub-menu for one R&P service (receipts, payments, transfers, or exchanges).
class RpServiceMenuPage extends ConsumerWidget {
  const RpServiceMenuPage({super.key, required this.type});

  final TransactionType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final title = switch (type) {
      TransactionType.receipt => l10n.rpServiceReceiptsTitle,
      TransactionType.payment => l10n.rpServicePaymentsTitle,
      TransactionType.transfer => l10n.rpServiceTransfersTitle,
      TransactionType.currencyExchange => l10n.rpServiceExchangesTitle,
    };
    final subtitle = switch (type) {
      TransactionType.receipt => l10n.rpServiceReceiptsSubtitle,
      TransactionType.payment => l10n.rpServicePaymentsSubtitle,
      TransactionType.transfer => l10n.rpServiceTransfersSubtitle,
      TransactionType.currencyExchange => l10n.rpServiceExchangesSubtitle,
    };
    final viewTitle = switch (type) {
      TransactionType.receipt => l10n.rpServiceViewReceipts,
      TransactionType.payment => l10n.rpServiceViewPayments,
      TransactionType.transfer => l10n.rpServiceViewTransfers,
      TransactionType.currencyExchange => l10n.rpServiceViewExchanges,
    };
    final viewSubtitle = switch (type) {
      TransactionType.receipt => l10n.rpServiceViewReceiptsSubtitle,
      TransactionType.payment => l10n.rpServiceViewPaymentsSubtitle,
      TransactionType.transfer => l10n.rpServiceViewTransfersSubtitle,
      TransactionType.currencyExchange => l10n.rpServiceViewExchangesSubtitle,
    };
    final createTitle = switch (type) {
      TransactionType.receipt => l10n.rpServiceCreateReceipt,
      TransactionType.payment => l10n.rpServiceCreatePayment,
      TransactionType.transfer => l10n.rpServiceCreateTransfer,
      TransactionType.currencyExchange => l10n.rpServiceCreateExchange,
    };
    final createSubtitle = switch (type) {
      TransactionType.receipt => l10n.rpCreateReceiptSubtitle,
      TransactionType.payment => l10n.rpCreatePaymentSubtitle,
      TransactionType.transfer => l10n.rpCreateTransferSubtitle,
      TransactionType.currencyExchange => l10n.rpCreateExchangeSubtitle,
    };
    final viewPermissions = switch (type) {
      TransactionType.receipt => ReceiptsPaymentsPermissions.receiptsView,
      TransactionType.payment => ReceiptsPaymentsPermissions.paymentsView,
      TransactionType.transfer => ReceiptsPaymentsPermissions.transfersView,
      TransactionType.currencyExchange =>
        ReceiptsPaymentsPermissions.exchangesView,
    };
    final createPermissions = switch (type) {
      TransactionType.receipt => ReceiptsPaymentsPermissions.receiptsCreate,
      TransactionType.payment => ReceiptsPaymentsPermissions.paymentsCreate,
      TransactionType.transfer => ReceiptsPaymentsPermissions.transfersCreate,
      TransactionType.currencyExchange =>
        ReceiptsPaymentsPermissions.exchangesCreate,
    };
    final createIcon = switch (type) {
      TransactionType.receipt => Icons.call_received_outlined,
      TransactionType.payment => Icons.call_made_outlined,
      TransactionType.transfer => Icons.swap_horiz_outlined,
      TransactionType.currencyExchange => Icons.currency_exchange_outlined,
    };

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: title,
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PermissionGate(
            anyOf: viewPermissions,
            child: _MenuCard(
                  icon: Icons.list_alt_outlined,
                  title: viewTitle,
                  subtitle: viewSubtitle,
                  onTap: () =>
                      ReceiptsPaymentsRoutes.pushList(context, type: type),
                )
                .animate()
                .fadeIn(duration: 260.ms)
                .slideY(begin: 0.04, end: 0, duration: 260.ms),
          ),
          const SizedBox(height: AppSpacing.md),
          PermissionGate(
            anyOf: createPermissions,
            child: _MenuCard(
                  icon: createIcon,
                  title: createTitle,
                  subtitle: createSubtitle,
                  onTap: () {
                    switch (type) {
                      case TransactionType.receipt:
                        ReceiptsPaymentsRoutes.pushCreateReceipt(context);
                      case TransactionType.payment:
                        ReceiptsPaymentsRoutes.pushCreatePayment(context);
                      case TransactionType.transfer:
                        ReceiptsPaymentsRoutes.pushCreateTransfer(context);
                      case TransactionType.currencyExchange:
                        ReceiptsPaymentsRoutes.pushCreateExchange(context);
                    }
                  },
                )
                .animate()
                .fadeIn(delay: 50.ms, duration: 260.ms)
                .slideY(
                  begin: 0.04,
                  end: 0,
                  delay: 50.ms,
                  duration: 260.ms,
                ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
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
