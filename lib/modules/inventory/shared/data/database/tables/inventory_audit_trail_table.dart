import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Audit trail table for tracking document posting, unposting, editing, and deletion.
@DataClassName('InventoryAuditTrailRow')
class InventoryAuditTrail extends Table {
  /// Canonical UUID v7 primary key identity.
  TextColumn get id => text().withLength(min: 36, max: 36).clientDefault(generateUuidV7)();

  /// Associated document ID (id of receipt, issue, sale, return, transfer, etc.)
  TextColumn get documentId => text()();

  /// Type of document ('stock_receipt', 'stock_issue', 'sale', 'stock_return', 'stock_transfer')
  TextColumn get documentType => text()();

  /// Event type ('post', 'unpost', 'edit', 'delete')
  TextColumn get eventType => text()();

  /// User ID who performed the action
  TextColumn get userId => text().nullable()();

  /// Timestamp of action in UTC milliseconds
  TextColumn get notes => text().nullable()();

  IntColumn get timestamp => integer()();

  /// Optional JSON metadata (e.g. reason for unpost, shortages)
  TextColumn get metadata => text().nullable()();

  TextColumn get companyId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {companyId, id},
      ];
}
