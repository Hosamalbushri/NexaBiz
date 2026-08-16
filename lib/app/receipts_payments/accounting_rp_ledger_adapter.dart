import '../../modules/accounting/domain/entities/journal_entry.dart';
import '../../modules/accounting/domain/services/journal_money.dart';
import '../../modules/accounting/domain/services/journal_posting_service.dart';
import '../../modules/receipts_payments/domain/entities/financial_transaction.dart';
import '../../modules/receipts_payments/domain/entities/financial_transaction_line.dart';
import '../../modules/receipts_payments/domain/entities/transaction_status.dart';
import '../../modules/receipts_payments/domain/entities/transaction_type.dart';
import '../../modules/receipts_payments/domain/services/rp_ledger_posting_port.dart';

/// App adapter: receipt/payment/transfer → local journal via [JournalPostingService].
///
/// Receipt: Dr cash · Cr counter line(s)
/// Payment: Dr counter line(s) · Cr cash
/// Transfer: Dr destination (to) · Cr source (from)
///
/// Cash and counter amounts/currencies are independent (multi-currency
/// receipts where cash is SAR and party AR is YER, etc.).
///
/// Cash-box line narrative is always `account name - statement`; counter
/// lines keep the statement (or their own line description) only.
class AccountingRpLedgerAdapter implements RpLedgerPostingPort {
  AccountingRpLedgerAdapter({required JournalPostingService posting})
      : _posting = posting;

  final JournalPostingService _posting;

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

  @override
  Future<void> syncTransaction(FinancialTransaction txn) async {
    final cashAmount = JournalMoney.round(txn.amount);
    if (cashAmount <= 0) return;

    final allocations = txn.resolvedLines
        .where((line) => line.amount > 0 && line.accountId.trim().isNotEmpty)
        .toList();
    if (allocations.isEmpty) return;

    final cashCurrency = txn.currencyCode.trim().toUpperCase();
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
          debit: JournalMoney.round(to.amount),
          credit: 0,
          currencyCode: to.currencyCode.trim().toUpperCase(),
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
          lineDescription: fromNarrative,
          sortOrder: 1,
        ),
      );
    } else if (txn.transactionType.isTransfer) {
      final to = allocations.first;
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
          lineDescription: fromNarrative,
          sortOrder: 1,
        ),
      );
    } else if (txn.transactionType.isReceipt) {
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
            lineDescription: narrative,
            sortOrder: i + 1,
          ),
        );
      }
    } else {
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

  @override
  Future<void> voidTransaction(FinancialTransaction txn) async {
    await _posting.softDeleteBySource(
      sourceType: sourceTypeFor(txn.transactionType),
      sourceId: txn.uuid,
    );
  }
}
