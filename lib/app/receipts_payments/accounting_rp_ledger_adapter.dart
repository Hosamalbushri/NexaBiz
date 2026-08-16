import '../../modules/accounting/domain/entities/journal_entry.dart';
import '../../modules/accounting/domain/services/journal_money.dart';
import '../../modules/accounting/domain/services/journal_posting_service.dart';
import '../../modules/receipts_payments/domain/entities/financial_transaction.dart';
import '../../modules/receipts_payments/domain/entities/transaction_status.dart';
import '../../modules/receipts_payments/domain/entities/transaction_type.dart';
import '../../modules/receipts_payments/domain/services/rp_ledger_posting_port.dart';

/// App adapter: receipt/payment → local journal via [JournalPostingService].
///
/// Receipt: Dr cash · Cr counter line(s)
/// Payment: Dr counter line(s) · Cr cash
///
/// Cash and counter amounts/currencies are independent (multi-currency
/// receipts where cash is SAR and party AR is YER, etc.).
class AccountingRpLedgerAdapter implements RpLedgerPostingPort {
  AccountingRpLedgerAdapter({required JournalPostingService posting})
      : _posting = posting;

  final JournalPostingService _posting;

  static String sourceTypeFor(TransactionType type) =>
      type.isReceipt ? 'receipt' : 'payment';

  @override
  Future<void> syncTransaction(FinancialTransaction txn) async {
    final cashAmount = JournalMoney.round(txn.amount);
    if (cashAmount <= 0) return;

    final allocations = txn.resolvedLines
        .where((line) => line.amount > 0 && line.accountId.trim().isNotEmpty)
        .toList();
    if (allocations.isEmpty) return;

    final cashCurrency = txn.currencyCode.trim().toUpperCase();
    final multiCurrency = allocations.any(
      (line) => line.currencyCode.trim().toUpperCase() != cashCurrency,
    );

    final party = txn.partyDisplayName;
    final voucherType = txn.transactionType.isReceipt ? 'قبض' : 'صرف';
    final description = party.isEmpty
        ? '$voucherType ${txn.transactionNumber}'
        : '$voucherType ${txn.transactionNumber} — $party';
    final fallbackNarrative = txn.description?.trim().isNotEmpty == true
        ? txn.description!.trim()
        : description;

    final lines = <JournalLineDraft>[];
    if (txn.transactionType.isReceipt) {
      lines.add(
        JournalLineDraft(
          accountUuid: txn.cashAccountId,
          debit: cashAmount,
          credit: 0,
          currencyCode: cashCurrency,
          lineDescription: fallbackNarrative,
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
          lineDescription: fallbackNarrative,
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
