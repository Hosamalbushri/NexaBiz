import '../money/decimal_money.dart';
import '../money/decimal_rate.dart';
import 'financial_side.dart';

/// Standalone Financial Package Journal Line domain entity.
class JournalLine {
  final String id;
  final String companyId;
  final String journalEntryId;
  final int lineNumber;
  final String accountId;
  final FinancialSide side;
  final DecimalMoney transactionAmount;
  final DecimalRate exchangeRate;
  final DecimalMoney baseAmount;
  final String? description;
  final String? subjectId;

  JournalLine({
    required this.id,
    required this.companyId,
    required this.journalEntryId,
    required this.lineNumber,
    required this.accountId,
    required this.side,
    required this.transactionAmount,
    required this.exchangeRate,
    required this.baseAmount,
    this.description,
    this.subjectId,
  }) {
    if (transactionAmount.isNegative) {
      throw ArgumentError('Journal line transaction amount cannot be negative: $transactionAmount');
    }
    if (baseAmount.isNegative) {
      throw ArgumentError('Journal line base amount cannot be negative: $baseAmount');
    }
    if (exchangeRate.fromCurrencyCode != transactionAmount.currencyCode) {
      throw ArgumentError(
        'Exchange rate source currency ${exchangeRate.fromCurrencyCode} does not match transaction currency ${transactionAmount.currencyCode}',
      );
    }
    if (exchangeRate.toCurrencyCode != baseAmount.currencyCode) {
      throw ArgumentError(
        'Exchange rate target currency ${exchangeRate.toCurrencyCode} does not match base currency ${baseAmount.currencyCode}',
      );
    }
  }

  /// Double-conversion safety factory: Posting engine creates lines using explicit currency conversion.
  factory JournalLine.create({
    required String id,
    required String companyId,
    required String journalEntryId,
    required int lineNumber,
    required String accountId,
    required FinancialSide side,
    required DecimalMoney transactionAmount,
    required DecimalRate exchangeRate,
    required String baseCurrencyCode,
    String? description,
    String? subjectId,
  }) {
    final computedBaseMoney = exchangeRate.convert(transactionAmount);
    if (computedBaseMoney.currencyCode != baseCurrencyCode.toUpperCase()) {
      throw ArgumentError(
        'Converted currency ${computedBaseMoney.currencyCode} does not match target base currency $baseCurrencyCode',
      );
    }

    return JournalLine(
      id: id,
      companyId: companyId,
      journalEntryId: journalEntryId,
      lineNumber: lineNumber,
      accountId: accountId,
      side: side,
      transactionAmount: transactionAmount,
      exchangeRate: exchangeRate,
      baseAmount: computedBaseMoney,
      description: description,
      subjectId: subjectId,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is JournalLine &&
            id == other.id &&
            companyId == other.companyId &&
            journalEntryId == other.journalEntryId &&
            lineNumber == other.lineNumber);
  }

  @override
  int get hashCode => Object.hash(id, companyId, journalEntryId, lineNumber);

  @override
  String toString() =>
      'Line #$lineNumber [$side] Acc:$accountId Tx:$transactionAmount Base:$baseAmount';
}
