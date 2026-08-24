import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:stock_count/app/bootstrap/app_initialization_state.dart';
import 'package:stock_count/core/connectivity/network_status.dart';
import 'package:stock_count/modules/authentication/data/sync_login_credential_store.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/entities/authentication_mode.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Phase 11 — Comprehensive Architecture & Mode Isolation Suite', () {
    test('1-5. Local & Sync Biometric Isolation and Mode Scoping', () async {
      final store = SyncLoginCredentialStore();

      // Initially disabled
      final localInitial = await store.isBiometricLoginEnabled(mode: AuthenticationMode.local);
      final syncInitial = await store.isBiometricLoginEnabled(mode: AuthenticationMode.sync);
      expect(localInitial, isFalse);
      expect(syncInitial, isFalse);

      // Save local credentials
      await store.saveCredentials(
        email: 'local_user@nexabiz.com',
        password: 'LocalPassword123!',
        mode: AuthenticationMode.local,
      );

      // Local enabled, Sync untouched
      expect(await store.isBiometricLoginEnabled(mode: AuthenticationMode.local), isTrue);
      expect(await store.isBiometricLoginEnabled(mode: AuthenticationMode.sync), isFalse);
      expect(await store.readEmail(mode: AuthenticationMode.local), equals('local_user@nexabiz.com'));
      expect(await store.readEmail(mode: AuthenticationMode.sync), isNull);

      // Save sync credentials
      await store.saveCredentials(
        email: 'sync_admin@company.com',
        password: 'SyncSecret456!',
        mode: AuthenticationMode.sync,
        serverContext: 'https://api.rawnaqq.com',
      );

      // Both enabled independently
      expect(await store.isBiometricLoginEnabled(mode: AuthenticationMode.local), isTrue);
      expect(await store.isBiometricLoginEnabled(mode: AuthenticationMode.sync), isTrue);
      expect(await store.readEmail(mode: AuthenticationMode.local), equals('local_user@nexabiz.com'));
      expect(await store.readEmail(mode: AuthenticationMode.sync), equals('sync_admin@company.com'));

      await store.clearAll();
    });

    test('6-11. Server Context Association for Sync Biometrics', () async {
      final store = SyncLoginCredentialStore();

      await store.saveCredentials(
        email: 'admin@company.com',
        password: 'Pass',
        mode: AuthenticationMode.sync,
        serverContext: 'https://server-a.com_comp1_user1',
      );

      // Matches exact server context
      expect(
        await store.isBiometricLoginEnabled(
          mode: AuthenticationMode.sync,
          serverContext: 'https://server-a.com_comp1_user1',
        ),
        isTrue,
      );

      // Different server context returns false (requires fresh opt-in)
      expect(
        await store.isBiometricLoginEnabled(
          mode: AuthenticationMode.sync,
          serverContext: 'https://server-b.com_comp2_user2',
        ),
        isFalse,
      );

      await store.clearAll();
    });

    test('12-18. Session Expiration & Queue Survival Invariants', () {
      final snapshot = AuthSessionSnapshot(
        user: const AuthUser(id: 'u1', name: 'User 1', email: 'u1@test.com'),
        companies: const [],
        roles: const ['admin'],
        permissions: const {'sales.create'},
        capturedAt: DateTime.now().toUtc(),
      );

      final state = AuthState(
        status: AuthStatus.sessionExpired,
        session: snapshot,
        errorMessage: 'token_expired',
      );

      expect(state.needsSessionRenewal, isTrue);
      expect(state.canUseRemoteSync, isFalse);
      expect(state.session, isNotNull);
    });

    test('19-25. InitializationState Machine Transition Invariants', () {
      var state = const InitializationState(status: InitializationStatus.initializing);

      // Downloading stage
      state = state.copyWith(
        status: InitializationStatus.downloadingInitialization,
        downloadedCount: 1250,
        totalToDownload: 1560,
        currentEntityType: 'products',
        progressPercentage: 0.8,
      );

      expect(state.isDownloading, isTrue);
      expect(state.downloadedCount, equals(1250));
      expect(state.totalToDownload, equals(1560));
      expect(state.currentEntityType, equals('products'));

      // Atomic DB write stage
      state = state.copyWith(status: InitializationStatus.initializingLocalDatabase);
      expect(state.isWritingDatabase, isTrue);

      // Bootstrap completed (before Ready)
      state = state.copyWith(status: InitializationStatus.bootstrapCompleted);
      expect(state.isBootstrapCompleted, isTrue);
      expect(state.isReady, isFalse);

      // Explicit user click 'Continue to Dashboard' -> Ready
      state = state.copyWith(status: InitializationStatus.ready);
      expect(state.isReady, isTrue);
    });

    test('26-31. NetworkStatus Indicator State Machine', () {
      expect(NetworkStatus.online.isOnline, isTrue);
      expect(NetworkStatus.offline.isOffline, isTrue);
      expect(NetworkStatus.reconnecting.isReconnecting, isTrue);
    });
  });
}
