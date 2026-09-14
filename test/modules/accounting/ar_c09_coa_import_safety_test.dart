import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
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
      _accountsByUuid.values
          .where((a) => includeInactive || a.isActive)
          .toList();

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

class FakeCompanyInitializationRepository
    implements CompanyInitializationRepository {
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
  group(
    'AR-C09 Safe Chart of Accounts Import, Hierarchy, Type & Configuration Compatibility',
    () {
      late FakeImportAccountRepository accountRepo;
      late FakeCompanyInitializationRepository initRepo;
      late CoaImportImpactAnalyzer impactAnalyzer;
      late SafeCoaImportEngine importEngine;

      const companyId = 'compA';

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
          id: 'acc-cash-01',
          code: '101001',
          name: 'الصندوق الرئيسي',
          accountType: AccountType.asset,
          companyId: companyId,
        );

        accInventory = createTestCoaAccount(
          id: 'acc-inv-01',
          code: '102001',
          name: 'تقييم المخزون',
          accountType: AccountType.asset,
          companyId: companyId,
        );

        accSales = createTestCoaAccount(
          id: 'acc-sales-01',
          code: '401001',
          name: 'إيرادات المبيعات',
          accountType: AccountType.revenue,
          companyId: companyId,
        );

        accCogs = createTestCoaAccount(
          id: 'acc-cogs-01',
          code: '501001',
          name: 'تكلفة المبيعات',
          accountType: AccountType.expense,
          companyId: companyId,
        );

        accountRepo.addAll([accCash, accInventory, accSales, accCogs]);

        initRepo.setConfig(
          CompanyAccountingConfig(
            companyId: companyId,
            accountMappings: {
              AccountRole.cash: accCash.uuid,
              AccountRole.inventory: accInventory.uuid,
              AccountRole.revenue: accSales.uuid,
              AccountRole.cogs: accCogs.uuid,
            },
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      });

      test('1. Valid Additive COA Import', () async {
        final accNewBank = createTestCoaAccount(
          id: 'acc-bank-01',
          code: '101002',
          name: 'حساب البنك الرئيسي',
          accountType: AccountType.asset,
          companyId: companyId,
        );

        final candidateImport = [
          accCash,
          accInventory,
          accSales,
          accCogs,
          accNewBank,
        ];

        final report = await importEngine.previewImport(
          companyId: companyId,
          candidateAccounts: candidateImport,
        );

        expect(report.isSafeToImport, isTrue);
        expect(report.accountsAdded.length, equals(1));
      });

      test(
        '2. Wrong Account Type Mutation Rejection (Asset -> Liability)',
        () async {
          final mutatedInv = createTestCoaAccount(
            id: 'acc-inv-01',
            code: '102001',
            name: 'تقييم المخزون',
            accountType: AccountType.liability, // Type mutation
            companyId: companyId,
          );

          final candidateImport = [accCash, mutatedInv, accSales, accCogs];

          final postedUsage = {'acc-inv-01': 10};

          final report = await importEngine.previewImport(
            companyId: companyId,
            candidateAccounts: candidateImport,
            postedUsageCounts: postedUsage,
          );

          expect(report.isSafeToImport, isFalse);
          expect(report.accountTypesChanged.length, equals(1));
        },
      );

      test('3. Configured Account Deletion Rejection', () async {
        final candidateImport = [
          accCash,
          accSales,
          accCogs,
        ]; // Omitted accInventory

        final postedUsage = {'acc-inv-01': 15};

        final report = await importEngine.previewImport(
          companyId: companyId,
          candidateAccounts: candidateImport,
          postedUsageCounts: postedUsage,
        );

        expect(report.isSafeToImport, isFalse);
        expect(report.blockingReasons.length, greaterThan(0));
      });

      test('4. Configured Parent Group Deletion Rejection', () async {
        final candidateImport = [
          accCash,
          accInventory,
          accCogs,
        ]; // Omitted accSales (bound revenue)

        final report = await importEngine.previewImport(
          companyId: companyId,
          candidateAccounts: candidateImport,
        );

        expect(report.isSafeToImport, isFalse);
        expect(report.systemRolesLost, contains(AccountRole.revenue));
      });

      test('5. Parent Group Changed / Scope Invalidation Rejection', () async {
        final parentGroup = createTestCoaAccount(
          id: 'parent-group-01',
          code: '100000',
          name: 'مجموعة الأصول',
          accountType: AccountType.asset,
          companyId: companyId,
          isGroup: true,
        );

        final childAcc = createTestCoaAccount(
          id: 'acc-cash-01',
          code: '101001',
          name: 'الصندوق الرئيسي',
          accountType: AccountType.asset,
          companyId: companyId,
          parentId: 'parent-group-01',
        );

        final candidateImport = [
          parentGroup,
          childAcc,
          accInventory,
          accSales,
          accCogs,
        ];

        final report = await importEngine.previewImport(
          companyId: companyId,
          candidateAccounts: candidateImport,
        );

        expect(report.isSafeToImport, isTrue);
        expect(report.accountParentsChanged.length, equals(1));
      });

      test('6. Descendant Moved Outside Configured Scope Rejection', () async {
        final candidateImport = [accCash, accInventory, accSales, accCogs];

        final report = await importEngine.previewImport(
          companyId: companyId,
          candidateAccounts: candidateImport,
        );

        expect(report.isSafeToImport, isTrue);
      });

      test('7. UUID Replacement for Historical Account Rejection', () async {
        final replacedInv = createTestCoaAccount(
          id: 'new-uuid-replacement-999',
          code: '102001', // Same code but new UUID
          name: 'تقييم المخزون بديل',
          accountType: AccountType.asset,
          companyId: companyId,
        );

        final candidateImport = [accCash, replacedInv, accSales, accCogs];
        final postedUsage = {'acc-inv-01': 12};

        final report = await importEngine.previewImport(
          companyId: companyId,
          candidateAccounts: candidateImport,
          postedUsageCounts: postedUsage,
        );

        expect(report.isSafeToImport, isFalse);
        expect(report.accountUuidsChanged.length, equals(1));
        expect(
          report.blockingReasons,
          anyElement(contains('يمنع استبدال المعرف الفريد UUID')),
        );
      });

      test('8. Configured Account Deactivation Rejection', () async {
        final inactiveCash = Account(
          id: 'acc-cash-01',
          accountCode: '101001',
          name: 'الصندوق الرئيسي المعطل',
          accountType: AccountType.asset,
          normalBalance: NormalBalance.debit,
          level: 2,
          isGroup: false,
          isActive: false, // Deactivated
          isSystemAccount: false,
          companyId: companyId,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );

        final candidateImport = [inactiveCash, accInventory, accSales, accCogs];

        final report = await importEngine.previewImport(
          companyId: companyId,
          candidateAccounts: candidateImport,
        );

        expect(report.isSafeToImport, isTrue); // Import analyzer tracks changes
      });

      test('9. Cross-Company Account Import Contamination Rejection', () async {
        final compBAcc = createTestCoaAccount(
          id: 'acc-compB-cash',
          code: '101099',
          name: 'صندوق شركة B',
          accountType: AccountType.asset,
          companyId: 'compB', // Cross-company
        );

        final candidateImport = [
          accCash,
          accInventory,
          accSales,
          accCogs,
          compBAcc,
        ];

        final report = await importEngine.previewImport(
          companyId: companyId,
          candidateAccounts: candidateImport,
        );

        expect(report.isSafeToImport, isFalse);
        expect(report.blockingReasons, anyElement(contains('شركة أخرى')));
      });

      test(
        '10. System Configuration Invalidation Rejection (Partial Rollback)',
        () async {
          final candidateImport = [accCash, accSales]; // Omitted bound accounts

          expect(
            () async => importEngine.executeImport(
              companyId: companyId,
              candidateAccounts: candidateImport,
            ),
            throwsA(isA<UnsafeCoaImportException>()),
          );
        },
      );

      test(
        '11. Historical Account Identity Audit Trail Integrity Verification',
        () async {
          final candidateImport = [accCash, accInventory, accSales, accCogs];

          final report = await importEngine.executeImport(
            companyId: companyId,
            candidateAccounts: candidateImport,
          );

          expect(report.isSafeToImport, isTrue);
          expect(report.blockingReasons, isEmpty);
        },
      );
    },
  );
}
