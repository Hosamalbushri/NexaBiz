import '../../core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/repositories/fiscal_year_repository.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/account_labels.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_money.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/financial_transaction_line.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_status.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_ledger_posting_port.dart';

/// App adapter: receipt/payment/transfer/exchange → local journal.
class AccountingRpLedgerAdapter implements RpLedgerPostingPort {
  AccountingRpLedgerAdapter({
    required JournalPostingService posting,
    required AccountRepository accounts,
    FiscalYearRepository? fiscalYears,
  }) : _posting = posting,
       _accounts = accounts,
       _fiscalYears = fiscalYears;

  final JournalPostingService _posting;
  final AccountRepository _accounts;
  final FiscalYearRepository? _fiscalYears;

  static String sourceTypeFor(TransactionType type) => switch (type) {
        TransactionType.receipt => 'receipt',
        TransactionType.payment => 'payment',
        TransactionType.transfer => 'transfer',
        TransactionType.currencyExchange => 'currency_exchange',
      };

  static String voucherTypeLabel(TransactionType type) => switch (type) {
        TransactionType.receipt => 'قبض',
        TransactionType.payment => 'صرف',
        TransactionType.transfer => 'نقل',
        TransactionType.currencyExchange => 'مصارفة',
      };

  /// Cash-box journal line: `اسم الحساب - البيان`.
  static String cashBoxLineDescription({
    required FinancialTransaction txn,
    required List<FinancialTransactionLine> allocations,
    required String fallbackNarrative,
  }) {
    final accountName = _counterAccountLabel(txn, allocations);
    final statement = txn.description?.trim() ?? '';
    if (accountName.isNotEmpty && statement.isNotEmpty) {
      return '$accountName - $statement';
    }
    if (accountName.isNotEmpty) {
      return accountName;
    }
    if (statement.isNotEmpty) {
      return statement;
    }
    return fallbackNarrative;
  }

  static String _accountLineDescription({
    required String? accountName,
    required String fallbackNarrative,
  }) {
    final name = accountName?.trim() ?? '';
    final statement = fallbackNarrative.trim();
    if (name.isNotEmpty && statement.isNotEmpty) {
      return '$name - $statement';
    }
    if (name.isNotEmpty) {
      return name;
    }
    return statement;
  }

  static String _counterAccountLabel(
    FinancialTransaction txn,
    List<FinancialTransactionLine> allocations,
  ) {
    final names = <String>[];
    for (final line in allocations) {
      final name = line.accountName?.trim() ?? '';
      if (name.isNotEmpty && !names.contains(name)) {
        names.add(name);
      }
    }
    if (names.isNotEmpty) {
      return names.join('، ');
    }
    final header = txn.counterAccountName?.trim() ?? '';
    if (header.isNotEmpty) {
      return header;
    }
    return txn.partyDisplayName.trim();
  }

  double _headerRate(FinancialTransaction txn) =>
      txn.exchangeRate <= 0 ? 1.0 : txn.exchangeRate;

  double _lineRate(FinancialTransaction txn, FinancialTransactionLine line) =>
      line.exchangeRate <= 0 ? _headerRate(txn) : line.exchangeRate;

  @override
  Future<void> syncTransaction(FinancialTransaction txn) async {
    final cashAmount = JournalMoney.round(txn.amount);
    if (cashAmount <= 0) {
      return;
    }

    final allocations = txn.resolvedLines
        .where((line) => line.amount > 0 && line.accountId.trim().isNotEmpty)
        .toList();
    if (allocations.isEmpty) {
      return;
    }

    final cashCurrency = txn.currencyCode.trim().toUpperCase();
    final baseCurrency = txn.baseCurrencyCode.trim().toUpperCase().isEmpty
        ? cashCurrency
        : txn.baseCurrencyCode.trim().toUpperCase();
    final multiCurrency = txn.transactionType.isCurrencyExchange ||
        allocations.any(
          (line) => line.currencyCode.trim().toUpperCase() != cashCurrency,
        );

    final party = txn.partyDisplayName;
    final voucherType = voucherTypeLabel(txn.transactionType);
    final description = party.isEmpty
        ? '$voucherType ${txn.transactionNumber}'
        : '$voucherType ${txn.transactionNumber} — $party';
    final fallbackNarrative = txn.description?.trim().isNotEmpty == true
        ? txn.description!.trim()
        : description;

    final lines = <JournalLineDraft>[];
    if (txn.transactionType.isCurrencyExchange) {
      final to = allocations.first;
      final fromRate = _headerRate(txn);
      final toRate = _lineRate(txn, to);
      final toAmount = JournalMoney.round(to.amount);
      final fromBase = JournalMoney.round(cashAmount * fromRate);
      final toBase = JournalMoney.round(toAmount * toRate);
      final baseDiff = JournalMoney.round(toBase - fromBase);
      final boxName = txn.cashAccountName;
      final toNarrative = _accountLineDescription(
        accountName: boxName,
        fallbackNarrative: fallbackNarrative,
      );
      final fromNarrative = _accountLineDescription(
        accountName: boxName,
        fallbackNarrative: fallbackNarrative,
      );
      lines.add(
        JournalLineDraft(
          accountUuid: txn.cashAccountId,
          debit: toAmount,
          credit: 0,
          currencyCode: to.currencyCode.trim().toUpperCase(),
          exchangeRateToBase: toRate,
          baseDebit: toBase,
          baseCredit: 0,
          lineDescription: toNarrative,
          sortOrder: 0,
        ),
      );
      lines.add(
        JournalLineDraft(
          accountUuid: txn.cashAccountId,
          debit: 0,
          credit: cashAmount,
          currencyCode: cashCurrency,
          exchangeRateToBase: fromRate,
          baseDebit: 0,
          baseCredit: fromBase,
          lineDescription: fromNarrative,
          sortOrder: 1,
        ),
      );
      if (baseDiff.abs() >= 0.005) {
        final fx = await _resolveFxAccounts(
          entryDate: txn.transactionDate,
          preferFiscalYear: true,
        );
        final absDiff = baseDiff.abs();
        if (baseDiff > 0) {
          lines.add(
            JournalLineDraft(
              accountUuid: fx.gainUuid,
              debit: 0,
              credit: absDiff,
              currencyCode: baseCurrency,
              exchangeRateToBase: 1,
              baseDebit: 0,
              baseCredit: absDiff,
              lineDescription: 'FX gain — $fallbackNarrative',
              sortOrder: 2,
            ),
          );
        } else {
          lines.add(
            JournalLineDraft(
              accountUuid: fx.lossUuid,
              debit: absDiff,
              credit: 0,
              currencyCode: baseCurrency,
              exchangeRateToBase: 1,
              baseDebit: absDiff,
              baseCredit: 0,
              lineDescription: 'FX loss — $fallbackNarrative',
              sortOrder: 2,
            ),
          );
        }
      }
    } else if (txn.transactionType.isTransfer) {
      final to = allocations.first;
      final rate = _headerRate(txn);
      final toNarrative = _accountLineDescription(
        accountName: to.accountName ?? txn.counterAccountName,
        fallbackNarrative: fallbackNarrative,
      );
      final fromNarrative = _accountLineDescription(
        accountName: txn.cashAccountName,
        fallbackNarrative: fallbackNarrative,
      );
      lines.add(
        JournalLineDraft(
          accountUuid: to.accountId,
          debit: JournalMoney.round(to.amount),
          credit: 0,
          currencyCode: to.currencyCode.trim().toUpperCase(),
          exchangeRateToBase: rate,
          lineDescription: toNarrative,
          sortOrder: 0,
        ),
      );
      lines.add(
        JournalLineDraft(
          accountUuid: txn.cashAccountId,
          debit: 0,
          credit: cashAmount,
          currencyCode: cashCurrency,
          exchangeRateToBase: rate,
          lineDescription: fromNarrative,
          sortOrder: 1,
        ),
      );
    } else if (txn.transactionType.isReceipt) {
      final cashRate = _headerRate(txn);
      final cashNarrative = cashBoxLineDescription(
        txn: txn,
        allocations: allocations,
        fallbackNarrative: fallbackNarrative,
      );
      lines.add(
        JournalLineDraft(
          accountUuid: txn.cashAccountId,
          debit: cashAmount,
          credit: 0,
          currencyCode: cashCurrency,
          exchangeRateToBase: cashRate,
          lineDescription: cashNarrative,
          sortOrder: 0,
        ),
      );
      for (var i = 0; i < allocations.length; i++) {
        final line = allocations[i];
        final narrative = line.description?.trim().isNotEmpty == true
            ? line.description!.trim()
            : fallbackNarrative;
        lines.add(
          JournalLineDraft(
            accountUuid: line.accountId,
            debit: 0,
            credit: JournalMoney.round(line.amount),
            currencyCode: line.currencyCode.trim().toUpperCase(),
            exchangeRateToBase: _lineRate(txn, line),
            lineDescription: narrative,
            sortOrder: i + 1,
          ),
        );
      }
    } else {
      final cashRate = _headerRate(txn);
      final cashNarrative = cashBoxLineDescription(
        txn: txn,
        allocations: allocations,
        fallbackNarrative: fallbackNarrative,
      );
      for (var i = 0; i < allocations.length; i++) {
        final line = allocations[i];
        final narrative = line.description?.trim().isNotEmpty == true
            ? line.description!.trim()
            : fallbackNarrative;
        lines.add(
          JournalLineDraft(
            accountUuid: line.accountId,
            debit: JournalMoney.round(line.amount),
            credit: 0,
            currencyCode: line.currencyCode.trim().toUpperCase(),
            exchangeRateToBase: _lineRate(txn, line),
            lineDescription: narrative,
            sortOrder: i,
          ),
        );
      }
      lines.add(
        JournalLineDraft(
          accountUuid: txn.cashAccountId,
          debit: 0,
          credit: cashAmount,
          currencyCode: cashCurrency,
          exchangeRateToBase: cashRate,
          lineDescription: cashNarrative,
          sortOrder: allocations.length,
        ),
      );
    }

    await _posting.post(
      JournalEntryDraft(
        entryDate: txn.transactionDate,
        voucherNumber: txn.transactionNumber,
        voucherType: voucherType,
        currencyCode: cashCurrency,
        baseCurrencyCode: baseCurrency,
        description: txn.description?.trim().isNotEmpty == true
            ? txn.description!.trim()
            : description,
        isPosted: txn.documentStatus.isPosted,
        sourceType: sourceTypeFor(txn.transactionType),
        sourceId: txn.uuid,
        allowUnbalancedMultiCurrency: multiCurrency,
        lines: lines,
      ),
    );
  }

  Future<({String gainUuid, String lossUuid})> _resolveFxAccounts({
    required DateTime entryDate,
    required bool preferFiscalYear,
  }) async {
    if (preferFiscalYear && _fiscalYears != null) {
      final period = await _fiscalYears!.findPeriodContaining(entryDate);
      if (period != null) {
        final fy = await _fiscalYears!.getByUuid(period.fiscalYearUuid);
        final gain = fy?.fxGainAccountUuid?.trim() ?? '';
        final loss = fy?.fxLossAccountUuid?.trim() ?? '';
        if (fy != null &&
            fy.fxRevaluationEnabled &&
            gain.isNotEmpty &&
            loss.isNotEmpty) {
          return (gainUuid: gain, lossUuid: loss);
        }
      }
    }

    final gain = await _systemAccountUuid('fx_gain') ??
        systemAccountUuid('fx_gain');
    final loss = await _systemAccountUuid('fx_loss') ??
        systemAccountUuid('fx_loss');
    return (gainUuid: gain, lossUuid: loss);
  }

  Future<String?> _systemAccountUuid(String systemKey) async {
    final preferred = systemAccountUuid(systemKey);
    final byUuid = await _accounts.getByUuid(preferred);
    if (byUuid != null && byUuid.canPost) {
      return byUuid.uuid;
    }
    final all = await _accounts.getAll(includeInactive: false);
    for (final account in all) {
      if (AccountLabels.systemKeyOf(account) == systemKey && account.canPost) {
        return account.uuid;
      }
    }
    return preferred;
  }

  @override
  Future<void> voidTransaction(FinancialTransaction txn) async {
    await _posting.voidBySource(
      sourceType: sourceTypeFor(txn.transactionType),
      sourceId: txn.uuid,
    );
  }
}
