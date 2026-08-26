import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/shared/presentation/pages/sales_routes.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../providers/dashboard_recent_operations_provider.dart';

/// Recent sales operations under the dashboard service grid.
class DashboardRecentOperations extends ConsumerWidget {
  const DashboardRecentOperations({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final async = ref.watch(dashboardRecentSalesProvider);
    final money = NumberFormat('#,##0.00', 'en');
    final dateFmt = DateFormat('dd/MM/yyyy');

    final tileColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F4F7);
    final tileBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : colorScheme.outlineVariant.withValues(alpha: 0.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              l10n.dashboardRecentOperations,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.go(SalesRoutes.list),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n.dashboardRecentOperationsViewAll),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        async.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              l10n.somethingWentWrong,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: tileBorder),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 30,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.dashboardRecentOperationsEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  _RecentSaleTile(
                    title: l10n.dashboardRecentSaleInvoiceLine(
                      items[i].settlementType.isCash
                          ? l10n.salesSettlementCash
                          : l10n.salesSettlementCredit,
                      items[i].saleNumber,
                    ),
                    customerName:
                        items[i].customerName?.trim().isNotEmpty == true
                        ? items[i].customerName!.trim()
                        : l10n.salesWalkInCustomer,
                    amount:
                        '${money.format(items[i].total)} ${items[i].currencyCode}',
                    dateLabel: dateFmt.format(items[i].saleDate.toLocal()),
                    tileColor: tileColor,
                    tileBorder: tileBorder,
                    onTap: () => SalesRoutes.pushDetails(context, items[i].id),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RecentSaleTile extends StatelessWidget {
  const _RecentSaleTile({
    required this.title,
    required this.customerName,
    required this.amount,
    required this.dateLabel,
    required this.tileColor,
    required this.tileBorder,
    required this.onTap,
  });

  final String title;
  final String customerName;
  final String amount;
  final String dateLabel;
  final Color tileColor;
  final Color tileBorder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: tileBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.point_of_sale_outlined,
                    color: colorScheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.15,
                          fontSize: 13.5,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        customerName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dateLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11.5,
                              height: 1.3,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            amount,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              fontSize: 13.5,
                              color: colorScheme.primary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
