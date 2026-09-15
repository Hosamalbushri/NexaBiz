import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Standalone Financial Package Journal Entries table.
@DataClassName('FinancialJournalEntryData')
class FinancialJournalEntries extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Tenant company scope.
  TextColumn get companyId => text()();

  /// Human-readable sequential entry number within company.
  TextColumn get entryNumber => text().withLength(min: 1, max: 64)();

  /// Base/functional currency ISO code for this journal entry (invariant: line base amounts match this currency).
  TextColumn get baseCurrencyCode => text().withLength(min: 1, max: 8)();

  /// Financial posting date.
  DateTimeColumn get postingDate => dateTime()();

  /// Entry status: `DRAFT`, `POSTED`, `REVERSED`.
  TextColumn get status => text().withLength(min: 1, max: 32).withDefault(const Constant('DRAFT'))();

  /// Header level description / memo.
  TextColumn get description => text().nullable()();

  /// Originating system module (e.g., 'sales', 'purchases', 'treasury', 'manual').
  TextColumn get sourceModule => text().nullable()();

  /// ID of the source document triggering this journal.
  TextColumn get sourceDocumentId => text().nullable()();

  /// Timestamp when posted (immutable after set).
  DateTimeColumn get postedAt => dateTime().nullable()();

  /// User ID who created this entry.
  TextColumn get createdById => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
        {companyId, entryNumber},
      ];
}
