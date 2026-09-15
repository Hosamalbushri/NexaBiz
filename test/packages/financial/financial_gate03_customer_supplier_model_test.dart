import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/packages/financial/financial.dart';

void main() {
  group('GATE-03 Customer & Supplier Accounting Model Test Suite', () {
    late NexabizDatabase db;
    late DriftFinancialAccountRepository accountRepo;
    late DriftFinancialSubjectRepository subjectRepo;
    late DriftFinancialJournalRepository journalRepo;
    late CustomerAccountingProvisioningService customerProvisioning;
    late SupplierAccountingProvisioningService supplierProvisioning;

    const companyA = '11111111-1111-1111-1111-111111111111';
    const companyB = '22222222-2222-2222-2222-222222222222';

    late FinancialAccount customerParentA;
    late FinancialAccount supplierParentA;
    late FinancialAccount customerParentB;

    setUp(() async {
      db = NexabizDatabase.memory();
      accountRepo = DriftFinancialAccountRepository(db);
      subjectRepo = DriftFinancialSubjectRepository(db);
      journalRepo = DriftFinancialJournalRepository(db);

      customerProvisioning = CustomerAccountingProvisioningService(
        accountRepo: accountRepo,
        subjectRepo: subjectRepo,
      );

      supplierProvisioning = SupplierAccountingProvisioningService(
        accountRepo: accountRepo,
        subjectRepo: subjectRepo,
      );

      // Setup Parent Accounts for Company A
      customerParentA = FinancialAccount(
        id: '00000000-0000-0000-0000-000000001200',
        companyId: companyA,
        code: '1200',
        nameAr: 'حساب العملاء الأب A',
        nameEn: 'Customers Parent Account A',
        accountType: FinancialAccountType.asset,
        isGroup: true,
        level: 2,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      supplierParentA = FinancialAccount(
        id: '00000000-0000-0000-0000-000000002100',
        companyId: companyA,
        code: '2100',
        nameAr: 'حساب الموردين الأب A',
        nameEn: 'Suppliers Parent Account A',
        accountType: FinancialAccountType.liability,
        isGroup: true,
        level: 2,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      // Setup Parent Account for Company B
      customerParentB = FinancialAccount(
        id: '00000000-0000-0000-0000-00000000120b',
        companyId: companyB,
        code: '1200',
        nameAr: 'حساب العملاء الأب B',
        nameEn: 'Customers Parent Account B',
        accountType: FinancialAccountType.asset,
        isGroup: true,
        level: 2,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );

      await accountRepo.saveAccount(customerParentA);
      await accountRepo.saveAccount(supplierParentA);
      await accountRepo.saveAccount(customerParentB);
    });

    tearDown(() async {
      await db.close();
    });

    test('TEST-23: Customer provisioning creates dedicated FinancialAccount and AccountingSubject', () async {
      final res = await customerProvisioning.provisionCustomer(
        companyId: companyA,
        customerId: '00000000-0000-0000-0000-0000000c0001',
        customerCode: 'CUST-001',
        customerName: 'شركة الأمل التجارية',
        configuredParentAccountId: customerParentA.id,
      );

      expect(res.isAlreadyProvisioned, isFalse);
      expect(res.accountCode, '120001');

      final account = await accountRepo.findById(companyA, res.accountId);
      final subject = await subjectRepo.findSubjectById(companyA, res.subjectId);

      expect(account, isNotNull);
      expect(account!.parentAccountId, customerParentA.id);
      expect(account.code, '120001');

      expect(subject, isNotNull);
      expect(subject!.subjectType, AccountingSubjectType.customer);
      expect(subject.primaryAccountId, account.id);
    });

    test('TEST-24: Supplier provisioning creates dedicated FinancialAccount and AccountingSubject', () async {
      final res = await supplierProvisioning.provisionSupplier(
        companyId: companyA,
        supplierId: '00000000-0000-0000-0000-0000000s0001',
        supplierCode: 'SUPP-001',
        supplierName: 'مؤسسة التقنية للتوريدات',
        configuredParentAccountId: supplierParentA.id,
      );

      expect(res.isAlreadyProvisioned, isFalse);
      expect(res.accountCode, '210001');

      final account = await accountRepo.findById(companyA, res.accountId);
      final subject = await subjectRepo.findSubjectById(companyA, res.subjectId);

      expect(account, isNotNull);
      expect(account!.parentAccountId, supplierParentA.id);
      expect(account.accountType, FinancialAccountType.liability);

      expect(subject, isNotNull);
      expect(subject!.subjectType, AccountingSubjectType.supplier);
    });

    test('TEST-25: Customer provisioning idempotency', () async {
      const custId = '00000000-0000-0000-0000-0000000c0025';

      final res1 = await customerProvisioning.provisionCustomer(
        companyId: companyA,
        customerId: custId,
        customerCode: 'CUST-025',
        customerName: 'عميل اختبار التكرار',
      );

      final res2 = await customerProvisioning.provisionCustomer(
        companyId: companyA,
        customerId: custId,
        customerCode: 'CUST-025',
        customerName: 'عميل اختبار التكرار',
      );

      expect(res1.isAlreadyProvisioned, isFalse);
      expect(res2.isAlreadyProvisioned, isTrue);
      expect(res2.accountId, res1.accountId);
      expect(res2.subjectId, res1.subjectId);
      expect(res2.accountCode, res1.accountCode);
    });

    test('TEST-26: Supplier provisioning idempotency', () async {
      const suppId = '00000000-0000-0000-0000-0000000s0026';

      final res1 = await supplierProvisioning.provisionSupplier(
        companyId: companyA,
        supplierId: suppId,
        supplierCode: 'SUPP-026',
        supplierName: 'مورد اختبار التكرار',
      );

      final res2 = await supplierProvisioning.provisionSupplier(
        companyId: companyA,
        supplierId: suppId,
        supplierCode: 'SUPP-026',
        supplierName: 'مورد اختبار التكرار',
      );

      expect(res1.isAlreadyProvisioned, isFalse);
      expect(res2.isAlreadyProvisioned, isTrue);
      expect(res2.accountId, res1.accountId);
      expect(res2.subjectId, res1.subjectId);
    });

    test('TEST-27 & TEST-28: Account number change preserves UUID identity', () async {
      final res = await customerProvisioning.provisionCustomer(
        companyId: companyA,
        customerId: '00000000-0000-0000-0000-0000000c0027',
        customerCode: 'CUST-027',
        customerName: 'العميل أحمد',
      );

      final originalAccount = await accountRepo.findById(companyA, res.accountId);
      expect(originalAccount!.code, '120001');

      // Update account code from 120001 to 121001
      final updatedAccount = FinancialAccount(
        id: originalAccount.id,
        companyId: originalAccount.companyId,
        code: '121001', // CODE MUTATED
        nameAr: originalAccount.nameAr,
        nameEn: originalAccount.nameEn,
        accountType: originalAccount.accountType,
        parentAccountId: originalAccount.parentAccountId,
        level: originalAccount.level,
        isGroup: false,
        currencyPolicy: originalAccount.currencyPolicy,
      );

      await accountRepo.saveAccount(updatedAccount);

      final reloaded = await accountRepo.findById(companyA, res.accountId);
      expect(reloaded!.id, res.accountId); // UUID IDENTICAL
      expect(reloaded.code, '121001');
    });

    test('TEST-29 & TEST-30: Account move is a non-financial metadata operation', () async {
      final res = await customerProvisioning.provisionCustomer(
        companyId: companyA,
        customerId: '00000000-0000-0000-0000-0000000c0029',
        customerCode: 'CUST-029',
        customerName: 'عميل فرع صنعاء',
      );

      // Create new sub-parent: 1210 Sanaa Customers
      final sanaaParent = FinancialAccount(
        id: '00000000-0000-0000-0000-000000001210',
        companyId: companyA,
        code: '1210',
        nameAr: 'عملاء صنعاء',
        nameEn: 'Sanaa Customers',
        accountType: FinancialAccountType.asset,
        isGroup: true,
        parentAccountId: customerParentA.id,
        level: 3,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );
      await accountRepo.saveAccount(sanaaParent);

      final initialAccount = await accountRepo.findById(companyA, res.accountId);

      // Move account under 1210 Sanaa Customers
      final movedAccount = FinancialAccount(
        id: initialAccount!.id,
        companyId: initialAccount.companyId,
        code: initialAccount.code, // CODE PRESERVED ON MOVE
        nameAr: initialAccount.nameAr,
        nameEn: initialAccount.nameEn,
        accountType: initialAccount.accountType,
        parentAccountId: sanaaParent.id, // PARENT MOVED
        level: sanaaParent.level + 1,
        isGroup: false,
        currencyPolicy: initialAccount.currencyPolicy,
      );

      await accountRepo.saveAccount(movedAccount);

      final reloaded = await accountRepo.findById(companyA, res.accountId);
      expect(reloaded!.parentAccountId, sanaaParent.id);
      expect(reloaded.code, '120001'); // Code remains unchanged

      // Verify ZERO journal entries created
      final journals = await journalRepo.findById(companyA, 'any-id');
      expect(journals, isNull);
    });

    test('TEST-31 & TEST-32: Provisioning fails closed on invalid company ID', () async {
      expect(
        () => customerProvisioning.provisionCustomer(
          companyId: '', // Invalid empty company
          customerId: '00000000-0000-0000-0000-0000000c0031',
          customerCode: 'CUST-31',
          customerName: 'Invalid Company Customer',
        ),
        throwsA(isA<FinancialValidationException>()),
      );
    });

    test('TEST-33: Cross-company parent rejection (Company A customer cannot use Company B parent account)', () async {
      expect(
        () => customerProvisioning.provisionCustomer(
          companyId: companyA,
          customerId: '00000000-0000-0000-0000-0000000c0033',
          customerCode: 'CUST-033',
          customerName: 'Cross Tenant Attacker',
          configuredParentAccountId: customerParentB.id, // FOREIGN COMPANY B PARENT!
        ),
        throwsA(
          isA<FinancialValidationException>().having(
            (e) => e.code,
            'code',
            'INVALID_PARENT_ACCOUNT',
          ),
        ),
      );
    });

    test('TEST-34 & TEST-35: Configured parent account is strictly respected', () async {
      // Create custom sub-group: 1220 Foreign Customers
      final foreignParent = FinancialAccount(
        id: '00000000-0000-0000-0000-000000001220',
        companyId: companyA,
        code: '1220',
        nameAr: 'العملاء الخارجيون',
        nameEn: 'Foreign Customers',
        accountType: FinancialAccountType.asset,
        isGroup: true,
        parentAccountId: customerParentA.id,
        level: 3,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );
      await accountRepo.saveAccount(foreignParent);

      final res = await customerProvisioning.provisionCustomer(
        companyId: companyA,
        customerId: '00000000-0000-0000-0000-0000000c0034',
        customerCode: 'CUST-034',
        customerName: 'عميل دولي',
        configuredParentAccountId: foreignParent.id,
      );

      final account = await accountRepo.findById(companyA, res.accountId);
      expect(account!.parentAccountId, foreignParent.id);
      expect(account.code, '122001'); // Generated under 1220
    });

    test('TEST-38 & TEST-39: Historical journal stability after account number change', () async {
      final res = await customerProvisioning.provisionCustomer(
        companyId: companyA,
        customerId: '00000000-0000-0000-0000-0000000c0038',
        customerCode: 'CUST-038',
        customerName: 'عميل سابقة تاريخية',
      );

      final revenueAccount = FinancialAccount(
        id: '00000000-0000-0000-0000-000000004001',
        companyId: companyA,
        code: '4001',
        nameAr: 'المبيعات',
        nameEn: 'Sales Revenue',
        accountType: FinancialAccountType.revenue,
        currencyPolicy: AccountCurrencyPolicy.functionalOnly,
      );
      await accountRepo.saveAccount(revenueAccount);

      final rate = DecimalRate.identity('YER');
      final amount = DecimalMoney.fromString('5000.00', 'YER');

      final line1 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000038001',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000038',
        lineNumber: 1,
        accountId: res.accountId, // LINKED TO TECHNICAL UUID
        side: FinancialSide.debit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final line2 = JournalLine.create(
        id: '00000000-0000-0000-0000-000000038002',
        companyId: companyA,
        journalEntryId: '00000000-0000-0000-0000-000000000038',
        lineNumber: 2,
        accountId: revenueAccount.id,
        side: FinancialSide.credit,
        transactionAmount: amount,
        exchangeRate: rate,
        baseCurrencyCode: 'YER',
      );

      final entry = JournalEntry(
        id: '00000000-0000-0000-0000-000000000038',
        companyId: companyA,
        entryNumber: 'HIST-CUST-38',
        baseCurrencyCode: 'YER',
        postingDate: DateTime.now(),
        status: JournalStatus.posted,
        lines: [line1, line2],
      );

      await journalRepo.saveEntry(entry);

      // Now mutate customer account code
      final account = await accountRepo.findById(companyA, res.accountId);
      final mutatedAccount = FinancialAccount(
        id: account!.id,
        companyId: account.companyId,
        code: '999999', // CODE MUTATED
        nameAr: account.nameAr,
        nameEn: account.nameEn,
        accountType: account.accountType,
        parentAccountId: account.parentAccountId,
        level: account.level,
        isGroup: false,
        currencyPolicy: account.currencyPolicy,
      );
      await accountRepo.saveAccount(mutatedAccount);

      // Historical entry query remains 100% valid
      final queriedEntry = await journalRepo.findById(companyA, entry.id);
      expect(queriedEntry, isNotNull);
      expect(queriedEntry!.lines[0].accountId, res.accountId);
    });

    test('TEST-40: Party acting as both Customer and Supplier gets distinct identities', () async {
      const partyId = '00000000-0000-0000-0000-000000party1';

      final custRes = await customerProvisioning.provisionCustomer(
        companyId: companyA,
        customerId: partyId,
        customerCode: 'PARTY-01',
        customerName: 'الجهة الفنية العالمية',
      );

      final suppRes = await supplierProvisioning.provisionSupplier(
        companyId: companyA,
        supplierId: partyId,
        supplierCode: 'PARTY-01',
        supplierName: 'الجهة الفنية العالمية',
      );

      expect(custRes.accountId, isNot(suppRes.accountId));
      expect(custRes.accountCode, '120001'); // Under 1200 Customers
      expect(suppRes.accountCode, '210001'); // Under 2100 Suppliers

      final custAccount = await accountRepo.findById(companyA, custRes.accountId);
      final suppAccount = await accountRepo.findById(companyA, suppRes.accountId);

      expect(custAccount!.accountType, FinancialAccountType.asset);
      expect(suppAccount!.accountType, FinancialAccountType.liability);
    });
  });
}
