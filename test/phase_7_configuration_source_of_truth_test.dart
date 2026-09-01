import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:drift/drift.dart' hide isNotNull;

import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_session.dart';
import 'package:stock_count/modules/authentication/domain/entities/auth_user.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_accounting_poster_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/warehouse_repository_impl.dart';
import 'package:stock_count/modules/system_setup/data/repositories/company_initialization_repository_impl.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_accounting_config_service.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_currency_service.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_setup_service.dart';
import 'package:stock_count/modules/system_setup/domain/services/company_warehouse_config_service.dart';
import 'package:stock_count/modules/system_setup/domain/services/initialization_guard.dart';
import 'package:stock_count/modules/system_setup/domain/services/initialization_validator.dart';

class FakePermissionGuard implements PermissionGuard {
  @override
  void requireAny(Iterable<String> permissions) {}

  @override
  void requireAll(Iterable<String> permissions) {}

  bool hasAny(Iterable<String> permissions) => true;

  bool hasAll(Iterable<String> permissions) => true;
}

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

  late Box<dynamic> settingsBoxCompanyA;
  late Box<dynamic> settingsBoxCompanyB;
  late InventoryDatabase db;
  late AccountingDatabase accountingDb;

  const companyAId = 'COMPANY-A';
  const companyBId = 'COMPANY-B';

  // Company A accounts
  const accAInventory = '00000000-0000-4000-8000-000000000a01';
  const accACogs = '00000000-0000-4000-8000-000000000a02';
  const accAPayable = '00000000-0000-4000-8000-000000000a03';
  const accARevenue = '00000000-0000-4000-8000-000000000a04';
  const accAReceivable = '00000000-0000-4000-8000-000000000a05';
  const accACash = '00000000-0000-4000-8000-000000000a06';
  const accAAdjustment = '00000000-0000-4000-8000-000000000a07';
  const accAFx = '00000000-0000-4000-8000-000000000a08';
  const whAId = '00000000-0000-4000-8000-000000000a09';

  // Company B accounts
  const accBInventory = '00000000-0000-4000-8000-000000000b01';
  const accBCogs = '00000000-0000-4000-8000-000000000b02';
  const accBPayable = '00000000-0000-4000-8000-000000000b03';
  const accBRevenue = '00000000-0000-4000-8000-000000000b04';
  const accBReceivable = '00000000-0000-4000-8000-000000000b05';
  const accBCash = '00000000-0000-4000-8000-000000000b06';
  const accBAdjustment = '00000000-0000-4000-8000-000000000b07';
  const accBFx = '00000000-0000-4000-8000-000000000b08';
  const whBId = '00000000-0000-4000-8000-000000000b09';

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    Hive.init('./test_hive_phase_7');
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    db = InventoryDatabase.memory();
    accountingDb = AccountingDatabase.memory();

    settingsBoxCompanyA = await Hive.openBox<dynamic>('settings_$companyAId');
    settingsBoxCompanyB = await Hive.openBox<dynamic>('settings_$companyBId');
    await settingsBoxCompanyA.clear();
    await settingsBoxCompanyB.clear();
  });

  tearDown(() async {
    await db.close();
    await accountingDb.close();
    await settingsBoxCompanyA.clear();
    await settingsBoxCompanyB.clear();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  Future<void> initializeCompany({
    required String companyId,
    required Box<dynamic> box,
    required String currencyCode,
    required String whId,
    required Map<AccountRole, String> accountsMap,
  }) async {
    final initRepo = CompanyInitializationRepositoryImpl(
      box: box,
      readCompanyId: () => companyId,
    );

    final setupService = CompanySetupService(
      settingsRepository: _InMemorySettingsRepository(),
      initRepository: initRepo,
    );

    final session = AuthSessionSnapshot(
      user: AuthUser(id: 'USER-$companyId', name: 'Admin $companyId', email: 'admin@$companyId.com'),
      companies: [],
      roles: ['admin'],
      permissions: {'system.setup', 'settings.company'},
      capturedAt: DateTime.now(),
      currentCompanyId: companyId,
    );

    await setupService.setupCompany(
      session: session,
      profile: CompanyProfile(name: 'Company $companyId'),
      isSuperAdmin: true,
    );

    final currencyService = CompanyCurrencyService(initRepository: initRepo);
    await currencyService.configureInventoryBaseCurrency(currencyCode: currencyCode);

    // Insert accounts into database
    final now = DateTime.now().millisecondsSinceEpoch;
    final accountRepo = AccountRepositoryImpl(accountingDb, readCompanyId: () => companyId);

    for (final entry in accountsMap.entries) {
      final role = entry.key;
      final uuid = entry.value;
      await accountingDb.into(accountingDb.accounts).insert(
            AccountsCompanion.insert(
              uuid: uuid,
              accountCode: '${role.name}_$companyId',
              name: '${role.name} for $companyId',
              accountType: role == AccountRole.inventory || role == AccountRole.receivable || role == AccountRole.cash
                  ? 'asset'
                  : (role == AccountRole.payable ? 'liability' : (role == AccountRole.revenue ? 'revenue' : 'expense')),
              normalBalance: role == AccountRole.payable || role == AccountRole.revenue ? 'credit' : 'debit',
              companyId: Value(companyId),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }

    final accountService = CompanyAccountingConfigService(
      accountRepository: accountRepo,
      initRepository: initRepo,
    );
    await accountService.saveAccountingConfig(mappings: accountsMap);

    // Insert Warehouse into database
    await db.into(db.warehouses).insert(
          WarehousesCompanion(
            uuid: Value(whId),
            code: Value('WH-$companyId'),
            name: Value('Warehouse $companyId'),
            companyId: Value(companyId),
            isActive: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    final warehouseRepo = WarehouseRepositoryImpl(db, null, () => companyId);
    final warehouseService = CompanyWarehouseConfigService(
      warehouseRepository: warehouseRepo,
      initRepository: initRepo,
    );
    await warehouseService.configureDefaultWarehouse(warehouseId: whId);

    await initRepo.finalizeInitialization();
  }

  group('Phase 7 — Configuration Becomes the Production Source of Truth', () {
    test('1. Company A & Company B use independent persisted configurations during posting', () async {
      // 1. Initialize Company A (Currency: YER)
      await initializeCompany(
        companyId: companyAId,
        box: settingsBoxCompanyA,
        currencyCode: 'YER',
        whId: whAId,
        accountsMap: {
          AccountRole.inventory: accAInventory,
          AccountRole.cogs: accACogs,
          AccountRole.payable: accAPayable,
          AccountRole.revenue: accARevenue,
          AccountRole.receivable: accAReceivable,
          AccountRole.cash: accACash,
          AccountRole.adjustment: accAAdjustment,
          AccountRole.fxGainLoss: accAFx,
        },
      );

      // 2. Initialize Company B (Currency: SAR)
      await initializeCompany(
        companyId: companyBId,
        box: settingsBoxCompanyB,
        currencyCode: 'SAR',
        whId: whBId,
        accountsMap: {
          AccountRole.inventory: accBInventory,
          AccountRole.cogs: accBCogs,
          AccountRole.payable: accBPayable,
          AccountRole.revenue: accBRevenue,
          AccountRole.receivable: accBReceivable,
          AccountRole.cash: accBCash,
          AccountRole.adjustment: accBAdjustment,
          AccountRole.fxGainLoss: accBFx,
        },
      );

      // --- Post Stock Receipt for Company A ---
      final initRepoA = CompanyInitializationRepositoryImpl(
        box: settingsBoxCompanyA,
        readCompanyId: () => companyAId,
      );
      final initGuardA = InitializationGuard(
        initRepository: initRepoA,
        validator: const InitializationValidator(),
      );

      final posterA = InventoryAccountingPosterImpl(
        accountingDb,
        readCompanyId: () => companyAId,
        initRepository: initRepoA,
        initializationGuard: initGuardA,
      );

      const recIdA = '00000000-0000-4000-8000-000000000a10';
      final docA = InventoryDocumentRef(
        documentId: recIdA,
        documentNumber: 'REC-A-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: whAId,
        currencyCode: 'YER',
      );

      await posterA.postAccountingEntry(
        document: docA,
        totalAmount: 5000,
      );

      // --- Post Stock Receipt for Company B ---
      final initRepoB = CompanyInitializationRepositoryImpl(
        box: settingsBoxCompanyB,
        readCompanyId: () => companyBId,
      );
      final initGuardB = InitializationGuard(
        initRepository: initRepoB,
        validator: const InitializationValidator(),
      );

      final posterB = InventoryAccountingPosterImpl(
        accountingDb,
        readCompanyId: () => companyBId,
        initRepository: initRepoB,
        initializationGuard: initGuardB,
      );

      const recIdB = '00000000-0000-4000-8000-000000000b10';
      final docB = InventoryDocumentRef(
        documentId: recIdB,
        documentNumber: 'REC-B-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: whBId,
        currencyCode: 'SAR',
      );

      await posterB.postAccountingEntry(
        document: docB,
        totalAmount: 1200,
      );

      // --- Verify Journal Entry for Company A ---
      final entryA = await (accountingDb.select(accountingDb.journalEntries)
            ..where((tbl) => tbl.sourceId.equals(recIdA) & tbl.companyId.equals(companyAId)))
          .getSingle();

      expect(entryA.currencyCode, equals('YER'));
      expect(entryA.companyId, equals(companyAId));

      final linesA = await (accountingDb.select(accountingDb.journalLines)
            ..where((tbl) => tbl.entryUuid.equals(entryA.uuid)))
          .get();

      expect(linesA.length, equals(2));
      final debitLineA = linesA.firstWhere((l) => l.debit > 0);
      final creditLineA = linesA.firstWhere((l) => l.credit > 0);

      expect(debitLineA.accountUuid, equals(accAInventory));
      expect(debitLineA.debit, equals(5000));
      expect(creditLineA.accountUuid, equals(accAPayable));
      expect(creditLineA.credit, equals(5000));

      // Accounting Invariant: Debit == Credit
      expect(debitLineA.debit, equals(creditLineA.credit));

      // --- Verify Journal Entry for Company B ---
      final entryB = await (accountingDb.select(accountingDb.journalEntries)
            ..where((tbl) => tbl.sourceId.equals(recIdB) & tbl.companyId.equals(companyBId)))
          .getSingle();

      expect(entryB.currencyCode, equals('SAR'));
      expect(entryB.companyId, equals(companyBId));

      final linesB = await (accountingDb.select(accountingDb.journalLines)
            ..where((tbl) => tbl.entryUuid.equals(entryB.uuid)))
          .get();

      expect(linesB.length, equals(2));
      final debitLineB = linesB.firstWhere((l) => l.debit > 0);
      final creditLineB = linesB.firstWhere((l) => l.credit > 0);

      expect(debitLineB.accountUuid, equals(accBInventory));
      expect(debitLineB.debit, equals(1200));
      expect(creditLineB.accountUuid, equals(accBPayable));
      expect(creditLineB.credit, equals(1200));

      // Accounting Invariant: Debit == Credit
      expect(debitLineB.debit, equals(creditLineB.credit));

      // Verify zero cross-tenant contamination
      expect(debitLineA.accountUuid, isNot(equals(accBInventory)));
      expect(debitLineB.accountUuid, isNot(equals(accAInventory)));
    });

    test('2. Company A & Company B Stock Issues use their respective COGS accounts and base currencies', () async {
      // 1. Initialize Company A
      await initializeCompany(
        companyId: companyAId,
        box: settingsBoxCompanyA,
        currencyCode: 'YER',
        whId: whAId,
        accountsMap: {
          AccountRole.inventory: accAInventory,
          AccountRole.cogs: accACogs,
          AccountRole.payable: accAPayable,
          AccountRole.revenue: accARevenue,
          AccountRole.receivable: accAReceivable,
          AccountRole.cash: accACash,
          AccountRole.adjustment: accAAdjustment,
          AccountRole.fxGainLoss: accAFx,
        },
      );

      // 2. Initialize Company B
      await initializeCompany(
        companyId: companyBId,
        box: settingsBoxCompanyB,
        currencyCode: 'SAR',
        whId: whBId,
        accountsMap: {
          AccountRole.inventory: accBInventory,
          AccountRole.cogs: accBCogs,
          AccountRole.payable: accBPayable,
          AccountRole.revenue: accBRevenue,
          AccountRole.receivable: accBReceivable,
          AccountRole.cash: accBCash,
          AccountRole.adjustment: accBAdjustment,
          AccountRole.fxGainLoss: accBFx,
        },
      );

      final initRepoA = CompanyInitializationRepositoryImpl(
        box: settingsBoxCompanyA,
        readCompanyId: () => companyAId,
      );
      final posterA = InventoryAccountingPosterImpl(
        accountingDb,
        readCompanyId: () => companyAId,
        initRepository: initRepoA,
        initializationGuard: InitializationGuard(
          initRepository: initRepoA,
          validator: const InitializationValidator(),
        ),
      );

      const issueIdA = '00000000-0000-4000-8000-000000000a20';
      final docIssueA = InventoryDocumentRef(
        documentId: issueIdA,
        documentNumber: 'ISS-A-001',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: DateTime.now(),
        warehouseId: whAId,
        currencyCode: 'YER',
      );

      await posterA.postAccountingEntry(
        document: docIssueA,
        totalAmount: 3000,
      );

      final entryIssueA = await (accountingDb.select(accountingDb.journalEntries)
            ..where((tbl) => tbl.sourceId.equals(issueIdA) & tbl.companyId.equals(companyAId)))
          .getSingle();

      final linesIssueA = await (accountingDb.select(accountingDb.journalLines)
            ..where((tbl) => tbl.entryUuid.equals(entryIssueA.uuid)))
          .get();

      final debitA = linesIssueA.firstWhere((l) => l.debit > 0);
      final creditA = linesIssueA.firstWhere((l) => l.credit > 0);

      expect(debitA.accountUuid, equals(accACogs));
      expect(creditA.accountUuid, equals(accAInventory));
      expect(debitA.debit, equals(3000));
      expect(creditA.credit, equals(3000));

      final initRepoB = CompanyInitializationRepositoryImpl(
        box: settingsBoxCompanyB,
        readCompanyId: () => companyBId,
      );
      final posterB = InventoryAccountingPosterImpl(
        accountingDb,
        readCompanyId: () => companyBId,
        initRepository: initRepoB,
        initializationGuard: InitializationGuard(
          initRepository: initRepoB,
          validator: const InitializationValidator(),
        ),
      );

      const issueIdB = '00000000-0000-4000-8000-000000000b20';
      final docIssueB = InventoryDocumentRef(
        documentId: issueIdB,
        documentNumber: 'ISS-B-001',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: DateTime.now(),
        warehouseId: whBId,
        currencyCode: 'SAR',
      );

      await posterB.postAccountingEntry(
        document: docIssueB,
        totalAmount: 800,
      );

      final entryIssueB = await (accountingDb.select(accountingDb.journalEntries)
            ..where((tbl) => tbl.sourceId.equals(issueIdB) & tbl.companyId.equals(companyBId)))
          .getSingle();

      final linesIssueB = await (accountingDb.select(accountingDb.journalLines)
            ..where((tbl) => tbl.entryUuid.equals(entryIssueB.uuid)))
          .get();

      final debitB = linesIssueB.firstWhere((l) => l.debit > 0);
      final creditB = linesIssueB.firstWhere((l) => l.credit > 0);

      expect(debitB.accountUuid, equals(accBCogs));
      expect(creditB.accountUuid, equals(accBInventory));
      expect(debitB.debit, equals(800));
      expect(creditB.credit, equals(800));
    });
  });
}
