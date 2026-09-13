import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Canonical Currencies master reference table in `nexabiz.sqlite`.
@DataClassName('CurrencyData')
class Currencies extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();
  TextColumn get code => text().named('code').withLength(min: 1, max: 8)();
  TextColumn get currencyCode => text().named('currency_code').withLength(min: 1, max: 8).nullable()();
  TextColumn get name => text().withLength(min: 1, max: 128).nullable()();
  TextColumn get nameAr => text().named('name_ar').withLength(min: 1, max: 128).withDefault(const Constant(''))();
  TextColumn get nameEn => text().named('name_en').withLength(min: 1, max: 128).withDefault(const Constant(''))();
  TextColumn get symbol => text().withLength(min: 1, max: 16)();
  IntColumn get decimalDigits => integer().named('decimal_digits').withDefault(const Constant(2))();
  BoolColumn get isBase => boolean().named('is_base').withDefault(const Constant(false))();
  BoolColumn get isDefault => boolean().named('is_default').withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().named('is_active').withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();
  TextColumn get companyId => text().named('company_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, code},
      ];
}
