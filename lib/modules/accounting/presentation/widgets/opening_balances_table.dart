import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/settings/company/app_currency.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_amount_field.dart';
import '../../domain/models/opening_balance_line.dart';

class _Cols {
  static const index = 44.0;
  static const currency = 140.0;
  static const debit = 140.0;
  static const credit = 140.0;
  static const actions = 48.0;
  static const hPad = AppSpacing.sm;

  static double get contentWidth => index + currency + debit + credit + actions;

  static double get width => contentWidth + hPad * 2;
}

/// One account group of opening-balance currency lines.
class OpeningBalanceAccountGroup {
  const OpeningBalanceAccountGroup({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.lines,
  });

  final String accountId;
  final String accountCode;
  final String accountName;
  final List<OpeningBalanceLine> lines;
}

/// Per-account spreadsheet tables for opening balances (import-table style).
class OpeningBalancesTables extends StatelessWidget {
  const OpeningBalancesTables({
    super.key,
    required this.groups,
    required this.configuredCurrencies,
    required this.defaultCurrencyCode,
    required this.enabled,
    required this.onChanged,
    required this.onRemoveLine,
    required this.onRemoveAccount,
    required this.onAddCurrencyLine,
  });

  final List<OpeningBalanceAccountGroup> groups;
  final List<AppCurrency> configuredCurrencies;
  final String defaultCurrencyCode;
  final bool enabled;
  final ValueChanged<OpeningBalanceLine> onChanged;
  final ValueChanged<String> onRemoveLine;
  final ValueChanged<String> onRemoveAccount;
  final void Function({
    required String accountId,
    required String accountCode,
    required String accountName,
  }) onAddCurrencyLine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (groups.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.35,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            l10n.accountingOpeningSetupEmptyBalances,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < groups.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          _AccountBalanceTable(
            group: groups[i],
            configuredCurrencies: configuredCurrencies,
            defaultCurrencyCode: defaultCurrencyCode,
            enabled: enabled,
            onChanged: onChanged,
            onRemoveLine: onRemoveLine,
            onRemoveAccount: onRemoveAccount,
            onAddCurrencyLine: onAddCurrencyLine,
          ),
        ],
      ],
    );
  }
}

class _AccountBalanceTable extends StatefulWidget {
  const _AccountBalanceTable({
    required this.group,
    required this.configuredCurrencies,
    required this.defaultCurrencyCode,
    required this.enabled,
    required this.onChanged,
    required this.onRemoveLine,
    required this.onRemoveAccount,
    required this.onAddCurrencyLine,
  });

  final OpeningBalanceAccountGroup group;
  final List<AppCurrency> configuredCurrencies;
  final String defaultCurrencyCode;
  final bool enabled;
  final ValueChanged<OpeningBalanceLine> onChanged;
  final ValueChanged<String> onRemoveLine;
  final ValueChanged<String> onRemoveAccount;
  final void Function({
    required String accountId,
    required String accountCode,
    required String accountName,
  }) onAddCurrencyLine;

  @override
  State<_AccountBalanceTable> createState() => _AccountBalanceTableState();
}

class _AccountBalanceTableState extends State<_AccountBalanceTable> {
  final _horizontalScroll = ScrollController();

  @override
  void dispose() {
    _horizontalScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final tableWidth = math.max(_Cols.width, viewportWidth - 48);
    final group = widget.group;
    final usedCurrencies = {
      for (final line in group.lines)
        line.currencyCode.trim().toUpperCase(),
    };
    final canAddCurrency = widget.configuredCurrencies.any(
      (c) => !usedCurrencies.contains(c.code),
    );

    return DecoratedBox(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${group.accountCode} — ${group.accountName}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.accountingOpeningSetupRemoveAccount,
                      onPressed: widget.enabled
                          ? () => widget.onRemoveAccount(group.accountId)
                          : null,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ),
            ),
            Scrollbar(
              controller: _horizontalScroll,
              thumbVisibility: true,
              radius: const Radius.circular(8),
              notificationPredicate: (n) =>
                  n.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: _horizontalScroll,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      _TableHeader(theme: theme, l10n: l10n),
                      for (var i = 0; i < group.lines.length; i++)
                        _CurrencyDataRow(
                          key: ValueKey(group.lines[i].id),
                          index: i,
                          row: group.lines[i],
                          striped: i.isOdd,
                          enabled: widget.enabled,
                          configuredCurrencies: widget.configuredCurrencies,
                          defaultCurrencyCode: widget.defaultCurrencyCode,
                          usedCurrenciesForAccount: {
                            for (final line in group.lines)
                              if (line.id != group.lines[i].id)
                                line.currencyCode.trim().toUpperCase(),
                          },
                          onChanged: widget.onChanged,
                          onRemove: widget.onRemoveLine,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: widget.enabled && canAddCurrency
                    ? () => widget.onAddCurrencyLine(
                          accountId: group.accountId,
                          accountCode: group.accountCode,
                          accountName: group.accountName,
                        )
                    : null,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(l10n.accountingOpeningSetupAddCurrencyLine),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.theme, required this.l10n});

  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final style = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    return ColoredBox(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            const SizedBox(width: _Cols.hPad),
            SizedBox(
              width: _Cols.index,
              child: Text('#', style: style, textAlign: TextAlign.center),
            ),
            SizedBox(
              width: _Cols.currency,
              child: Text(l10n.accountingImportCurrency, style: style),
            ),
            SizedBox(
              width: _Cols.debit,
              child: Text(l10n.accountingImportOpeningDebit, style: style),
            ),
            SizedBox(
              width: _Cols.credit,
              child: Text(l10n.accountingImportOpeningCredit, style: style),
            ),
            const SizedBox(width: _Cols.actions),
            const SizedBox(width: _Cols.hPad),
          ],
        ),
      ),
    );
  }
}

class _CurrencyDataRow extends StatelessWidget {
  const _CurrencyDataRow({
    super.key,
    required this.index,
    required this.row,
    required this.striped,
    required this.enabled,
    required this.configuredCurrencies,
    required this.defaultCurrencyCode,
    required this.usedCurrenciesForAccount,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final OpeningBalanceLine row;
  final bool striped;
  final bool enabled;
  final List<AppCurrency> configuredCurrencies;
  final String defaultCurrencyCode;
  final Set<String> usedCurrenciesForAccount;
  final ValueChanged<OpeningBalanceLine> onChanged;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final bg = striped
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.28)
        : scheme.surface;

    final selectedCurrency = () {
      final code = row.currencyCode.trim().toUpperCase().isEmpty
          ? defaultCurrencyCode
          : row.currencyCode.trim().toUpperCase();
      if (configuredCurrencies.any((c) => c.code == code)) {
        return code;
      }
      return configuredCurrencies.isNotEmpty
          ? configuredCurrencies.first.code
          : defaultCurrencyCode;
    }();

    final currencyItems = [
      for (final currency in configuredCurrencies)
        if (currency.code == selectedCurrency ||
            !usedCurrenciesForAccount.contains(currency.code))
          currency,
    ];

    return ColoredBox(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: _Cols.hPad),
            SizedBox(
              width: _Cols.index,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '${index + 1}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _Cols.currency,
              child: DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: currencyItems.any((c) => c.code == selectedCurrency)
                    ? selectedCurrency
                    : (currencyItems.isNotEmpty
                        ? currencyItems.first.code
                        : null),
                isExpanded: true,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final currency in currencyItems)
                    DropdownMenuItem(
                      value: currency.code,
                      child: Text(currency.code),
                    ),
                ],
                onChanged: enabled
                    ? (value) {
                        if (value != null) {
                          onChanged(row.copyWith(currencyCode: value));
                        }
                      }
                    : null,
              ),
            ),
            SizedBox(
              width: _Cols.debit,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AppAmountField(
                  value: row.debit,
                  enabled: enabled,
                  variant: AppAmountFieldVariant.compact,
                  emptyWhenZero: true,
                  onChanged: (value) => onChanged(
                    row.copyWith(
                      debit: value,
                      credit: value > 0 ? 0 : row.credit,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _Cols.credit,
              child: AppAmountField(
                value: row.credit,
                enabled: enabled,
                variant: AppAmountFieldVariant.compact,
                emptyWhenZero: true,
                onChanged: (value) => onChanged(
                  row.copyWith(
                    credit: value,
                    debit: value > 0 ? 0 : row.debit,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _Cols.actions,
              child: IconButton(
                tooltip: l10n.accountingImportRemoveRow,
                onPressed: enabled ? () => onRemove(row.id) : null,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ),
            const SizedBox(width: _Cols.hPad),
          ],
        ),
      ),
    );
  }
}
