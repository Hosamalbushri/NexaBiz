import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Canonical Voucher Books master reference table in `nexabiz.sqlite`.
@DataClassName('VoucherBookData')
class VoucherBooks extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();
  TextColumn get parentBookId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get bookType => text().withLength(min: 1, max: 32)();
  BoolColumn get isGroup => boolean().withDefault(const Constant(false))();
  IntColumn get nextNumber => integer().withDefault(const Constant(1))();
  IntColumn get endNumber => integer().withDefault(const Constant(9999))();
  IntColumn get padLength => integer().withDefault(const Constant(4))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get companyId => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
        {companyId, name, bookType},
      ];
}
