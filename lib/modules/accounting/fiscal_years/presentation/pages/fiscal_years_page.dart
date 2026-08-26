import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_empty_state.dart';
import 'package:stock_count/core/widgets/app_error_state.dart';
import 'package:stock_count/core/widgets/app_loading.dart';
import 'package:stock_count/core/widgets/app_status_badge.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import '../../domain/entities/accounting_period_status.dart';
import 'package:stock_count/modules/accounting/journals/presentation/providers/journal_providers.dart';
import 'package:stock_count/modules/accounting/shared/presentation/pages/accounting_routes.dart';

/// Lists configured fiscal years.
class FiscalYearsPage extends ConsumerWidget {
  const FiscalYearsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(fiscalYearSummariesProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.accountingFiscalYearsTitle,
        showBackButton: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AccountingRoutes.pushFiscalYearCreate(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.accountingFiscalYearsAdd),
      ),
      body: async.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(fiscalYearSummariesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return AppEmptyState(
              title: l10n.accountingFiscalYearsEmptyTitle,
              subtitle: l10n.accountingFiscalYearsEmptyMessage,
              icon: Icons.date_range_outlined,
            );
          }
          final dateFmt = DateFormat.yMMMd();
          return ListView.separated(
            padding: AppConstants.pageInsets(context).copyWith(bottom: 88),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = items[index];
              final fy = item.fiscalYear;
              return Material(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: () =>
                      AccountingRoutes.pushFiscalYearDetails(context, fy.uuid),
                  child: Ink(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                fy.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            AppStatusBadge(
                              label: fy.status == FiscalYearStatus.open
                                  ? l10n.accountingPeriodStatusOpen
                                  : l10n.accountingPeriodStatusClosed,
                              tone: fy.status == FiscalYearStatus.open
                                  ? AppStatusTone.success
                                  : AppStatusTone.neutral,
                              animate: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${fy.code} · ${dateFmt.format(fy.startDate.toLocal())}'
                          ' – ${dateFmt.format(fy.endDate.toLocal())}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.accountingFiscalYearOpenPeriods(
                            item.openPeriodCount,
                          ),
                          style: theme.textTheme.labelMedium,
                        ),
                        Text(
                          l10n.accountingFiscalYearClosedPeriods(
                            item.closedPeriodCount,
                          ),
                          style: theme.textTheme.labelMedium,
                        ),
                        if (fy.fxRevaluationEnabled)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              l10n.accountingFiscalYearFxEnabled,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
