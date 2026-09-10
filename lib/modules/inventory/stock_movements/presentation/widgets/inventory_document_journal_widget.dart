import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/settings/company/app_currency.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_loading.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/account_labels.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/presentation/providers/journal_providers.dart';
import 'package:stock_count/app/localization/app_localizations.dart';

/// Widget displaying the accounting journal entry associated with an inventory document,
/// grouped clearly by currency with complete line details and base currency values.
class InventoryDocumentJournalWidget extends ConsumerWidget {
  const InventoryDocumentJournalWidget({
    super.key,
    required this.sourceType,
    required this.sourceId,
    required this.isPosted,
  });

  final String sourceType;
  final String sourceId;
  final bool isPosted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final journalAsync = ref.watch(
      journalBySourceProvider((sourceType: sourceType, sourceId: sourceId)),
    );

    return journalAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: const AppLoading(),
      ),
      error: (err, stack) => const SizedBox.shrink(),
      data: (entry) {
        if (entry == null) {
          return _UnpostedJournalInfoCard(isPosted: isPosted);
        }

        // Group lines by currencyCode
        final Map<String, List<JournalLine>> groupedLines = {};
        for (final line in entry.lines) {
          final code = line.currencyCode.trim().toUpperCase();
          groupedLines.putIfAbsent(code, () => []).add(line);
        }

        final double totalBaseDebit = entry.lines.fold(
          0.0,
          (sum, line) => sum + line.baseDebit,
        );
        final double totalBaseCredit = entry.lines.fold(
          0.0,
          (sum, line) => sum + line.baseCredit,
        );

        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: scheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'القيود المحاسبية للمستند (مفصلة حسب العملة)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'رقم القيد: ${entry.voucherNumber} | ${entry.voucherType}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: entry.isPosted
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: entry.isPosted
                              ? Colors.green.shade300
                              : Colors.orange.shade300,
                        ),
                      ),
                      child: Text(
                        entry.isPosted ? 'مرحّل' : 'مسودة',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: entry.isPosted
                              ? Colors.green.shade900
                              : Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Currency Sections
                for (final entryGroup in groupedLines.entries) ...[
                  _CurrencyGroupCard(
                    currencyCode: entryGroup.key,
                    lines: entryGroup.value,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                const SizedBox(height: AppSpacing.xs),
                const Divider(),
                const SizedBox(height: AppSpacing.xs),

                // Base Currency Totals Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'إجمالي بالعملة الرئيسية:',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${totalBaseDebit.toStringAsFixed(2)} / ${totalBaseCredit.toStringAsFixed(2)}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CurrencyGroupCard extends StatelessWidget {
  const _CurrencyGroupCard({
    required this.currencyCode,
    required this.lines,
  });

  final String currencyCode;
  final List<JournalLine> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final currency = AppCurrencies.byCode(currencyCode);

    final double groupDebit = lines.fold(0.0, (sum, line) => sum + line.debit);
    final double groupCredit = lines.fold(0.0, (sum, line) => sum + line.credit);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Currency Header Strip
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer.withValues(alpha: 0.35),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.md - 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currency.nameAr} (${currency.code})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSecondaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'المجموع: ${groupDebit > 0 ? groupDebit.toStringAsFixed(2) : groupCredit.toStringAsFixed(2)} ${currency.symbol}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: scheme.onSecondaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Lines List
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              children: [
                for (final line in lines) ...[
                  _JournalLineRow(line: line, currencySymbol: currency.symbol),
                  if (line != lines.last) const Divider(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalLineRow extends ConsumerWidget {
  const _JournalLineRow({
    required this.line,
    required this.currencySymbol,
  });

  final JournalLine line;
  final String currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final accountAsync = ref.watch(accountByUuidProvider(line.accountUuid));

    final isDebit = line.debit > 0;
    final amount = isDebit ? line.debit : line.credit;
    final baseAmount = isDebit ? line.baseDebit : line.baseCredit;

    final accountTitle = accountAsync.maybeWhen(
      data: (account) => account == null
          ? line.accountUuid
          : '${account.accountCode} - ${AccountLabels.displayName(l10n, account)}',
      orElse: () => line.accountUuid,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + account name
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDebit
                      ? Colors.blue.shade50
                      : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  isDebit ? Icons.add_circle_outline : Icons.remove_circle_outline,
                  color: isDebit ? Colors.blue.shade800 : Colors.amber.shade900,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  accountTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          if (line.lineDescription != null &&
              line.lineDescription!.trim().isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(right: 36),
              child: Text(
                line.lineDescription!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          // Amount row
          Padding(
            padding: const EdgeInsets.only(right: 36, top: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${isDebit ? "مدين" : "دائن"}: ${amount.toStringAsFixed(2)} $currencySymbol',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isDebit ? Colors.blue.shade900 : Colors.amber.shade900,
                  ),
                ),
                if (line.exchangeRateToBase > 0 && line.exchangeRateToBase != 1.0)
                  Flexible(
                    child: Text(
                      'معادل: ${baseAmount.toStringAsFixed(2)} (×${line.exchangeRateToBase.toStringAsFixed(2)})',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnpostedJournalInfoCard extends StatelessWidget {
  const _UnpostedJournalInfoCard({required this.isPosted});

  final bool isPosted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: scheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isPosted
                  ? 'يتم تحميل وتجهيز بيانات القيود المحاسبية التلقائية للمستند...'
                  : 'المستند في حالة مسودة (غير مرحّل). سيتم توليد وتثبيت القيد المحاسبي بالعملات تلقائياً عند الترحيل.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
