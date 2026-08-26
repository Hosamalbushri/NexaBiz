import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/services/loading_providers.dart';
import 'package:stock_count/core/utils/grouped_decimal_input.dart';
import 'package:stock_count/core/widgets/app_amount_field.dart';
import 'package:stock_count/core/widgets/app_button.dart';
import 'package:stock_count/core/widgets/app_error_state.dart';
import 'package:stock_count/core/widgets/app_loading.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/sales/invoices/domain/services/device_sale_number.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/financial_transaction_line.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/rp_payment_method.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_source.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_currency_port.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/services/rp_money.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_treasury_account_port.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_voucher_book_port.dart';
import 'package:stock_count/modules/receipts_payments/transactions/presentation/providers/rp_providers.dart';
import 'package:stock_count/modules/receipts_payments/transactions/presentation/providers/transaction_list_provider.dart';
import 'package:stock_count/modules/receipts_payments/transactions/presentation/widgets/rp_account_search_field.dart';
import 'package:stock_count/modules/receipts_payments/transactions/presentation/widgets/rp_error_messages.dart';
import 'package:stock_count/modules/receipts_payments/shared/presentation/pages/receipts_payments_routes.dart';

/// Slim form: transfer amount between two cash-box accounts.
class CashBoxTransferFormPage extends ConsumerStatefulWidget {
  const CashBoxTransferFormPage({super.key, this.transactionId});

  final int? transactionId;

  @override
  ConsumerState<CashBoxTransferFormPage> createState() =>
      _CashBoxTransferFormPageState();
}

class _CashBoxTransferFormPageState
    extends ConsumerState<CashBoxTransferFormPage> {
  final _descriptionController = TextEditingController();

  var _loading = true;
  var _saving = false;
  String? _loadError;

  DateTime _date = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  double _amount = 0;
  String _currencyCode = 'SAR';
  double _exchangeRate = 1;
  String _baseCurrencyCode = 'SAR';
  RpAccountRef? _fromAccount;
  RpAccountRef? _toAccount;
  RpVoucherBookRef? _voucherBook;
  String? _previewNumber;
  List<RpVoucherBookRef> _voucherBooks = const [];
  List<RpCurrencyRef> _currencies = const [];

  bool get _isEdit => widget.transactionId != null;

  double get _safeRate => _exchangeRate <= 0 ? 1.0 : _exchangeRate;

  double get _baseEquivalent => RpMoney.round(_amount * _safeRate);

  bool get _canSave =>
      !_saving &&
      _amount > 0 &&
      _fromAccount != null &&
      _toAccount != null &&
      _fromAccount!.accountId != _toAccount!.accountId &&
      (_voucherBook != null || _isEdit);

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
    try {
      await loading.run(
        message: l10n.rpLoading,
        action: () async {
          final currencyPort = ref.read(rpCurrencyPortProvider);
          _currencies = await currencyPort.listEnabledCurrencies();
          _baseCurrencyCode = await currencyPort.baseCurrencyCode;
          _currencyCode = _baseCurrencyCode;
          _exchangeRate = 1;

          _voucherBooks = await ref
              .read(rpVoucherBookPortProvider)
              .listActiveBooks(TransactionType.transfer);
          if (_voucherBooks.isNotEmpty) {
            _voucherBook = _voucherBooks.first;
            _previewNumber = _voucherBook!.previewNumber;
          }

          if (!mounted) {
            return;
          }
          final dateLabel = DateFormat('d/M/yyyy').format(_date);
          _descriptionController.text =
              l10n.rpDefaultTransferDescription(dateLabel);

          final treasury = ref.read(rpTreasuryAccountPortProvider);
          final languageCode = Localizations.localeOf(context).languageCode;
          final defaultCash = await treasury.findDefaultCashBox(
            languageCode: languageCode,
          );
          if (defaultCash != null) {
            _fromAccount = defaultCash;
          }

          if (_isEdit) {
            final txn = await ref
                .read(getFinancialTransactionByIdProvider)
                .call(widget.transactionId!);
            if (txn == null || !txn.transactionType.isTransfer) {
              throw StateError('not_found');
            }
            await _hydrateFromTransaction(txn, languageCode: languageCode);
          }
        },
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadError = null;
      });
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

  Future<void> _hydrateFromTransaction(
    FinancialTransaction txn, {
    required String languageCode,
  }) async {
    final treasury = ref.read(rpTreasuryAccountPortProvider);
    _date = txn.transactionDate.toLocal();
    _amount = txn.amount;
    _currencyCode = txn.currencyCode;
    _exchangeRate = txn.exchangeRate <= 0 ? 1 : txn.exchangeRate;
    _baseCurrencyCode = txn.baseCurrencyCode;
    _descriptionController.text = txn.description ?? '';
    _previewNumber = txn.transactionNumber;

    _fromAccount = await treasury.findById(
      txn.cashAccountId,
      languageCode: languageCode,
    );
    _toAccount = await treasury.findById(
      txn.counterAccountId,
      languageCode: languageCode,
    );

    if (txn.voucherBookId != null) {
      final book = await ref
          .read(rpVoucherBookPortProvider)
          .findById(txn.voucherBookId!);
      if (book != null) {
        _voucherBook = book;
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final previousLabel = DateFormat('d/M/yyyy').format(_date);
    final autoPrevious = l10n.rpDefaultTransferDescription(previousLabel);
    final currentDescription = _descriptionController.text.trim();
    setState(() => _date = picked);
    if (currentDescription.isEmpty || currentDescription == autoPrevious) {
      final nextLabel = DateFormat('d/M/yyyy').format(picked);
      _descriptionController.text =
          l10n.rpDefaultTransferDescription(nextLabel);
    }
  }

  Future<void> _pickCurrency() async {
    if (_currencies.isEmpty) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selected = await showModalBottomSheet<RpCurrencyRef>(
      context: context,
      useSafeArea: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  l10n.rpCurrency,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final currency in _currencies)
                ListTile(
                  leading: Icon(
                    currency.code == _currencyCode
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: currency.code == _currencyCode
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(currency.code),
                  subtitle: currency.isBase
                      ? Text(l10n.rpBaseCurrency)
                      : Text(
                          '${l10n.rpExchangeRate}: ${currency.rateToBase.toStringAsFixed(4)}',
                        ),
                  onTap: () => Navigator.of(ctx).pop(currency),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
    if (selected == null) {
      return;
    }
    setState(() {
      _currencyCode = selected.code;
      _exchangeRate = selected.rateToBase <= 0 ? 1 : selected.rateToBase;
    });
  }

  void _swapAccounts() {
    setState(() {
      final previousFrom = _fromAccount;
      _fromAccount = _toAccount;
      _toAccount = previousFrom;
    });
  }

  FinancialTransactionDraft _toDraft() {
    final from = _fromAccount!;
    final to = _toAccount!;
    final description = _descriptionController.text.trim();
    final rate = _safeRate;
    return FinancialTransactionDraft(
      transactionType: TransactionType.transfer,
      source: TransactionSource.cashBoxTransfer,
      transactionDate: _date,
      amount: _amount,
      currencyCode: _currencyCode,
      baseCurrencyCode: _baseCurrencyCode,
      exchangeRate: rate,
      counterAmount: _amount,
      counterCurrencyCode: _currencyCode,
      counterExchangeRate: rate,
      voucherBookId: _voucherBook?.bookId,
      cashAccountId: from.accountId,
      cashAccountCode: from.code,
      cashAccountName: from.name,
      counterAccountId: to.accountId,
      counterAccountCode: to.code,
      counterAccountName: to.name,
      description: description.isEmpty ? null : description,
      paymentMethod: RpPaymentMethod.cash,
      lines: [
        FinancialTransactionLine(
          accountId: to.accountId,
          accountCode: to.code,
          accountName: to.name,
          amount: _amount,
          currencyCode: _currencyCode,
          exchangeRate: rate,
          description: description.isEmpty ? null : description,
          lineOrder: 0,
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_canSave) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await ref
            .read(updateFinancialTransactionProvider)
            .call(widget.transactionId!, _toDraft());
        if (!mounted) {
          return;
        }
        showAppSnackBar(context, message: l10n.rpSaved, isSuccess: true);
        ref.invalidate(financialTransactionByIdProvider(widget.transactionId!));
        ref.invalidate(transactionListProvider);
        ReceiptsPaymentsRoutes.pushDetails(context, widget.transactionId!);
      } else {
        final created =
            await ref.read(createFinancialTransactionProvider).call(_toDraft());
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = _isEdit
        ? l10n.rpFormTitleTransferEdit
        : l10n.rpFormTitleTransfer;
    final numberLabel = _isEdit
        ? formatSaleNumberPrimary(_previewNumber ?? '—')
        : (_previewNumber ??
            _voucherBook?.previewNumber ??
            l10n.rpVoucherBookEmpty);
    final dateLabel = DateFormat('d/M/yyyy').format(_date);
    final rate = _safeRate;
    final equivalent = _baseEquivalent;
    final equivalentText = formatGroupedDecimal(
      equivalent,
      decimalPlaces: 2,
      emptyWhenZero: false,
    );

    if (_loading) {
      return Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: CustomAppBar(title: title, showBackButton: true),
        body: AppLoading(message: l10n.rpLoading),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: CustomAppBar(title: title, showBackButton: true),
        body: AppErrorState(
          message: _loadError!,
          onRetry: () {
            setState(() {
              _loading = true;
              _loadError = null;
            });
            _loadPage();
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: CustomAppBar(title: title, showBackButton: true),
      bottomNavigationBar: Material(
        color: scheme.surface,
        elevation: 8,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: AppButton(
              label: l10n.rpSave,
              onPressed: _canSave ? _save : null,
              isLoading: _saving,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          Material(
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
                          onTap: _pickDate,
                        ),
                      ),
                    ],
                  ),
                  if (!_isEdit && _voucherBooks.length > 1) ...[
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: _voucherBook?.bookId,
                      isExpanded: true,
                      decoration:
                          InputDecoration(labelText: l10n.rpVoucherBook),
                      items: [
                        for (final book in _voucherBooks)
                          DropdownMenuItem(
                            value: book.bookId,
                            child: Text(book.name, softWrap: true),
                          ),
                      ],
                      onChanged: (bookId) {
                        if (bookId == null) {
                          return;
                        }
                        RpVoucherBookRef? selected;
                        for (final book in _voucherBooks) {
                          if (book.bookId == bookId) {
                            selected = book;
                            break;
                          }
                        }
                        setState(() {
                          _voucherBook = selected;
                          _previewNumber = selected?.previewNumber;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 240.ms)
              .slideY(begin: 0.02, end: 0, duration: 240.ms),
          const SizedBox(height: AppSpacing.md),
          Material(
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
                  _CashBoxLane(
                    tone: scheme.error,
                    child: RpCashAccountDropdown(
                      label: l10n.rpTransferFromAccount,
                      selected: _fromAccount,
                      showSelectedNameBelow: true,
                      onSelected: (account) {
                        setState(() {
                          _fromAccount = account;
                          if (_toAccount?.accountId == account?.accountId) {
                            _toAccount = null;
                          }
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color:
                                scheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Material(
                          color: scheme.primary.withValues(alpha: 0.12),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: (_fromAccount != null || _toAccount != null)
                                ? _swapAccounts
                                : null,
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.swap_vert_rounded,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Divider(
                            color:
                                scheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _CashBoxLane(
                    tone: scheme.tertiary,
                    child: RpCashAccountDropdown(
                      label: l10n.rpTransferToAccount,
                      selected: _toAccount,
                      showSelectedNameBelow: true,
                      onSelected: (account) =>
                          setState(() => _toAccount = account),
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 40.ms, duration: 240.ms)
              .slideY(begin: 0.02, end: 0, delay: 40.ms, duration: 240.ms),
          const SizedBox(height: AppSpacing.md),
          Material(
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
                  AppAmountField(
                    value: _amount,
                    onChanged: (value) {
                      setState(() => _amount = value < 0 ? 0 : value);
                    },
                    decimalPlaces: 2,
                    emptyWhenZero: true,
                    label: l10n.rpAmount,
                    suffixText: _currencyCode,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _MetaTile(
                    icon: Icons.payments_outlined,
                    label: l10n.rpCurrency,
                    value: _currencyCode,
                    onTap: _pickCurrency,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ExchangeRateField(
                    value: rate,
                    onChanged: (value) {
                      if (value <= 0) {
                        return;
                      }
                      setState(() => _exchangeRate = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _EquivalentReadonly(
                    label: l10n.rpCurrencyEquivalent,
                    valueText: equivalentText,
                    currencyCode: _baseCurrencyCode,
                    rateHint: _currencyCode == _baseCurrencyCode
                        ? null
                        : '1 $_currencyCode = ${rate.toStringAsFixed(4)} $_baseCurrencyCode',
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 80.ms, duration: 240.ms)
              .slideY(begin: 0.02, end: 0, delay: 80.ms, duration: 240.ms),
          const SizedBox(height: AppSpacing.md),
          Material(
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
              child: TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.rpGeneralDescription,
                  alignLabelWithHint: true,
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 120.ms, duration: 240.ms)
              .slideY(begin: 0.02, end: 0, delay: 120.ms, duration: 240.ms),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _CashBoxLane extends StatelessWidget {
  const _CashBoxLane({
    required this.tone,
    required this.child,
  });

  final Color tone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: tone.withValues(alpha: 0.16)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: child,
    );
  }
}

class _ExchangeRateField extends StatelessWidget {
  const _ExchangeRateField({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
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
            child: Icon(
              Icons.currency_exchange_outlined,
              size: 16,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.rpExchangeRate,
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
                AppAmountField(
                  value: value,
                  onChanged: onChanged,
                  decimalPlaces: 6,
                  emptyWhenZero: false,
                  trimTrailingZeros: true,
                  variant: AppAmountFieldVariant.compact,
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EquivalentReadonly extends StatelessWidget {
  const _EquivalentReadonly({
    required this.label,
    required this.valueText,
    required this.currencyCode,
    this.rateHint,
  });

  final String label;
  final String valueText;
  final String currencyCode;
  final String? rateHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            softWrap: true,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (rateHint != null) ...[
            const SizedBox(height: 4),
            Text(
              rateHint!,
              softWrap: true,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  valueText.isEmpty ? '0.00' : valueText,
                  softWrap: true,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                currencyCode,
                softWrap: true,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
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
