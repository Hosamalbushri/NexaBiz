import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Standalone Financial Package Fiscal Years table (GATE-08 V4).
@DataClassName('FinancialFiscalYearData')
class FinancialFiscalYears extends Table {
  /// Primary key UUID v7 identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Tenant company scope.
  TextColumn get companyId => text().withLength(min: 36, max: 36)();

  /// Fiscal year code (e.g. 'FY2026').
  TextColumn get code => text().withLength(min: 1, max: 32)();

  /// Fiscal year display name.
  TextColumn get name => text().withLength(min: 1, max: 128)();

  /// UTC day epoch ms start date.
  IntColumn get startDate => integer()();

  /// UTC day epoch ms end date.
  IntColumn get endDate => integer()();

  /// Status: 'draft', 'open', 'closed', 'locked'.
  TextColumn get status => text().withLength(min: 1, max: 16)();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get closedAt => integer().nullable()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get closedBy => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
        {companyId, code},
      ];
}
