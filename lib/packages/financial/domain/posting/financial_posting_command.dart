import '../journal/financial_side.dart';
import '../money/decimal_money.dart';
import '../money/decimal_rate.dart';

/// Line command for financial posting.
class FinancialPostingLineCommand {
  final String accountId;
  final FinancialSide side;
  final DecimalMoney transactionAmount;
  final DecimalRate exchangeRate;
  final int lineNumber;
  final String? description;

  const FinancialPostingLineCommand({
    required this.accountId,
    required this.side,
    required this.transactionAmount,
    required this.exchangeRate,
    required this.lineNumber,
    this.description,
  });
}

/// Command DTO representing a business financial posting request.
class FinancialPostingCommand {
  final String companyId;
  final String entryNumber;
  final String baseCurrencyCode;
  final DateTime postingDate;
  final String sourceModule;
  final String sourceDocumentId;
  final String? description;
  final List<FinancialPostingLineCommand> lines;

  const FinancialPostingCommand({
    required this.companyId,
    required this.entryNumber,
    required this.baseCurrencyCode,
    required this.postingDate,
    required this.sourceModule,
    required this.sourceDocumentId,
    this.description,
    required this.lines,
  });
}
