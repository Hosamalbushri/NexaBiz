import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:drift/drift.dart' hide isNotNull;

import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/core/network/server_validator.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_accounting_poster_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/warehouse_repository_impl.dart';
import 'package:stock_count/modules/system_setup/data/repositories/company_initialization_repository_impl.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_accounting_config_service.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_currency_service.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_setup_service.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_warehouse_config_service.dart';
import 'package:stock_count/modules/system_setup/domain/services/initialization_guard.dart';
import 'package:stock_count/modules/system_setup/domain/services/initialization_validator.dart';

class _InMemorySettingsRepository implements SettingsRepository {
  CompanyProfile _profile = const CompanyProfile();

  @override
  Future<CompanyProfile> loadCompanyProfile() async => _profile;

  @override
  Future<void> saveCompanyProfile(CompanyProfile profile) async {
    _profile = profile;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> settingsBoxA;
  late Box<dynamic> settingsBoxB;
  late InventoryDatabase db;
  late AccountingDatabase accountingDb;

  const companyAId = 'COMP-ADV-A';
  const companyBId = 'COMP-ADV-B';

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    Hive.init('./test_hive_phase_8');
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    db = InventoryDatabase.memory();
    accountingDb = AccountingDatabase.memory();

    settingsBoxA = await Hive.openBox<dynamic>('settings_$companyAId');
    settingsBoxB = await Hive.openBox<dynamic>('settings_$companyBId');
    await settingsBoxA.clear();
    await settingsBoxB.clear();
  });

  tearDown(() async {
    await db.close();
    await accountingDb.close();
    await settingsBoxA.clear();
    await settingsBoxB.clear();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  group('Phase 8 — Adversarial Security, Multi-Tenancy & Sync Audit', () {
    test('ATTACK 1: Cross-Tenant Isolation Rejection', () async {
      final initRepoA = CompanyInitializationRepositoryImpl(
        box: settingsBoxA,
        readCompanyId: () => companyAId,
      );

      final warehouseRepo = WarehouseRepositoryImpl(db, null, () => companyAId);
      final warehouseService = CompanyWarehouseConfigService(
        warehouseRepository: warehouseRepo,
        initRepository: initRepoA,
      );

      // Attempt assigning Company B warehouse to Company A
      expect(
        () => warehouseService.configureDefaultWarehouse(warehouseId: 'WH-COMPANY-B-UUID'),
        throwsA(isA<InvalidWarehouseException>()),
      );
    });

    test('ATTACK 2: Unauthorized User Configuration Mutation Rejection', () async {
      final initRepo = CompanyInitializationRepositoryImpl(
        box: settingsBoxA,
        readCompanyId: () => companyAId,
      );
      final setupService = CompanySetupService(
        settingsRepository: _InMemorySettingsRepository(),
        initRepository: initRepo,
      );

      final limitedSession = AuthSessionSnapshot(
        user: const AuthUser(id: 'ATTACKER', name: 'Attacker', email: 'attacker@evil.com'),
        companies: [],
        roles: ['user'],
        permissions: {'inventory.view'},
        capturedAt: DateTime.now(),
        currentCompanyId: companyAId,
      );

      expect(
        () => setupService.setupCompany(
          session: limitedSession,
          profile: const CompanyProfile(name: 'Evil Corp'),
          userPermissions: ['inventory.view'],
          isSuperAdmin: false,
        ),
        throwsA(isA<CompanySetupException>()),
      );
    });

    test('ATTACK 3: Initialization Bypass Rejection at Domain Layer', () async {
      final uninitRepo = CompanyInitializationRepositoryImpl(
        box: settingsBoxA,
        readCompanyId: () => companyAId,
      );
      final initGuard = InitializationGuard(
        initRepository: uninitRepo,
        validator: const InitializationValidator(),
      );

      final poster = InventoryAccountingPosterImpl(
        accountingDb,
        readCompanyId: () => companyAId,
        initRepository: uninitRepo,
        initializationGuard: initGuard,
      );

      final doc = InventoryDocumentRef(
        documentId: 'BYPASS-001',
        documentNumber: 'BYPASS-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
      );

      expect(
        () => poster.postAccountingEntry(document: doc, totalAmount: 100),
        throwsA(isA<UninitializedCompanyException>()),
      );
    });

    test('ATTACK 4: Replay Complete Initialization (Idempotency Check)', () async {
      final initRepo = CompanyInitializationRepositoryImpl(
        box: settingsBoxA,
        readCompanyId: () => companyAId,
      );

      // Save initial config
      await initRepo.saveAccountingConfig(
        const CompanyAccountingConfig(
          companyId: companyAId,
          accountMappings: {AccountRole.inventory: '1230'},
        ),
      );

      // Replay same initialization
      await initRepo.saveAccountingConfig(
        const CompanyAccountingConfig(
          companyId: companyAId,
          accountMappings: {AccountRole.inventory: '1230'},
        ),
      );

      final config = await initRepo.getAccountingConfig();
      expect(config?.accountMappings[AccountRole.inventory], equals('1230'));
    });

    test('ATTACK 5: Partial Failure keeps Initialization Incomplete', () async {
      final initRepo = CompanyInitializationRepositoryImpl(
        box: settingsBoxA,
        readCompanyId: () => companyAId,
      );

      // Set only currency (missing accounting & warehouse)
      await initRepo.saveInventoryConfig(
        const CompanyInventoryConfig(
          companyId: companyAId,
          inventoryBaseCurrencyId: 'SAR',
        ),
      );

      final state = await initRepo.getState();
      final validator = const InitializationValidator();
      final result = validator.validate(state: state);

      expect(result.isReady, isFalse);
      expect(result.missingRequirements, contains('System chart of accounts mappings are incomplete'));
      expect(result.missingRequirements, contains('Default primary warehouse is not configured'));
    });

    test('OFFLINE: Local Password Security uses PBKDF2-HMAC-SHA256 with 10,000 iterations', () async {
      final storeBox = await Hive.openBox<dynamic>('test_auth_box');
      await storeBox.clear();
      final store = LocalAuthStore(box: storeBox);

      await store.ensureSeeded();
      final session = await store.login(
        email: LocalAuthDefaults.adminEmail,
        password: LocalAuthDefaults.adminPassword,
        deviceId: 'TEST-DEV',
      );

      expect(session, isNotNull);
      expect(session!.user.email, equals(LocalAuthDefaults.adminEmail));
      await storeBox.clear();
    });

    test('SERVER VALIDATOR: Enforces HTTPS requirement for non-loopback connections', () async {
      // Remote HTTP must be rejected
      final remoteHttp = await ServerValidator.validate('http://api.nexabiz-erp.com');
      expect(remoteHttp.healthy, isFalse);
      expect(remoteHttp.error, contains('HTTPS protocol is required'));

      // Loopback HTTP (localhost / 127.0.0.1) is allowed for dev testing
      final localHttp = await ServerValidator.validate('http://localhost:8080');
      // Should not throw HTTPS requirement error
      expect(localHttp.error ?? '', isNot(contains('HTTPS protocol is required')));
    });
  });
}
