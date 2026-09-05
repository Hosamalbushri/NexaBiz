import 'package:drift/drift.dart';

@DataClassName('CashRegisterRow')
class CashRegisters extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().withLength(min: 36, max: 36).unique()();
  TextColumn get companyId => text()();
  TextColumn get name => text().withLength(min: 1, max: 512)();
  TextColumn get code => text().withLength(min: 1, max: 64)();
  TextColumn get description => text().nullable()();
  TextColumn get accountingAccountId => text().nullable()();
  TextColumn get accountingLinkStatus => text().withDefault(const Constant('ACCOUNTING_NOT_LINKED'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  IntColumn get lastSyncedAt => integer().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get deletedAt => integer().nullable()();
}
