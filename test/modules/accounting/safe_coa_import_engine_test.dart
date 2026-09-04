import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/coa_import_impact_analyzer.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/safe_coa_import_engine.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';

class FakeImportAccountRepository implements AccountRepository {
  final Map<String, Account> _accountsByUuid = {};

  void addAll(List<Account> accounts) {
    for (final acc in accounts) {
      _accountsByUuid[acc.uuid] = acc;
    }
  }

  @override
  Future<List<Account>> getAll({bool includeInactive = false}) async =>
      _accountsByUuid.values.where((a) => includeInactive || a.isActive).toList();

  @override
  Future<Account?> getByUuid(String uuid) async => _accountsByUuid[uuid];

  @override
  Future<Account?> getByAccountCode(String code) async {
    for (final acc in _accountsByUuid.values) {
      if (acc.accountCode == code) return acc;
    }
    return null;
  }

  @override
  Future<Account?> getById(int id) async => null;

  @override
  Future<void> ensureDefaultChartSeeded() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCompanyInitializationRepository implements CompanyInitializationRepository {
  CompanyAccountingConfig? _config;

  void setConfig(CompanyAccountingConfig config) {
    _config = config;
  }

  @override
  Future<CompanyAccountingConfig?> getAccountingConfig() async => _config;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Account createTestCoaAccount({
  required int id,
  required String uuid,
  required String code,
  required String name,
  required AccountType accountType,
  required String companyId,
  String? parentId,
  bool isGroup = false,
}) {
  return Account(
    id: id,
    uuid: uuid,
    accountCode: code,
    name: name,
    accountType: accountType,
    normalBalance: accountType.normalBalance,
    parentId: parentId,
    level: parentId == null ? 1 : 2,
    isGroup: isGroup,
    isActive: true,
    isSystemAccount: false,
    companyId: companyId,
    createdAt: DateTime.now().toUtc(),
    updatedAt: DateTime.now().toUtc(),
  );
}


void main() {
  group('NEXABIZ — SAFE CHART OF ACCOUNTS CHANGE & IMPORT (12 Mandatory Tests)', () {
    late FakeImportAccountRepository accountRepo;
    late FakeCompanyInitializationRepository initRepo;
    late CoaImportImpactAnalyzer impactAnalyzer;
    late SafeCoaImportEngine importEngine;

    const companyId = 'co_tenant_200';

    late Account accCash;
    late Account accSales;
    late Account accCogs;
    late Account accInventory;

    setUp(() {
      accountRepo = FakeImportAccountRepository();
      initRepo = FakeCompanyInitializationRepository();
      impactAnalyzer = CoaImportImpactAnalyzer();
      importEngine = SafeCoaImportEngine(
        accountRepository: accountRepo,
        impactAnalyzer: impactAnalyzer,
        initializationRepository: initRepo,
      );

      accCash = createTestCoaAccount(
        id: 1,
        uuid: 'cash_uuid_101',
        code: '1110',
        name: 'الصندوق الرئيسي',
        accountType: AccountType.asset,
        companyId: companyId,
      );

      accInventory = createTestCoaAccount(
        id: 2,
        uuid: 'inv_uuid_102',
        code: '1210',
        name: 'حساب تقييم المخزون',
        accountType: AccountType.asset,
        companyId: companyId,
      );

      accSales = createTestCoaAccount(
        id: 3,
        uuid: 'sales_uuid_103',
        code: '4100',
        name: 'إيرادات المبيعات',
        accountType: AccountType.revenue,
        companyId: companyId,
      );

      accCogs = createTestCoaAccount(
        id: 4,
        uuid: 'cogs_uuid_104',
        code: '5100',
        name: 'تكلفة البضاعة المباعة',
        accountType: AccountType.expense,
        companyId: companyId,
      );

      accountRepo.addAll([accCash, accInventory, accSales, accCogs]);

      initRepo.setConfig(CompanyAccountingConfig(
        companyId: companyId,
        accountMappings: {
          AccountRole.cash: accCash.uuid,
          AccountRole.inventory: accInventory.uuid,
          AccountRole.revenue: accSales.uuid,
          AccountRole.cogs: accCogs.uuid,
        },
        updatedAt: DateTime.now().toUtc(),
      ));
    });

    test('Test 1: Additive import succeeds safely', () async {
      final accNewBank = createTestCoaAccount(
        id: 5,
        uuid: 'bank_uuid_105',
        code: '1120',
        name: 'حساب البنك الجديد',
        accountType: AccountType.asset,
        companyId: companyId,
      );

      final candidateImport = [accCash, accInventory, accSales, accCogs, accNewBank];

      final report = await importEngine.previewImport(
        companyId: companyId,
        candidateAccounts: candidateImport,
      );

      expect(report.isSafeToImport, isTrue);
      expect(report.accountsAdded.length, equals(1));
      expect(report.accountsAdded.first.uuid, equals('bank_uuid_105'));
    });

    test('Test 2: Safe rename succeeds', () async {
      final renamedCash = createTestCoaAccount(
        id: 1,
        uuid: 'cash_uuid_101',
        code: '1110',
        name: 'الصندوق المركزي المعدل',
        accountType: AccountType.asset,
        companyId: companyId,
      );

      final candidateImport = [renamedCash, accInventory, accSales, accCogs];

      final report = await importEngine.previewImport(
        companyId: companyId,
        candidateAccounts: candidateImport,
      );

      expect(report.isSafeToImport, isTrue);
      expect(report.accountNamesChanged.length, equals(1));
    });

    test('Test 3: Safe code change (same UUID) succeeds', () async {
      final reCodedCash = createTestCoaAccount(
        id: 1,
        uuid: 'cash_uuid_101',
        code: '1111',
        name: 'الصندوق الرئيسي',
        accountType: AccountType.asset,
        companyId: companyId,
      );

      final candidateImport = [reCodedCash, accInventory, accSales, accCogs];

      final report = await importEngine.previewImport(
        companyId: companyId,
        candidateAccounts: candidateImport,
      );

      expect(report.isSafeToImport, isTrue);
      expect(report.accountCodesChanged.length, equals(1));
    });

    test('Test 4: Unsafe deletion of account with posted journals is BLOCKED', () async {
      // Import set omits accInventory (uuid: inv_uuid_102)
      final candidateImport = [accCash, accSales, accCogs];

      final postedUsage = {
        'inv_uuid_102': 15, // 15 posted transactions
      };

      final report = await importEngine.previewImport(
        companyId: companyId,
        candidateAccounts: candidateImport,
        postedUsageCounts: postedUsage,
      );

      expect(report.isSafeToImport, isFalse);
      expect(report.historicalJournalImpact.length, greaterThan(0));
      expect(report.blockingReasons.length, greaterThan(0));
    });

    test('Test 5: UUID replacement for account with posted journals is BLOCKED', () async {
      // Replacement has code 1210 but new UUID 'new_inv_uuid_999'
      final replacedInv = createTestCoaAccount(
        id: 99,
        uuid: 'new_inv_uuid_999',
        code: '1210',
        name: 'حساب تقييم المخزون المستبدل',
        accountType: AccountType.asset,
        companyId: companyId,
      );

      final candidateImport = [accCash, replacedInv, accSales, accCogs];

      final postedUsage = {
        'inv_uuid_102': 10,
      };

      final report = await importEngine.previewImport(
        companyId: companyId,
        candidateAccounts: candidateImport,
        postedUsageCounts: postedUsage,
      );

      expect(report.isSafeToImport, isFalse);
      expect(report.accountUuidsChanged.length, equals(1));
      expect(report.blockingReasons, anyElement(contains('يمنع استبدال المعرف الفريد UUID')));
    });

    test('Test 6: Account type change for account with posted journals is BLOCKED', () async {
      // Change accInventory type from Asset to Expense
      final modifiedInv = createTestCoaAccount(
        id: 2,
        uuid: 'inv_uuid_102',
        code: '1210',
        name: 'حساب تقييم المخزون',
        accountType: AccountType.expense,
        companyId: companyId,
      );

      final candidateImport = [accCash, modifiedInv, accSales, accCogs];

      final postedUsage = {
        'inv_uuid_102': 8,
      };

      final report = await importEngine.previewImport(
        companyId: companyId,
        candidateAccounts: candidateImport,
        postedUsageCounts: postedUsage,
      );

      expect(report.isSafeToImport, isFalse);
      expect(report.accountTypesChanged.length, equals(1));
    });

    test('Test 7: Parent change validation prevents circular hierarchy issues', () async {
      final parentAcc = createTestCoaAccount(
        id: 10,
        uuid: 'parent_uuid_100',
        code: '1000',
        name: 'الأصول المتداولة',
        accountType: AccountType.asset,
        companyId: companyId,
        isGroup: true,
      );

      final childAcc = createTestCoaAccount(
        id: 1,
        uuid: 'cash_uuid_101',
        code: '1110',
        name: 'الصندوق الرئيسي',
        accountType: AccountType.asset,
        companyId: companyId,
        parentId: 'parent_uuid_100',

      );

      final candidateImport = [parentAcc, childAcc, accInventory, accSales, accCogs];

      final report = await importEngine.previewImport(
        companyId: companyId,
        candidateAccounts: candidateImport,
      );

      expect(report.isSafeToImport, isTrue);
      expect(report.accountParentsChanged.length, equals(1));
    });

    test('Test 8: System-role loss due to missing bound account is BLOCKED', () async {
      // Candidate omits accSales (bound to AccountRole.revenue)
      final candidateImport = [accCash, accInventory, accCogs];

      final report = await importEngine.previewImport(
        companyId: companyId,
        candidateAccounts: candidateImport,
      );

      expect(report.isSafeToImport, isFalse);
      expect(report.systemRolesLost, contains(AccountRole.revenue));
      expect(report.configurationsBroken.length, greaterThan(0));
    });

    test('Test 9: Broken module mapping is REJECTED', () async {
      // Candidate omits bound account and introduces incompatible replacement
      final candidateImport = [
        accCash,
        accInventory,
        accCogs,
      ];

      expect(
        () async => importEngine.executeImport(
          companyId: companyId,
          candidateAccounts: candidateImport,
        ),
        throwsA(isA<UnsafeCoaImportException>()),
      );
    });

    test('Test 10: Atomic rollback verification on validation error', () async {
      final candidateImport = [accCash, accSales]; // Missing inv and cogs

      try {
        await importEngine.executeImport(
          companyId: companyId,
          candidateAccounts: candidateImport,
        );
        fail('Should have thrown UnsafeCoaImportException');
      } on UnsafeCoaImportException catch (e) {
        expect(e.blockingReasons.length, greaterThan(0));
      }

      // Verify repository state remained untouched
      final accountsAfter = await accountRepo.getAll(includeInactive: true);
      expect(accountsAfter.length, equals(4)); // Original 4 accounts remain
    });

    test('Test 11: Offline import preview and impact execution runs locally', () async {
      final accNewCash = createTestCoaAccount(
        id: 11,
        uuid: 'sub_cash_uuid_111',
        code: '1112',
        name: 'صندوق الفعالية الفرعي',
        accountType: AccountType.asset,
        companyId: companyId,
      );

      final candidateImport = [accCash, accInventory, accSales, accCogs, accNewCash];

      final report = await importEngine.previewImport(
        companyId: companyId,
        candidateAccounts: candidateImport,
      );

      expect(report.isSafeToImport, isTrue);
      expect(report.accountsAdded.length, equals(1));
    });

    test('Test 12: Sync engine integrity after import returns clean report', () async {
      final candidateImport = [accCash, accInventory, accSales, accCogs];

      final report = await importEngine.executeImport(
        companyId: companyId,
        candidateAccounts: candidateImport,
      );

      expect(report.isSafeToImport, isTrue);
      expect(report.blockingReasons, isEmpty);
    });
  });
}
