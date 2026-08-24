import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/app/bootstrap/app_initialization_state.dart';
import 'package:stock_count/core/connectivity/network_status.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/entities/authentication_mode.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Mode & Navigation State Machine Tests', () {
    test('1. AuthenticationMode strongly typed enum verification', () {
      const localMode = AuthenticationMode.local;
      const syncMode = AuthenticationMode.sync;

      expect(localMode.isLocal, isTrue);
      expect(localMode.isSync, isFalse);
      expect(syncMode.isSync, isTrue);
      expect(syncMode.isLocal, isFalse);
    });

    test('2. InitializationState transitions to bootstrapCompleted before ready', () {
      var state = const InitializationState(status: InitializationStatus.initializing);
      expect(state.isBootstrapCompleted, isFalse);

      state = state.copyWith(status: InitializationStatus.bootstrapCompleted);
      expect(state.isBootstrapCompleted, isTrue);
      expect(state.isReady, isFalse);

      state = state.copyWith(status: InitializationStatus.ready);
      expect(state.isBootstrapCompleted, isFalse);
      expect(state.isReady, isTrue);
    });

    test('3. AuthState sessionExpired preserves local permissions snapshot for offline gating', () {
      final snapshot = AuthSessionSnapshot(
        user: const AuthUser(
          id: 'user_1',
          name: 'Test User',
          email: 'user@nexabiz.com',
        ),
        companies: const [],
        roles: const [],
        permissions: const {'sales.create', 'sales.view'},
        capturedAt: DateTime.now(),
        currentCompanyId: 'comp_1',
      );

      final state = AuthState(
        status: AuthStatus.sessionExpired,
        session: snapshot,
        errorMessage: 'session_expired',
      );

      expect(state.needsSessionRenewal, isTrue);
      expect(state.canUseRemoteSync, isFalse);
      expect(state.hasPermission('sales.create'), isTrue);
      expect(state.session, isNotNull);
    });

    test('4. NetworkStatus maps connectivity and sync state accurately', () {
      expect(NetworkStatus.online.isOnline, isTrue);
      expect(NetworkStatus.offline.isOffline, isTrue);
      expect(NetworkStatus.reconnecting.isReconnecting, isTrue);
    });
  });
}
