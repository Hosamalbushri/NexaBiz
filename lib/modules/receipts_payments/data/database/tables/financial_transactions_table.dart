import 'package:drift/drift.dart';

/// Standalone receipt/payment documents.
@DataClassName('FinancialTransactionRow')
class FinancialTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uuid => text().withLength(min: 36, max: 36).unique()();

  TextColumn get transactionNumber => text().withLength(min: 1, max: 64)();

  /// [TransactionType.name] — receipt | payment
  TextColumn get transactionType => text()();

  /// [TransactionSource.name]
  TextColumn get source => text()();

  /// Business date (UTC epoch ms).
  IntColumn get transactionDate => integer()();

  RealColumn get amount => real()();

  TextColumn get currencyCode => text().withDefault(const Constant('SAR'))();

  TextColumn get baseCurrencyCode =>
      text().withDefault(const Constant('SAR'))();

  RealColumn get exchangeRate => real().withDefault(const Constant(1.0))();

  /// Counter/party amount (may differ from cash [amount] when currencies differ).
  RealColumn get counterAmount => real().withDefault(const Constant(0.0))();

  TextColumn get counterCurrencyCode =>
      text().withDefault(const Constant('SAR'))();

  RealColumn get counterExchangeRate =>
      real().withDefault(const Constant(1.0))();

  /// JSON array of party/CoA allocation lines (multi-account support).
  TextColumn get linesJson => text().nullable()();

  TextColumn get voucherBookId => text().nullable()();

  TextColumn get cashAccountId => text()();

  TextColumn get cashAccountCode => text().nullable()();

  TextColumn get cashAccountName => text().nullable()();

  TextColumn get counterAccountId => text()();

  TextColumn get counterAccountCode => text().nullable()();

  TextColumn get counterAccountName => text().nullable()();

  TextColumn get customerId => text().nullable()();

  TextColumn get customerCode => text().nullable()();

  TextColumn get customerName => text().nullable()();

  TextColumn get partyName => text().nullable()();

  TextColumn get reference => text().nullable()();

  TextColumn get description => text().nullable()();

  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();

  /// [TransactionStatus.name]
  TextColumn get documentStatus =>
      text().withDefault(const Constant('unposted'))();

  TextColumn get relatedDocumentId => text().nullable()();

  TextColumn get relatedDocumentType => text().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  IntColumn get cancelledAt => integer().nullable()();

  TextColumn get externalId => text().nullable()();

  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  IntColumn get lastSyncedAt => integer().nullable()();

  IntColumn get version => integer().withDefault(const Constant(1))();

  IntColumn get deletedAt => integer().nullable()();
}
