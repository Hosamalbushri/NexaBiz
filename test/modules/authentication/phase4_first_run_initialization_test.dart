import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/domain/entities/system_role.dart';
import 'package:stock_count/modules/system_setup/domain/entities/system_setup_state.dart';
import 'package:stock_count/modules/system_setup/domain/ports/system_setup_seed_port.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/system_setup_state_repository.dart';
import 'package:stock_count/modules/system_setup/domain/services/system_initialization_coordinator.dart';

class MemorySystemSetupStateRepository implements SystemSetupStateRepository {
  SetupProgress _progress = const SetupProgress(
    schemaVersion: SystemSetupSchema.currentVersion,
    status: SystemSetupStatus.notStarted,
    steps: {},
  );

  @override
  Future<SetupProgress> load() async => _progress;

  @override
  Future<void> save(SetupProgress progress) async {
    _progress = progress;
  }
}

class MockSystemSetupSeedPort implements SystemSetupSeedPort {
  bool seeded = false;

  @override
  Future<void> ensureLocalDefaults({
    String? baseCurrency,
    String? defaultWarehouseName = 'المستودع الرئيسي',
    String? defaultWarehouseCode = 'WH-01',
  }) async {
    seeded = true;
  }

  @override
  Future<void> pullRemoteDefaults() async {}
}

class MockFailingSeedPort implements SystemSetupSeedPort {
  @override
  Future<void> ensureLocalDefaults({
    String? baseCurrency,
    String? defaultWarehouseName = 'المستودع الرئيسي',
    String? defaultWarehouseCode = 'WH-01',
  }) async {
    throw Exception('Database seed error');
  }

  @override
  Future<void> pullRemoteDefaults() async {}
}

class MockLocalAuthStore implements LocalAuthStore {
  bool configuredAdmin = false;
  AuthUser? systemAdmin;

  @override
  Future<bool> hasConfiguredAdmin() async => configuredAdmin || systemAdmin != null;

  @override
  Future<AuthUser> createInitialSystemAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    if (systemAdmin != null) return systemAdmin!;
    configuredAdmin = true;
    systemAdmin = AuthUser(
      id: 'sys_admin_mock',
      name: name,
      email: email,
      systemRole: SystemRole.systemAdmin,
      status: 'active',
    );
    return systemAdmin!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Phase 4 — First Run / System Initialization Tests (14 Scenarios)', () {
    late MemorySystemSetupStateRepository repo;
    late MockSystemSetupSeedPort seedPort;
    late MockLocalAuthStore authStore;

    setUp(() {
      repo = MemorySystemSetupStateRepository();
      seedPort = MockSystemSetupSeedPort();
      authStore = MockLocalAuthStore();
    });

    test('1. Fresh installation initializes in uninitialized state', () async {
      final coordinator = SystemInitializationCoordinator(
        stateRepository: repo,
        seedPort: seedPort,
        authStore: authStore,
      );

      expect(coordinator.currentState, equals(SystemInitializationState.uninitialized));
    });

    test('2 & 3 & 4 & 5. Complete First-Run System Initialization Sequence', () async {
      final coordinator = SystemInitializationCoordinator(
        stateRepository: repo,
        seedPort: seedPort,
        authStore: authStore,
      );

      expect(coordinator.currentState, equals(SystemInitializationState.uninitialized));
      expect(seedPort.seeded, isFalse);

      await coordinator.initializeSystem(
        adminName: 'Initial Admin',
        adminEmail: 'admin@nexabiz.local',
        adminPassword: 'Password123!',
      );

      expect(seedPort.seeded, isTrue);
      expect(authStore.configuredAdmin, isTrue);
      expect(authStore.systemAdmin?.systemRole, equals(SystemRole.systemAdmin));
      expect(coordinator.currentState, equals(SystemInitializationState.initialized));
    });

    test('6. Initialization called twice is rejected (Closed-Path Security)', () async {
      final coordinator = SystemInitializationCoordinator(
        stateRepository: repo,
        seedPort: seedPort,
        authStore: authStore,
      );

      await coordinator.initializeSystem(
        adminName: 'Admin 1',
        adminEmail: 'admin1@nexabiz.local',
        adminPassword: 'Password123!',
      );

      final state = await coordinator.getInitializationState();
      expect(state, equals(SystemInitializationState.initialized));

      expect(
        () => coordinator.initializeSystem(
          adminName: 'Admin 2',
          adminEmail: 'admin2@nexabiz.local',
          adminPassword: 'Password123!',
        ),
        throwsA(isA<SystemAlreadyInitializedException>()),
      );
    });

    test('7. Initialization interruption transitions to initializationFailed', () async {
      final failingSeedPort = MockFailingSeedPort();
      final coordinator = SystemInitializationCoordinator(
        stateRepository: repo,
        seedPort: failingSeedPort,
        authStore: authStore,
      );

      await expectLater(
        () => coordinator.initializeSystem(
          adminName: 'Admin',
          adminEmail: 'admin@nexabiz.local',
          adminPassword: 'Password123!',
        ),
        throwsA(isA<Exception>()),
      );

      expect(coordinator.currentState, equals(SystemInitializationState.initializationFailed));
    });

    test('8. Recovery after failure allows clean re-initialization', () async {
      var coordinator = SystemInitializationCoordinator(
        stateRepository: repo,
        seedPort: MockFailingSeedPort(),
        authStore: authStore,
      );

      try {
        await coordinator.initializeSystem(
          adminName: 'Admin',
          adminEmail: 'admin@nexabiz.local',
          adminPassword: 'Password123!',
        );
      } catch (_) {}

      expect(coordinator.currentState, equals(SystemInitializationState.initializationFailed));

      // Retry with working seedPort
      coordinator = SystemInitializationCoordinator(
        stateRepository: repo,
        seedPort: seedPort,
        authStore: authStore,
      );

      expect(coordinator.currentState, equals(SystemInitializationState.uninitialized));

      await coordinator.initializeSystem(
        adminName: 'Admin',
        adminEmail: 'admin@nexabiz.local',
        adminPassword: 'Password123!',
      );

      expect(coordinator.currentState, equals(SystemInitializationState.initialized));
    });

    test('9 & 10. Existing initialized installation detected as initialized', () async {
      authStore.configuredAdmin = true;
      final coordinator = SystemInitializationCoordinator(
        stateRepository: repo,
        seedPort: seedPort,
        authStore: authStore,
      );

      final state = await coordinator.getInitializationState();
      expect(state, equals(SystemInitializationState.initialized));
    });

    test('11 & 14. Second-admin creation path after initialization is REJECTED', () async {
      authStore.configuredAdmin = true;
      final coordinator = SystemInitializationCoordinator(
        stateRepository: repo,
        seedPort: seedPort,
        authStore: authStore,
      );

      expect(
        () => coordinator.initializeSystem(
          adminName: 'Rogue Admin',
          adminEmail: 'rogue@nexabiz.local',
          adminPassword: 'Password123!',
        ),
        throwsA(isA<SystemAlreadyInitializedException>()),
      );
    });

    test('12 & 13. System Admin has NO automatic company & activeCompanyContext remains null', () {
      const initialAdmin = AuthUser(
        id: 'sys_admin_01',
        name: 'System Admin',
        email: 'sysadmin@nexabiz.local',
        systemRole: SystemRole.systemAdmin,
      );

      final session = AuthSessionSnapshot(
        user: initialAdmin,
        companies: const [],
        roles: const [],
        permissions: const {'system.manage'},
        capturedAt: DateTime.now().toUtc(),
        currentCompanyId: null,
        activeMembership: null,
        activeCompanyContext: null,
      );

      expect(session.user.systemRole, equals(SystemRole.systemAdmin));
      expect(session.user.isSystemAdmin, isTrue);
      expect(session.companyContext, isNull);
      expect(session.activeCompanyId, isNull);
      expect(session.hasCompany, isFalse);
      expect(session.isValidSecuritySession, isTrue);
    });
  });
}
