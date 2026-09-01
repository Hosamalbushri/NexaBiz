import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/system_setup/data/repositories/company_initialization_repository_impl.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_setup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> settingsBox;
  late SettingsRepository settingsRepository;
  late CompanyInitializationRepositoryImpl initRepository;
  late CompanySetupService setupService;

  const testCompanyId = 'company-tenant-alpha';
  const testUserId = 'user-001';

  AuthSessionSnapshot createTestSession({
    String companyId = testCompanyId,
    bool isSuperAdmin = false,
    List<String> permissions = const ['system.setup'],
  }) {
    final user = AuthUser(
      id: testUserId,
      name: 'Admin User',
      email: 'admin@nexabiz.com',
      isSuperAdmin: isSuperAdmin,
    );

    final company = AuthCompany(
      id: companyId,
      name: 'NexaBiz Alpha Corp',
      code: 'ALPHA',
    );

    return AuthSessionSnapshot(
      user: user,
      companies: [company],
      roles: const ['admin'],
      permissions: permissions.toSet(),
      capturedAt: DateTime.utc(2026, 8, 30),
      currentCompanyId: companyId,
    );
  }

  setUp(() async {
    Hive.init('./test_hive_temp_p2');
    if (!Hive.isBoxOpen(HiveBoxes.settings)) {
      settingsBox = await Hive.openBox<dynamic>(HiveBoxes.settings);
    } else {
      settingsBox = Hive.box<dynamic>(HiveBoxes.settings);
    }
    await settingsBox.clear();

    settingsRepository = SettingsRepository(box: settingsBox);
    initRepository = CompanyInitializationRepositoryImpl(
      box: settingsBox,
      readCompanyId: () => testCompanyId,
    );
    setupService = CompanySetupService(
      settingsRepository: settingsRepository,
      initRepository: initRepository,
    );
  });

  tearDown(() async {
    await settingsBox.clear();
  });

  group('Phase 2 — Post-Authentication Company Setup Tests', () {
    test('1. Authenticated Access & Successful Setup', () async {
      final session = createTestSession();
      const draft = CompanyProfile(
        name: 'NexaBiz Alpha Ltd',
        taxNumber: '123456789',
        city: 'Riyadh',
        country: 'SA',
      );

      final result = await setupService.setupCompany(
        session: session,
        profile: draft,
        userPermissions: ['system.setup'],
      );

      expect(result.name, equals('NexaBiz Alpha Ltd'));
      expect(result.taxNumber, equals('123456789'));

      final initState = await initRepository.getState();
      expect(initState.companyCreated, isTrue);
      expect(initState.companyId, equals(testCompanyId));
    });

    test('2. Unauthenticated Rejection', () async {
      const draft = CompanyProfile(name: 'Unauthorized Corp');

      expect(
        () async => await setupService.setupCompany(
          session: null,
          profile: draft,
        ),
        throwsA(isA<CompanySetupException>()),
      );
    });

    test('3. Authorized Setup Execution', () async {
      final session = createTestSession(
        permissions: ['system.setup'],
      );

      const draft = CompanyProfile(name: 'Authorized Enterprise');
      final result = await setupService.setupCompany(
        session: session,
        profile: draft,
        userPermissions: ['system.setup'],
      );

      expect(result.name, equals('Authorized Enterprise'));
    });

    test('4. Unauthorized Setup Rejection', () async {
      final session = createTestSession(
        permissions: ['sales.read'], // No system.setup or settings.company
      );

      const draft = CompanyProfile(name: 'Hacker Corp');

      expect(
        () async => await setupService.setupCompany(
          session: session,
          profile: draft,
          userPermissions: ['sales.read'],
          isSuperAdmin: false,
        ),
        throwsA(
          isA<CompanySetupException>().having(
            (e) => e.message,
            'message',
            contains('Access Denied'),
          ),
        ),
      );
    });

    test('5. Existing Company Reuse (No Duplicate Creation)', () async {
      final session = createTestSession();

      // Initial setup
      const initialProfile = CompanyProfile(name: 'Initial Company Name');
      await setupService.setupCompany(
        session: session,
        profile: initialProfile,
        userPermissions: ['system.setup'],
      );

      // Re-running setup for existing company
      const updatedProfile = CompanyProfile(
        name: 'Updated Company Name',
        taxNumber: '987654321',
      );

      final result = await setupService.setupCompany(
        session: session,
        profile: updatedProfile,
        userPermissions: ['system.setup'],
      );

      expect(result.name, equals('Updated Company Name'));
      expect(result.taxNumber, equals('987654321'));

      final initState = await initRepository.getState();
      expect(initState.companyId, equals(testCompanyId));
      expect(initState.companyCreated, isTrue);
    });

    test('6. Duplicate Protection & Cross-Company Scoping', () async {
      final session = createTestSession(companyId: 'company-tenant-alpha');

      const draft = CompanyProfile(name: 'Tenant Alpha Updated');
      await setupService.setupCompany(
        session: session,
        profile: draft,
        userPermissions: ['system.setup'],
      );

      // Verify state was written exclusively for session's companyId
      final initStateAlpha = await initRepository.getState();
      expect(initStateAlpha.companyId, equals('company-tenant-alpha'));
      expect(initStateAlpha.companyCreated, isTrue);
    });
  });
}
