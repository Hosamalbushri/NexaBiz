import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/packages/financial/financial.dart';

void main() {
  group('GATE-04 Subject Account Binding Semantics Test Suite', () {
    late NexabizDatabase db;
    late DriftFinancialAccountRepository accountRepo;
    late DriftFinancialSubjectRepository subjectRepo;
    late DriftFinancialJournalRepository journalRepo;
    late SubjectAccountBindingService bindingService;
    late CustomerAccountingProvisioningService customerProvisioning;
    late SupplierAccountingProvisioningService supplierProvisioning;

    const companyA = '11111111-1111-1111-1111-111111111111';
    const companyB = '22222222-2222-2222-2222-222222222222';

    late FinancialAccount customerParentA;
    late FinancialAccount supplierParentA;
    late FinancialAccount accountA1;
    late FinancialAccount accountA2;
    late FinancialAccount accountB1;

    late AccountingSubject subjectA1;
    late AccountingSubject subjectA2;
    late AccountingSubject subjectB1;

    setUp(() async {
      db = NexabizDatabase.memory();
      accountRepo = DriftFinancialAccountRepository(db);
      subjectRepo = DriftFinancialSubjectRepository(db);
      journalRepo = DriftFinancialJournalRepository(db);

      bindingService = SubjectAccountBindingService(
        accountRepo: accountRepo,
        subjectRepo: subjectRepo,
      );

      customerProvisioning = CustomerAccountingProvisioningService(
        accountRepo: accountRepo,
        subjectRepo: subjectRepo,
      );

      supplierProvisioning = SupplierAccountingProvisioningService(
        accountRepo: accountRepo,
        subjectRepo: subjectRepo,
      );

      // Parent Accounts
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

      // Company A Accounts
      accountA1 = FinancialAccount(
        id: '00000000-0000-0000-0000-0000000a1001',
        companyId: companyA,
        code: '120001',
        nameAr: 'عميل A1',
        nameEn: 'Customer A1 Account',
        accountType: FinancialAccountType.asset,
        parentAccountId: customerParentA.id,
        level: 3,
        isGroup: false,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      accountA2 = FinancialAccount(
        id: '00000000-0000-0000-0000-0000000a1002',
        companyId: companyA,
        code: '120002',
        nameAr: 'عميل A2',
        nameEn: 'Customer A2 Account',
        accountType: FinancialAccountType.asset,
        parentAccountId: customerParentA.id,
        level: 3,
        isGroup: false,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      // Company B Account
      accountB1 = FinancialAccount(
        id: '00000000-0000-0000-0000-0000000b1001',
        companyId: companyB,
        code: '120001',
        nameAr: 'عميل B1',
        nameEn: 'Customer B1 Account',
        accountType: FinancialAccountType.asset,
        level: 3,
        isGroup: false,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      await accountRepo.saveAccount(accountA1);
      await accountRepo.saveAccount(accountA2);
      await accountRepo.saveAccount(accountB1);

      // Company A Subjects
      subjectA1 = AccountingSubject(
        id: '00000000-0000-0000-0000-000000suba01',
        companyId: companyA,
        subjectType: AccountingSubjectType.customer,
        name: 'العميل A1',
        code: 'CUST-A1',
        primaryAccountId: accountA1.id,
        isActive: true,
      );

      subjectA2 = AccountingSubject(
        id: '00000000-0000-0000-0000-000000suba02',
        companyId: companyA,
        subjectType: AccountingSubjectType.customer,
        name: 'العميل A2',
        code: 'CUST-A2',
        primaryAccountId: accountA2.id,
        isActive: true,
      );

      // Company B Subject
      subjectB1 = AccountingSubject(
        id: '00000000-0000-0000-0000-000000subb01',
        companyId: companyB,
        subjectType: AccountingSubjectType.customer,
        name: 'العميل B1',
        code: 'CUST-B1',
        primaryAccountId: accountB1.id,
        isActive: true,
      );

      await subjectRepo.saveSubject(subjectA1);
      await subjectRepo.saveSubject(subjectA2);
      await subjectRepo.saveSubject(subjectB1);
    });

    tearDown(() async {
      await db.close();
    });

    test('TEST-43: Canonical subject -> account binding creation', () async {
      final res = await bindingService.bindSubjectToAccount(
        companyId: companyA,
        subjectId: subjectA1.id,
        financialAccountId: accountA1.id,
        roleKey: 'CUSTOMER_RECEIVABLE',
      );

      expect(res.subjectId, subjectA1.id);
      expect(res.accountId, accountA1.id);
      expect(res.isAlreadyBound, isTrue); // Already set in setup

      final resolvedAccount = await bindingService.resolveSubjectAccount(
        companyId: companyA,
        subjectId: subjectA1.id,
      );
      expect(resolvedAccount, accountA1.id);
    });

    test('TEST-44: Duplicate identical binding returns existing', () async {
      final res1 = await bindingService.bindSubjectToAccount(
        companyId: companyA,
        subjectId: subjectA1.id,
        financialAccountId: accountA1.id,
      );

      final res2 = await bindingService.bindSubjectToAccount(
        companyId: companyA,
        subjectId: subjectA1.id,
        financialAccountId: accountA1.id,
      );

      expect(res1.isAlreadyBound, isTrue);
      expect(res2.isAlreadyBound, isTrue);
      expect(res2.accountId, res1.accountId);
    });

    test('TEST-45 & TEST-49: Cross-company subject/account binding rejection (Attack A)', () async {
      expect(
        () => bindingService.bindSubjectToAccount(
          companyId: companyA,
          subjectId: subjectA1.id,
          financialAccountId: accountB1.id, // Company B account!
        ),
        throwsA(
          isA<FinancialValidationException>().having((e) => e.code, 'code', 'ACCOUNT_NOT_FOUND'),
        ),
      );
    });

    test('TEST-46: Cross-company subject binding under wrong company context (Attack B)', () async {
      expect(
        () => bindingService.bindSubjectToAccount(
          companyId: companyA,
          subjectId: subjectB1.id, // Company B subject!
          financialAccountId: accountA1.id,
        ),
        throwsA(
          isA<FinancialValidationException>().having((e) => e.code, 'code', 'SUBJECT_NOT_FOUND'),
        ),
      );
    });

    test('TEST-47: Invalid role rejection', () async {
      expect(
        () => bindingService.bindSubjectToAccount(
          companyId: companyA,
          subjectId: subjectA1.id, // Customer
          financialAccountId: supplierParentA.id, // Liability account
          roleKey: 'CUSTOMER_RECEIVABLE', // Expects Asset
        ),
        throwsA(
          isA<FinancialValidationException>().having((e) => e.code, 'code', 'ROLE_ACCOUNT_MISMATCH'),
        ),
      );
    });

    test('TEST-48: Inactive account rejection', () async {
      final inactiveAccount = FinancialAccount(
        id: '00000000-0000-0000-0000-000000inact1',
        companyId: companyA,
        code: '120099',
        nameAr: 'حساب غير نشط',
        nameEn: 'Inactive Account',
        accountType: FinancialAccountType.asset,
        isActive: false, // INACTIVE
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );
      await accountRepo.saveAccount(inactiveAccount);

      expect(
        () => bindingService.bindSubjectToAccount(
          companyId: companyA,
          subjectId: subjectA1.id,
          financialAccountId: inactiveAccount.id,
        ),
        throwsA(
          isA<FinancialValidationException>().having((e) => e.code, 'code', 'INACTIVE_ACCOUNT'),
        ),
      );
    });

    test('TEST-50 & TEST-52: Customer provisioning creates canonical binding and is idempotent', () async {
      final res1 = await customerProvisioning.provisionCustomer(
        companyId: companyA,
        customerId: '00000000-0000-0000-0000-0000000c0050',
        customerCode: 'CUST-050',
        customerName: 'عميل الربط النهائي',
      );

      expect(res1.isAlreadyProvisioned, isFalse);

      final resolvedAccount = await bindingService.resolveSubjectAccount(
        companyId: companyA,
        subjectId: res1.subjectId,
      );
      expect(resolvedAccount, res1.accountId);

      // Second provisioning attempt (Idempotent)
      final res2 = await customerProvisioning.provisionCustomer(
        companyId: companyA,
        customerId: '00000000-0000-0000-0000-0000000c0050',
        customerCode: 'CUST-050',
        customerName: 'عميل الربط النهائي',
      );

      expect(res2.isAlreadyProvisioned, isTrue);
      expect(res2.accountId, res1.accountId);
    });

    test('TEST-51 & TEST-53: Supplier provisioning creates canonical binding and is idempotent', () async {
      final res1 = await supplierProvisioning.provisionSupplier(
        companyId: companyA,
        supplierId: '00000000-0000-0000-0000-0000000s0051',
        supplierCode: 'SUPP-051',
        supplierName: 'مورد الربط النهائي',
      );

      expect(res1.isAlreadyProvisioned, isFalse);

      final resolvedAccount = await bindingService.resolveSubjectAccount(
        companyId: companyA,
        subjectId: res1.subjectId,
      );
      expect(resolvedAccount, res1.accountId);

      final res2 = await supplierProvisioning.provisionSupplier(
        companyId: companyA,
        supplierId: '00000000-0000-0000-0000-0000000s0051',
        supplierCode: 'SUPP-051',
        supplierName: 'مورد الربط النهائي',
      );

      expect(res2.isAlreadyProvisioned, isTrue);
      expect(res2.accountId, res1.accountId);
    });

    test('TEST-54: Account code mutation preserves binding identity', () async {
      final res = await customerProvisioning.provisionCustomer(
        companyId: companyA,
        customerId: '00000000-0000-0000-0000-0000000c0054',
        customerCode: 'CUST-054',
        customerName: 'عميل تغيير الرقم',
      );

      final account = await accountRepo.findById(companyA, res.accountId);

      // Mutate display code from 120001 to 129999
      final mutatedAccount = FinancialAccount(
        id: account!.id,
        companyId: account.companyId,
        code: '129999', // MUTATED CODE
        nameAr: account.nameAr,
        nameEn: account.nameEn,
        accountType: account.accountType,
        parentAccountId: account.parentAccountId,
        level: account.level,
        isGroup: false,
        currencyPolicy: account.currencyPolicy,
      );

      await accountRepo.saveAccount(mutatedAccount);

      final resolved = await bindingService.resolveSubjectAccount(
        companyId: companyA,
        subjectId: res.subjectId,
      );

      expect(resolved, res.accountId); // UUID v7 bound account remains identical
    });

    test('TEST-55: Account move under new parent preserves binding identity', () async {
      final res = await customerProvisioning.provisionCustomer(
        companyId: companyA,
        customerId: '00000000-0000-0000-0000-0000000c0055',
        customerCode: 'CUST-055',
        customerName: 'عميل نقل المجموعة',
      );

      final newParent = FinancialAccount(
        id: '00000000-0000-0000-0000-000000001250',
        companyId: companyA,
        code: '1250',
        nameAr: 'عملاء VIP',
        nameEn: 'VIP Customers',
        accountType: FinancialAccountType.asset,
        isGroup: true,
        parentAccountId: customerParentA.id,
        level: 3,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );
      await accountRepo.saveAccount(newParent);

      final account = await accountRepo.findById(companyA, res.accountId);
      final movedAccount = FinancialAccount(
        id: account!.id,
        companyId: account.companyId,
        code: account.code,
        nameAr: account.nameAr,
        nameEn: account.nameEn,
        accountType: account.accountType,
        parentAccountId: newParent.id, // MOVED PARENT
        level: newParent.level + 1,
        isGroup: false,
        currencyPolicy: account.currencyPolicy,
      );
      await accountRepo.saveAccount(movedAccount);

      final resolved = await bindingService.resolveSubjectAccount(
        companyId: companyA,
        subjectId: res.subjectId,
      );

      expect(resolved, res.accountId);
    });

    test('TEST-56: Reassignment preserves historical JournalLines immutability', () async {
      // 1. Create entry with initial accountA1
      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000056001',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000056',
        lineNumber: 1,
        accountId: accountA1.id,
        subjectId: subjectA1.id,
        side: FinancialSide.debit,
        transactionAmount: DecimalMoney.fromString('1000.00', 'YER'),
        exchangeRate: DecimalRate.identity('YER'),
        baseCurrencyCode: 'YER',
      );

      final line2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000056002',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000056',
        lineNumber: 2,
        accountId: customerParentA.id,
        side: FinancialSide.credit,
        transactionAmount: DecimalMoney.fromString('1000.00', 'YER'),
        exchangeRate: DecimalRate.identity('YER'),
        baseCurrencyCode: 'YER',
      );

      final entry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000056',
        companyId: companyA,
        entryNumber: 'REASSIGN-56',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        status: JournalStatus.posted,
        lines: [line1, line2],
      );

      await journalRepo.saveEntry(entry);

      // 2. Reassign subjectA1 from accountA1 to accountA2
      await bindingService.reassignSubjectAccount(
        companyId: companyA,
        subjectId: subjectA1.id,
        newFinancialAccountId: accountA2.id,
      );

      // 3. Verify resolution points to new accountA2
      final resolved = await bindingService.resolveSubjectAccount(
        companyId: companyA,
        subjectId: subjectA1.id,
      );
      expect(resolved, accountA2.id);

      // 4. Verify historical posted line in journal is IMMUTABLE (still references accountA1)
      final queriedEntry = await journalRepo.findById(companyA, entry.id);
      expect(queriedEntry!.lines[0].accountId, accountA1.id);
    });

    test('TEST-58 & TEST-59: Resolver returns technical UUID v7 identity and never human code', () async {
      final resolvedId = await bindingService.resolveSubjectAccount(
        companyId: companyA,
        subjectId: subjectA1.id,
      );

      expect(resolvedId, accountA1.id);
      expect(resolvedId, isNot(accountA1.code)); // NOT "120001"
      expect(resolvedId.length, 36); // UUID v7 length
    });

    test('TEST-60: Missing binding fails explicitly without silent fallback', () async {
      final unlinkedSubject = AccountingSubject(
        id: '00000000-0000-0000-0000-000000unlink',
        companyId: companyA,
        subjectType: AccountingSubjectType.customer,
        name: 'عميل بدون حساب',
        code: 'UNLINK-01',
        primaryAccountId: '', // EMPTY PRIMARY ACCOUNT
        isActive: true,
      );
      await subjectRepo.saveSubject(unlinkedSubject);

      expect(
        () => bindingService.resolveSubjectAccount(
          companyId: companyA,
          subjectId: unlinkedSubject.id,
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'MISSING_SUBJECT_ACCOUNT_BINDING',
          ),
        ),
      );
    });

    test('TEST-61: Multi-role Customer + Supplier remains 100% isolated', () async {
      const partyId = '00000000-0000-0000-0000-0000000party';

      final custRes = await customerProvisioning.provisionCustomer(
        companyId: companyA,
        customerId: partyId,
        customerCode: 'PARTY-VIP',
        customerName: 'جهة متعددة الأدوار',
      );

      final suppRes = await supplierProvisioning.provisionSupplier(
        companyId: companyA,
        supplierId: partyId,
        supplierCode: 'PARTY-VIP',
        supplierName: 'جهة متعددة الأدوار',
      );

      expect(custRes.accountId, isNot(suppRes.accountId));
      expect(custRes.subjectId, isNot(suppRes.subjectId));

      final resolvedCustAccount = await bindingService.resolveSubjectAccount(
        companyId: companyA,
        subjectId: custRes.subjectId,
      );

      final resolvedSuppAccount = await bindingService.resolveSubjectAccount(
        companyId: companyA,
        subjectId: suppRes.subjectId,
      );

      expect(resolvedCustAccount, isNot(resolvedSuppAccount));
    });
  });
}
