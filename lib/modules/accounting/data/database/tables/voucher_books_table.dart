import 'package:drift/drift.dart';

/// Numbering books for operational vouchers (sales, receipts, …).
///
/// Hierarchy: section **groups** (`is_group = 1`, no parent) own child
/// numbering books (`is_group = 0`, `parent_id` = group uuid). Each section
/// may have many children (e.g. sales invoices + sales returns).
@DataClassName('VoucherBookRow')
class VoucherBooks extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uuid => text().withLength(min: 36, max: 36).unique()();

  /// Parent group uuid; null for section roots.
  TextColumn get parentId => text().nullable()();

  TextColumn get name => text().withLength(min: 1, max: 120)();

  /// Storage key — section or leaf kind (see [VoucherBookType]).
  TextColumn get bookType => text().withLength(min: 1, max: 32)();

  /// Section folder (no numbering) vs leaf numbering book.
  BoolColumn get isGroup => boolean().withDefault(const Constant(false))();

  /// Current number in the book (next value to allocate). Stored as `next_number`.
  IntColumn get nextNumber => integer().withDefault(const Constant(1))();

  /// Last number available in this book (≥ current).
  IntColumn get endNumber => integer().withDefault(const Constant(9999))();

  /// Legacy unused column (older installs); ignored by the app.
  IntColumn get padLength => integer().withDefault(const Constant(4))();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  TextColumn get notes => text().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();
}
