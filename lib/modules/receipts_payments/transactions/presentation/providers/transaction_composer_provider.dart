import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/financial_transaction.dart';
import '../../domain/entities/financial_transaction_line.dart';
import '../../domain/entities/rp_payment_method.dart';
import '../../domain/entities/transaction_source.dart';
import '../../domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_customer_lookup_port.dart';
import '../../domain/services/rp_money.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_treasury_account_port.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_voucher_book_port.dart';
import 'rp_providers.dart';

/// One editable party/CoA allocation row on the form.
class ComposerEntryLine {
  const ComposerEntryLine({
    required this.key,
    this.account,
    this.amount = 0,
    this.currencyCode = 'SAR',
    this.exchangeRate = 1,
    this.crossRate = 1,
    this.amountAuto = true,
    this.description,
    this.descriptionLocked = false,
  });

  final String key;
  final RpAccountRef? account;
  final double amount;
  final String currencyCode;

  /// Party currency → base.
  final double exchangeRate;

  /// Party units per 1 cash-currency unit (manual FX next to amount).
  final double crossRate;

  /// When true, [amount] follows cash amount × [crossRate].
  final bool amountAuto;
  final String? description;
  final bool descriptionLocked;

  String get resolvedDescription => description?.trim() ?? '';

  ComposerEntryLine copyWith({
    String? key,
    RpAccountRef? account,
    bool clearAccount = false,
    double? amount,
    String? currencyCode,
    double? exchangeRate,
    double? crossRate,
    bool? amountAuto,
    String? description,
    bool clearDescription = false,
    bool? descriptionLocked,
  }) {
    return ComposerEntryLine(
      key: key ?? this.key,
      account: clearAccount ? null : (account ?? this.account),
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      crossRate: crossRate ?? this.crossRate,
      amountAuto: amountAuto ?? this.amountAuto,
      description: clearDescription ? null : (description ?? this.description),
      descriptionLocked: descriptionLocked ?? this.descriptionLocked,
    );
  }
}

/// Editable draft state for create / edit receipt or payment screens.
class TransactionComposerState {
  const TransactionComposerState({
    required this.transactionType,
    required this.source,
    required this.transactionDate,
    this.amount = 0,
    this.cashAccount,
    this.customer,
    this.partyName,
    this.reference,
    this.description,
    this.paymentMethod = RpPaymentMethod.cash,
    this.voucherBook,
    this.currencyCode = 'SAR',
    this.baseCurrencyCode = 'SAR',
    this.exchangeRate = 1,
    this.lines = const [],
    this.editingTransactionId,
    this.previewTransactionNumber,
  });

  final TransactionType transactionType;
  final TransactionSource source;
  final DateTime transactionDate;

  /// Cash/treasury amount.
  final double amount;

  final RpAccountRef? cashAccount;
  final RpCustomerRef? customer;
  final String? partyName;
  final String? reference;
  final String? description;
  final RpPaymentMethod paymentMethod;
  final RpVoucherBookRef? voucherBook;

  /// Cash currency.
  final String currencyCode;
  final String baseCurrencyCode;
  final double exchangeRate;

  final List<ComposerEntryLine> lines;

  final int? editingTransactionId;
  final String? previewTransactionNumber;

  double get baseEquivalent => RpMoney.round(amount * exchangeRate);

  double get counterAmountTotal =>
      RpMoney.round(lines.fold<double>(0, (sum, line) => sum + line.amount));

  /// Party allocations converted to base currency.
  double get counterBaseTotal {
    var sum = 0.0;
    for (final line in lines) {
      if (line.account == null) continue;
      final rate = line.exchangeRate <= 0 ? 1.0 : line.exchangeRate;
      sum += line.amount * rate;
    }
    return RpMoney.round(sum);
  }

  /// Cash leg in base (receipt = debit, payment = credit).
  double get totalDebitBase =>
      transactionType.isReceipt ? baseEquivalent : counterBaseTotal;

  /// Counter leg(s) in base (receipt = credit, payment = debit).
  double get totalCreditBase =>
      transactionType.isReceipt ? counterBaseTotal : baseEquivalent;

  double get balanceDifferenceBase =>
      RpMoney.round((totalDebitBase - totalCreditBase).abs());

  bool get isBalanced => balanceDifferenceBase < 0.005;

  String? get resolvedPartyName {
    final linked = customer?.name.trim();
    if (linked != null && linked.isNotEmpty) {
      return linked;
    }
    final party = partyName?.trim();
    if (party != null && party.isNotEmpty) {
      return party;
    }
    for (final line in lines) {
      final name = line.account?.name.trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    return null;
  }

  TransactionComposerState copyWith({
    TransactionType? transactionType,
    TransactionSource? source,
    DateTime? transactionDate,
    double? amount,
    RpAccountRef? cashAccount,
    bool clearCashAccount = false,
    RpCustomerRef? customer,
    bool clearCustomer = false,
    String? partyName,
    bool clearPartyName = false,
    String? reference,
    bool clearReference = false,
    String? description,
    bool clearDescription = false,
    RpPaymentMethod? paymentMethod,
    RpVoucherBookRef? voucherBook,
    bool clearVoucherBook = false,
    String? currencyCode,
    String? baseCurrencyCode,
    double? exchangeRate,
    List<ComposerEntryLine>? lines,
    int? editingTransactionId,
    bool clearEditingTransactionId = false,
    String? previewTransactionNumber,
    bool clearPreviewTransactionNumber = false,
  }) {
    return TransactionComposerState(
      transactionType: transactionType ?? this.transactionType,
      source: source ?? this.source,
      transactionDate: transactionDate ?? this.transactionDate,
      amount: amount ?? this.amount,
      cashAccount: clearCashAccount ? null : (cashAccount ?? this.cashAccount),
      customer: clearCustomer ? null : (customer ?? this.customer),
      partyName: clearPartyName ? null : (partyName ?? this.partyName),
      reference: clearReference ? null : (reference ?? this.reference),
      description: clearDescription ? null : (description ?? this.description),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      voucherBook: clearVoucherBook ? null : (voucherBook ?? this.voucherBook),
      currencyCode: currencyCode ?? this.currencyCode,
      baseCurrencyCode: baseCurrencyCode ?? this.baseCurrencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      lines: lines ?? this.lines,
      editingTransactionId: clearEditingTransactionId
          ? null
          : (editingTransactionId ?? this.editingTransactionId),
      previewTransactionNumber: clearPreviewTransactionNumber
          ? null
          : (previewTransactionNumber ?? this.previewTransactionNumber),
    );
  }

  FinancialTransactionDraft toDraft() {
    final allocated = <FinancialTransactionLine>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final account = line.account;
      if (account == null) continue;
      final narrative = line.descriptionLocked
          ? line.resolvedDescription
          : (line.resolvedDescription.isNotEmpty
              ? line.resolvedDescription
              : (description?.trim() ?? ''));
      allocated.add(
        FinancialTransactionLine(
          accountId: account.accountId,
          accountCode: account.code,
          accountName: account.name,
          amount: line.amount,
          currencyCode: line.currencyCode,
          exchangeRate: line.exchangeRate <= 0 ? 1 : line.exchangeRate,
          description: narrative.isEmpty ? null : narrative,
          lineOrder: i,
        ),
      );
    }
    final first = allocated.isNotEmpty ? allocated.first : null;
    final rollupAmount = allocated.isEmpty
        ? 0.0
        : RpMoney.round(
            allocated.fold<double>(0, (sum, line) => sum + line.amount),
          );

    return FinancialTransactionDraft(
      transactionType: transactionType,
      source: source,
      transactionDate: transactionDate,
      amount: amount,
      currencyCode: currencyCode,
      baseCurrencyCode: baseCurrencyCode,
      exchangeRate: exchangeRate,
      counterAmount: rollupAmount,
      counterCurrencyCode: first?.currencyCode ?? currencyCode,
      counterExchangeRate: first?.exchangeRate ?? exchangeRate,
      voucherBookId: voucherBook?.bookId,
      cashAccountId: cashAccount?.accountId ?? '',
      cashAccountCode: cashAccount?.code,
      cashAccountName: cashAccount?.name,
      counterAccountId: first?.accountId ?? '',
      counterAccountCode: first?.accountCode,
      counterAccountName: first?.accountName,
      customerId: customer?.customerId,
      customerCode: customer?.customerCode,
      customerName: customer?.name,
      partyName: resolvedPartyName,
      reference: reference,
      description: description,
      paymentMethod: paymentMethod,
      lines: allocated,
    );
  }
}

class TransactionComposerController
    extends StateNotifier<TransactionComposerState> {
  TransactionComposerController(this._ref)
      : super(
          TransactionComposerState(
            transactionType: TransactionType.receipt,
            source: TransactionSource.manualReceipt,
            transactionDate: _today(),
          ),
        );

  final Ref _ref;
  var _lineSeq = 0;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _nextLineKey() {
    _lineSeq += 1;
    return 'line_$_lineSeq';
  }

  ComposerEntryLine _newLine({
    required String currencyCode,
    required double exchangeRate,
    required double crossRate,
    String? description,
    bool amountAuto = true,
  }) {
    return ComposerEntryLine(
      key: _nextLineKey(),
      currencyCode: currencyCode,
      exchangeRate: exchangeRate,
      crossRate: crossRate,
      amountAuto: amountAuto,
      description: description,
    );
  }

  Future<void> loadDefaults(
    TransactionType type, {
    String? defaultDescription,
  }) async {
    final sources = TransactionSourceX.forType(type);
    final defaultSource = sources.isNotEmpty
        ? sources.first
        : (type.isTransfer
            ? TransactionSource.cashBoxTransfer
            : (type.isCurrencyExchange
                ? TransactionSource.currencyExchange
                : (type.isReceipt
                    ? TransactionSource.manualReceipt
                    : TransactionSource.manualPayment)));

    final currencyPort = _ref.read(rpCurrencyPortProvider);
    final base = await currencyPort.baseCurrencyCode;
    final desc = defaultDescription?.trim();

    state = TransactionComposerState(
      transactionType: type,
      source: defaultSource,
      transactionDate: _today(),
      currencyCode: base,
      baseCurrencyCode: base,
      exchangeRate: 1,
      description: desc,
      lines: const [],
    );

    final treasury = _ref.read(rpTreasuryAccountPortProvider);
    final defaultCash = await treasury.findDefaultCashBox();
    if (defaultCash != null) {
      state = state.copyWith(cashAccount: defaultCash);
    }

    final books = await _ref
        .read(rpVoucherBookPortProvider)
        .listActiveBooks(type);
    if (books.isNotEmpty) {
      final book = books.first;
      state = state.copyWith(
        voucherBook: book,
        previewTransactionNumber: book.previewNumber,
      );
    }
  }

  void loadFromTransaction(FinancialTransaction txn) {
    final resolved = txn.resolvedLines;
    final cashRate = txn.exchangeRate <= 0 ? 1.0 : txn.exchangeRate;
    final lines = <ComposerEntryLine>[];
    for (final line in resolved) {
      final partyRate = line.exchangeRate <= 0 ? cashRate : line.exchangeRate;
      final cross = txn.currencyCode == line.currencyCode
          ? 1.0
          : (partyRate <= 0 ? 1.0 : RpMoney.round(cashRate / partyRate));
      lines.add(
        ComposerEntryLine(
          key: _nextLineKey(),
          account: RpAccountRef(
            accountId: line.accountId,
            code: line.accountCode ?? '',
            name: line.accountName ?? line.accountId,
          ),
          amount: line.amount,
          currencyCode: line.currencyCode,
          exchangeRate: partyRate,
          crossRate: cross <= 0 ? 1 : cross,
          amountAuto: false,
          description: line.description,
          descriptionLocked: (line.description?.trim() ?? '') !=
              (txn.description?.trim() ?? ''),
        ),
      );
    }

    state = TransactionComposerState(
      transactionType: txn.transactionType,
      source: txn.source,
      transactionDate: txn.transactionDate.toLocal(),
      amount: txn.amount,
      cashAccount: RpAccountRef(
        accountId: txn.cashAccountId,
        code: txn.cashAccountCode ?? '',
        name: txn.cashAccountName ?? txn.cashAccountId,
      ),
      customer: txn.customerId == null
          ? null
          : RpCustomerRef(
              customerId: txn.customerId!,
              customerCode: txn.customerCode ?? '',
              name: txn.customerName ?? '',
              accountId: txn.counterAccountId,
            ),
      partyName: txn.customerId == null ? txn.partyName : null,
      reference: txn.reference,
      description: txn.description,
      paymentMethod: txn.paymentMethod,
      voucherBook: txn.voucherBookId == null
          ? null
          : RpVoucherBookRef(
              bookId: txn.voucherBookId!,
              name: txn.voucherBookId!,
              nextNumber: 0,
              canAllocate: false,
              transactionType: txn.transactionType,
            ),
      currencyCode: txn.currencyCode,
      baseCurrencyCode: txn.baseCurrencyCode,
      exchangeRate: cashRate,
      lines: lines,
      editingTransactionId: txn.id,
      previewTransactionNumber: txn.transactionNumber,
    );
  }

  void _replaceLine(int index, ComposerEntryLine line) {
    if (index < 0 || index >= state.lines.length) return;
    final next = [...state.lines];
    next[index] = line;
    state = state.copyWith(lines: next);
  }

  void _recalcAutoLines() {
    if (state.lines.isEmpty) return;
    // Auto-fill only when a single allocation line is following cash×rate.
    if (state.lines.length != 1) return;
    final line = state.lines.first;
    if (!line.amountAuto) return;
    final rate = line.crossRate <= 0 ? 1.0 : line.crossRate;
    _replaceLine(
      0,
      line.copyWith(amount: RpMoney.round(state.amount * rate)),
    );
  }

  void setAmount(double amount) {
    state = state.copyWith(amount: amount < 0 ? 0 : amount);
    _recalcAutoLines();
  }

  void setCashAccount(RpAccountRef? account) {
    state = state.copyWith(
      cashAccount: account,
      clearCashAccount: account == null,
    );
  }

  void addEntryLine() {
    final template = state.lines.isNotEmpty ? state.lines.last : null;
    final cashRate = state.exchangeRate <= 0 ? 1.0 : state.exchangeRate;
    final currency = template?.currencyCode ?? state.currencyCode;
    final partyRate = template?.exchangeRate ?? cashRate;
    final same = currency == state.currencyCode;
    final cross = same
        ? 1.0
        : (partyRate <= 0 ? 1.0 : RpMoney.round(cashRate / partyRate));
    state = state.copyWith(
      lines: [
        ...state.lines,
        _newLine(
          currencyCode: currency,
          exchangeRate: partyRate,
          crossRate: cross <= 0 ? 1 : cross,
          description: state.description,
          amountAuto: false,
        ),
      ],
    );
  }

  /// Adds a committed allocation line with a selected CoA account (Sales-like).
  void addEntryLineWithAccount(RpAccountRef account) {
    final cashRate = state.exchangeRate <= 0 ? 1.0 : state.exchangeRate;
    final template = state.lines.isNotEmpty ? state.lines.last : null;
    final currency = template?.currencyCode ?? state.currencyCode;
    final partyRate = template?.exchangeRate ?? cashRate;
    final same = currency == state.currencyCode;
    final cross = same
        ? 1.0
        : (partyRate <= 0 ? 1.0 : RpMoney.round(cashRate / partyRate));
    final rate = cross <= 0 ? 1.0 : cross;
    final amountAuto = state.lines.isEmpty;
    final amount =
        amountAuto ? RpMoney.round(state.amount * rate) : 0.0;
    final line = _newLine(
      currencyCode: currency,
      exchangeRate: partyRate,
      crossRate: rate,
      description: state.description,
      amountAuto: amountAuto,
    ).copyWith(
      account: account,
      amount: amount,
    );
    state = state.copyWith(lines: [...state.lines, line]);
    if ((state.partyName == null || state.partyName!.trim().isEmpty) &&
        state.customer == null) {
      state = state.copyWith(partyName: account.name);
    }
  }

  void removeEntryLine(int index) {
    if (index < 0 || index >= state.lines.length) return;
    final next = [...state.lines]..removeAt(index);
    state = state.copyWith(lines: next);
  }

  void setLineAccount(int index, RpAccountRef? account) {
    if (index < 0 || index >= state.lines.length) return;
    final line = state.lines[index];
    _replaceLine(
      index,
      line.copyWith(
        account: account,
        clearAccount: account == null,
      ),
    );
    if (account != null &&
        (state.partyName == null || state.partyName!.trim().isEmpty) &&
        state.customer == null) {
      state = state.copyWith(partyName: account.name);
    }
  }

  void setLineAmount(int index, double amount, {bool manual = true}) {
    if (index < 0 || index >= state.lines.length) return;
    final line = state.lines[index];
    _replaceLine(
      index,
      line.copyWith(
        amount: amount < 0 ? 0 : amount,
        amountAuto: manual ? false : line.amountAuto,
      ),
    );
  }

  void setLineCrossRate(int index, double rate) {
    if (index < 0 || index >= state.lines.length) return;
    if (rate <= 0) return;
    final line = state.lines[index];
    final cashRate = state.exchangeRate <= 0 ? 1.0 : state.exchangeRate;
    final partyRate = RpMoney.round(cashRate / rate);
    var next = line.copyWith(
      crossRate: rate,
      exchangeRate: partyRate <= 0 ? 1 : partyRate,
      amountAuto: true,
    );
    if (state.lines.length == 1 || line.amountAuto) {
      next = next.copyWith(amount: RpMoney.round(state.amount * rate));
    }
    _replaceLine(index, next);
  }

  void setLineCurrency({
    required int index,
    required String code,
    required double rateToBase,
  }) {
    if (index < 0 || index >= state.lines.length) return;
    final normalized = code.trim().toUpperCase();
    final rate = rateToBase <= 0 ? 1.0 : rateToBase;
    final cashRate = state.exchangeRate <= 0 ? 1.0 : state.exchangeRate;
    final same = normalized == state.currencyCode;
    final cross = same ? 1.0 : RpMoney.round(cashRate / rate);
    final line = state.lines[index];
    var next = line.copyWith(
      currencyCode: normalized.isEmpty ? line.currencyCode : normalized,
      exchangeRate: rate,
      crossRate: cross <= 0 ? 1 : cross,
      amountAuto: true,
    );
    if (state.lines.length == 1) {
      next = next.copyWith(
        amount: RpMoney.round(state.amount * (cross <= 0 ? 1 : cross)),
      );
    }
    _replaceLine(index, next);
  }

  void setLineDescription(int index, String? description) {
    if (index < 0 || index >= state.lines.length) return;
    final trimmed = description?.trim() ?? '';
    final general = state.description?.trim() ?? '';
    final line = state.lines[index];
    _replaceLine(
      index,
      line.copyWith(
        description: description,
        clearDescription: trimmed.isEmpty,
        descriptionLocked: trimmed != general,
      ),
    );
  }

  void setCustomer(RpCustomerRef? customer) {
    state = state.copyWith(
      customer: customer,
      clearCustomer: customer == null,
      clearPartyName: customer != null,
    );
    if (customer?.hasAccount ?? false) {
      final accountId = customer!.accountId!;
      if (state.lines.isEmpty) {
        state = state.copyWith(
          lines: [
            _newLine(
              currencyCode: state.currencyCode,
              exchangeRate: state.exchangeRate,
              crossRate: 1,
              description: state.description,
            ).copyWith(
              account: RpAccountRef(
                accountId: accountId,
                code: customer.customerCode,
                name: customer.name,
              ),
            ),
          ],
        );
      } else {
        setLineAccount(
          0,
          RpAccountRef(
            accountId: accountId,
            code: customer.customerCode,
            name: customer.name,
          ),
        );
      }
    }
  }

  void clearCustomer() {
    state = state.copyWith(clearCustomer: true);
  }

  void setPartyName(String name) {
    state = state.copyWith(
      partyName: name,
      clearPartyName: name.trim().isEmpty,
      clearCustomer: name.trim().isNotEmpty,
    );
  }

  void setSource(TransactionSource source) {
    state = state.copyWith(source: source);
    if (source.requiresCustomer) {
      state = state.copyWith(clearPartyName: true);
    } else {
      state = state.copyWith(clearCustomer: true);
    }
  }

  void setDate(DateTime date) {
    final local = date.isUtc ? date.toLocal() : date;
    state = state.copyWith(
      transactionDate: DateTime(local.year, local.month, local.day),
    );
  }

  void setReference(String? reference) {
    state = state.copyWith(
      reference: reference,
      clearReference: reference == null || reference.trim().isEmpty,
    );
  }

  void setDescription(String? description) {
    final trimmed = description?.trim() ?? '';
    final clear = trimmed.isEmpty;
    state = state.copyWith(
      description: description,
      clearDescription: clear,
    );
    if (state.lines.isEmpty) return;
    final next = <ComposerEntryLine>[];
    for (final line in state.lines) {
      if (line.descriptionLocked) {
        next.add(line);
      } else {
        next.add(
          line.copyWith(
            description: clear ? null : trimmed,
            clearDescription: clear,
          ),
        );
      }
    }
    state = state.copyWith(lines: next);
  }

  void setPaymentMethod(RpPaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  /// Cash currency + rate to base.
  void setCurrency({required String code, required double rateToBase}) {
    final normalized = code.trim().toUpperCase();
    final rate = rateToBase <= 0 ? 1.0 : rateToBase;
    final nextLines = <ComposerEntryLine>[];
    for (final line in state.lines) {
      final partyRate = line.exchangeRate <= 0 ? 1.0 : line.exchangeRate;
      final same = normalized == line.currencyCode;
      final cross = same ? 1.0 : RpMoney.round(rate / partyRate);
      var updated = line.copyWith(
        crossRate: cross <= 0 ? 1 : cross,
        amountAuto: line.amountAuto || state.lines.length == 1,
      );
      if (state.lines.length == 1 && updated.amountAuto) {
        updated = updated.copyWith(
          amount: RpMoney.round(state.amount * (cross <= 0 ? 1 : cross)),
        );
      }
      nextLines.add(updated);
    }
    state = state.copyWith(
      currencyCode: normalized.isEmpty ? state.currencyCode : normalized,
      exchangeRate: rate,
      lines: nextLines,
    );
    _recalcAutoLines();
  }

  void setBaseCurrencyCode(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      return;
    }
    state = state.copyWith(baseCurrencyCode: normalized);
  }

  void setVoucherBook(RpVoucherBookRef? book) {
    if (state.editingTransactionId != null) {
      state = state.copyWith(
        voucherBook: book,
        clearVoucherBook: book == null,
      );
      return;
    }
    state = state.copyWith(
      voucherBook: book,
      clearVoucherBook: book == null,
      previewTransactionNumber: book?.previewNumber,
      clearPreviewTransactionNumber: book == null,
    );
  }
}

final transactionComposerProvider = StateNotifierProvider.autoDispose<
    TransactionComposerController, TransactionComposerState>(
  (ref) => TransactionComposerController(ref),
);
