import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Standalone Financial Package Chart of Accounts table.
@DataClassName('FinancialAccountData')
class FinancialAccounts extends Table {
  /// Canonical UUID v7 primary key.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Tenant company scope.
  TextColumn get companyId => text()();

  /// Hierarchical account code (e.g., '1101').
  TextColumn get code => text().withLength(min: 1, max: 64)();

  /// Arabic display name.
  TextColumn get nameAr => text().withDefault(const Constant(''))();

  /// English display name.
  TextColumn get nameEn => text().withDefault(const Constant(''))();

  /// Account type (ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE).
  TextColumn get accountType => text().withLength(min: 1, max: 32)();

  /// Account currency policy:
  /// - `MULTI_CURRENCY_BUCKETED`: Customer/Supplier AR/AP accounts.
  /// - `SINGLE_FIXED_CURRENCY`: Cash, Bank, Card, Wallet accounts.
  /// - `FUNCTIONAL_ONLY`: Revenue, Expense, Inventory, COGS, FX accounts.
  TextColumn get currencyPolicy => text().withLength(min: 1, max: 32)();

  /// Fixed currency ISO code (required when policy is SINGLE_FIXED_CURRENCY).
  TextColumn get fixedCurrencyCode => text().nullable()();

  /// Parent account ID for hierarchical Chart of Accounts structure.
  TextColumn get parentAccountId => text().nullable()();

  /// Level in account hierarchy tree.
  IntColumn get level => integer().withDefault(const Constant(0))();

  /// Whether this is a header/group account that cannot accept postings.
  BoolColumn get isGroup => boolean().withDefault(const Constant(false))();

  /// System account flag (e.g. system retained earnings or default AR/AP).
  BoolColumn get isSystemAccount => boolean().withDefault(const Constant(false))();

  /// Active operational status.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
        {companyId, code},
      ];
}
