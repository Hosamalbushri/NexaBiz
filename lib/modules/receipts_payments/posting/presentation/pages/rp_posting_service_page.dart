import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_colors.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_shadows.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/services/loading_providers.dart';
import 'package:stock_count/core/widgets/app_dialog.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/core/domain/services/device_document_number.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_list_item.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/permissions/receipts_payments_permission_package.dart';
import '../providers/rp_posting_service_provider.dart';
import 'package:stock_count/modules/receipts_payments/transactions/presentation/utils/rp_labels.dart';
import 'package:stock_count/modules/receipts_payments/transactions/presentation/widgets/rp_error_messages.dart';
import 'package:stock_count/modules/receipts_payments/transactions/presentation/widgets/transaction_status_badge.dart';

/// Bulk post / unpost for receipts, payments, transfers, and exchanges.
class RpPostingServicePage extends ConsumerStatefulWidget {
  const RpPostingServicePage({super.key});

  @override
  ConsumerState<RpPostingServicePage> createState() =>
      _RpPostingServicePageState();
}

class _RpPostingServicePageState extends ConsumerState<RpPostingServicePage> {
  late final TextEditingController _numberFromController;
  late final TextEditingController _numberToController;

  @override
  void initState() {
    super.initState();
    _numberFromController = TextEditingController();
    _numberToController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final allowed = _allowedTypes(ref);
      if (allowed.isEmpty) return;
      final current = ref.read(rpPostingServiceProvider).transactionType;
      if (!allowed.contains(current)) {
        ref
            .read(rpPostingServiceProvider.notifier)
            .setTransactionType(allowed.first);
      }
    });
  }

  @override
  void dispose() {
    _numberFromController.dispose();
    _numberToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(rpPostingServiceProvider);
    final notifier = ref.read(rpPostingServiceProvider.notifier);
    final allowedTypes = _allowedTypes(ref);
    final selectedType = allowedTypes.contains(state.transactionType)
        ? state.transactionType
        : (allowedTypes.isEmpty ? state.transactionType : allowedTypes.first);
    final isPost = state.operation == RpPostingOperation.post;
    final filterError = _filterErrorMessage(l10n, state.error);
    final accent = isPost ? AppColors.success : scheme.tertiary;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.rpPostingServiceTitle,
        showBackButton: true,
      ),
      body: allowedTypes.isEmpty
          ? _EmptyPermission(message: l10n.rpPostingServiceNoPermission)
          : Column(
              children: [
                _ModeRibbon(
                  isPost: isPost,
                  label: isPost ? l10n.rpPost : l10n.rpUnpost,
                  hint: l10n.rpPostingServiceSubtitle,
                ),
                Expanded(
                  child: ListView(
                    padding: AppConstants.pageInsets(context),
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      _CriteriaPanel(
                        accent: accent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _StepBlock(
                              index: 1,
                              title: l10n.rpPostingServiceDocumentType,
                              child: _TypeGrid(
                                types: allowedTypes,
                                selected: selectedType,
                                enabled: !state.isApplying,
                                onChanged: notifier.setTransactionType,
                              ),
                            ),
                            const _Hairline(),
                            _StepBlock(
                              index: 2,
                              title: l10n.rpPostingServiceOperation,
                              child: _SegmentedToggle<RpPostingOperation>(
                                left: _SegItem(
                                  value: RpPostingOperation.post,
                                  label: l10n.rpPost,
                                  icon: Icons.check_circle_rounded,
                                ),
                                right: _SegItem(
                                  value: RpPostingOperation.unpost,
                                  label: l10n.rpUnpost,
                                  icon: Icons.undo_rounded,
                                ),
                                selected: state.operation,
                                enabled: !state.isApplying,
                                activeColor: accent,
                                onChanged: notifier.setOperation,
                              ),
                            ),
                            const _Hairline(),
                            _StepBlock(
                              index: 3,
                              title: l10n.rpPostingServiceLookup,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _SegmentedToggle<RpPostingLookupMode>(
                                    left: _SegItem(
                                      value: RpPostingLookupMode.byDate,
                                      label: l10n.rpDate,
                                      icon: Icons.calendar_month_rounded,
                                    ),
                                    right: _SegItem(
                                      value: RpPostingLookupMode.byNumber,
                                      label: l10n.rpTransactionNumber,
                                      icon: Icons.tag_rounded,
                                    ),
                                    selected: state.lookupMode,
                                    enabled: !state.isApplying,
                                    activeColor: scheme.primary,
                                    onChanged: (mode) {
                                      notifier.setLookupMode(mode);
                                      if (mode ==
                                          RpPostingLookupMode.byNumber) {
                                        _numberFromController.text =
                                            state.numberFrom;
                                        _numberToController.text =
                                            state.numberTo;
                                      }
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  if (state.lookupMode ==
                                      RpPostingLookupMode.byDate)
                                    _RangeRow(
                                      start: _DateField(
                                        label: l10n.rpPostingServiceFromDate,
                                        value: state.fromDate,
                                        placeholder:
                                            l10n.rpPostingServicePickDate,
                                        enabled: !state.isApplying,
                                        onTap: () => _pickDate(isFrom: true),
                                      ),
                                      end: _DateField(
                                        label: l10n.rpPostingServiceToDate,
                                        value: state.toDate,
                                        placeholder:
                                            l10n.rpPostingServicePickDate,
                                        enabled: !state.isApplying,
                                        onTap: () => _pickDate(isFrom: false),
                                      ),
                                    )
                                  else
                                    _RangeRow(
                                      start: TextField(
                                        controller: _numberFromController,
                                        enabled: !state.isApplying,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        decoration: _fieldDecoration(
          context,
          label: l10n.rpPostingServiceFromNumber,
          hint: l10n.rpPostingServiceNumberHint,
        ),
        onChanged: notifier.setNumberFrom,
        textInputAction: TextInputAction.next,
      ),
      end: TextField(
        controller: _numberToController,
        enabled: !state.isApplying,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        decoration: _fieldDecoration(
          context,
          label: l10n.rpPostingServiceToNumber,
          hint: l10n.rpPostingServiceNumberHint,
        ),
        onChanged: notifier.setNumberTo,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _search(),
      ),
    ),
                                  if (filterError != null) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    _InlineError(message: filterError),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            FilledButton(
                              onPressed: state.isLoading || state.isApplying
                                  ? null
                                  : _search,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                backgroundColor: scheme.primary,
                                foregroundColor: scheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.control,
                                  ),
                                ),
                              ),
                              child: state.isLoading
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: scheme.onPrimary,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.search_rounded),
                                        const SizedBox(width: AppSpacing.xs),
                                        Text(
                                          l10n.rpPostingServiceSearch,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: scheme.onPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 260.ms)
                          .slideY(begin: 0.02, end: 0, duration: 260.ms),
                      if (state.hasSearched) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _ResultsShell(
                          title: l10n.rpPostingServiceResultsCount(
                            state.items.length,
                          ),
                          badge: isPost ? l10n.rpPost : l10n.rpUnpost,
                          badgeColor: accent,
                          child: state.items.isEmpty
                              ? _EmptyResults(
                                  message: l10n.rpPostingServiceEmpty,
                                )
                              : Column(
                                  children: [
                                    for (var i = 0;
                                        i < state.items.length;
                                        i++) ...[
                                      if (i > 0) const _Hairline(indent: 16),
                                      _LedgerRow(
                                        item: state.items[i],
                                        selected: state.selectedId ==
                                            state.items[i].id,
                                        enabled: !state.isApplying,
                                        accent: accent,
                                        onTap: () => notifier.selectItem(
                                          state.items[i].id,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                        )
                            .animate()
                            .fadeIn(delay: 60.ms, duration: 260.ms)
                            .slideY(
                              begin: 0.02,
                              end: 0,
                              delay: 60.ms,
                              duration: 260.ms,
                            ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  ),
                ),
                if (state.hasSearched && state.items.isNotEmpty)
                  _ActionDock(
                    isPost: isPost,
                    accent: accent,
                    selectedSummary: _selectedSummary(l10n, state),
                    canApplySelected:
                        !state.isApplying && state.selectedId != null,
                    canApplyAll: !state.isApplying,
                    selectedLabel: isPost
                        ? l10n.rpPostingServiceApplySelectedPost
                        : l10n.rpPostingServiceApplySelectedUnpost,
                    allLabel: isPost
                        ? l10n.rpPostingServiceApplyAllPost(state.items.length)
                        : l10n.rpPostingServiceApplyAllUnpost(
                            state.items.length,
                          ),
                    onApplySelected: _applySelected,
                    onApplyAll: _applyAll,
                  ),
              ],
            ),
    );
  }

  String? _selectedSummary(AppLocalizations l10n, RpPostingServiceState state) {
    final id = state.selectedId;
    if (id == null) return l10n.rpPostingServiceSelectOne;
    for (final item in state.items) {
      if (item.id == id) {
        return formatSaleNumberPrimary(item.transactionNumber);
      }
    }
    return l10n.rpPostingServiceSelectOne;
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    required String hint,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: theme.textTheme.labelSmall?.copyWith(
        color: scheme.primary,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: theme.textTheme.bodySmall?.copyWith(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
    );
  }

  String? _filterErrorMessage(AppLocalizations l10n, Object? error) {
    return switch (error) {
      'date_required' => l10n.rpPostingServiceDateRequired,
      'date_range_invalid' => l10n.rpPostingServiceDateRangeInvalid,
      'number_required' => l10n.rpPostingServiceNumberRequired,
      'number_range_invalid' => l10n.rpPostingServiceNumberRangeInvalid,
      _ => null,
    };
  }

  List<TransactionType> _allowedTypes(WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final types = <TransactionType>[];
    if (auth.hasAnyPermission(ReceiptsPaymentsPermissions.receiptsPost)) {
      types.add(TransactionType.receipt);
    }
    if (auth.hasAnyPermission(ReceiptsPaymentsPermissions.paymentsPost)) {
      types.add(TransactionType.payment);
    }
    if (auth.hasAnyPermission(ReceiptsPaymentsPermissions.transfersPost)) {
      types.add(TransactionType.transfer);
    }
    if (auth.hasAnyPermission(ReceiptsPaymentsPermissions.exchangesPost)) {
      types.add(TransactionType.currencyExchange);
    }
    return types;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final state = ref.read(rpPostingServiceProvider);
    final now = DateTime.now();
    final initial = isFrom
        ? (state.fromDate ?? state.toDate ?? now)
        : (state.toDate ?? state.fromDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    final notifier = ref.read(rpPostingServiceProvider.notifier);
    if (isFrom) {
      notifier.setFromDate(picked);
      if (state.toDate == null) notifier.setToDate(picked);
    } else {
      notifier.setToDate(picked);
      if (state.fromDate == null) notifier.setFromDate(picked);
    }
  }

  Future<void> _search() async {
    await ref.read(rpPostingServiceProvider.notifier).search();
  }

  Future<void> _applySelected() async {
    final l10n = AppLocalizations.of(context);
    final state = ref.read(rpPostingServiceProvider);
    TransactionListItem? item;
    for (final e in state.items) {
      if (e.id == state.selectedId) {
        item = e;
        break;
      }
    }
    if (item == null) return;
    final number = formatSaleNumberPrimary(item.transactionNumber);
    final ok = await showAppDialog(
      context: context,
      title: state.operation == RpPostingOperation.post
          ? l10n.rpPost
          : l10n.rpUnpost,
      message: state.operation == RpPostingOperation.post
          ? l10n.rpPostingServiceConfirmOnePost(number)
          : l10n.rpPostingServiceConfirmOneUnpost(number),
      confirmLabel: state.operation == RpPostingOperation.post
          ? l10n.rpPost
          : l10n.rpUnpost,
    );
    if (ok != true || !mounted) return;
    await _runApply(
      () => ref.read(rpPostingServiceProvider.notifier).applySelected(),
    );
  }

  Future<void> _applyAll() async {
    final l10n = AppLocalizations.of(context);
    final state = ref.read(rpPostingServiceProvider);
    final ok = await showAppDialog(
      context: context,
      title: state.operation == RpPostingOperation.post
          ? l10n.rpPost
          : l10n.rpUnpost,
      message: state.operation == RpPostingOperation.post
          ? l10n.rpPostingServiceConfirmAllPost(state.items.length)
          : l10n.rpPostingServiceConfirmAllUnpost(state.items.length),
      confirmLabel: state.operation == RpPostingOperation.post
          ? l10n.rpPostingServiceApplyAllPost(state.items.length)
          : l10n.rpPostingServiceApplyAllUnpost(state.items.length),
    );
    if (ok != true || !mounted) return;
    await _runApply(
      () => ref.read(rpPostingServiceProvider.notifier).applyAll(),
    );
  }

  Future<void> _runApply(
    Future<({int success, int failed, Object? firstError})> Function() action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final loading = ref.read(loadingControllerProvider);
    final state = ref.read(rpPostingServiceProvider);
    if (loading.isVisible) return;
    await loading.run(
      message: state.operation == RpPostingOperation.post
          ? l10n.rpPosting
          : l10n.rpUnposting,
      action: () async {
        final result = await action();
        if (!mounted) return;
        if (result.firstError == 'none_selected') {
          showAppSnackBar(
            context,
            message: l10n.rpPostingServiceSelectOne,
            isSuccess: false,
          );
          return;
        }
        if (result.failed == 0) {
          showAppSnackBar(
            context,
            message: state.operation == RpPostingOperation.post
                ? l10n.rpPostingServiceSuccessPost(result.success)
                : l10n.rpPostingServiceSuccessUnpost(result.success),
            isSuccess: true,
          );
        } else if (result.success == 0) {
          showAppSnackBar(
            context,
            message: rpErrorMessage(l10n, result.firstError ?? 'failed'),
            isSuccess: false,
          );
        } else {
          showAppSnackBar(
            context,
            message: l10n.rpPostingServicePartial(
              result.success,
              result.failed,
            ),
            isSuccess: false,
          );
        }
      },
    );
  }
}

class _ModeRibbon extends StatelessWidget {
  const _ModeRibbon({
    required this.isPost,
    required this.label,
    required this.hint,
  });

  final bool isPost;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = isPost ? AppColors.success : scheme.tertiary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isPost ? Icons.verified_outlined : Icons.history_toggle_off_rounded,
            color: accent.withValues(alpha: 0.85),
          ),
        ],
      ),
    );
  }
}

class _CriteriaPanel extends StatelessWidget {
  const _CriteriaPanel({required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: AppShadows.card(brightness),
      ),
      child: Column(
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
              gradient: LinearGradient(
                colors: [
                  accent,
                  accent.withValues(alpha: 0.35),
                  scheme.primary.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _StepBlock extends StatelessWidget {
  const _StepBlock({
    required this.index,
    required this.title,
    required this.child,
  });

  final int index;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$index',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          child,
        ],
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline({this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context)
            .colorScheme
            .outlineVariant
            .withValues(alpha: 0.45),
      ),
    );
  }
}

class _TypeGrid extends StatelessWidget {
  const _TypeGrid({
    required this.types,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final List<TransactionType> types;
  final TransactionType selected;
  final bool enabled;
  final ValueChanged<TransactionType> onChanged;

  IconData _icon(TransactionType type) => switch (type) {
        TransactionType.receipt => Icons.call_received_rounded,
        TransactionType.payment => Icons.call_made_rounded,
        TransactionType.transfer => Icons.swap_horiz_rounded,
        TransactionType.currencyExchange => Icons.currency_exchange_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = AppSpacing.xs;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final type in types)
              SizedBox(
                width: width,
                child: Material(
                  color: type == selected
                      ? scheme.primary.withValues(alpha: 0.1)
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  child: InkWell(
                    onTap: enabled && type != selected
                        ? () => onChanged(type)
                        : null,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm + 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.control),
                        border: Border.all(
                          color: type == selected
                              ? scheme.primary.withValues(alpha: 0.55)
                              : scheme.outlineVariant.withValues(alpha: 0.4),
                          width: type == selected ? 1.4 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _icon(type),
                            size: 18,
                            color: type == selected
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rpTransactionTypeLabel(l10n, type),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: type == selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: type == selected
                                    ? scheme.primary
                                    : scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SegItem<T> {
  const _SegItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  final T value;
  final String label;
  final IconData icon;
}

class _SegmentedToggle<T> extends StatelessWidget {
  const _SegmentedToggle({
    required this.left,
    required this.right,
    required this.selected,
    required this.enabled,
    required this.activeColor,
    required this.onChanged,
  });

  final _SegItem<T> left;
  final _SegItem<T> right;
  final T selected;
  final bool enabled;
  final Color activeColor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegButton(
              item: left,
              selected: selected == left.value,
              enabled: enabled,
              activeColor: activeColor,
              onTap: () => onChanged(left.value),
            ),
          ),
          Expanded(
            child: _SegButton(
              item: right,
              selected: selected == right.value,
              enabled: enabled,
              activeColor: activeColor,
              onTap: () => onChanged(right.value),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegButton<T> extends StatelessWidget {
  const _SegButton({
    required this.item,
    required this.selected,
    required this.enabled,
    required this.activeColor,
    required this.onTap,
  });

  final _SegItem<T> item;
  final bool selected;
  final bool enabled;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? scheme.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: selected ? activeColor : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? activeColor : scheme.onSurfaceVariant,
                    ),
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

class _RangeRow extends StatelessWidget {
  const _RangeRow({required this.start, required this.end});

  final Widget start;
  final Widget end;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: start),
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Icon(
            Icons.east_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(child: end),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final String placeholder;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            floatingLabelStyle: theme.textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
              borderSide: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.65),
              ),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            suffixIcon: Icon(
              Icons.event_rounded,
              size: 16,
              color: scheme.primary.withValues(alpha: 0.8),
            ),
            filled: true,
            fillColor: Colors.transparent,
          ),
          child: Text(
            value == null ? placeholder : DateFormat('d/M/yyyy').format(value!),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: value == null ? FontWeight.w500 : FontWeight.w600,
              color: value == null ? scheme.onSurfaceVariant : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.error),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsShell extends StatelessWidget {
  const _ResultsShell({
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.child,
  });

  final String title;
  final String badge;
  final Color badgeColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: AppShadows.card(brightness),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    badge,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
          child,
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.item,
    required this.selected,
    required this.enabled,
    required this.accent,
    required this.onTap,
  });

  final TransactionListItem item;
  final bool selected;
  final bool enabled;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final party = (item.partyDisplayName ?? '').trim();
    final description = (item.description ?? '').trim();
    final amount = NumberFormat('#,##0.##').format(item.amount);
    final showParty = item.transactionType.isReceipt && party.isNotEmpty;
    final showDescription = !item.transactionType.isReceipt &&
        description.isNotEmpty;

    return Material(
      color: selected ? accent.withValues(alpha: 0.07) : Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 4,
                color: selected ? accent : Colors.transparent,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md - 4,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '#${formatSaleNumberPrimary(item.transactionNumber)}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                TransactionStatusBadge(
                                  status: item.documentStatus,
                                  label: rpTransactionStatusLabel(
                                    l10n,
                                    item.documentStatus,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('d/M/yyyy')
                                  .format(item.transactionDate),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            if (showParty) ...[
                              const SizedBox(height: 2),
                              Text(
                                party,
                                softWrap: true,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ],
                            if (showDescription) ...[
                              const SizedBox(height: 2),
                              Text(
                                description,
                                softWrap: true,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            amount,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              color: scheme.onSurface,
                            ),
                          ),
                          Text(
                            item.currencyCode,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: selected ? accent : scheme.outline,
                        size: 22,
                      ),
                    ],
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

class _ActionDock extends StatelessWidget {
  const _ActionDock({
    required this.isPost,
    required this.accent,
    required this.selectedSummary,
    required this.canApplySelected,
    required this.canApplyAll,
    required this.selectedLabel,
    required this.allLabel,
    required this.onApplySelected,
    required this.onApplyAll,
  });

  final bool isPost;
  final Color accent;
  final String? selectedSummary;
  final bool canApplySelected;
  final bool canApplyAll;
  final String selectedLabel;
  final String allLabel;
  final VoidCallback onApplySelected;
  final VoidCallback onApplyAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: brightness == Brightness.dark ? 0.35 : 0.08,
            ),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    isPost
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: accent,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      selectedSummary ?? '',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: canApplySelected
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: FilledButton(
                      onPressed: canApplySelected ? onApplySelected : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            scheme.onSurface.withValues(alpha: 0.12),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.control),
                        ),
                      ),
                      child: Text(
                        selectedLabel,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 4,
                    child: OutlinedButton(
                      onPressed: canApplyAll ? onApplyAll : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(color: accent.withValues(alpha: 0.55)),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.control),
                        ),
                      ),
                      child: Text(
                        allLabel,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ),
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

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 42,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPermission extends StatelessWidget {
  const _EmptyPermission({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: AppConstants.pageInsets(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 44,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
