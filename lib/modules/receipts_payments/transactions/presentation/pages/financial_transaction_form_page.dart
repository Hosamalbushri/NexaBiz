import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/services/loading_providers.dart';
import 'package:stock_count/core/widgets/app_amount_field.dart';
import 'package:stock_count/core/widgets/app_button.dart';
import 'package:stock_count/core/widgets/app_error_state.dart';
import 'package:stock_count/core/widgets/app_loading.dart';
import 'package:stock_count/core/widgets/app_select_field.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/app_text_field.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/core/domain/services/device_document_number.dart';
import '../../domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_currency_port.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_treasury_account_port.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_voucher_book_port.dart';
import '../providers/rp_providers.dart';
import '../providers/transaction_composer_provider.dart';
import '../providers/transaction_list_provider.dart';
import '../widgets/rp_account_search_field.dart';
import 'package:stock_count/app/exit/app_exit_scope.dart';
import '../widgets/rp_entry_lines_table.dart';
import 'package:stock_count/core/widgets/app_filter_sheet.dart';
import 'package:stock_count/core/widgets/app_kpi_tile.dart';
import 'package:stock_count/core/widgets/app_responsive_scaffold.dart';
import 'package:stock_count/modules/receipts_payments/shared/presentation/pages/receipts_payments_routes.dart';
import '../widgets/rp_error_messages.dart';

class FinancialTransactionFormPage extends ConsumerStatefulWidget {
  const FinancialTransactionFormPage({
    super.key,
    this.transactionType,
    this.transactionId,
  });

  final TransactionType? transactionType;
  final int? transactionId;

  @override
  ConsumerState<FinancialTransactionFormPage> createState() =>
      _FinancialTransactionFormPageState();
}

class _FinancialTransactionFormPageState
    extends ConsumerState<FinancialTransactionFormPage> {
  final _descriptionController = TextEditingController();
  var _loading = true;
  var _saving = false;
  String? _loadError;
  List<RpVoucherBookRef> _voucherBooks = const [];
  List<RpCurrencyRef> _currencies = const [];

  bool get _isEdit => widget.transactionId != null;

  var _dirty = false;

  TransactionType get _resolvedType {
    if (_isEdit) {
      return ref.read(transactionComposerProvider).transactionType;
    }
    return widget.transactionType ?? TransactionType.receipt;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPage());
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadPage() async {
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final loading = ref.read(loadingControllerProvider);

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      await loading.run(
        message: l10n.rpLoading,
        action: () async {
          final composer = ref.read(transactionComposerProvider.notifier);
          if (_isEdit) {
            final txn = await ref
                .read(getFinancialTransactionByIdProvider)
                .call(widget.transactionId!);
            if (!mounted) {
              return;
            }
            if (txn == null) {
              throw StateError('not_found');
            }
            composer.loadFromTransaction(txn);
            _syncControllersFromState();
            final treasury = ref.read(rpTreasuryAccountPortProvider);
            final languageCode =
                Localizations.localeOf(context).languageCode;
            final cash = await treasury.findById(
              txn.cashAccountId,
              languageCode: languageCode,
            );
            if (cash != null) {
              composer.setCashAccount(cash);
            }
            final resolved = txn.resolvedLines;
            for (var i = 0; i < resolved.length; i++) {
              final account = await treasury.findById(
                resolved[i].accountId,
                languageCode: languageCode,
              );
              if (account != null) {
                composer.setLineAccount(i, account);
              }
            }
            if (txn.voucherBookId != null) {
              final book = await ref
                  .read(rpVoucherBookPortProvider)
                  .findById(txn.voucherBookId!);
              if (book != null) {
                composer.setVoucherBook(book);
              }
            }
          } else {
            final dateLabel = DateFormat('d/M/yyyy').format(DateTime.now());
            await composer.loadDefaults(
              _resolvedType,
              defaultDescription: _resolvedType.isPayment
                  ? l10n.rpDefaultPaymentDescription(dateLabel)
                  : l10n.rpDefaultGeneralDescription,
            );
            _syncControllersFromState();
          }
          final currencyPort = ref.read(rpCurrencyPortProvider);
          _currencies = await currencyPort.listEnabledCurrencies();
          final base = await currencyPort.baseCurrencyCode;
          composer.setBaseCurrencyCode(base);
          _voucherBooks = await ref
              .read(rpVoucherBookPortProvider)
              .listActiveBooks(_resolvedType);
        },
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadError = null;
      });
      // Mark clean after initial load.
      if (mounted) {
        setState(() => _dirty = false);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadError = e.toString().contains('not_found')
            ? l10n.rpNotFound
            : rpErrorMessage(l10n, e);
      });
    }
  }

  void _syncControllersFromState() {
    final state = ref.read(transactionComposerProvider);
    _descriptionController.text = state.description ?? '';
  }

  Future<void> _pickDate() async {
    final current = ref.read(transactionComposerProvider).transactionDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    final notifier = ref.read(transactionComposerProvider.notifier);
    notifier.setDate(picked);
    setState(() => _dirty = true);
    if (!_resolvedType.isPayment || !mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final currentDescription =
        ref.read(transactionComposerProvider).description?.trim() ?? '';
    final previousLabel = DateFormat('d/M/yyyy').format(current);
    final autoPrevious = l10n.rpDefaultPaymentDescription(previousLabel);
    if (currentDescription.isEmpty || currentDescription == autoPrevious) {
      final nextLabel = DateFormat('d/M/yyyy').format(picked);
      final nextDescription = l10n.rpDefaultPaymentDescription(nextLabel);
      notifier.setDescription(nextDescription);
      _descriptionController.text = nextDescription;
    }
  }

  Future<void> _pickCurrency() async {
    if (_currencies.isEmpty) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = ref.read(transactionComposerProvider).currencyCode;
    RpCurrencyRef? selectedCurrency;

    await AppFilterSheet.show<void>(
      context: context,
      title: l10n.rpCurrency,
      applyLabel: l10n.rpSave,
      onApply: () {},
      children: [
        for (final c in _currencies)
          ListTile(
            leading: Icon(
              c.code == current
                  ? Icons.check_circle
                  : Icons.circle_outlined,
              color: c.code == current
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(c.code),
            subtitle: c.isBase
                ? Text(l10n.rpBaseCurrency)
                : Text(
                    '${l10n.rpExchangeRate}: ${c.rateToBase.toStringAsFixed(4)}',
                  ),
            onTap: () {
              selectedCurrency = c;
              Navigator.of(context).pop();
            },
          ),
      ],
    );

    if (selectedCurrency != null) {
      ref.read(transactionComposerProvider.notifier).setCurrency(
            code: selectedCurrency!.code,
            rateToBase: selectedCurrency!.rateToBase,
          );
      setState(() => _dirty = true);
    }
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final state = ref.read(transactionComposerProvider);
    if (!state.isBalanced) {
      showAppSnackBar(
        context,
        message: l10n.rpErrorUnbalanced,
        isSuccess: false,
      );
      return;
    }
    final draft = state.toDraft();

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await ref
            .read(updateFinancialTransactionProvider)
            .call(widget.transactionId!, draft);
        if (!mounted) {
          return;
        }
        showAppSnackBar(context, message: l10n.rpSaved, isSuccess: true);
        ref.invalidate(financialTransactionByIdProvider(widget.transactionId!));
        ref.invalidate(transactionListProvider);
        ReceiptsPaymentsRoutes.pushDetails(context, widget.transactionId!);
      } else {
        final created =
            await ref.read(createFinancialTransactionProvider).call(draft);
        if (!mounted) {
          return;
        }
        showAppSnackBar(context, message: l10n.rpSaved, isSuccess: true);
        ref.invalidate(transactionListProvider);
        ref.invalidate(transactionDashboardProvider);
        ReceiptsPaymentsRoutes.pushDetails(context, created.id);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: rpErrorMessage(l10n, e),
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  bool _hasUnsavedChanges() {
    if (_loading || _saving) {
      return false;
    }
    if (_isEdit) {
      return _dirty;
    }
    // New transaction — dirty if composer has any meaningful content.
    final state = ref.read(transactionComposerProvider);
    return state.amount != 0 || state.lines.isNotEmpty || (state.description?.trim().isNotEmpty ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(transactionComposerProvider);
    final type = state.transactionType;
    final title = _isEdit
        ? l10n.rpEditTitle
        : (type.isReceipt ? l10n.rpFormTitleReceipt : l10n.rpFormTitlePayment);

    if (_loading) {
      return AppResponsiveScaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        appBar: CustomAppBar(title: title, showBackButton: true),
        body: AppLoading(message: l10n.rpLoading),
      );
    }

    if (_loadError != null) {
      return AppResponsiveScaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        appBar: CustomAppBar(title: title, showBackButton: true),
        body: AppErrorState(message: _loadError!, onRetry: _loadPage),
      );
    }

    final number = formatSaleNumberPrimary(
      state.previewTransactionNumber ?? state.voucherBook?.previewNumber ?? '—',
    );
    final dateLabel =
        DateFormat('d/M/yyyy').format(state.transactionDate.toLocal());
    final equivalentLabel =
        '${state.baseEquivalent.toStringAsFixed(2)} ${state.baseCurrencyCode}';

    return UnsavedChangesScope(
      hasUnsavedChanges: _hasUnsavedChanges,
      child: AppResponsiveScaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        appBar: CustomAppBar(title: title, showBackButton: true),
        body: ListView(
          padding: AppConstants.pageInsets(context),
          children: [
            _HeaderCard(
              numberLabel: number,
              dateLabel: dateLabel,
              onPickDate: _pickDate,
              voucherBooks: _voucherBooks,
              selectedBook: state.voucherBook,
              canChangeBook: !_isEdit,
              onBookChanged: (book) {
                ref
                    .read(transactionComposerProvider.notifier)
                    .setVoucherBook(book);
                setState(() => _dirty = true);
              },
              cashAccount: state.cashAccount,
              onCashSelected: (account) {
                ref
                    .read(transactionComposerProvider.notifier)
                    .setCashAccount(account);
              },
              cashAmount: state.amount,
              onCashAmountChanged: (value) {
                ref.read(transactionComposerProvider.notifier).setAmount(value);
                setState(() => _dirty = true);
              },
              currencyCode: state.currencyCode,
              onPickCurrency: _pickCurrency,
              equivalentLabel: equivalentLabel,
              exchangeRate: state.exchangeRate,
              descriptionController: _descriptionController,
              onDescriptionChanged: (value) {
                ref
                    .read(transactionComposerProvider.notifier)
                    .setDescription(value);
                setState(() => _dirty = true);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            RpEntryLinesTable(
              lines: state.lines,
              cashCurrencyCode: state.currencyCode,
              currencies: _currencies,
              amountColumnLabel: type.isReceipt
                  ? l10n.rpLineAmountCredit
                  : l10n.rpLineAmountDebit,
              onAccountSelected: (account) {
                ref
                    .read(transactionComposerProvider.notifier)
                    .addEntryLineWithAccount(account);
                setState(() => _dirty = true);
              },
              onAmountChanged: (index, amount) {
                ref
                    .read(transactionComposerProvider.notifier)
                    .setLineAmount(index, amount, manual: true);
                setState(() => _dirty = true);
              },
              onCrossRateChanged: (index, rate) {
                ref
                    .read(transactionComposerProvider.notifier)
                    .setLineCrossRate(index, rate);
                setState(() => _dirty = true);
              },
              onCurrencyChanged: (index, code, rate) {
                ref.read(transactionComposerProvider.notifier).setLineCurrency(
                      index: index,
                      code: code,
                      rateToBase: rate,
                    );
                setState(() => _dirty = true);
              },
              onLineDescriptionChanged: (index, value) {
                ref
                    .read(transactionComposerProvider.notifier)
                    .setLineDescription(index, value);
                setState(() => _dirty = true);
              },
              onRemoveLine: (index) {
                ref
                    .read(transactionComposerProvider.notifier)
                    .removeEntryLine(index);
                setState(() => _dirty = true);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _BalanceSummaryCard(
              debitLabel: l10n.rpTotalsDebit,
              creditLabel: l10n.rpTotalsCredit,
              differenceLabel: l10n.rpTotalsDifference,
              baseCurrencyCode: state.baseCurrencyCode,
              debit: state.totalDebitBase,
              credit: state.totalCreditBase,
              difference: state.balanceDifferenceBase,
              isBalanced: state.isBalanced,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
        bottomActions: AppBottomActions(
          child: AppButton(
            label: l10n.rpSave,
            onPressed: (_saving || !state.isBalanced) ? null : _save,
            isLoading: _saving,
            expand: true,
          ),
        ),
      ),
    );
  }
}

class _BalanceSummaryCard extends StatelessWidget {
  const _BalanceSummaryCard({
    required this.debitLabel,
    required this.creditLabel,
    required this.differenceLabel,
    required this.baseCurrencyCode,
    required this.debit,
    required this.credit,
    required this.difference,
    required this.isBalanced,
  });

  final String debitLabel;
  final String creditLabel;
  final String differenceLabel;
  final String baseCurrencyCode;
  final double debit;
  final double credit;
  final double difference;
  final bool isBalanced;

  String _fmt(double value) =>
      '${value.toStringAsFixed(2)} $baseCurrencyCode';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final differenceColor = isBalanced ? scheme.primary : scheme.error;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppKpiTile(
                    label: debitLabel,
                    value: _fmt(debit),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppKpiTile(
                    label: creditLabel,
                    value: _fmt(credit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppKpiTile(
              label: differenceLabel,
              value: _fmt(difference),
              valueColor: differenceColor,
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.numberLabel,
    required this.dateLabel,
    required this.onPickDate,
    required this.voucherBooks,
    required this.selectedBook,
    required this.canChangeBook,
    required this.onBookChanged,
    required this.cashAccount,
    required this.onCashSelected,
    required this.cashAmount,
    required this.onCashAmountChanged,
    required this.currencyCode,
    required this.onPickCurrency,
    required this.equivalentLabel,
    required this.exchangeRate,
    required this.descriptionController,
    required this.onDescriptionChanged,
  });

  final String numberLabel;
  final String dateLabel;
  final VoidCallback onPickDate;
  final List<RpVoucherBookRef> voucherBooks;
  final RpVoucherBookRef? selectedBook;
  final bool canChangeBook;
  final ValueChanged<RpVoucherBookRef?> onBookChanged;
  final RpAccountRef? cashAccount;
  final ValueChanged<RpAccountRef?> onCashSelected;
  final double cashAmount;
  final ValueChanged<double> onCashAmountChanged;
  final String currencyCode;
  final VoidCallback onPickCurrency;
  final String equivalentLabel;
  final double exchangeRate;
  final TextEditingController descriptionController;
  final ValueChanged<String> onDescriptionChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    RpVoucherBookRef? bookValue;
    if (selectedBook != null) {
      for (final book in voucherBooks) {
        if (book.bookId == selectedBook!.bookId) {
          bookValue = book;
          break;
        }
      }
    }
    bookValue ??= voucherBooks.isEmpty ? selectedBook : null;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _MetaTile(
                    icon: Icons.tag_rounded,
                    label: l10n.rpTransactionNumber,
                    value: numberLabel,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MetaTile(
                    icon: Icons.calendar_month_outlined,
                    label: l10n.rpDate,
                    value: dateLabel,
                    onTap: onPickDate,
                  ),
                ),
              ],
            ),
            if (voucherBooks.isNotEmpty && canChangeBook) ...[
              const SizedBox(height: AppSpacing.md),
              AppSelectField<RpVoucherBookRef?>(
                value: bookValue,
                label: l10n.rpVoucherBook,
                items: [
                  for (final book in voucherBooks)
                    AppSelectItem(
                      value: book,
                      label: '${book.name} (${book.previewNumber})',
                    ),
                ],
                onChanged: canChangeBook ? onBookChanged : null,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            RpCashAccountDropdown(
              label: l10n.rpCashAccount,
              selected: cashAccount,
              hintText: l10n.rpCashAccount,
              onSelected: onCashSelected,
            ),
            const SizedBox(height: AppSpacing.md),
            AppAmountField(
              value: cashAmount,
              onChanged: onCashAmountChanged,
              decimalPlaces: 0,
              emptyWhenZero: true,
              label: l10n.rpCashAmount,
              suffixText: currencyCode,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MetaTile(
                    icon: Icons.payments_outlined,
                    label: l10n.rpCurrency,
                    value: currencyCode,
                    onTap: onPickCurrency,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MetaTile(
                    icon: Icons.currency_exchange_outlined,
                    label: l10n.rpCurrencyEquivalent,
                    value: equivalentLabel,
                    secondaryValue: exchangeRate == 1
                        ? null
                        : '${l10n.rpExchangeRate}: ${exchangeRate.toStringAsFixed(4)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: descriptionController,
              label: l10n.rpGeneralDescription,
              prefixIcon: Icons.notes_outlined,
              maxLines: 3,
              onChanged: onDescriptionChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
    this.secondaryValue,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? secondaryValue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: scheme.primary),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        value,
                        maxLines: 1,
                        softWrap: false,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.15,
                          height: 1.15,
                        ),
                      ),
                    ),
                    if (secondaryValue != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        secondaryValue!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.edit_outlined,
                  size: 15,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
