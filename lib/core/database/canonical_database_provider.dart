import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/database/repositories/canonical_identity_repository.dart';
import 'package:stock_count/core/database/repositories/canonical_master_data_repository.dart';

/// Lifecycle states for the single canonical database `nexabiz.sqlite`.
enum CanonicalDatabaseLifecycleState {
  /// Database has not been initialized.
  uninitialized,

  /// Database connection is currently opening.
  opening,

  /// Database is open and ready for queries.
  open,

  /// Database connection is currently closing.
  closing,

  /// Database has been closed.
  closed,
}

/// Lifecycle manager and authority for canonical database `nexabiz.sqlite`.
class CanonicalDatabaseManager {
  CanonicalDatabaseManager();

  NexabizDatabase? _instance;
  Completer<NexabizDatabase>? _openingCompleter;
  CanonicalDatabaseLifecycleState _state =
      CanonicalDatabaseLifecycleState.uninitialized;

  /// Current database lifecycle state.
  CanonicalDatabaseLifecycleState get state => _state;

  /// Whether the canonical database is currently open.
  bool get isOpen =>
      _state == CanonicalDatabaseLifecycleState.open && _instance != null;

  /// Returns the active [NexabizDatabase] instance synchronously.
  ///
  /// Instantiates and marks the database as open if not yet initialized.
  NexabizDatabase get instance {
    if (_instance != null && _state == CanonicalDatabaseLifecycleState.open) {
      return _instance!;
    }
    _instance ??= NexabizDatabase(name: 'nexabiz');
    _state = CanonicalDatabaseLifecycleState.open;
    return _instance!;
  }

  /// Returns the active [NexabizDatabase] instance, opening it if necessary.
  ///
  /// Thread-safe: concurrent calls share a single-flight opening completion lock.
  Future<NexabizDatabase> openDatabase({String name = 'nexabiz'}) async {
    if (_instance != null &&
        _state == CanonicalDatabaseLifecycleState.open) {
      try {
        await _instance!.customSelect('SELECT 1').get();
        return _instance!;
      } catch (_) {
        // Fall through to re-open if health check fails
      }
    }
    if (_openingCompleter != null) {
      return _openingCompleter!.future;
    }

    final completer = Completer<NexabizDatabase>();
    _openingCompleter = completer;
    _state = CanonicalDatabaseLifecycleState.opening;

    try {
      final db = _instance ?? NexabizDatabase(name: name);
      // Run trivial query to verify connection and SQLCipher key validity
      await db.customSelect('SELECT 1').get();
      _instance = db;
      _state = CanonicalDatabaseLifecycleState.open;
      completer.complete(db);
      return db;
    } catch (e, stack) {
      _state = CanonicalDatabaseLifecycleState.closed;
      _instance = null;
      completer.completeError(e, stack);
      rethrow;
    } finally {
      _openingCompleter = null;
    }
  }


  /// Injects a custom instance (e.g. for testing).
  void setTestInstance(NexabizDatabase db) {
    _instance = db;
    _state = CanonicalDatabaseLifecycleState.open;
  }

  /// Safely closes the active canonical database connection.
  Future<void> closeDatabase() async {
    _openingCompleter = null;
    if (_instance == null ||
        _state == CanonicalDatabaseLifecycleState.closed) {
      _state = CanonicalDatabaseLifecycleState.closed;
      return;
    }

    _state = CanonicalDatabaseLifecycleState.closing;
    try {
      await _instance!.close();
    } finally {
      _instance = null;
      _state = CanonicalDatabaseLifecycleState.closed;
    }
  }

  /// Closes and re-opens the canonical database.
  Future<NexabizDatabase> reopenDatabase({String name = 'nexabiz'}) async {
    await closeDatabase();
    return openDatabase(name: name);
  }

  /// Verifies database connectivity and returns integrity status.
  Future<bool> healthCheck() async {
    if (_instance == null || !isOpen) {
      return false;
    }
    try {
      final result = await _instance!.customSelect('SELECT 1').get();
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

/// Global provider for [CanonicalDatabaseManager].
final canonicalDatabaseManagerProvider =
    Provider<CanonicalDatabaseManager>((ref) {
  final manager = CanonicalDatabaseManager();
  ref.onDispose(() {
    manager.closeDatabase();
  });
  return manager;
});

/// Provider for active canonical [NexabizDatabase] instance.
///
/// Returns the initialized [NexabizDatabase] instance.
final nexabizDatabaseProvider = Provider<NexabizDatabase>((ref) {
  final manager = ref.watch(canonicalDatabaseManagerProvider);
  return manager.instance;
});

/// Async provider for explicitly opening/initializing canonical [NexabizDatabase].
final nexabizDatabaseInitializerProvider =
    FutureProvider<NexabizDatabase>((ref) async {
  final manager = ref.watch(canonicalDatabaseManagerProvider);
  return manager.openDatabase();
});

/// Provider for canonical identity repository operating on [nexabizDatabaseProvider].
final canonicalIdentityRepositoryProvider =
    Provider<CanonicalIdentityRepository>((ref) {
  final db = ref.watch(nexabizDatabaseProvider);
  return CanonicalIdentityRepositoryImpl(db);
});

/// Provider for canonical master data repository operating on [nexabizDatabaseProvider].
final canonicalMasterDataRepositoryProvider =
    Provider<CanonicalMasterDataRepository>((ref) {
  final db = ref.watch(nexabizDatabaseProvider);
  return CanonicalMasterDataRepositoryImpl(db);
});


