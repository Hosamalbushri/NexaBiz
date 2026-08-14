import 'package:drift/drift.dart';

/// Journal entry line (debit or credit against one account).
@DataClassName('JournalLineRow')
class JournalLines extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uuid => text().withLength(min: 36, max: 36).unique()();

  /// Parent [JournalEntries.uuid].
  TextColumn get entryUuid => text().withLength(min: 36, max: 36)();

  /// Posting account UUID ([Accounts.uuid]).
  TextColumn get accountUuid => text().withLength(min: 36, max: 36)();

  RealColumn get debit => real().withDefault(const Constant(0))();

  RealColumn get credit => real().withDefault(const Constant(0))();

  TextColumn get lineDescription => text().nullable()();

  TextColumn get currencyCode => text().withLength(min: 3, max: 8)();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}
