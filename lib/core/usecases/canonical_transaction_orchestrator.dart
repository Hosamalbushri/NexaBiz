import 'dart:async';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/utils/id_generator.dart';

/// Context metadata associated with an application-level cross-domain operation.
class OperationContext {
  final String correlationId;
  final String? userId;
  final String companyId;
  final DateTime timestamp;

  OperationContext({
    String? correlationId,
    this.userId,
    required this.companyId,
    DateTime? timestamp,
  })  : correlationId = correlationId ?? generateUuidV4(),
        timestamp = timestamp ?? DateTime.now().toUtc();
}

/// Canonical Transaction Orchestrator enforcing atomic single-SQLite transaction boundaries
/// across all cross-domain operations on `nexabiz.sqlite`.
class CanonicalTransactionOrchestrator {
  final NexabizDatabase _db;

  CanonicalTransactionOrchestrator(this._db);

  /// Runs [action] within a single SQLite transaction on `nexabiz.sqlite`.
  /// All database writes across Sales, Purchases, Inventory, Costing, Accounting, Audit, and Sync
  /// executed inside [action] commit atomically or roll back completely on failure.
  Future<T> runInTransaction<T>(
    Future<T> Function(OperationContext context) action, {
    required String companyId,
    String? userId,
    String? correlationId,
    int maxRetries = 3,
  }) async {
    final context = OperationContext(
      correlationId: correlationId,
      userId: userId,
      companyId: companyId,
    );

    int attempt = 0;
    while (true) {
      try {
        return await _db.transaction(() async {
          return await action(context);
        });
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        final isBusy = errStr.contains('sqlite_busy') ||
            errStr.contains('database is locked') ||
            errStr.contains('code 5');
        if (isBusy && attempt < maxRetries) {
          attempt++;
          await Future.delayed(Duration(milliseconds: 50 * attempt));
          continue;
        }
        rethrow;
      }
    }
  }
}
