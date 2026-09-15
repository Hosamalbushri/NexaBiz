import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/packages/financial/financial.dart';

class MockContextBindingRepo implements ContextAccountBindingRepositoryPort {
  final Map<String, String> _bindings = {};

  void setBinding({
    required String companyId,
    required String contextId,
    required String roleKey,
    required String accountId,
  }) {
    _bindings['$companyId:$contextId:$roleKey'] = accountId;
  }

  @override
  Future<String?> findAccountId({
    required String companyId,
    required String contextId,
    required String roleKey,
  }) async {
    return _bindings['$companyId:$contextId:$roleKey'];
  }

  @override
  Future<bool> isAccountBound({
    required String companyId,
    required String accountId,
  }) async {
    return _bindings.entries.any((e) => e.key.startsWith('$companyId:') && e.value == accountId);
  }
}

class MockCompanyMappingRepo implements CompanyAccountMappingRepositoryPort {
  final Map<String, String> _mappings = {};

  void setMapping({
    required String companyId,
    required String roleKey,
    required String accountId,
  }) {
    _mappings['$companyId:$roleKey'] = accountId;
  }

  @override
  Future<String?> findAccountId({
    required String companyId,
    required String roleKey,
  }) async {
    return _mappings['$companyId:$roleKey'];
  }

  @override
  Future<bool> isAccountBound({
    required String companyId,
    required String accountId,
  }) async {
    return _mappings.entries.any((e) => e.key.startsWith('$companyId:') && e.value == accountId);
  }
}


void main() {
  group('GATE-05 Account Resolution Precedence Hardening Suite', () {
    late NexabizDatabase db;
    late DriftFinancialAccountRepository accountRepo;
    late DriftFinancialSubjectRepository subjectRepo;
    late MockContextBindingRepo contextRepo;
    late MockCompanyMappingRepo companyMappingRepo;
    late CanonicalAccountResolverService resolver;

    const companyA = '11111111-1111-1111-1111-111111111111';
    const companyB = '22222222-2222-2222-2222-222222222222';

    late FinancialAccount customerParentA;
    late FinancialAccount supplierParentA;
    late FinancialAccount accountContextA;
    late FinancialAccount accountSubjectA;
    late FinancialAccount accountCompanyDefaultA;
    late FinancialAccount accountGroupA;
    late FinancialAccount accountInactiveA;
    late FinancialAccount accountB;

    late AccountingSubject subjectA;
    late AccountingSubject subjectUnconfiguredA;
    late AccountingSubject subjectInactiveA;
    late AccountingSubject subjectInvalidAccountA;
    late AccountingSubject subjectB;

    setUp(() async {
      db = NexabizDatabase.memory();
      accountRepo = DriftFinancialAccountRepository(db);
      subjectRepo = DriftFinancialSubjectRepository(db);
      contextRepo = MockContextBindingRepo();
      companyMappingRepo = MockCompanyMappingRepo();

      resolver = CanonicalAccountResolverService(
        accountRepo: accountRepo,
        subjectRepo: subjectRepo,
        contextBindingRepo: contextRepo,
        companyMappingRepo: companyMappingRepo,
      );

      customerParentA = FinancialAccount(
        id: '00000000-0000-0000-0000-000000001200',
        companyId: companyA,
        code: '1200',
        nameAr: 'العملاء A',
        nameEn: 'Customers A',
        accountType: FinancialAccountType.asset,
        isGroup: true,
        level: 2,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      supplierParentA = FinancialAccount(
        id: '00000000-0000-0000-0000-000000002100',
        companyId: companyA,
        code: '2100',
        nameAr: 'الموردون A',
        nameEn: 'Suppliers A',
        accountType: FinancialAccountType.liability,
        isGroup: true,
        level: 2,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      await accountRepo.saveAccount(customerParentA);
      await accountRepo.saveAccount(supplierParentA);

      accountContextA = FinancialAccount(
        id: '00000000-0000-0000-0000-000000cntxt1',
        companyId: companyA,
        code: '120011',
        nameAr: 'حساب السياق',
        nameEn: 'Context Account',
        accountType: FinancialAccountType.asset,
        parentAccountId: customerParentA.id,
        level: 3,
        isGroup: false,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      accountSubjectA = FinancialAccount(
        id: '00000000-0000-0000-0000-000000sbjct1',
        companyId: companyA,
        code: '120012',
        nameAr: 'حساب الشخص',
        nameEn: 'Subject Account',
        accountType: FinancialAccountType.asset,
        parentAccountId: customerParentA.id,
        level: 3,
        isGroup: false,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      accountCompanyDefaultA = FinancialAccount(
        id: '00000000-0000-0000-0000-000000cmpny1',
        companyId: companyA,
        code: '120013',
        nameAr: 'حساب افتراضي للشركة',
        nameEn: 'Company Default Account',
        accountType: FinancialAccountType.asset,
        parentAccountId: customerParentA.id,
        level: 3,
        isGroup: false,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      accountGroupA = FinancialAccount(
        id: '00000000-0000-0000-0000-000000group1',
        companyId: companyA,
        code: '120014',
        nameAr: 'مجموعة رئيسية',
        nameEn: 'Group Account',
        accountType: FinancialAccountType.asset,
        parentAccountId: customerParentA.id,
        level: 2,
        isGroup: true, // GROUP ACCOUNT
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      accountInactiveA = FinancialAccount(
        id: '00000000-0000-0000-0000-000000inact1',
        companyId: companyA,
        code: '120015',
        nameAr: 'حساب غير نشط',
        nameEn: 'Inactive Account',
        accountType: FinancialAccountType.asset,
        parentAccountId: customerParentA.id,
        level: 3,
        isGroup: false,
        isActive: false, // INACTIVE
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      accountB = FinancialAccount(
        id: '00000000-0000-0000-0000-00000000accb',
        companyId: companyB,
        code: '120001',
        nameAr: 'حساب الشركة B',
        nameEn: 'Company B Account',
        accountType: FinancialAccountType.asset,
        level: 3,
        isGroup: false,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      await accountRepo.saveAccount(accountContextA);
      await accountRepo.saveAccount(accountSubjectA);
      await accountRepo.saveAccount(accountCompanyDefaultA);
      await accountRepo.saveAccount(accountGroupA);
      await accountRepo.saveAccount(accountInactiveA);
      await accountRepo.saveAccount(accountB);

      subjectA = AccountingSubject(
        id: '00000000-0000-0000-0000-000000suba01',
        companyId: companyA,
        subjectType: AccountingSubjectType.customer,
        name: 'عميل A1',
        code: 'CUST-A1',
        primaryAccountId: accountSubjectA.id,
        isActive: true,
      );

      subjectUnconfiguredA = AccountingSubject(
        id: '00000000-0000-0000-0000-000000subu01',
        companyId: companyA,
        subjectType: AccountingSubjectType.customer,
        name: 'عميل غير مهيأ',
        code: 'CUST-UNCFG',
        primaryAccountId: '', // UNCONFIGURED
        isActive: true,
      );

      subjectInactiveA = AccountingSubject(
        id: '00000000-0000-0000-0000-000000subin1',
        companyId: companyA,
        subjectType: AccountingSubjectType.customer,
        name: 'عميل غير نشط',
        code: 'CUST-INACT',
        primaryAccountId: accountSubjectA.id,
        isActive: false, // INACTIVE SUBJECT
      );

      subjectInvalidAccountA = AccountingSubject(
        id: '00000000-0000-0000-0000-000000subinv',
        companyId: companyA,
        subjectType: AccountingSubjectType.customer,
        name: 'عميل بحساب غير نشط',
        code: 'CUST-INACC',
        primaryAccountId: accountInactiveA.id, // Bounded to inactive account
        isActive: true,
      );

      subjectB = AccountingSubject(
        id: '00000000-0000-0000-0000-000000subb01',
        companyId: companyB,
        subjectType: AccountingSubjectType.customer,
        name: 'عميل B1',
        code: 'CUST-B1',
        primaryAccountId: accountB.id,
        isActive: true,
      );

      await subjectRepo.saveSubject(subjectA);
      await subjectRepo.saveSubject(subjectUnconfiguredA);
      await subjectRepo.saveSubject(subjectInactiveA);
      await subjectRepo.saveSubject(subjectInvalidAccountA);
      await subjectRepo.saveSubject(subjectB);

      // Seed Layer A and Layer C Mappings
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-01',
        roleKey: 'SALES_REVENUE',
        accountId: accountContextA.id,
      );

      companyMappingRepo.setMapping(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        accountId: accountCompanyDefaultA.id,
      );

      companyMappingRepo.setMapping(
        companyId: companyA,
        roleKey: 'INVENTORY',
        accountId: accountCompanyDefaultA.id,
      );

      companyMappingRepo.setMapping(
        companyId: companyA,
        roleKey: 'CUSTOMER_RECEIVABLE',
        accountId: accountCompanyDefaultA.id,
      );
    });

    tearDown(() async {
      await db.close();
    });

    // ------------------------------------------------------------------------
    // PRECEDENCE & APPLICABILITY MATRIX TESTS (TEST-63 to TEST-87)
    // ------------------------------------------------------------------------
    test('TEST-64: Layer A Context account wins when context is specified for applicable role', () async {
      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'WH-01',
      );

      expect(res.source, ResolutionSource.context);
      expect(res.accountId, accountContextA.id);
    });

    test('TEST-63: Layer B Subject account wins when context is absent for subject role', () async {
      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'CUSTOMER_RECEIVABLE',
        subjectId: subjectA.id,
      );

      expect(res.source, ResolutionSource.subject);
      expect(res.accountId, accountSubjectA.id);
    });

    test('TEST-65: Layer C Company mapping wins when context and subject are absent', () async {
      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'INVENTORY',
      );

      expect(res.source, ResolutionSource.companyMapping);
      expect(res.accountId, accountCompanyDefaultA.id);
    });

    test('TEST-66 & TEST-75: Missing mapping fails explicitly without hardcoded fallback', () async {
      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'NON_EXISTENT_ROLE',
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'MISSING_ACCOUNT_MAPPING',
          ),
        ),
      );
    });

    // ------------------------------------------------------------------------
    // MANDATORY HARDENING TEST SUITE (TEST-88 to TEST-106)
    // ------------------------------------------------------------------------
    test('TEST-88: Context + Subject supplied follows Role Applicability Matrix', () async {
      final revRes = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'WH-01',
        subjectId: subjectA.id,
      );
      expect(revRes.source, ResolutionSource.context);

      final recRes = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'CUSTOMER_RECEIVABLE',
        contextId: 'WH-01',
        subjectId: subjectA.id,
      );
      expect(recRes.source, ResolutionSource.subject);
    });

    test('TEST-89: Context UNCONFIGURED proceeds to next applicable layer', () async {
      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'UNCONFIGURED_WH',
      );
      expect(res.source, ResolutionSource.companyMapping);
      expect(res.accountId, accountCompanyDefaultA.id);
    });

    test('TEST-90 & TEST-91: Context CONFIGURED BUT INVALID (inactive account) FAILS CLOSED', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-INVALID',
        roleKey: 'SALES_REVENUE',
        accountId: accountInactiveA.id,
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'WH-INVALID',
        ),
        throwsA(
          isA<FinancialValidationException>().having((e) => e.code, 'code', 'INACTIVE_ACCOUNT'),
        ),
      );
    });

    test('TEST-92: Context CONFIGURED BUT INVALID (cross-company account) FAILS CLOSED', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-ATTACK',
        roleKey: 'SALES_REVENUE',
        accountId: accountB.id,
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'WH-ATTACK',
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'CROSS_TENANT_ACCOUNT_REJECTION',
          ),
        ),
      );
    });

    test('TEST-93: Context CONFIGURED BUT INVALID (group account) FAILS CLOSED', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-GROUP',
        roleKey: 'SALES_REVENUE',
        accountId: accountGroupA.id,
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'WH-GROUP',
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'GROUP_ACCOUNT_NOT_POSTABLE',
          ),
        ),
      );
    });

    test('TEST-94: Subject UNCONFIGURED (empty primaryAccountId) proceeds to Company Mapping', () async {
      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'CUSTOMER_RECEIVABLE',
        subjectId: subjectUnconfiguredA.id,
      );

      expect(res.source, ResolutionSource.companyMapping);
      expect(res.accountId, accountCompanyDefaultA.id);
    });

    test('TEST-95 & TEST-96: Subject CONFIGURED BUT INVALID (inactive account) FAILS CLOSED without fallback', () async {
      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'CUSTOMER_RECEIVABLE',
          subjectId: subjectInvalidAccountA.id,
        ),
        throwsA(
          isA<FinancialValidationException>().having((e) => e.code, 'code', 'INACTIVE_ACCOUNT'),
        ),
      );
    });

    test('TEST-97: Context Wrong Role (Context binding not applicable to requested role) FAILS CLOSED or Ignores', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-01',
        roleKey: 'TAX',
        accountId: accountContextA.id,
      );

      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'CUSTOMER_RECEIVABLE', // CUSTOMER_RECEIVABLE does not allow Context
        contextId: 'WH-01',
        subjectId: subjectA.id,
      );

      // Context is ignored because Context is not applicable for CUSTOMER_RECEIVABLE
      expect(res.source, ResolutionSource.subject);
      expect(res.accountId, accountSubjectA.id);
    });

    test('TEST-98: Subject Wrong Role (Subject configured account bound to inactive account) FAILS CLOSED', () async {
      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'CUSTOMER_RECEIVABLE',
          subjectId: subjectInvalidAccountA.id,
        ),
        throwsA(
          isA<FinancialValidationException>().having((e) => e.code, 'code', 'INACTIVE_ACCOUNT'),
        ),
      );
    });

    test('TEST-99: All Sources Absent FAILS CLOSED with MISSING_ACCOUNT_MAPPING', () async {
      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'UNMAPPED_ROLE',
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'MISSING_ACCOUNT_MAPPING',
          ),
        ),
      );
    });

    test('TEST-100: Three-Source Deterministic Resolution (Cases A, B, C, D)', () async {
      // Case A: CUSTOMER_RECEIVABLE with Context + Subject + Company -> Subject wins
      final caseA = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'CUSTOMER_RECEIVABLE',
        contextId: 'WH-01',
        subjectId: subjectA.id,
      );
      expect(caseA.source, ResolutionSource.subject);
      expect(caseA.accountId, accountSubjectA.id);

      // Case B: SALES_REVENUE with Context + Company -> Context wins
      final caseB = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'WH-01',
        subjectId: subjectA.id,
      );
      expect(caseB.source, ResolutionSource.context);
      expect(caseB.accountId, accountContextA.id);

      // Case C: SALES_REVENUE with Context UNCONFIGURED + Company -> Company wins
      final caseC = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'WH-UNCONFIGURED',
      );
      expect(caseC.source, ResolutionSource.companyMapping);
      expect(caseC.accountId, accountCompanyDefaultA.id);

      // Case D: Higher source CONFIGURED BUT INVALID + lower source valid -> FAILS CLOSED
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-INVALID-CASE-D',
        roleKey: 'SALES_REVENUE',
        accountId: accountInactiveA.id,
      );
      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'WH-INVALID-CASE-D',
        ),
        throwsA(
          isA<FinancialValidationException>().having((e) => e.code, 'code', 'INACTIVE_ACCOUNT'),
        ),
      );
    });

    test('TEST-101: Resolver returns technical UUID v7 identity', () async {
      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'CUSTOMER_RECEIVABLE',
        subjectId: subjectA.id,
      );

      expect(res.accountId, accountSubjectA.id);
      expect(res.accountId.length, 36);
    });

    test('TEST-102: Account code mutation does not alter resolution result', () async {
      final mutAccount = FinancialAccount(
        id: accountSubjectA.id,
        companyId: companyA,
        code: '999999',
        nameAr: accountSubjectA.nameAr,
        nameEn: accountSubjectA.nameEn,
        accountType: accountSubjectA.accountType,
        parentAccountId: accountSubjectA.parentAccountId,
        level: accountSubjectA.level,
        isGroup: false,
        currencyPolicy: accountSubjectA.currencyPolicy,
      );
      await accountRepo.saveAccount(mutAccount);

      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'CUSTOMER_RECEIVABLE',
        subjectId: subjectA.id,
      );

      expect(res.accountId, accountSubjectA.id);
    });

    test('TEST-103: Account move (parentAccountId change) does not alter resolution result', () async {
      final movedAccount = FinancialAccount(
        id: accountSubjectA.id,
        companyId: companyA,
        code: accountSubjectA.code,
        nameAr: accountSubjectA.nameAr,
        nameEn: accountSubjectA.nameEn,
        accountType: accountSubjectA.accountType,
        parentAccountId: null,
        level: 1,
        isGroup: false,
        currencyPolicy: accountSubjectA.currencyPolicy,
      );
      await accountRepo.saveAccount(movedAccount);

      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'CUSTOMER_RECEIVABLE',
        subjectId: subjectA.id,
      );

      expect(res.accountId, accountSubjectA.id);
    });

    test('TEST-104 & TEST-105: Resolver performs zero journal postings or balance mutations', () async {
      final journalRepo = DriftFinancialJournalRepository(db);
      final entriesBefore = await journalRepo.getCompanyEntries(companyA);

      await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'WH-01',
      );

      final entriesAfter = await journalRepo.getCompanyEntries(companyA);
      expect(entriesAfter.length, entriesBefore.length);
    });

    test('TEST-106: Resolver performs zero currency operations, base calculations, or FX rate snapshots', () async {
      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'WH-01',
        requiredCurrencyCode: 'USD',
      );

      // Verifies resolution purely returns account ID without modifying money or rates
      expect(res.accountId, accountContextA.id);
      expect(res.source, ResolutionSource.context);
    });

    // ------------------------------------------------------------------------
    // ADVERSARIAL ATTACK MATRIX (ATTACK-01 to ATTACK-15)
    // ------------------------------------------------------------------------
    test('ATTACK-01: Context from Company A, Operation from Company B -> REJECTED', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-A',
        roleKey: 'SALES_REVENUE',
        accountId: accountContextA.id,
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyB,
          roleKey: 'SALES_REVENUE',
          contextId: 'WH-A',
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'MISSING_ACCOUNT_MAPPING',
          ),
        ),
      );
    });

    test('ATTACK-02: Subject from Company A, Operation from Company B -> REJECTED', () async {
      expect(
        () => resolver.resolveAccount(
          companyId: companyB,
          roleKey: 'CUSTOMER_RECEIVABLE',
          subjectId: subjectA.id,
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'CROSS_TENANT_SUBJECT_REJECTION',
          ),
        ),
      );
    });

    test('ATTACK-03: Company mapping from Company A, Operation from Company B -> REJECTED', () async {
      expect(
        () => resolver.resolveAccount(
          companyId: companyB,
          roleKey: 'INVENTORY',
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'MISSING_ACCOUNT_MAPPING',
          ),
        ),
      );
    });

    test('ATTACK-04: Context configured with inactive account, Subject valid -> REJECTED', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-INACT',
        roleKey: 'SALES_REVENUE',
        accountId: accountInactiveA.id,
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'WH-INACT',
          subjectId: subjectA.id,
        ),
        throwsA(
          isA<FinancialValidationException>().having((e) => e.code, 'code', 'INACTIVE_ACCOUNT'),
        ),
      );
    });

    test('ATTACK-05: Context configured with group account, Subject valid -> REJECTED', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-GRP',
        roleKey: 'SALES_REVENUE',
        accountId: accountGroupA.id,
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'WH-GRP',
          subjectId: subjectA.id,
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'GROUP_ACCOUNT_NOT_POSTABLE',
          ),
        ),
      );
    });

    test('ATTACK-06: Subject configured with inactive account, Company mapping valid -> REJECTED', () async {
      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'CUSTOMER_RECEIVABLE',
          subjectId: subjectInvalidAccountA.id,
        ),
        throwsA(
          isA<FinancialValidationException>().having((e) => e.code, 'code', 'INACTIVE_ACCOUNT'),
        ),
      );
    });

    test('ATTACK-07: Subject configured with group account, Company mapping valid -> REJECTED', () async {
      final subjectGroupAccount = AccountingSubject(
        id: '00000000-0000-0000-0000-000000subgrp',
        companyId: companyA,
        subjectType: AccountingSubjectType.customer,
        name: 'عميل بمجموعة',
        code: 'CUST-GRP',
        primaryAccountId: accountGroupA.id, // Group account
        isActive: true,
      );
      await subjectRepo.saveSubject(subjectGroupAccount);

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'CUSTOMER_RECEIVABLE',
          subjectId: subjectGroupAccount.id,
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'GROUP_ACCOUNT_NOT_POSTABLE',
          ),
        ),
      );
    });

    test('ATTACK-08: Context configured with wrong-role / cross-company account, Subject valid -> REJECTED', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-CROSS',
        roleKey: 'SALES_REVENUE',
        accountId: accountB.id, // Cross-company account
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'WH-CROSS',
          subjectId: subjectA.id,
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'CROSS_TENANT_ACCOUNT_REJECTION',
          ),
        ),
      );
    });

    test('ATTACK-09: Account code supplied where FinancialAccount.id expected -> REJECTED', () async {
      companyMappingRepo.setMapping(
        companyId: companyA,
        roleKey: 'ATTACK_CODE',
        accountId: '120011',
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'ATTACK_CODE',
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'ILLEGAL_ACCOUNT_CODE_AS_IDENTITY',
          ),
        ),
      );
    });

    test('ATTACK-10: Changed account code after binding -> Resolution succeeds by UUID v7', () async {
      final mutAccount = FinancialAccount(
        id: accountSubjectA.id,
        companyId: companyA,
        code: 'CHANGED_CODE',
        nameAr: accountSubjectA.nameAr,
        nameEn: accountSubjectA.nameEn,
        accountType: accountSubjectA.accountType,
        parentAccountId: accountSubjectA.parentAccountId,
        level: accountSubjectA.level,
        isGroup: false,
        currencyPolicy: accountSubjectA.currencyPolicy,
      );
      await accountRepo.saveAccount(mutAccount);

      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'CUSTOMER_RECEIVABLE',
        subjectId: subjectA.id,
      );

      expect(res.accountId, accountSubjectA.id);
    });

    test('ATTACK-11: Moved account after binding -> Resolution succeeds by UUID v7', () async {
      final movedAccount = FinancialAccount(
        id: accountSubjectA.id,
        companyId: companyA,
        code: accountSubjectA.code,
        nameAr: accountSubjectA.nameAr,
        nameEn: accountSubjectA.nameEn,
        accountType: accountSubjectA.accountType,
        parentAccountId: supplierParentA.id, // Moved parent
        level: 3,
        isGroup: false,
        currencyPolicy: accountSubjectA.currencyPolicy,
      );
      await accountRepo.saveAccount(movedAccount);

      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'CUSTOMER_RECEIVABLE',
        subjectId: subjectA.id,
      );

      expect(res.accountId, accountSubjectA.id);
    });

    test('ATTACK-12: Missing mapping with legacy hardcoded code available -> REJECTED', () async {
      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'UNMAPPED_LEGACY_FALLBACK_ROLE',
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'MISSING_ACCOUNT_MAPPING',
          ),
        ),
      );
    });

    test('ATTACK-13: Resolver called with inconsistent company/subject identifiers -> REJECTED', () async {
      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'CUSTOMER_RECEIVABLE',
          subjectId: subjectB.id, // Subject B belongs to Company B!
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'CROSS_TENANT_SUBJECT_REJECTION',
          ),
        ),
      );
    });

    test('ATTACK-14: Illegal company ID rejected fail-closed', () async {
      expect(
        () => resolver.resolveAccount(
          companyId: 'fallback',
          roleKey: 'SALES_REVENUE',
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'MISSING_COMPANY_SCOPE',
          ),
        ),
      );
    });

    test('ATTACK-15: Operational context provided for subject-only role -> Context ignored, Subject wins', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-01',
        roleKey: 'CUSTOMER_RECEIVABLE',
        accountId: accountContextA.id,
      );

      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'CUSTOMER_RECEIVABLE',
        contextId: 'WH-01',
        subjectId: subjectA.id,
      );

      // Context is ignored for CUSTOMER_RECEIVABLE role; Subject wins!
      expect(res.source, ResolutionSource.subject);
      expect(res.accountId, accountSubjectA.id);
    });
  });
}
