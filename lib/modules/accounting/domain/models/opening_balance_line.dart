import '../../../../core/utils/id_generator.dart';

/// One opening-balance currency leg for a posting account.
class OpeningBalanceLine {
  const OpeningBalanceLine({
    required this.id,
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    this.currencyCode = '',
    this.debit = 0,
    this.credit = 0,
  });

  factory OpeningBalanceLine.forAccount({
    required String accountId,
    required String accountCode,
    required String accountName,
    String currencyCode = '',
    double debit = 0,
    double credit = 0,
  }) {
    return OpeningBalanceLine(
      id: generateUuidV4(),
      accountId: accountId,
      accountCode: accountCode,
      accountName: accountName,
      currencyCode: currencyCode,
      debit: debit,
      credit: credit,
    );
  }

  final String id;
  final String accountId;
  final String accountCode;
  final String accountName;
  final String currencyCode;
  final double debit;
  final double credit;

  bool get hasAmount => debit > 0.0000001 || credit > 0.0000001;

  bool get hasBothSides => debit > 0.0000001 && credit > 0.0000001;

  String get accountCurrencyKey =>
      '${accountId.trim()}|${currencyCode.trim().toUpperCase()}';

  OpeningBalanceLine copyWith({
    String? accountId,
    String? accountCode,
    String? accountName,
    String? currencyCode,
    double? debit,
    double? credit,
  }) {
    return OpeningBalanceLine(
      id: id,
      accountId: accountId ?? this.accountId,
      accountCode: accountCode ?? this.accountCode,
      accountName: accountName ?? this.accountName,
      currencyCode: currencyCode ?? this.currencyCode,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
    );
  }
}

/// Aggregate totals for one currency in the review step.
class OpeningBalanceCurrencySummary {
  const OpeningBalanceCurrencySummary({
    required this.currencyCode,
    required this.totalDebit,
    required this.totalCredit,
  });

  final String currencyCode;
  final double totalDebit;
  final double totalCredit;

  double get netDebit => totalDebit - totalCredit;
}
