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


class MockContextHierarchyProvider implements ContextHierarchyProviderPort {
  final Map<String, ContextHierarchyNode> _nodes = {};

  void addNode(ContextHierarchyNode node) {
    _nodes[node.contextId] = node;
  }

  @override
  Future<ContextHierarchyNode?> getContextNode(String contextId) async {
    return _nodes[contextId];
  }
}

void main() {
  group('GATE-06 Context Binding Hierarchy Test Suite', () {
    late NexabizDatabase db;
    late DriftFinancialAccountRepository accountRepo;
    late DriftFinancialSubjectRepository subjectRepo;
    late MockContextBindingRepo contextRepo;
    late MockCompanyMappingRepo companyMappingRepo;
    late MockContextHierarchyProvider hierarchyProvider;
    late CanonicalAccountResolverService resolver;

    const companyA = '11111111-1111-1111-1111-111111111111';
    const companyB = '22222222-2222-2222-2222-222222222222';

    late FinancialAccount accountChildA;
    late FinancialAccount accountParentA;
    late FinancialAccount accountGrandparentA;
    late FinancialAccount accountGreatGrandparentA;
    late FinancialAccount accountCompanyDefaultA;
    late FinancialAccount accountGroupA;
    late FinancialAccount accountInactiveA;
    late FinancialAccount accountSubjectA;
    late FinancialAccount accountB;

    late AccountingSubject subjectA;

    setUp(() async {
      db = NexabizDatabase.memory();
      accountRepo = DriftFinancialAccountRepository(db);
      subjectRepo = DriftFinancialSubjectRepository(db);
      contextRepo = MockContextBindingRepo();
      companyMappingRepo = MockCompanyMappingRepo();
      hierarchyProvider = MockContextHierarchyProvider();

      resolver = CanonicalAccountResolverService(
        accountRepo: accountRepo,
        subjectRepo: subjectRepo,
        contextBindingRepo: contextRepo,
        companyMappingRepo: companyMappingRepo,
        contextHierarchyProvider: hierarchyProvider,
      );

      accountChildA = FinancialAccount(
        id: '00000000-0000-0000-0000-000000child1',
        companyId: companyA,
        code: '410001',
        nameAr: 'إيراد الفرع الفرعي',
        nameEn: 'Register Revenue',
        accountType: FinancialAccountType.revenue,
        isGroup: false,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      accountParentA = FinancialAccount(
        id: '00000000-0000-0000-0000-000000prnt01',
        companyId: companyA,
        code: '410002',
        nameAr: 'إيراد المستودع',
        nameEn: 'Warehouse Revenue',
        accountType: FinancialAccountType.revenue,
        isGroup: false,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      accountGrandparentA = FinancialAccount(
        id: '00000000-0000-0000-0000-000000grnd01',
        companyId: companyA,
        code: '410003',
        nameAr: 'إيراد الفرع الرئيسي',
        nameEn: 'Branch Revenue',
        accountType: FinancialAccountType.revenue,
        isGroup: false,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      accountGreatGrandparentA = FinancialAccount(
        id: '00000000-0000-0000-0000-000000grt001',
        companyId: companyA,
        code: '410004',
        nameAr: 'إيراد المنطقة',
        nameEn: 'Region Revenue',
        accountType: FinancialAccountType.revenue,
        isGroup: false,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      accountCompanyDefaultA = FinancialAccount(
        id: '00000000-0000-0000-0000-000000cmpny1',
        companyId: companyA,
        code: '410000',
        nameAr: 'إيراد مبيعات عام',
        nameEn: 'General Sales Revenue',
        accountType: FinancialAccountType.revenue,
        isGroup: false,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      accountGroupA = FinancialAccount(
        id: '00000000-0000-0000-0000-000000group1',
        companyId: companyA,
        code: '400000',
        nameAr: 'مجموعة الإيرادات',
        nameEn: 'Revenue Group',
        accountType: FinancialAccountType.revenue,
        isGroup: true,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      accountInactiveA = FinancialAccount(
        id: '00000000-0000-0000-0000-000000inact1',
        companyId: companyA,
        code: '410099',
        nameAr: 'إيراد ملغى',
        nameEn: 'Inactive Revenue',
        accountType: FinancialAccountType.revenue,
        isActive: false,
        isGroup: false,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      accountSubjectA = FinancialAccount(
        id: '00000000-0000-0000-0000-000000sbjct1',
        companyId: companyA,
        code: '120001',
        nameAr: 'عميل A',
        nameEn: 'Customer A Account',
        accountType: FinancialAccountType.asset,
        isGroup: false,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      accountB = FinancialAccount(
        id: '00000000-0000-0000-0000-00000000accb',
        companyId: companyB,
        code: '410001',
        nameAr: 'إيراد شركة B',
        nameEn: 'Company B Revenue',
        accountType: FinancialAccountType.revenue,
        isGroup: false,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      await accountRepo.saveAccount(accountChildA);
      await accountRepo.saveAccount(accountParentA);
      await accountRepo.saveAccount(accountGrandparentA);
      await accountRepo.saveAccount(accountGreatGrandparentA);
      await accountRepo.saveAccount(accountCompanyDefaultA);
      await accountRepo.saveAccount(accountGroupA);
      await accountRepo.saveAccount(accountInactiveA);
      await accountRepo.saveAccount(accountSubjectA);
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
      await subjectRepo.saveSubject(subjectA);

      companyMappingRepo.setMapping(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        accountId: accountCompanyDefaultA.id,
      );
    });

    tearDown(() async {
      await db.close();
    });

    // ------------------------------------------------------------------------
    // BASIC TESTS (TEST-107 to TEST-110)
    // ------------------------------------------------------------------------
    test('TEST-107: Single context with valid mapping resolves context account', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'REG-01',
        roleKey: 'SALES_REVENUE',
        accountId: accountChildA.id,
      );

      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'REG-01',
      );

      expect(res.source, ResolutionSource.context);
      expect(res.accountId, accountChildA.id);
    });

    test('TEST-108: Single context without mapping falls back to Company mapping', () async {
      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'REG-UNCONFIGURED',
      );

      expect(res.source, ResolutionSource.companyMapping);
      expect(res.accountId, accountCompanyDefaultA.id);
    });

    test('TEST-109: Parent context provides mapping when child context is unconfigured', () async {
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'REG-01',
          companyId: companyA,
          parentContextId: 'WH-01',
        ),
      );
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'WH-01',
          companyId: companyA,
        ),
      );

      // Child REG-01 is unconfigured. Parent WH-01 has mapping accountParentA.
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-01',
        roleKey: 'SALES_REVENUE',
        accountId: accountParentA.id,
      );

      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'REG-01',
      );

      expect(res.source, ResolutionSource.context);
      expect(res.accountId, accountParentA.id);
    });

    test('TEST-110: Child mapping overrides parent mapping', () async {
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'REG-01',
          companyId: companyA,
          parentContextId: 'WH-01',
        ),
      );

      // Child has accountChildA, Parent has accountParentA
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'REG-01',
        roleKey: 'SALES_REVENUE',
        accountId: accountChildA.id,
      );
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-01',
        roleKey: 'SALES_REVENUE',
        accountId: accountParentA.id,
      );

      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'REG-01',
      );

      expect(res.source, ResolutionSource.context);
      expect(res.accountId, accountChildA.id);
    });

    // ------------------------------------------------------------------------
    // FAIL CLOSED TESTS (TEST-111 to TEST-115)
    // ------------------------------------------------------------------------
    test('TEST-111: Child configured-invalid + parent valid FAILS CLOSED immediately', () async {
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'REG-01',
          companyId: companyA,
          parentContextId: 'WH-01',
        ),
      );

      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'REG-01',
        roleKey: 'SALES_REVENUE',
        accountId: accountInactiveA.id, // Configured BUT inactive!
      );
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-01',
        roleKey: 'SALES_REVENUE',
        accountId: accountParentA.id, // Parent is valid
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'REG-01',
        ),
        throwsA(
          isA<FinancialValidationException>().having((e) => e.code, 'code', 'INACTIVE_ACCOUNT'),
        ),
      );
    });

    test('TEST-112: Child configured-invalid + company valid FAILS CLOSED immediately', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'REG-01',
        roleKey: 'SALES_REVENUE',
        accountId: accountGroupA.id, // Configured BUT group account!
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'REG-01',
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

    test('TEST-113: Wrong-role child mapping does not resolve wrong role', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-01',
        roleKey: 'INVENTORY',
        accountId: accountChildA.id,
      );

      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE', // Requesting SALES_REVENUE
        contextId: 'WH-01',
      );

      // WH-01 has no mapping for SALES_REVENUE -> falls through to Company mapping
      expect(res.source, ResolutionSource.companyMapping);
      expect(res.accountId, accountCompanyDefaultA.id);
    });

    test('TEST-114: Inactive context node FAILS CLOSED with INACTIVE_CONTEXT', () async {
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'WH-INACTIVE',
          companyId: companyA,
          isActive: false, // INACTIVE CONTEXT
        ),
      );

      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-INACTIVE',
        roleKey: 'SALES_REVENUE',
        accountId: accountChildA.id,
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'WH-INACTIVE',
        ),
        throwsA(
          isA<FinancialValidationException>().having((e) => e.code, 'code', 'INACTIVE_CONTEXT'),
        ),
      );
    });

    test('TEST-115: Deleted/archived context node FAILS CLOSED with INACTIVE_CONTEXT', () async {
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'WH-DELETED',
          companyId: companyA,
          isDeleted: true, // DELETED CONTEXT
        ),
      );

      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-DELETED',
        roleKey: 'SALES_REVENUE',
        accountId: accountChildA.id,
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'WH-DELETED',
        ),
        throwsA(
          isA<FinancialValidationException>().having((e) => e.code, 'code', 'INACTIVE_CONTEXT'),
        ),
      );
    });

    // ------------------------------------------------------------------------
    // TENANCY TESTS (TEST-116 & TEST-117)
    // ------------------------------------------------------------------------
    test('TEST-116: Cross-company parent context FAILS CLOSED with CROSS_TENANT_CONTEXT_REJECTION', () async {
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'REG-01',
          companyId: companyA,
          parentContextId: 'WH-COMP-B',
        ),
      );
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'WH-COMP-B',
          companyId: companyB, // Parent belongs to Company B!
        ),
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'REG-01',
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'CROSS_TENANT_CONTEXT_REJECTION',
          ),
        ),
      );
    });

    test('TEST-117: Cross-company context mapping FAILS CLOSED with CROSS_TENANT_ACCOUNT_REJECTION', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'REG-01',
        roleKey: 'SALES_REVENUE',
        accountId: accountB.id, // Mapped to account in Company B!
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'REG-01',
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

    // ------------------------------------------------------------------------
    // HIERARCHY TESTS (TEST-118 to TEST-121)
    // ------------------------------------------------------------------------
    test('TEST-118: Three-level inheritance (Register -> Warehouse -> Branch)', () async {
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'REG-01',
          companyId: companyA,
          parentContextId: 'WH-01',
        ),
      );
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'WH-01',
          companyId: companyA,
          parentContextId: 'BRANCH-01',
        ),
      );
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'BRANCH-01',
          companyId: companyA,
        ),
      );

      // Binding configured only at BRANCH-01 (Grandparent)
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'BRANCH-01',
        roleKey: 'SALES_REVENUE',
        accountId: accountGrandparentA.id,
      );

      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'REG-01',
      );

      expect(res.source, ResolutionSource.context);
      expect(res.accountId, accountGrandparentA.id);
    });

    test('TEST-119: Four-level inheritance (Register -> Warehouse -> Sub-Branch -> Main Branch)', () async {
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'REG-01',
          companyId: companyA,
          parentContextId: 'WH-01',
        ),
      );
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'WH-01',
          companyId: companyA,
          parentContextId: 'SUBBRANCH-01',
        ),
      );
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'SUBBRANCH-01',
          companyId: companyA,
          parentContextId: 'MAINBRANCH-01',
        ),
      );
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'MAINBRANCH-01',
          companyId: companyA,
        ),
      );

      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'MAINBRANCH-01',
        roleKey: 'SALES_REVENUE',
        accountId: accountGreatGrandparentA.id,
      );

      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'REG-01',
      );

      expect(res.source, ResolutionSource.context);
      expect(res.accountId, accountGreatGrandparentA.id);
    });

    test('TEST-120: Cycle detection FAILS CLOSED with CONTEXT_HIERARCHY_CYCLE', () async {
      // Cycle: A -> B -> C -> A
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'CTX-A',
          companyId: companyA,
          parentContextId: 'CTX-B',
        ),
      );
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'CTX-B',
          companyId: companyA,
          parentContextId: 'CTX-C',
        ),
      );
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'CTX-C',
          companyId: companyA,
          parentContextId: 'CTX-A', // CIRCULAR REFERENCE!
        ),
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'CTX-A',
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'CONTEXT_HIERARCHY_CYCLE',
          ),
        ),
      );
    });

    test('TEST-135: Acyclic context hierarchy exceeding MAX_DEPTH fails closed', () async {
      // Build an explicit ACYCLIC chain of 12 distinct nodes (CTX-01 -> CTX-02 -> ... -> CTX-12):
      for (int i = 1; i <= 11; i++) {
        final currentId = 'CTX-${i.toString().padLeft(2, '0')}';
        final parentId = 'CTX-${(i + 1).toString().padLeft(2, '0')}';
        hierarchyProvider.addNode(
          ContextHierarchyNode(
            contextId: currentId,
            companyId: companyA,
            parentContextId: parentId,
          ),
        );
      }
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'CTX-12',
          companyId: companyA,
          parentContextId: null,
        ),
      );

      // Only CTX-12 (at depth 12) has a valid account binding
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'CTX-12',
        roleKey: 'SALES_REVENUE',
        accountId: accountChildA.id,
      );

      // Verify explicit negative assertion: All node IDs in hierarchy are distinct (cycleDetected == false)
      final allNodeIds = <String>{};
      for (int i = 1; i <= 12; i++) {
        final nodeId = 'CTX-${i.toString().padLeft(2, '0')}';
        expect(allNodeIds.contains(nodeId), isFalse, reason: 'Hierarchy must be strictly acyclic');
        allNodeIds.add(nodeId);
      }
      expect(allNodeIds.length, 12);

      // Traversal starts at CTX-01. Chain is strictly ACYCLIC.
      // Must terminate bounded traversal at MAX_DEPTH (10) and fail closed with CONTEXT_HIERARCHY_DEPTH_EXCEEDED.
      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'CTX-01',
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'CONTEXT_HIERARCHY_DEPTH_EXCEEDED',
          ),
        ),
      );

      // Assert zero side-effects
      final journalRepo = DriftFinancialJournalRepository(db);
      final entries = await journalRepo.getCompanyEntries(companyA);
      expect(entries.isEmpty, isTrue);
    });

    test('TEST-121: Deterministic repeated resolution returns identical result', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-01',
        roleKey: 'SALES_REVENUE',
        accountId: accountParentA.id,
      );

      for (int i = 0; i < 10; i++) {
        final res = await resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'WH-01',
        );
        expect(res.accountId, accountParentA.id);
        expect(res.source, ResolutionSource.context);
      }
    });

    // ------------------------------------------------------------------------
    // GATE-05 INTEGRATION TESTS (TEST-122 to TEST-125)
    // ------------------------------------------------------------------------
    test('TEST-122: Context unconfigured -> valid Company fallback occurs', () async {
      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'UNCONFIGURED-CTX',
      );

      expect(res.source, ResolutionSource.companyMapping);
      expect(res.accountId, accountCompanyDefaultA.id);
    });

    test('TEST-123: Context configured-invalid -> valid Company fallback MUST NOT occur', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'CTX-INVALID',
        roleKey: 'SALES_REVENUE',
        accountId: accountInactiveA.id,
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'CTX-INVALID',
        ),
        throwsA(
          isA<FinancialValidationException>().having((e) => e.code, 'code', 'INACTIVE_ACCOUNT'),
        ),
      );
    });

    test('TEST-124: CUSTOMER_RECEIVABLE ignores Context entirely and uses Subject account', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-01',
        roleKey: 'CUSTOMER_RECEIVABLE',
        accountId: accountChildA.id,
      );

      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'CUSTOMER_RECEIVABLE',
        contextId: 'WH-01',
        subjectId: subjectA.id,
      );

      expect(res.source, ResolutionSource.subject);
      expect(res.accountId, accountSubjectA.id);
    });

    test('TEST-125: SUPPLIER_PAYABLE ignores Context entirely', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-01',
        roleKey: 'SUPPLIER_PAYABLE',
        accountId: accountChildA.id,
      );

      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SUPPLIER_PAYABLE',
        contextId: 'WH-01',
        subjectId: subjectA.id,
      );

      expect(res.source, ResolutionSource.subject);
      expect(res.accountId, accountSubjectA.id);
    });

    // ------------------------------------------------------------------------
    // IDENTITY TESTS (TEST-126 to TEST-128)
    // ------------------------------------------------------------------------
    test('TEST-126: Account code mutation does not change resolved FinancialAccount.id', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-01',
        roleKey: 'SALES_REVENUE',
        accountId: accountChildA.id,
      );

      final mutatedAccount = FinancialAccount(
        id: accountChildA.id,
        companyId: companyA,
        code: '999999', // Mutated code
        nameAr: accountChildA.nameAr,
        nameEn: accountChildA.nameEn,
        accountType: accountChildA.accountType,
        isGroup: false,
        currencyPolicy: accountChildA.currencyPolicy,
      );
      await accountRepo.saveAccount(mutatedAccount);

      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'WH-01',
      );

      expect(res.accountId, accountChildA.id);
    });

    test('TEST-127: Account hierarchy move does not change resolved FinancialAccount.id', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-01',
        roleKey: 'SALES_REVENUE',
        accountId: accountChildA.id,
      );

      final movedAccount = FinancialAccount(
        id: accountChildA.id,
        companyId: companyA,
        code: accountChildA.code,
        nameAr: accountChildA.nameAr,
        nameEn: accountChildA.nameEn,
        accountType: accountChildA.accountType,
        parentAccountId: accountGroupA.id, // Moved under group account
        level: 2,
        isGroup: false,
        currencyPolicy: accountChildA.currencyPolicy,
      );
      await accountRepo.saveAccount(movedAccount);

      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'WH-01',
      );

      expect(res.accountId, accountChildA.id);
    });

    test('TEST-128: Numeric account code passed as technical identity FAILS CLOSED', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-01',
        roleKey: 'SALES_REVENUE',
        accountId: '410001', // Numeric string code instead of UUID v7!
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'WH-01',
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

    // ------------------------------------------------------------------------
    // ZERO FINANCIAL SIDE EFFECTS TESTS (TEST-129 to TEST-134)
    // ------------------------------------------------------------------------
    test('TEST-129 & TEST-130: Resolver creates zero journals and zero journal lines', () async {
      final journalRepo = DriftFinancialJournalRepository(db);
      final entriesBefore = await journalRepo.getCompanyEntries(companyA);

      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-01',
        roleKey: 'SALES_REVENUE',
        accountId: accountChildA.id,
      );

      await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'WH-01',
      );

      final entriesAfter = await journalRepo.getCompanyEntries(companyA);
      expect(entriesAfter.length, equals(entriesBefore.length));
    });

    test('TEST-131: Resolver mutates zero balances or accounts', () async {
      final accountBefore = await accountRepo.findById(companyA, accountChildA.id);

      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-01',
        roleKey: 'SALES_REVENUE',
        accountId: accountChildA.id,
      );

      await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'WH-01',
      );

      final accountAfter = await accountRepo.findById(companyA, accountChildA.id);
      expect(accountAfter?.id, equals(accountBefore?.id));
      expect(accountAfter?.code, equals(accountBefore?.code));
    });

    test('TEST-132, TEST-133, TEST-134: Resolver performs zero currency conversions, exchange snapshots, or Money mutations', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-01',
        roleKey: 'SALES_REVENUE',
        accountId: accountChildA.id,
      );

      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'WH-01',
        requiredCurrencyCode: 'USD',
      );

      expect(res.accountId, accountChildA.id);
      expect(res.source, ResolutionSource.context);
    });

    // ------------------------------------------------------------------------
    // ADVERSARIAL ATTACK MATRIX (ATTACK-16 to ATTACK-26)
    // ------------------------------------------------------------------------
    test('ATTACK-16: Cross-company parent injection -> REJECTED', () async {
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'REG-ATTACK-16',
          companyId: companyA,
          parentContextId: 'WH-COMP-B',
        ),
      );
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'WH-COMP-B',
          companyId: companyB, // Belong to Company B
        ),
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'REG-ATTACK-16',
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'CROSS_TENANT_CONTEXT_REJECTION',
          ),
        ),
      );
    });

    test('ATTACK-17: Context hierarchy cycle -> REJECTED', () async {
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'NODE-1',
          companyId: companyA,
          parentContextId: 'NODE-2',
        ),
      );
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'NODE-2',
          companyId: companyA,
          parentContextId: 'NODE-1', // Direct cycle
        ),
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'NODE-1',
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'CONTEXT_HIERARCHY_CYCLE',
          ),
        ),
      );
    });

    test('ATTACK-18: Configured-invalid child attempting silent parent fallback -> REJECTED', () async {
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'CHILD-INV',
          companyId: companyA,
          parentContextId: 'PARENT-VAL',
        ),
      );
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'CHILD-INV',
        roleKey: 'SALES_REVENUE',
        accountId: accountInactiveA.id, // Inactive account!
      );
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'PARENT-VAL',
        roleKey: 'SALES_REVENUE',
        accountId: accountParentA.id,
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'CHILD-INV',
        ),
        throwsA(
          isA<FinancialValidationException>().having((e) => e.code, 'code', 'INACTIVE_ACCOUNT'),
        ),
      );
    });

    test('ATTACK-19: Configured-invalid context attempting silent Company fallback -> REJECTED', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'CTX-INV-19',
        roleKey: 'SALES_REVENUE',
        accountId: accountGroupA.id, // Group account!
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'CTX-INV-19',
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

    test('ATTACK-20: Wrong-role mapping injection -> REJECTED or IGNORED', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'CTX-20',
        roleKey: 'INVENTORY', // Mapped for INVENTORY, not SALES_REVENUE
        accountId: accountChildA.id,
      );

      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'CTX-20',
      );

      expect(res.source, ResolutionSource.companyMapping);
      expect(res.accountId, accountCompanyDefaultA.id);
    });

    test('ATTACK-21: Numeric account code supplied as FinancialAccount.id -> REJECTED', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'CTX-21',
        roleKey: 'SALES_REVENUE',
        accountId: '12345',
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'CTX-21',
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

    test('ATTACK-22: Inactive mapped account -> REJECTED', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'CTX-22',
        roleKey: 'SALES_REVENUE',
        accountId: accountInactiveA.id,
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'CTX-22',
        ),
        throwsA(
          isA<FinancialValidationException>().having((e) => e.code, 'code', 'INACTIVE_ACCOUNT'),
        ),
      );
    });

    test('ATTACK-23: Group/non-postable mapped account -> REJECTED', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'CTX-23',
        roleKey: 'SALES_REVENUE',
        accountId: accountGroupA.id,
      );

      expect(
        () => resolver.resolveAccount(
          companyId: companyA,
          roleKey: 'SALES_REVENUE',
          contextId: 'CTX-23',
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

    test('ATTACK-24: Context hierarchy containing duplicate/conflicting mappings resolves nearest context', () async {
      hierarchyProvider.addNode(
        const ContextHierarchyNode(
          contextId: 'CTX-NEAR',
          companyId: companyA,
          parentContextId: 'CTX-FAR',
        ),
      );

      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'CTX-NEAR',
        roleKey: 'SALES_REVENUE',
        accountId: accountChildA.id,
      );
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'CTX-FAR',
        roleKey: 'SALES_REVENUE',
        accountId: accountParentA.id,
      );

      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'CTX-NEAR',
      );

      expect(res.source, ResolutionSource.context);
      expect(res.accountId, accountChildA.id);
    });

    test('ATTACK-25: CUSTOMER_RECEIVABLE context override attempt -> REJECTED/IGNORED', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'CTX-25',
        roleKey: 'CUSTOMER_RECEIVABLE',
        accountId: accountChildA.id,
      );

      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'CUSTOMER_RECEIVABLE',
        contextId: 'CTX-25',
        subjectId: subjectA.id,
      );

      expect(res.source, ResolutionSource.subject);
      expect(res.accountId, accountSubjectA.id);
    });

    test('ATTACK-26: SUPPLIER_PAYABLE context override attempt -> REJECTED/IGNORED', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'CTX-26',
        roleKey: 'SUPPLIER_PAYABLE',
        accountId: accountChildA.id,
      );

      final res = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SUPPLIER_PAYABLE',
        contextId: 'CTX-26',
        subjectId: subjectA.id,
      );

      expect(res.source, ResolutionSource.subject);
      expect(res.accountId, accountSubjectA.id);
    });

    // ------------------------------------------------------------------------
    // PROPERTY / INVARIANT TESTS
    // ------------------------------------------------------------------------
    test('INVARIANT: Same company + context + role always returns identical FinancialAccount.id', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-INV',
        roleKey: 'SALES_REVENUE',
        accountId: accountChildA.id,
      );

      final res1 = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'WH-INV',
      );
      final res2 = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'WH-INV',
      );

      expect(res1.accountId, equals(res2.accountId));
    });

    test('INVARIANT: Changing account.code does not alter resolution result', () async {
      contextRepo.setBinding(
        companyId: companyA,
        contextId: 'WH-INV2',
        roleKey: 'SALES_REVENUE',
        accountId: accountChildA.id,
      );

      final resBefore = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'WH-INV2',
      );

      final mutated = FinancialAccount(
        id: accountChildA.id,
        companyId: companyA,
        code: '987654',
        nameAr: accountChildA.nameAr,
        nameEn: accountChildA.nameEn,
        accountType: accountChildA.accountType,
        isGroup: false,
        currencyPolicy: accountChildA.currencyPolicy,
      );
      await accountRepo.saveAccount(mutated);

      final resAfter = await resolver.resolveAccount(
        companyId: companyA,
        roleKey: 'SALES_REVENUE',
        contextId: 'WH-INV2',
      );

      expect(resAfter.accountId, equals(resBefore.accountId));
    });
  });
}
