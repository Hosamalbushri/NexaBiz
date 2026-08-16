import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/models/account_import_row.dart';

class _Cols {
  static const index = 44.0;
  static const code = 130.0;
  static const name = 420.0;
  static const actions = 48.0;
  static const hPad = AppSpacing.sm;

  static double get contentWidth => index + code + name + actions;

  static double get width => contentWidth + hPad * 2;
}

/// Spreadsheet-style editor for CoA import rows (code + name only).
class AccountImportRowsTable extends StatefulWidget {
  const AccountImportRowsTable({
    super.key,
    required this.rows,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
    required this.onAdd,
  });

  final List<AccountImportRow> rows;
  final bool enabled;
  final ValueChanged<AccountImportRow> onChanged;
  final ValueChanged<String> onRemove;
  final VoidCallback onAdd;

  @override
  State<AccountImportRowsTable> createState() => _AccountImportRowsTableState();
}

class _AccountImportRowsTableState extends State<AccountImportRowsTable> {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: l10n.accountingImportRowsTitle),
        const SizedBox(height: AppSpacing.md),
        if (widget.rows.isEmpty)
          _EmptyAddCard(
            emptyLabel: l10n.accountingImportEmptyRows,
            addLabel: l10n.accountingImportAddRow,
            onAdd: widget.enabled ? widget.onAdd : null,
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
              child: Column(
                children: [
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
                            for (var i = 0; i < widget.rows.length; i++)
                              _ImportDataRow(
                                key: ValueKey(widget.rows[i].id),
                                index: i,
                                row: widget.rows[i],
                                striped: i.isOdd,
                                enabled: widget.enabled,
                                onChanged: widget.onChanged,
                                onRemove: widget.onRemove,
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
                      onPressed: widget.enabled ? widget.onAdd : null,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text(l10n.accountingImportAddRow),
                    ),
                  ),
                ],
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
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _EmptyAddCard extends StatelessWidget {
  const _EmptyAddCard({
    required this.emptyLabel,
    required this.addLabel,
    required this.onAdd,
  });

  final String emptyLabel;
  final String addLabel;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(
              emptyLabel,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(addLabel),
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
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            const SizedBox(width: _Cols.hPad),
            SizedBox(
              width: _Cols.index,
              child: Text('#', style: style, textAlign: TextAlign.center),
            ),
            SizedBox(
              width: _Cols.code,
              child: Text(l10n.accountingFieldCode, style: style),
            ),
            SizedBox(
              width: _Cols.name,
              child: Text(l10n.accountingFieldName, style: style),
            ),
            const SizedBox(width: _Cols.actions),
            const SizedBox(width: _Cols.hPad),
          ],
        ),
      ),
    );
  }
}

class _ImportDataRow extends StatefulWidget {
  const _ImportDataRow({
    super.key,
    required this.index,
    required this.row,
    required this.striped,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final AccountImportRow row;
  final bool striped;
  final bool enabled;
  final ValueChanged<AccountImportRow> onChanged;
  final ValueChanged<String> onRemove;

  @override
  State<_ImportDataRow> createState() => _ImportDataRowState();
}

class _ImportDataRowState extends State<_ImportDataRow> {
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.row.code);
    _nameController = TextEditingController(text: widget.row.name);
  }

  @override
  void didUpdateWidget(covariant _ImportDataRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.id != widget.row.id) {
      _codeController.text = widget.row.code;
      _nameController.text = widget.row.name;
    } else {
      if (_codeController.text != widget.row.code) {
        _codeController.text = widget.row.code;
      }
      if (_nameController.text != widget.row.name) {
        _nameController.text = widget.row.name;
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final bg = widget.striped
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.28)
        : scheme.surface;

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
                  '${widget.index + 1}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _Cols.code,
              child: TextField(
                controller: _codeController,
                enabled: widget.enabled,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) =>
                    widget.onChanged(widget.row.copyWith(code: value)),
              ),
            ),
            SizedBox(
              width: _Cols.name,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: _nameController,
                  enabled: widget.enabled,
                  maxLines: null,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) =>
                      widget.onChanged(widget.row.copyWith(name: value)),
                ),
              ),
            ),
            SizedBox(
              width: _Cols.actions,
              child: IconButton(
                tooltip: l10n.accountingImportRemoveRow,
                onPressed: widget.enabled
                    ? () => widget.onRemove(widget.row.id)
                    : null,
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
