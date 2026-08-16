import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/digit_normalization.dart';
import '../../../../core/widgets/app_amount_field.dart';
import '../../domain/services/rp_currency_port.dart';
import '../../domain/services/rp_treasury_account_port.dart';
import '../providers/rp_providers.dart';
import '../providers/transaction_composer_provider.dart';

/// Fixed multi-column widths — matched to [SaleProductsTable] proportions.
class _Cols {
  static const index = 44.0;
  static const account = 168.0;
  static const amount = 148.0;
  static const currency = 88.0;
  static const rate = 96.0;
  static const narrative = 220.0;
  static const actions = 48.0;

  /// Matches horizontal padding on header / filled rows.
  static const hPad = AppSpacing.sm;

  static double get contentWidth =>
      index + account + amount + currency + rate + narrative + actions;

  /// Outer scroll width: columns + side padding (avoids Row overflow).
  static double get width => contentWidth + hPad * 2;
}

/// Spreadsheet-style CoA allocations — chrome matched to Sales products table.
class RpEntryLinesTable extends ConsumerStatefulWidget {
  const RpEntryLinesTable({
    super.key,
    required this.lines,
    required this.cashCurrencyCode,
    required this.currencies,
    required this.amountColumnLabel,
    required this.onAccountSelected,
    required this.onAmountChanged,
    required this.onCrossRateChanged,
    required this.onCurrencyChanged,
    required this.onLineDescriptionChanged,
    required this.onRemoveLine,
  });

  final List<ComposerEntryLine> lines;
  final String cashCurrencyCode;
  final List<RpCurrencyRef> currencies;
  final String amountColumnLabel;
  final ValueChanged<RpAccountRef> onAccountSelected;
  final void Function(int index, double amount) onAmountChanged;
  final void Function(int index, double rate) onCrossRateChanged;
  final void Function(int index, String code, double rateToBase)
      onCurrencyChanged;
  final void Function(int index, String value) onLineDescriptionChanged;
  final ValueChanged<int> onRemoveLine;

  @override
  ConsumerState<RpEntryLinesTable> createState() => _RpEntryLinesTableState();
}

class _RpEntryLinesTableState extends ConsumerState<RpEntryLinesTable> {
  final List<int> _draftRowIds = [];
  var _nextDraftId = 0;
  final _horizontalScroll = ScrollController();

  @override
  void dispose() {
    _horizontalScroll.dispose();
    super.dispose();
  }

  void _addDraftRow() {
    setState(() => _draftRowIds.add(_nextDraftId++));
  }

  void _removeDraftRow(int id) {
    setState(() => _draftRowIds.remove(id));
  }

  void _onDraftAccountSelected(int draftId, RpAccountRef account) {
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onAccountSelected(account);
    _removeDraftRow(draftId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final filled = [
      for (final line in widget.lines)
        if (line.account != null) line,
    ];
    final hasContent = filled.isNotEmpty || _draftRowIds.isNotEmpty;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final tableWidth = math.max(_Cols.width, viewportWidth - 48);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: l10n.rpFormSectionLines),
        const SizedBox(height: AppSpacing.md),
        if (!hasContent)
          _EmptyAddCard(
            onAdd: _addDraftRow,
            addLabel: l10n.rpAddAccountLine,
            emptyLabel: l10n.rpLinesEmpty,
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
                            _TableHeader(
                              theme: theme,
                              l10n: l10n,
                              amountColumnLabel: widget.amountColumnLabel,
                            ),
                            for (var i = 0; i < filled.length; i++)
                              _FilledLineRow(
                                index: i,
                                line: filled[i],
                                striped: i.isOdd,
                                cashCurrencyCode: widget.cashCurrencyCode,
                                currencies: widget.currencies,
                                onAmountChanged: (amount) =>
                                    widget.onAmountChanged(i, amount),
                                onCrossRateChanged: (rate) =>
                                    widget.onCrossRateChanged(i, rate),
                                onCurrencyChanged: (code, rate) =>
                                    widget.onCurrencyChanged(i, code, rate),
                                onLineDescriptionChanged: (value) =>
                                    widget.onLineDescriptionChanged(i, value),
                                onRemove: () => widget.onRemoveLine(i),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  for (final draftId in _draftRowIds)
                    _DraftAccountRow(
                      key: ValueKey('draft-$draftId'),
                      onAccountSelected: (account) {
                        _onDraftAccountSelected(draftId, account);
                      },
                      onCancel: () => _removeDraftRow(draftId),
                    ),
                  _TableActionsBar(
                    onAdd: _addDraftRow,
                    addLabel: l10n.rpAddAnotherAccountLine,
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

class _TableActionsBar extends StatelessWidget {
  const _TableActionsBar({
    required this.onAdd,
    required this.addLabel,
  });

  final VoidCallback onAdd;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm + 4,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AddRowButton(label: addLabel, onTap: onAdd),
          ),
        ],
      ),
    );
  }
}

class _AddRowButton extends StatelessWidget {
  const _AddRowButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary,
                Color.lerp(scheme.primary, scheme.primaryContainer, 0.28)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: scheme.onPrimary.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: scheme.onPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyAddCard extends StatelessWidget {
  const _EmptyAddCard({
    required this.onAdd,
    required this.addLabel,
    required this.emptyLabel,
  });

  final VoidCallback onAdd;
  final String addLabel;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: scheme.outlineVariant.withValues(alpha: 0.75),
          radius: AppRadius.lg,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary.withValues(alpha: 0.16),
                      scheme.primary.withValues(alpha: 0.06),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.playlist_add_rounded,
                  color: scheme.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                emptyLabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _AddRowButton(label: addLabel, onTap: onAdd),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
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
              textAlign: TextAlign.center,
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
            child: Text(
              l10n.rpLineDescription,
              style: style,
            ),
          ),
          const SizedBox(width: _Cols.actions),
        ],
      ),
    );
  }
}

class _FilledLineRow extends StatefulWidget {
  const _FilledLineRow({
    required this.index,
    required this.line,
    required this.striped,
    required this.cashCurrencyCode,
    required this.currencies,
    required this.onAmountChanged,
    required this.onCrossRateChanged,
    required this.onCurrencyChanged,
    required this.onLineDescriptionChanged,
    required this.onRemove,
  });

  final int index;
  final ComposerEntryLine line;
  final bool striped;
  final String cashCurrencyCode;
  final List<RpCurrencyRef> currencies;
  final ValueChanged<double> onAmountChanged;
  final ValueChanged<double> onCrossRateChanged;
  final void Function(String code, double rateToBase) onCurrencyChanged;
  final ValueChanged<String> onLineDescriptionChanged;
  final VoidCallback onRemove;

  @override
  State<_FilledLineRow> createState() => _FilledLineRowState();
}

class _FilledLineRowState extends State<_FilledLineRow> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final account = widget.line.account!;

    return ColoredBox(
      color: widget.striped
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _Cols.index,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Center(
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.index + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _Cols.account,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 2),
                child: Text(
                  account.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _Cols.amount,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 2, end: 4),
                child: AppAmountField(
                  value: widget.line.amount,
                  emptyWhenZero: true,
                  decimalPlaces: 0,
                  variant: AppAmountFieldVariant.compact,
                  skipTraversal: true,
                  onChanged: widget.onAmountChanged,
                ),
              ),
            ),
            SizedBox(
              width: _Cols.currency,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _CompactCurrencyField(
                  value: widget.line.currencyCode,
                  currencies: widget.currencies,
                  onChanged: widget.onCurrencyChanged,
                ),
              ),
            ),
            SizedBox(
              width: _Cols.rate,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AppAmountField(
                  value: widget.line.crossRate,
                  emptyWhenZero: false,
                  decimalPlaces: 6,
                  trimTrailingZeros: true,
                  variant: AppAmountFieldVariant.compact,
                  skipTraversal: true,
                  onChanged: (rate) {
                    if (rate > 0) widget.onCrossRateChanged(rate);
                  },
                ),
              ),
            ),
            SizedBox(
              width: _Cols.narrative,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _CompactTextField(
                  value: widget.line.resolvedDescription,
                  onChanged: widget.onLineDescriptionChanged,
                  maxLines: 2,
                ),
              ),
            ),
            SizedBox(
              width: _Cols.actions,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: IconButton(
                  tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                  onPressed: widget.onRemove,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: scheme.error.withValues(alpha: 0.85),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftAccountRow extends ConsumerStatefulWidget {
  const _DraftAccountRow({
    super.key,
    required this.onAccountSelected,
    required this.onCancel,
  });

  final ValueChanged<RpAccountRef> onAccountSelected;
  final VoidCallback onCancel;

  @override
  ConsumerState<_DraftAccountRow> createState() => _DraftAccountRowState();
}

class _DraftAccountRowState extends ConsumerState<_DraftAccountRow> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode(skipTraversal: true);
  final _session = _SearchSession();
  var _loading = false;
  var _showResults = false;
  var _searchFailed = false;
  List<RpAccountRef> _results = const [];

  static const _minQueryLength = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future<void>.delayed(const Duration(milliseconds: 140), () {
          if (mounted && !_focusNode.hasFocus) {
            setState(() => _showResults = false);
          }
        });
      } else if (normalizeDigitsToWestern(_controller.text).trim().length >=
          _minQueryLength) {
        setState(() => _showResults = true);
      }
    });
  }

  @override
  void dispose() {
    _session.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final query = normalizeDigitsToWestern(value).trim();
    if (query.length < _minQueryLength) {
      _session.invalidate();
      setState(() {
        _results = const [];
        _loading = false;
        _showResults = false;
        _searchFailed = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _showResults = true;
      _searchFailed = false;
    });
    _session.schedule((token) => _search(query, token));
  }

  Future<void> _search(String query, int token) async {
    try {
      final languageCode = Localizations.localeOf(context).languageCode;
      final results = await ref
          .read(rpTreasuryAccountPortProvider)
          .searchPostingAccounts(
            query,
            limit: 50,
            languageCode: languageCode,
          );
      if (!mounted || !_session.isCurrent(token)) {
        return;
      }
      setState(() {
        _results = results;
        _loading = false;
        _showResults = true;
        _searchFailed = false;
      });
    } catch (_) {
      if (!mounted || !_session.isCurrent(token)) {
        return;
      }
      setState(() {
        _results = const [];
        _loading = false;
        _showResults = true;
        _searchFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final query = normalizeDigitsToWestern(_controller.text).trim();

    return ColoredBox(
      color: scheme.primaryContainer.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              inputFormatters: const [WesternDigitsInputFormatter()],
              textInputAction: TextInputAction.done,
              onChanged: _onChanged,
              onEditingComplete: () => _focusNode.unfocus(),
              onSubmitted: (_) => _focusNode.unfocus(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: scheme.surface,
                hintText: l10n.rpSearchAccountHint,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: scheme.primary,
                ),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .cancelButtonLabel,
                        onPressed: widget.onCancel,
                        icon: Icon(
                          Icons.close_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide(
                    color: scheme.primary,
                    width: 1.4,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 14,
                ),
              ),
            ),
          ),
          if (_showResults && query.length >= _minQueryLength)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Material(
                color: scheme.surface,
                elevation: 2,
                shadowColor: scheme.shadow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : _searchFailed
                          ? Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Text(
                                l10n.somethingWentWrong,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.error,
                                ),
                              ),
                            )
                          : _results.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Text(
                                    l10n.rpLinesEmpty,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: _results.length,
                                  separatorBuilder: (_, _) => Divider(
                                    height: 1,
                                    color: scheme.outlineVariant.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                  itemBuilder: (context, index) {
                                    final account = _results[index];
                                    final code = account.code.trim();
                                    return InkWell(
                                      onTap: () {
                                        _focusNode.unfocus();
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                        widget.onAccountSelected(account);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.md,
                                          vertical: AppSpacing.sm + 2,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    account.name,
                                                    style: theme
                                                        .textTheme.bodyMedium
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  if (code.isNotEmpty)
                                                    Text(
                                                      code,
                                                      style: theme
                                                          .textTheme.labelSmall
                                                          ?.copyWith(
                                                        color: scheme
                                                            .onSurfaceVariant,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchSession {
  var _token = 0;
  final _debounceMs = 300;

  void schedule(void Function(int token) run) {
    final token = ++_token;
    Future<void>.delayed(Duration(milliseconds: _debounceMs), () {
      if (token == _token) {
        run(token);
      }
    });
  }

  void invalidate() => _token++;

  bool isCurrent(int token) => token == _token;

  void dispose() => invalidate();
}

class _CompactTextField extends StatefulWidget {
  const _CompactTextField({
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  State<_CompactTextField> createState() => _CompactTextFieldState();
}

class _CompactTextFieldState extends State<_CompactTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode(skipTraversal: true);
  }

  @override
  void didUpdateWidget(covariant _CompactTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus &&
        oldWidget.value != widget.value &&
        _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: widget.maxLines,
      minLines: widget.maxLines > 1 ? widget.maxLines : 1,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: widget.maxLines > 1 ? 12 : 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      onChanged: widget.onChanged,
      onEditingComplete: () => _focusNode.unfocus(),
      onSubmitted: (_) => _focusNode.unfocus(),
    );
  }
}

class _CompactCurrencyField extends StatelessWidget {
  const _CompactCurrencyField({
    required this.value,
    required this.currencies,
    required this.onChanged,
  });

  final String value;
  final List<RpCurrencyRef> currencies;
  final void Function(String code, double rateToBase) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final codes = {for (final c in currencies) c.code};
    final effective = codes.contains(value)
        ? value
        : (currencies.isNotEmpty ? currencies.first.code : value);

    return DropdownButtonFormField<String>(
      key: ValueKey(effective),
      initialValue: effective,
      isExpanded: true,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      items: [
        for (final c in currencies)
          DropdownMenuItem(
            value: c.code,
            child: Text(c.code, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (code) {
        if (code == null) return;
        for (final c in currencies) {
          if (c.code == code) {
            onChanged(c.code, c.rateToBase);
            return;
          }
        }
      },
    );
  }
}
