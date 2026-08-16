import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_amount_field.dart';
import '../../domain/entities/financial_transaction_line.dart';
import 'transaction_status_badge.dart';

/// Fixed multi-column widths — matched to [SaleProductsReadonlyTable].
class _Cols {
  static const index = 44.0;
  static const account = 220.0;
  static const amount = 128.0;
  static const currency = 88.0;
  static const rate = 96.0;
  static const narrative = 220.0;

  static const hPad = AppSpacing.sm;

  static double get contentWidth =>
      index + account + amount + currency + rate + narrative;

  static double get width => contentWidth + hPad * 2;
}

/// Read-only party / CoA allocation spreadsheet (invoice products style).
class RpEntryLinesReadonlyTable extends StatelessWidget {
  const RpEntryLinesReadonlyTable({
    super.key,
    required this.lines,
    required this.amountColumnLabel,
  });

  final List<FinancialTransactionLine> lines;
  final String amountColumnLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final tableWidth = math.max(_Cols.width, viewportWidth - 48);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: l10n.rpFormSectionLines),
        const SizedBox(height: AppSpacing.md),
        if (lines.isEmpty)
          Material(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                l10n.rpLinesEmpty,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: math.max(tableWidth, constraints.maxWidth),
                      child: Column(
                        children: [
                          _TableHeader(
                            theme: theme,
                            l10n: l10n,
                            amountColumnLabel: amountColumnLabel,
                          ),
                          for (var i = 0; i < lines.length; i++)
                            _ReadonlyLineRow(
                              index: i,
                              line: lines[i],
                              striped: i.isOdd,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary.withValues(alpha: 0.18),
                scheme.primary.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            Icons.account_tree_outlined,
            color: scheme.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.theme,
    required this.l10n,
    required this.amountColumnLabel,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final String amountColumnLabel;

  @override
  Widget build(BuildContext context) {
    final style = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.55,
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _Cols.index,
            child: Text('#', style: style, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: _Cols.account,
            child: Text(l10n.rpCounterAccount, style: style),
          ),
          SizedBox(
            width: _Cols.amount,
            child: Text(
              amountColumnLabel,
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
          SizedBox(
            width: _Cols.currency,
            child: Text(
              l10n.rpCurrency,
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: _Cols.rate,
            child: Text(
              l10n.rpManualExchangeRate,
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: _Cols.narrative,
            child: Text(l10n.rpLineDescription, style: style),
          ),
        ],
      ),
    );
  }
}

class _ReadonlyLineRow extends StatelessWidget {
  const _ReadonlyLineRow({
    required this.index,
    required this.line,
    required this.striped,
  });

  final int index;
  final FinancialTransactionLine line;
  final bool striped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cellStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final code = line.accountCode?.trim() ?? '';
    final name = line.accountName?.trim().isNotEmpty == true
        ? line.accountName!.trim()
        : line.accountId;
    final accountLabel = code.isEmpty ? name : '$code — $name';
    final narrative = line.description?.trim() ?? '';

    return ColoredBox(
      color: striped
          ? scheme.surfaceContainerHighest.withValues(alpha: 0.22)
          : scheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.28),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md + 4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _Cols.index,
              child: Center(
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _Cols.account,
              child: Text(
                accountLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: cellStyle,
              ),
            ),
            SizedBox(
              width: _Cols.amount,
              child: RpMoneyText(
                line.amount,
                textAlign: TextAlign.end,
                style: cellStyle?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ),
            SizedBox(
              width: _Cols.currency,
              child: Text(
                line.currencyCode,
                textAlign: TextAlign.center,
                style: cellStyle,
              ),
            ),
            SizedBox(
              width: _Cols.rate,
              child: Text(
                formatGroupedDecimal(
                  line.exchangeRate <= 0 ? 1 : line.exchangeRate,
                  decimalPlaces: 4,
                  trimTrailingZeros: true,
                ),
                textAlign: TextAlign.center,
                style: cellStyle,
              ),
            ),
            SizedBox(
              width: _Cols.narrative,
              child: Text(
                narrative.isEmpty ? '—' : narrative,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: cellStyle?.copyWith(
                  color: narrative.isEmpty
                      ? scheme.onSurfaceVariant
                      : scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
