import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/sync/sync.dart';

void main() {
  group('DatasetSyncStateResolver Unit Tests', () {
    const resolver = DatasetSyncStateResolver();

    test('TEST 1: Server has no data + local empty -> emptyServerData', () {
      final state = resolver.resolve(
        isAuthenticated: true,
        isServerReachable: true,
        localDataRecordCount: 0,
        localCursorSequence: 0,
        serverHasData: false,
        serverSequence: 0,
      );
      expect(state, equals(DatasetSyncState.emptyServerData));
    });

    test('TEST 2: Server has data + local empty -> initialSyncRequired', () {
      final state = resolver.resolve(
        isAuthenticated: true,
        isServerReachable: true,
        localDataRecordCount: 0,
        localCursorSequence: 0,
        serverHasData: true,
        serverSequence: 150,
      );
      expect(state, equals(DatasetSyncState.initialSyncRequired));
    });

    test('TEST 3: Server has data + local has data + no new changes -> synchronized', () {
      final state = resolver.resolve(
        isAuthenticated: true,
        isServerReachable: true,
        localDataRecordCount: 50,
        localCursorSequence: 150,
        serverHasData: true,
        serverSequence: 150,
      );
      expect(state, equals(DatasetSyncState.synchronized));
    });

    test('TEST 4: Server has new changes + local has data -> syncRequired', () {
      final state = resolver.resolve(
        isAuthenticated: true,
        isServerReachable: true,
        localDataRecordCount: 50,
        localCursorSequence: 150,
        serverHasData: true,
        serverSequence: 200,
      );
      expect(state, equals(DatasetSyncState.syncRequired));
    });

    test('TEST 5: Server unavailable + local has data -> offlineReady', () {
      final state = resolver.resolve(
        isAuthenticated: true,
        isServerReachable: false,
        localDataRecordCount: 50,
        localCursorSequence: 150,
        serverHasData: false,
        serverSequence: 0,
      );
      expect(state, equals(DatasetSyncState.offlineReady));
    });

    test('TEST 6: Server unavailable + local empty -> offlineUninitialized', () {
      final state = resolver.resolve(
        isAuthenticated: true,
        isServerReachable: false,
        localDataRecordCount: 0,
        localCursorSequence: 0,
        serverHasData: false,
        serverSequence: 0,
      );
      expect(state, equals(DatasetSyncState.offlineUninitialized));
    });

    test('TEST 7: Local database empty + cursor > 0 -> recoveryRequired', () {
      final state = resolver.resolve(
        isAuthenticated: true,
        isServerReachable: true,
        localDataRecordCount: 0,
        localCursorSequence: 500, // Non-zero cursor but empty DB!
        serverHasData: true,
        serverSequence: 600,
      );
      expect(state, equals(DatasetSyncState.recoveryRequired));
    });

    test('TEST 8: Unauthenticated -> uninitialized', () {
      final state = resolver.resolve(
        isAuthenticated: false,
        isServerReachable: true,
        localDataRecordCount: 50,
        localCursorSequence: 100,
        serverHasData: true,
        serverSequence: 100,
      );
      expect(state, equals(DatasetSyncState.uninitialized));
    });

    test('TEST 9: Fatal error present -> failed', () {
      final state = resolver.resolve(
        isAuthenticated: true,
        isServerReachable: true,
        localDataRecordCount: 50,
        localCursorSequence: 100,
        serverHasData: true,
        serverSequence: 100,
        hasFatalError: true,
      );
      expect(state, equals(DatasetSyncState.failed));
    });

    test('TEST 10: Unresolved conflicts present -> conflict', () {
      final state = resolver.resolve(
        isAuthenticated: true,
        isServerReachable: true,
        localDataRecordCount: 50,
        localCursorSequence: 100,
        serverHasData: true,
        serverSequence: 100,
        hasConflicts: true,
      );
      expect(state, equals(DatasetSyncState.conflict));
    });

    test('TEST 11: Deterministic state resolution for identical inputs', () {
      final state1 = resolver.resolve(
        isAuthenticated: true,
        isServerReachable: true,
        localDataRecordCount: 120,
        localCursorSequence: 500,
        serverHasData: true,
        serverSequence: 500,
      );
      final state2 = resolver.resolve(
        isAuthenticated: true,
        isServerReachable: true,
        localDataRecordCount: 120,
        localCursorSequence: 500,
        serverHasData: true,
        serverSequence: 500,
      );
      expect(state1, equals(state2));
      expect(state1, equals(DatasetSyncState.synchronized));
    });

    test('TEST 12: Recovery required evaluated even when server unavailable if local DB empty and cursor > 0', () {
      final state = resolver.resolve(
        isAuthenticated: true,
        isServerReachable: false,
        localDataRecordCount: 0,
        localCursorSequence: 100,
        serverHasData: false,
        serverSequence: 0,
      );
      // Offline with data = offlineReady, offline without data = offlineUninitialized
      expect(state, equals(DatasetSyncState.offlineUninitialized));
    });

    test('TEST 13: Local DB record count > 0 with server Sequence == local Cursor -> synchronized', () {
      final state = resolver.resolve(
        isAuthenticated: true,
        isServerReachable: true,
        localDataRecordCount: 1,
        localCursorSequence: 10,
        serverHasData: true,
        serverSequence: 10,
      );
      expect(state, equals(DatasetSyncState.synchronized));
    });

    test('TEST 14: Server dataset sequence > local cursor -> syncRequired', () {
      final state = resolver.resolve(
        isAuthenticated: true,
        isServerReachable: true,
        localDataRecordCount: 1,
        localCursorSequence: 10,
        serverHasData: true,
        serverSequence: 11,
      );
      expect(state, equals(DatasetSyncState.syncRequired));
    });

    test('TEST 15: Server dataset sequence < local cursor -> synchronized', () {
      final state = resolver.resolve(
        isAuthenticated: true,
        isServerReachable: true,
        localDataRecordCount: 10,
        localCursorSequence: 20,
        serverHasData: true,
        serverSequence: 18,
      );
      expect(state, equals(DatasetSyncState.synchronized));
    });
  });
}
