import 'accounting_transaction_context.dart';

/// Canonical Accounting Journal Line Domain Contract.
class AccountingJournalLine {
  const AccountingJournalLine({
    required this.uuid,
    required this.entryUuid,
    required this.accountUuid,
    required this.debit,
    required this.credit,
    required this.currencyCode,
    required this.exchangeRateToBase,
    required this.baseDebit,
    required this.baseCredit,
    this.lineDescription,
    this.sortOrder = 0,
    this.id,
  });

  final int? id;
  final String uuid;
  final String entryUuid;
  final String accountUuid;
  final double debit;
  final double credit;
  final String currencyCode;
  final double exchangeRateToBase;
  final double baseDebit;
  final double baseCredit;
  final String? lineDescription;
  final int sortOrder;
}

/// Canonical Accounting Journal Domain Contract.
class AccountingJournal {
  const AccountingJournal({
    required this.uuid,
    required this.context,
    required this.voucherNumber,
    required this.voucherType,
    required this.lines,
    required this.isPosted,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.id,
  });

  final int? id;
  final String uuid;
  final AccountingTransactionContext context;
  final String voucherNumber;
  final String voucherType;
  final String? description;
  final bool isPosted;
  final List<AccountingJournalLine> lines;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Total debit in base currency.
  double get totalBaseDebit =>
      lines.fold(0.0, (sum, line) => sum + line.baseDebit);

  /// Total credit in base currency.
  double get totalBaseCredit =>
      lines.fold(0.0, (sum, line) => sum + line.baseCredit);

  /// Verifies journal integrity (base currency debit == base currency credit).
  bool get isIntegrityValid =>
      lines.isNotEmpty && (totalBaseDebit - totalBaseCredit).abs() < 0.001;
}
