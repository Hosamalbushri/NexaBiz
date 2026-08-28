import 'package:drift/drift.dart';

/// Audit trail table for tracking document posting, unposting, editing, and deletion.
@DataClassName('InventoryAuditTrailRow')
class InventoryAuditTrail extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// UUID of the audit event.
  TextColumn get uuid => text().withLength(min: 36, max: 36).unique()();

  /// Associated document ID (uuid of receipt, issue, sale, return, transfer, etc.)
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
}
