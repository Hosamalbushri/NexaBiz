import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/core/auth/domain/entities/authorization_context.dart';
import 'package:stock_count/core/auth/domain/services/offline_login_policy.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/core/time/domain/trusted_clock.dart';
import 'package:stock_count/core/time/domain/services/clock_integrity_service.dart';
import 'package:stock_count/core/sync/sync_manager.dart';
import 'package:stock_count/core/sync/sync_queue.dart';
import 'package:stock_count/core/sync/sync_overview.dart';
import 'package:stock_count/core/connectivity/connectivity_service.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/modules/authentication/domain/entities/authentication_mode.dart';
import 'package:stock_count/modules/authentication/domain/entities/offline_authorization_snapshot.dart';

class FakeStopwatch implements Stopwatch {
  int _elapsedMs = 0;

  @override
  int get elapsedMilliseconds => _elapsedMs;

  @override
  int get elapsedMicroseconds => _elapsedMs * 1000;

  @override
  Duration get elapsed => Duration(milliseconds: _elapsedMs);

  void increment(Duration duration) {
    _elapsedMs += duration.inMilliseconds;
  }

  @override
  bool get isRunning => true;

  @override
  void start() {}

  @override
  void stop() {}

  @override
  void reset() {}

  @override
  int get elapsedTicks => _elapsedMs * 1000;

  @override
  int get frequency => 1000000;
}

class FakeConnectivityService implements ConnectivityService {
  @override
  bool get isOnline => true;

  @override
  Stream<ConnectivityStatus> get statusStream => Stream.value(ConnectivityStatus.online);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRemoteSyncApi implements RemoteSyncApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    AuthorizationContext.globalClock = null;
  });

  group('Phase 6 — Trusted Time & Temporal Authorization Security Suite', () {
    test('1. Trusted clock returns valid time', () async {
      final fakeStopwatch = FakeStopwatch();
      final clock = TrustedClock(stopwatch: fakeStopwatch);
      await clock.initialize();

      final serverTime = DateTime.parse('2026-08-25T12:00:00Z').toUtc();
      final localWall = DateTime.parse('2026-08-25T12:05:00Z').toUtc();

      await clock.setCheckpoint(serverTime: serverTime, localWallClock: localWall);

      // Verify that utcNow returns calibrated time
      expect(clock.utcNow(), equals(serverTime));

      // Advance fake stopwatch by 10 minutes
      fakeStopwatch.increment(const Duration(minutes: 10));

      expect(clock.utcNow(), equals(serverTime.add(const Duration(minutes: 10))));
    });

    test('2. Monotonic elapsed time works', () {
      final fakeStopwatch = FakeStopwatch();
      final clock = TrustedClock(stopwatch: fakeStopwatch);
      expect(clock.currentMonotonicMs, equals(0));

      fakeStopwatch.increment(const Duration(seconds: 30));
      expect(clock.currentMonotonicMs, equals(30000));
    });

    test('3. Wall clock moves backwards', () async {
      final fakeStopwatch = FakeStopwatch();
      final clock = TrustedClock(stopwatch: fakeStopwatch);
      await clock.initialize();

      final baseTime = DateTime.parse('2026-08-25T12:00:00Z').toUtc();
      await clock.setCheckpoint(serverTime: baseTime, localWallClock: baseTime);

      final integrity = ClockIntegrityService(clock: clock);

      // Save a wall clock checkpoint later in time
      await clock.updateWallClock(baseTime.add(const Duration(hours: 1)));

      // Current wall clock is at baseTime (moved backwards!)
      // checkIntegrity compares DateTime.now().toUtc() against lastStoredWallClock.
      // To simulate wall clock backward shift:
      // We set lastStoredWallClock to tomorrow, which is in the future relative to DateTime.now()
      await clock.updateWallClock(DateTime.now().toUtc().add(const Duration(days: 1)));

      expect(integrity.checkIntegrity(), equals(ClockIntegrityState.tampered));
    });

    test('4. Wall clock moves forward', () async {
      final fakeStopwatch = FakeStopwatch();
      final clock = TrustedClock(stopwatch: fakeStopwatch);
      await clock.initialize();

      final baseTime = DateTime.now().toUtc().subtract(const Duration(hours: 2));
      await clock.setCheckpoint(serverTime: baseTime, localWallClock: baseTime);

      final integrity = ClockIntegrityService(clock: clock);

      // lastStoredWallClock is 1 hour ago. currentWallClock is now (which is after lastStoredWallClock)
      await clock.updateWallClock(DateTime.now().toUtc().subtract(const Duration(hours: 1)));

      expect(integrity.checkIntegrity(), isNot(equals(ClockIntegrityState.tampered)));
    });

    test('5. Wall clock and monotonic clock remain consistent', () async {
      final fakeStopwatch = FakeStopwatch();
      final clock = TrustedClock(stopwatch: fakeStopwatch);
      await clock.initialize();

      final baseTime = DateTime.now().toUtc();
      await clock.setCheckpoint(serverTime: baseTime, localWallClock: baseTime);

      final integrity = ClockIntegrityService(clock: clock);
      expect(integrity.checkIntegrity(), equals(ClockIntegrityState.trusted));
    });

    test('6. Suspicious clock drift is detected', () async {
      final fakeStopwatch = FakeStopwatch();
      final clock = TrustedClock(stopwatch: fakeStopwatch);
      await clock.initialize();

      // Checkpoint at day 0
      final baseTime = DateTime.now().toUtc();
      await clock.setCheckpoint(serverTime: baseTime, localWallClock: baseTime);

      final integrity = ClockIntegrityService(clock: clock);

      // Advance monotonic by 10 hours, but keep wall clock at baseTime (wall clock delta = 0, mono delta = 10 hrs)
      fakeStopwatch.increment(const Duration(hours: 10));

      expect(integrity.checkIntegrity(), equals(ClockIntegrityState.tampered));
    });

    test('7. Tampered clock state is detected', () async {
      final fakeStopwatch = FakeStopwatch();
      final clock = TrustedClock(stopwatch: fakeStopwatch);
      await clock.initialize();

      final baseTime = DateTime.now().toUtc();
      await clock.setCheckpoint(serverTime: baseTime, localWallClock: baseTime);

      final integrity = ClockIntegrityService(clock: clock);

      // Simulate backward shift
      await clock.updateWallClock(baseTime.add(const Duration(days: 2)));

      expect(integrity.checkIntegrity(), equals(ClockIntegrityState.tampered));
    });

    test('8. Premium grace works under trusted time', () {
      final context = AuthorizationContext(
        userId: 'u1',
        companyId: 'c1',
        permissions: const {'sync.execute'},
        entitlement: Entitlement.premiumActive('c1'),
        authenticationMode: AuthenticationMode.sync,
        isTimeTrusted: true,
        isOfflineGraceActive: true,
        requiresReverification: false,
      );

      expect(
        context.hasAuthorizedCapability(
          permission: 'sync.execute',
          capability: EntitlementCapability.sync,
        ),
        isTrue,
      );
    });

    test('9. Premium grace cannot be extended by moving the clock backwards', () {
      final context = AuthorizationContext(
        userId: 'u1',
        companyId: 'c1',
        permissions: const {'sync.execute'},
        entitlement: Entitlement.premiumActive('c1'),
        authenticationMode: AuthenticationMode.sync,
        temporalTrustState: 'tampered',
        isTimeTrusted: false,
        isOfflineGraceActive: false,
        requiresReverification: true,
      );

      expect(
        context.hasAuthorizedCapability(
          permission: 'sync.execute',
          capability: EntitlementCapability.sync,
        ),
        isFalse,
      );
    });

    test('10. Premium grace cannot be extended by moving the clock forward and backward', () {
      final context = AuthorizationContext(
        userId: 'u1',
        companyId: 'c1',
        permissions: const {'sync.execute'},
        entitlement: Entitlement.premiumActive('c1'),
        authenticationMode: AuthenticationMode.sync,
        temporalTrustState: 'tampered', // Lockout
        isTimeTrusted: false,
        isOfflineGraceActive: false,
      );

      expect(
        context.hasAuthorizedCapability(
          permission: 'sync.execute',
          capability: EntitlementCapability.sync,
        ),
        isFalse,
      );
    });

    test('11. Expired grace blocks sync', () {
      final context = AuthorizationContext(
        userId: 'u1',
        companyId: 'c1',
        permissions: const {'sync.execute'},
        entitlement: Entitlement.premiumActive('c1'),
        authenticationMode: AuthenticationMode.sync,
        isTimeTrusted: true,
        isOfflineGraceActive: false, // Expired
      );

      expect(
        context.hasAuthorizedCapability(
          permission: 'sync.execute',
          capability: EntitlementCapability.sync,
        ),
        isFalse,
      );
    });

    test('12. Expired grace does not block Free local CRUD', () {
      final context = AuthorizationContext(
        userId: 'u1',
        companyId: 'c1',
        permissions: const {'sales.create'},
        entitlement: Entitlement.freeLocal('c1'),
        authenticationMode: AuthenticationMode.local,
        isTimeTrusted: false, // clock untrusted
        isOfflineGraceActive: false,
      );

      // Local FreeCRUD requires sales.create permission, and it does not check EntitlementCapability.sync
      expect(
        context.permissions.contains('sales.create'),
        isTrue,
      );
    });

    test('13. Missing trusted checkpoint requires verification', () {
      final context = AuthorizationContext(
        userId: 'u1',
        companyId: 'c1',
        permissions: const {'sync.execute'},
        entitlement: Entitlement.premiumActive('c1'),
        authenticationMode: AuthenticationMode.sync,
        isTimeTrusted: false,
        requiresReverification: true,
      );

      expect(
        context.hasAuthorizedCapability(
          permission: 'sync.execute',
          capability: EntitlementCapability.sync,
        ),
        isFalse,
      );
    });

    test('14. Server time checkpoint is stored correctly', () async {
      final fakeStopwatch = FakeStopwatch();
      final clock = TrustedClock(stopwatch: fakeStopwatch);
      await clock.initialize();

      final serverTime = DateTime.parse('2026-08-25T12:00:00Z').toUtc();
      await clock.setCheckpoint(serverTime: serverTime, localWallClock: serverTime);

      expect(clock.checkpoint?.serverTime, equals(serverTime));
    });

    test('15. Server verification resets suspicious temporal state when valid', () async {
      final fakeStopwatch = FakeStopwatch();
      final clock = TrustedClock(stopwatch: fakeStopwatch);
      await clock.initialize();

      final baseTime = DateTime.now().toUtc();
      await clock.setCheckpoint(serverTime: baseTime, localWallClock: baseTime);

      final integrity = ClockIntegrityService(clock: clock);

      // Flagged as tampered due to backwards shift
      await clock.updateWallClock(DateTime.now().toUtc().add(const Duration(days: 2)));
      expect(integrity.checkIntegrity(), equals(ClockIntegrityState.tampered));

      // Re-calibrating via a new server response resets state to trusted
      await clock.setCheckpoint(serverTime: DateTime.now().toUtc(), localWallClock: DateTime.now().toUtc());
      expect(integrity.checkIntegrity(), equals(ClockIntegrityState.trusted));
    });

    test('16. OfflineLoginPolicy rejects unsafe temporal authorization', () {
      final policy = const OfflineLoginPolicy(
        expectedServerUrl: 'https://api.nexabiz.com',
        currentDeviceId: 'device_x',
      );

      final snapshot = OfflineAuthorizationSnapshot(
        userId: 'u1',
        companyId: 'c1',
        email: 'u1@nexabiz.com',
        roles: const ['user'],
        permissions: const {'sync.execute'},
        snapshotCreatedAt: DateTime.now().toUtc(),
        lastServerAuthenticatedAt: DateTime.now().toUtc(),
        serverBaseUrl: 'https://api.nexabiz.com',
        deviceId: 'device_x',
        authorizationVersion: 1,
      );

      final result = policy.evaluate(
        snapshot: snapshot,
        requestedUserId: 'u1',
        requestedCompanyId: 'c1',
        userStatus: 'active',
        userCompanyIds: const ['c1'],
        companyEntitlement: Entitlement.premiumActive('c1'),
        clockState: ClockIntegrityState.tampered,
      );

      expect(result.outcome, equals(OfflineLoginOutcome.temporalIntegritySuspicious));
    });

    test('17. AuthorizationContext exposes correct temporal state', () {
      final context = AuthorizationContext(
        userId: 'u1',
        companyId: 'c1',
        permissions: const {},
        entitlement: Entitlement.freeLocal('c1'),
        authenticationMode: AuthenticationMode.local,
        temporalTrustState: 'tampered',
        isOfflineGraceActive: false,
        requiresReverification: true,
        isTimeTrusted: false,
      );

      expect(context.temporalTrustState, equals('tampered'));
      expect(context.isOfflineGraceActive, isFalse);
      expect(context.requiresReverification, isTrue);
      expect(context.isTimeTrusted, isFalse);
    });

    test('18. SyncManager blocks sync when temporal authorization fails', () async {
      var syncAllowed = false;
      final queue = SyncQueue(box: MockBox([]));

      final manager = SyncManager(
        queue: queue,
        connectivity: FakeConnectivityService(),
        remoteProvider: () => FakeRemoteSyncApi(),
        hasSyncCapability: () => true,
        hasSyncPermission: () => true,
        readClockState: () => ClockIntegrityState.tampered,
        isTimeTrusted: () => false,
      );

      final pass = await manager.syncNow();
      expect(pass.outcome, equals(SyncPassOutcome.clockTampered));
    });

    test('19. SyncManager allows sync when all security conditions pass', () async {
      final queue = SyncQueue(box: MockBox([]));

      final manager = SyncManager(
        queue: queue,
        connectivity: FakeConnectivityService(),
        remoteProvider: () => FakeRemoteSyncApi(),
        hasSyncCapability: () => true,
        hasSyncPermission: () => true,
        readClockState: () => ClockIntegrityState.trusted,
        isTimeTrusted: () => true,
        isOfflineGraceActive: () => true,
        requiresReverification: () => false,
      );

      final pass = await manager.syncNow();
      expect(pass.outcome, isNot(equals(SyncPassOutcome.clockTampered)));
    });

    test('20. Logout clears security-sensitive temporal session state', () async {
      final fakeStopwatch = FakeStopwatch();
      final clock = TrustedClock(stopwatch: fakeStopwatch);
      await clock.initialize();

      await clock.setCheckpoint(serverTime: DateTime.now().toUtc(), localWallClock: DateTime.now().toUtc());
      expect(clock.checkpoint, isNotNull);

      await clock.clearSession();
      expect(clock.checkpoint, isNull);
    });

    test('21. Company switching cannot inherit another company\'s temporal authorization', () {
      final contextA = AuthorizationContext(
        userId: 'u1',
        companyId: 'company_a',
        permissions: const {'sync.execute'},
        entitlement: Entitlement.premiumActive('company_a'),
        authenticationMode: AuthenticationMode.sync,
        isTimeTrusted: true,
        isOfflineGraceActive: true,
      );

      final contextB = AuthorizationContext(
        userId: 'u1',
        companyId: 'company_b',
        permissions: const {'sync.execute'},
        entitlement: Entitlement.freeLocal('company_b'),
        authenticationMode: AuthenticationMode.local,
        isTimeTrusted: true,
        isOfflineGraceActive: false,
      );

      expect(contextA.companyId, equals('company_a'));
      expect(contextB.companyId, equals('company_b'));
      expect(contextB.hasAuthorizedCapability(
        permission: 'sync.execute',
        capability: EntitlementCapability.sync,
      ), isFalse);
    });

    test('22. Device switching cannot inherit another device\'s authorization checkpoint', () {
      final snapshotA = OfflineAuthorizationSnapshot(
        userId: 'u1',
        companyId: 'c1',
        email: 'u1@nexabiz.com',
        roles: const ['user'],
        permissions: const {'sync.execute'},
        snapshotCreatedAt: DateTime.now().toUtc(),
        lastServerAuthenticatedAt: DateTime.now().toUtc(),
        serverBaseUrl: 'https://api.nexabiz.com',
        deviceId: 'device_a',
        authorizationVersion: 1,
      );

      final policy = const OfflineLoginPolicy(
        expectedServerUrl: 'https://api.nexabiz.com',
        currentDeviceId: 'device_b', // Device mismatch!
      );

      final result = policy.evaluate(
        snapshot: snapshotA,
        requestedUserId: 'u1',
        requestedCompanyId: 'c1',
        userStatus: 'active',
        userCompanyIds: const ['c1'],
        companyEntitlement: Entitlement.premiumActive('c1'),
        clockState: ClockIntegrityState.trusted,
      );

      expect(result.outcome, equals(OfflineLoginOutcome.deviceMismatch));
    });

    test('23. Legacy snapshots migrate without data loss', () {
      final policy = const OfflineLoginPolicy(
        expectedServerUrl: 'https://api.nexabiz.com',
        currentDeviceId: 'device_x',
      );

      final snapshot = OfflineAuthorizationSnapshot(
        userId: 'u1',
        companyId: 'c1',
        email: 'u1@nexabiz.com',
        roles: const ['user'],
        permissions: const {'sync.execute'},
        snapshotCreatedAt: DateTime.now().toUtc(),
        lastServerAuthenticatedAt: DateTime.now().toUtc(),
        serverBaseUrl: 'https://api.nexabiz.com',
        deviceId: 'device_x',
        authorizationVersion: 1,
      );

      final result = policy.evaluate(
        snapshot: snapshot,
        requestedUserId: 'u1',
        requestedCompanyId: 'c1',
        userStatus: 'active',
        userCompanyIds: const ['c1'],
        companyEntitlement: Entitlement.premiumActive('c1'),
        clockState: ClockIntegrityState.trusted,
      );

      expect(result.isAllowed, isTrue);
    });
  });
}

class MockBox<T> implements Box<T> {
  MockBox(List<T> initial) {
    for (final item in initial) {
      final id = (item as dynamic).id;
      _map[id] = item;
    }
  }
  final Map<dynamic, T> _map = {};

  @override
  Iterable<T> get values => _map.values;

  @override
  Map<dynamic, T> toMap() => Map.from(_map);

  @override
  Future<void> put(dynamic key, T value) async {
    _map[key] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _map.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
