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

/// Sub-menu for one R&P service (receipts or payments).
class RpServiceMenuPage extends ConsumerWidget {
  const RpServiceMenuPage({super.key, required this.type});

  final TransactionType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isReceipt = type == TransactionType.receipt;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: isReceipt
            ? l10n.rpServiceReceiptsTitle
            : l10n.rpServicePaymentsTitle,
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          Text(
            isReceipt
                ? l10n.rpServiceReceiptsSubtitle
                : l10n.rpServicePaymentsSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PermissionGate(
            anyOf: isReceipt
                ? ReceiptsPaymentsPermissions.receiptsView
                : ReceiptsPaymentsPermissions.paymentsView,
            child: _MenuCard(
                  icon: Icons.list_alt_outlined,
                  title: isReceipt
                      ? l10n.rpServiceViewReceipts
                      : l10n.rpServiceViewPayments,
                  subtitle: isReceipt
                      ? l10n.rpServiceViewReceiptsSubtitle
                      : l10n.rpServiceViewPaymentsSubtitle,
                  onTap: () =>
                      ReceiptsPaymentsRoutes.pushList(context, type: type),
                )
                .animate()
                .fadeIn(duration: 260.ms)
                .slideY(begin: 0.04, end: 0, duration: 260.ms),
          ),
          const SizedBox(height: AppSpacing.md),
          PermissionGate(
            anyOf: isReceipt
                ? ReceiptsPaymentsPermissions.receiptsCreate
                : ReceiptsPaymentsPermissions.paymentsCreate,
            child: _MenuCard(
                  icon: isReceipt
                      ? Icons.call_received_outlined
                      : Icons.call_made_outlined,
                  title: isReceipt
                      ? l10n.rpServiceCreateReceipt
                      : l10n.rpServiceCreatePayment,
                  subtitle: isReceipt
                      ? l10n.rpCreateReceiptSubtitle
                      : l10n.rpCreatePaymentSubtitle,
                  onTap: () {
                    if (isReceipt) {
                      ReceiptsPaymentsRoutes.pushCreateReceipt(context);
                    } else {
                      ReceiptsPaymentsRoutes.pushCreatePayment(context);
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
