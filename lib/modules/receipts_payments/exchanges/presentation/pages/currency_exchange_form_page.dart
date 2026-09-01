import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/core/domain/services/device_document_number.dart';
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

/// Currency exchange within one cash box (from currency → to currency).
class CurrencyExchangeFormPage extends ConsumerStatefulWidget {
  const CurrencyExchangeFormPage({super.key, this.transactionId});

  final int? transactionId;

  @override
  ConsumerState<CurrencyExchangeFormPage> createState() =>
      _CurrencyExchangeFormPageState();
}

class _CurrencyExchangeFormPageState
    extends ConsumerState<CurrencyExchangeFormPage> {
  final _descriptionController = TextEditingController();

  var _loading = true;
  var _saving = false;
  String? _loadError;

  DateTime _date = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  double _fromAmount = 0;
  double _toAmount = 0;
  String _fromCurrency = 'SAR';
  String _toCurrency = 'USD';
  double _fromRate = 1;
  double _toRate = 1;
  String _baseCurrencyCode = 'SAR';
  RpAccountRef? _cashAccount;
  RpVoucherBookRef? _voucherBook;
  String? _previewNumber;
  List<RpVoucherBookRef> _voucherBooks = const [];
  List<RpCurrencyRef> _currencies = const [];
  var _syncingToAmount = false;

  bool get _isEdit => widget.transactionId != null;

  double get _safeFromRate => _fromRate <= 0 ? 1.0 : _fromRate;
  double get _safeToRate => _toRate <= 0 ? 1.0 : _toRate;

  double get _creditBase => RpMoney.round(_fromAmount * _safeFromRate);
  double get _debitBase => RpMoney.round(_toAmount * _safeToRate);
  double get _balanceDifference =>
      RpMoney.round((_debitBase - _creditBase).abs());
  bool get _isBalanced => _balanceDifference < 0.005;

  bool get _canSave =>
      !_saving &&
      _fromAmount > 0 &&
      _toAmount > 0 &&
      _isBalanced &&
      _cashAccount != null &&
      _fromCurrency.trim().isNotEmpty &&
      _toCurrency.trim().isNotEmpty &&
      _fromCurrency.toUpperCase() != _toCurrency.toUpperCase() &&
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
          _fromCurrency = _baseCurrencyCode;
          _fromRate = 1;

          final nonBase = _currencies.where((c) => !c.isBase).toList();
          if (nonBase.isNotEmpty) {
            _toCurrency = nonBase.first.code;
            _toRate =
                nonBase.first.rateToBase <= 0 ? 1 : nonBase.first.rateToBase;
          } else if (_currencies.length > 1) {
            _toCurrency = _currencies[1].code;
            _toRate = _currencies[1].rateToBase <= 0
                ? 1
                : _currencies[1].rateToBase;
          } else {
            _toCurrency = _baseCurrencyCode;
            _toRate = 1;
          }

          _voucherBooks = await ref
              .read(rpVoucherBookPortProvider)
              .listActiveBooks(TransactionType.currencyExchange);
          if (_voucherBooks.isNotEmpty) {
            _voucherBook = _voucherBooks.first;
            _previewNumber = _voucherBook!.previewNumber;
          }

          if (!mounted) {
            return;
          }
          final dateLabel = DateFormat('d/M/yyyy').format(_date);
          _descriptionController.text =
              l10n.rpDefaultExchangeDescription(dateLabel);

          final treasury = ref.read(rpTreasuryAccountPortProvider);
          final languageCode = Localizations.localeOf(context).languageCode;
          final defaultCash = await treasury.findDefaultCashBox(
            languageCode: languageCode,
          );
          if (defaultCash != null) {
            _cashAccount = defaultCash;
          }

          if (_isEdit) {
            final txn = await ref
                .read(getFinancialTransactionByIdProvider)
                .call(widget.transactionId!);
            if (txn == null || !txn.transactionType.isCurrencyExchange) {
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
    _fromAmount = txn.amount;
    _fromCurrency = txn.currencyCode;
    _fromRate = txn.exchangeRate <= 0 ? 1 : txn.exchangeRate;
    _toAmount = txn.counterAmount > 0 ? txn.counterAmount : txn.amount;
    _toCurrency = txn.counterCurrencyCode.trim().isEmpty
        ? txn.currencyCode
        : txn.counterCurrencyCode;
    _toRate = txn.counterExchangeRate <= 0 ? 1 : txn.counterExchangeRate;
    _baseCurrencyCode = txn.baseCurrencyCode;
    _descriptionController.text = txn.description ?? '';
    _previewNumber = txn.transactionNumber;

    _cashAccount = await treasury.findById(
      txn.cashAccountId,
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
    final autoPrevious = l10n.rpDefaultExchangeDescription(previousLabel);
    final currentDescription = _descriptionController.text.trim();
    setState(() => _date = picked);
    if (currentDescription.isEmpty || currentDescription == autoPrevious) {
      final nextLabel = DateFormat('d/M/yyyy').format(picked);
      _descriptionController.text =
          l10n.rpDefaultExchangeDescription(nextLabel);
    }
  }

  Future<void> _pickCurrency({required bool fromSide}) async {
    if (_currencies.isEmpty) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = fromSide ? _fromCurrency : _toCurrency;
    final excluded = fromSide ? _toCurrency : _fromCurrency;
    final options = _currencies
        .where(
          (currency) =>
              currency.code.toUpperCase() != excluded.toUpperCase() ||
              currency.code.toUpperCase() == current.toUpperCase(),
        )
        .toList(growable: false);
    if (options.isEmpty) {
      return;
    }
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
                  fromSide
                      ? l10n.rpExchangeFromCurrency
                      : l10n.rpExchangeToCurrency,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final currency in options)
                ListTile(
                  leading: Icon(
                    currency.code == current
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: currency.code == current
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
      if (fromSide) {
        _fromCurrency = selected.code;
        _fromRate = selected.rateToBase <= 0 ? 1 : selected.rateToBase;
        _recalculateToAmount();
      } else {
        _toCurrency = selected.code;
        _toRate = selected.rateToBase <= 0 ? 1 : selected.rateToBase;
        _recalculateToAmount();
      }
    });
  }

  void _recalculateToAmount() {
    if (_syncingToAmount) {
      return;
    }
    final fromBase = _fromAmount * _safeFromRate;
    _toAmount = RpMoney.round(fromBase / _safeToRate);
  }

  void _setFromAmount(double value) {
    setState(() {
      _fromAmount = value < 0 ? 0 : value;
      _recalculateToAmount();
    });
  }

  void _setToAmount(double value) {
    setState(() {
      _syncingToAmount = true;
      _toAmount = value < 0 ? 0 : value;
      if (_toAmount > 0 && _safeFromRate > 0) {
        final toBase = _toAmount * _safeToRate;
        _fromAmount = RpMoney.round(toBase / _safeFromRate);
      }
      _syncingToAmount = false;
    });
  }

  void _setFromRate(double value) {
    if (value <= 0) {
      return;
    }
    setState(() {
      _fromRate = value;
      _recalculateToAmount();
    });
  }

  void _setToRate(double value) {
    if (value <= 0) {
      return;
    }
    setState(() {
      _toRate = value;
      _recalculateToAmount();
    });
  }

  FinancialTransactionDraft _toDraft() {
    final cash = _cashAccount!;
    final description = _descriptionController.text.trim();
    final fromRate = _safeFromRate;
    final toRate = _safeToRate;
    return FinancialTransactionDraft(
      transactionType: TransactionType.currencyExchange,
      source: TransactionSource.currencyExchange,
      transactionDate: _date,
      amount: _fromAmount,
      currencyCode: _fromCurrency,
      baseCurrencyCode: _baseCurrencyCode,
      exchangeRate: fromRate,
      counterAmount: _toAmount,
      counterCurrencyCode: _toCurrency,
      counterExchangeRate: toRate,
      voucherBookId: _voucherBook?.bookId,
      cashAccountId: cash.accountId,
      cashAccountCode: cash.code,
      cashAccountName: cash.name,
      counterAccountId: cash.accountId,
      counterAccountCode: cash.code,
      counterAccountName: cash.name,
      description: description.isEmpty ? null : description,
      paymentMethod: RpPaymentMethod.cash,
      lines: [
        FinancialTransactionLine(
          accountId: cash.accountId,
          accountCode: cash.code,
          accountName: cash.name,
          amount: _toAmount,
          currencyCode: _toCurrency,
          exchangeRate: toRate,
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
        ? l10n.rpFormTitleExchangeEdit
        : l10n.rpFormTitleExchange;
    final numberLabel = _isEdit
        ? formatSaleNumberPrimary(_previewNumber ?? '—')
        : (_previewNumber ??
            _voucherBook?.previewNumber ??
            l10n.rpVoucherBookEmpty);
    final dateLabel = DateFormat('d/M/yyyy').format(_date);

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
          _SurfaceCard(
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
                    decoration: InputDecoration(labelText: l10n.rpVoucherBook),
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
          )
              .animate()
              .fadeIn(duration: 240.ms)
              .slideY(begin: 0.02, end: 0, duration: 240.ms),
          const SizedBox(height: AppSpacing.md),
          _SurfaceCard(
            child: RpCashAccountDropdown(
              label: l10n.rpExchangeCashAccount,
              selected: _cashAccount,
              showSelectedNameBelow: true,
              onSelected: (account) => setState(() => _cashAccount = account),
            ),
          )
              .animate()
              .fadeIn(delay: 40.ms, duration: 240.ms)
              .slideY(begin: 0.02, end: 0, delay: 40.ms, duration: 240.ms),
          const SizedBox(height: AppSpacing.md),
          _SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CurrencyLeg(
                  tone: scheme.error,
                  amountLabel: l10n.rpExchangeFromAmount,
                  currencyLabel: l10n.rpExchangeFromCurrency,
                  amount: _fromAmount,
                  onAmountChanged: _setFromAmount,
                  currencyCode: _fromCurrency,
                  onPickCurrency: () => _pickCurrency(fromSide: true),
                  rate: _safeFromRate,
                  onRateChanged: _setFromRate,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Center(
                    child: Icon(
                      Icons.currency_exchange_outlined,
                      color: scheme.primary,
                    ),
                  ),
                ),
                _CurrencyLeg(
                  tone: scheme.tertiary,
                  amountLabel: l10n.rpExchangeToAmount,
                  currencyLabel: l10n.rpExchangeToCurrency,
                  amount: _toAmount,
                  onAmountChanged: _setToAmount,
                  currencyCode: _toCurrency,
                  onPickCurrency: () => _pickCurrency(fromSide: false),
                  rate: _safeToRate,
                  onRateChanged: _setToRate,
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 80.ms, duration: 240.ms)
              .slideY(begin: 0.02, end: 0, delay: 80.ms, duration: 240.ms),
          const SizedBox(height: AppSpacing.md),
          _ExchangeBalanceCard(
            debitLabel: l10n.rpTotalsDebit,
            creditLabel: l10n.rpTotalsCredit,
            differenceLabel: l10n.rpTotalsDifference,
            baseCurrencyCode: _baseCurrencyCode,
            debit: _debitBase,
            credit: _creditBase,
            difference: _balanceDifference,
            isBalanced: _isBalanced,
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 240.ms)
              .slideY(begin: 0.02, end: 0, delay: 100.ms, duration: 240.ms),
          const SizedBox(height: AppSpacing.md),
          _SurfaceCard(
            child: TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.rpGeneralDescription,
                alignLabelWithHint: true,
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

class _CurrencyLeg extends StatelessWidget {
  const _CurrencyLeg({
    required this.tone,
    required this.amountLabel,
    required this.currencyLabel,
    required this.amount,
    required this.onAmountChanged,
    required this.currencyCode,
    required this.onPickCurrency,
    required this.rate,
    required this.onRateChanged,
  });

  final Color tone;
  final String amountLabel;
  final String currencyLabel;
  final double amount;
  final ValueChanged<double> onAmountChanged;
  final String currencyCode;
  final VoidCallback onPickCurrency;
  final double rate;
  final ValueChanged<double> onRateChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: tone.withValues(alpha: 0.16)),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppAmountField(
            value: amount,
            onChanged: onAmountChanged,
            decimalPlaces: 2,
            emptyWhenZero: true,
            label: amountLabel,
            suffixText: currencyCode,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetaTile(
            icon: Icons.payments_outlined,
            label: currencyLabel,
            value: currencyCode,
            onTap: onPickCurrency,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ExchangeRateField(
            value: rate,
            onChanged: onRateChanged,
            label: l10n.rpExchangeRate,
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
        child: child,
      ),
    );
  }
}

class _ExchangeRateField extends StatelessWidget {
  const _ExchangeRateField({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
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

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
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

class _ExchangeBalanceCard extends StatelessWidget {
  const _ExchangeBalanceCard({
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

  String _fmt(double value) => '${value.toStringAsFixed(2)} $baseCurrencyCode';

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
          color: isBalanced
              ? scheme.outlineVariant.withValues(alpha: 0.5)
              : scheme.error.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _BalanceTile(
                    label: debitLabel,
                    value: _fmt(debit),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _BalanceTile(
                    label: creditLabel,
                    value: _fmt(credit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _BalanceTile(
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

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: emphasized
            ? (valueColor ?? scheme.primary).withValues(alpha: 0.08)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: emphasized
            ? Border.all(
                color: (valueColor ?? scheme.primary).withValues(alpha: 0.28),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: valueColor,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
