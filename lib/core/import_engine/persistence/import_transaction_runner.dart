import 'dart:async';

/// Generic database transaction runner contract.
/// Encapsulates platform/ORM specific transaction boundaries (Drift, SQLite, PostgreSQL).
abstract class ImportTransactionRunner {
  /// Executes [action] inside a database transaction block.
  /// Automatically rolls back on unhandled exceptions.
  Future<R> runInTransaction<R>(Future<R> Function() action);
}

/// In-memory transactional runner supporting transactional rollback callbacks for testing.
class InMemoryImportTransactionRunner implements ImportTransactionRunner {
  InMemoryImportTransactionRunner({this.onRollback});

  /// Optional callback invoked when a transaction rolls back.
  final void Function()? onRollback;

  @override
  Future<R> runInTransaction<R>(Future<R> Function() action) async {
    try {
      return await action();
    } catch (e) {
      if (onRollback != null) {
        onRollback!();
      }
      rethrow;
    }
  }
}
