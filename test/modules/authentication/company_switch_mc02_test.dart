import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase MC-02 — Atomic Company Context Switching Engine Tests', () {
    late LocalAuthStore authStore;
    late String branchCompanyId;

    setUpAll(() async {
      FlutterSecureStorage.setMockInitialValues({});
      Hive.init('./test_hive_mc02');
    });

    tearDownAll(() async {
      await Hive.deleteFromDisk();
    });

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      authStore = LocalAuthStore();
      await authStore.ensureSeeded();

      await authStore.createOwnerAndCompany(
        companyId: LocalAuthDefaults.companyId,
        companyName: LocalAuthDefaults.companyName,
        companyCode: LocalAuthDefaults.companyCode,
        ownerEmail: LocalAuthDefaults.adminEmail,
        ownerPassword: 'password',
        ownerName: LocalAuthDefaults.adminName,
      );

      final branchCompany = await authStore.createCompany(
        name: 'Branch 02',
        code: 'BR02',
      );
      branchCompanyId = branchCompany.id;
    });

    test('TEST 1 — A -> B: Session ID remains stable during company switch', () async {
      final initialSession = await authStore.login(
        email: LocalAuthDefaults.adminEmail,
        password: 'password',
        deviceId: 'test_device',
        companyId: LocalAuthDefaults.companyId,
      );

      expect(initialSession, isNotNull);
      final originalSessionId = initialSession!.sessionId;
      expect(originalSessionId, isNotNull);
      expect(initialSession.currentCompanyId, equals(LocalAuthDefaults.companyId));

      final switched = await authStore.switchCompany(
        current: initialSession,
        companyId: branchCompanyId,
      );

      expect(switched, isNotNull);
      expect(switched!.currentCompanyId, equals(branchCompanyId));
      expect(switched.sessionId, equals(originalSessionId), reason: 'Rule 1: sessionId MUST NOT change during company switch');
    });

    test('TEST 2 — B -> A: Reverse company switch preserves session ID', () async {
      final sessionA = await authStore.login(
        email: LocalAuthDefaults.adminEmail,
        password: 'password',
        deviceId: 'test_device',
        companyId: LocalAuthDefaults.companyId,
      );
      final originalSessionId = sessionA!.sessionId;

      final sessionB = await authStore.switchCompany(
        current: sessionA,
        companyId: branchCompanyId,
      );
      expect(sessionB!.currentCompanyId, equals(branchCompanyId));

      final reversedA = await authStore.switchCompany(
        current: sessionB,
        companyId: LocalAuthDefaults.companyId,
      );

      expect(reversedA, isNotNull);
      expect(reversedA!.currentCompanyId, equals(LocalAuthDefaults.companyId));
      expect(reversedA.sessionId, equals(originalSessionId));
    });

    test('TEST 3 — A -> B -> A: Multi-switch preserves original session ID', () async {
      final sessionA = (await authStore.login(
        email: LocalAuthDefaults.adminEmail,
        password: 'password',
        deviceId: 'test_device',
        companyId: LocalAuthDefaults.companyId,
      ))!;
      final originalSessionId = sessionA.sessionId;

      final sessionB = await authStore.switchCompany(current: sessionA, companyId: branchCompanyId);
      final sessionBackA = await authStore.switchCompany(current: sessionB!, companyId: LocalAuthDefaults.companyId);

      expect(sessionBackA!.sessionId, equals(originalSessionId));
    });

    test('TEST 4 — SAME COMPANY: A -> A is idempotent no-op', () async {
      final sessionA = (await authStore.login(
        email: LocalAuthDefaults.adminEmail,
        password: 'password',
        deviceId: 'test_device',
        companyId: LocalAuthDefaults.companyId,
      ))!;

      final sameCompanySession = await authStore.switchCompany(
        current: sessionA,
        companyId: LocalAuthDefaults.companyId,
      );

      expect(sameCompanySession, equals(sessionA));
      expect(sameCompanySession!.sessionId, equals(sessionA.sessionId));
    });

    test('TEST 5 — INVALID MEMBERSHIP: Switch to invalid company returns null and preserves context', () async {
      final sessionA = (await authStore.login(
        email: LocalAuthDefaults.adminEmail,
        password: 'password',
        deviceId: 'test_device',
        companyId: LocalAuthDefaults.companyId,
      ))!;

      final invalidSwitch = await authStore.switchCompany(
        current: sessionA,
        companyId: 'non_existent_company_9999',
      );

      expect(invalidSwitch, isNull, reason: 'Rule 12: Invalid switch MUST return null');

      final restoredSession = await authStore.loadSession();
      expect(restoredSession, isNotNull);
      expect(restoredSession!.currentCompanyId, equals(LocalAuthDefaults.companyId), reason: 'Rule 12: Active context A MUST remain intact on switch failure');
    });

    test('TEST 9 — SYSTEM SCOPE: Unassigned/system scope tenant context has empty companyId', () {
      const emptyContext = TenantContext.empty;
      expect(emptyContext.companyId, equals(''));
      expect(emptyContext.hasActiveCompany, isFalse);
    });

    test('TEST 10 — SESSION RESTORATION: Preserves persisted companyId and sessionId', () async {
      final loginSession = (await authStore.login(
        email: LocalAuthDefaults.adminEmail,
        password: 'password',
        deviceId: 'test_device',
        companyId: LocalAuthDefaults.companyId,
      ))!;
      final switchedSession = await authStore.switchCompany(
        current: loginSession,
        companyId: branchCompanyId,
      );

      final restored = await authStore.loadSession();
      expect(restored, isNotNull);
      expect(restored!.sessionId, equals(switchedSession!.sessionId));
      expect(restored.currentCompanyId, equals(branchCompanyId));
    });
  });
}
