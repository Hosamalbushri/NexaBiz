import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/bootstrap/app_initialization_state.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';

class MockSyncEntityHandler implements SyncEntityHandler {
  MockSyncEntityHandler(this.entityType);

  @override
  final String entityType;

  @override
  bool get preferServerWhenLocalSynced => false;

  final List<SyncRemoteChange> appliedChanges = [];

  @override
  Future<void> applyRemoteChange(SyncRemoteChange change) async {
    appliedChanges.add(change);
  }

  @override
  Future<SyncUploadAck> upload(SyncOperation operation) async {
    return SyncUploadAck(entityId: operation.entityId, remoteVersion: 1);
  }

  @override
  Future<List<SyncRemoteChange>> pull({DateTime? since}) async {
    return [];
  }

  @override
  Future<void> markLocalSynced({
    required String entityId,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {}

  @override
  Future<void> markLocalConflict({required String entityId, String? message}) async {}

  @override
  Future<void> confirmPull() async {}

  @override
  Future<void> abandonPull() async {}

  @override
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async {
    return null;
  }
}

void main() {
  group('Server Initialization Flow Tests', () {
    test('Mock handler captures remote entity payload changes correctly', () async {
      final handler = MockSyncEntityHandler('account');
      final change = SyncRemoteChange(
        entityType: 'account',
        entityId: 'acc_123',
        version: 1,
        updatedAt: DateTime.utc(2026, 1, 1),
        deleted: false,
        payload: {
          'id': 'acc_123',
          'code': '1010',
          'name': 'Cash on Hand',
          'accountType': 'asset',
        },
      );

      await handler.applyRemoteChange(change);

      expect(handler.appliedChanges.length, equals(1));
      expect(handler.appliedChanges.first.entityId, equals('acc_123'));
      expect(handler.appliedChanges.first.payload['code'], equals('1010'));
    });

    test('AuthState in remote mode with authenticated status allows remote sync', () {
      final capturedAt = DateTime.now().toUtc();
      final snapshot = AuthSessionSnapshot(
        user: const AuthUser(id: 'usr_1', name: 'Admin', email: 'admin@nexabiz.com'),
        companies: const [],
        roles: const ['admin'],
        permissions: const {'sync.execute'},
        currentCompanyId: 'comp_1',
        capturedAt: capturedAt,
      );

      final state = AuthState(
        status: AuthStatus.authenticated,
        session: snapshot,
        backend: AuthBackend.remote,
      );

      expect(state.isAuthenticated, isTrue);
      expect(state.canUseRemoteSync, isTrue);
    });

    test('InitializationState ready status indicates successful bootstrap', () {
      final completedAt = DateTime.now();
      final state = InitializationState(
        status: InitializationStatus.ready,
        stage: InitializationStage.applicationReady,
        operatingMode: ApplicationOperatingMode.server,
        completedAt: completedAt,
        progressPercentage: 1.0,
      );

      expect(state.isReady, isTrue);
      expect(state.canOperate, isTrue);
      expect(state.isFailed, isFalse);
    });
  });
}
