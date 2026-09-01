import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_accounting_poster_impl.dart';
import 'package:stock_count/modules/system_setup/data/repositories/company_initialization_repository_impl.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AccountingDatabase accountingDb;
  late Box<dynamic> settingsBox;
  late CompanyInitializationRepositoryImpl initRepoCompanyA;
  late CompanyInitializationRepositoryImpl initRepoCompanyB;

  const companyA = 'COMPANY_ALPHA_YER';
  const companyB = 'COMPANY_BETA_SAR';

  setUp(() async {
    accountingDb = AccountingDatabase.memory();

    Hive.init('./test_hive_temp_p6');
    if (!Hive.isBoxOpen(HiveBoxes.settings)) {
      settingsBox = await Hive.openBox<dynamic>(HiveBoxes.settings);
    } else {
      settingsBox = Hive.box<dynamic>(HiveBoxes.settings);
    }
    await settingsBox.clear();

    initRepoCompanyA = CompanyInitializationRepositoryImpl(
      box: settingsBox,
      readCompanyId: () => companyA,
    );

    initRepoCompanyB = CompanyInitializationRepositoryImpl(
      box: settingsBox,
      readCompanyId: () => companyB,
    );

    final now = DateTime.now().millisecondsSinceEpoch;

    // Seed Accounts for Company A (Base: YER)
    await accountingDb.into(accountingDb.accounts).insert(
          AccountsCompanion.insert(
            uuid: '10000000-0000-4000-8000-0000000000a1',
            accountCode: '1230-A',
            name: 'Inventory Acc Company A',
            accountType: 'asset',
            normalBalance: 'debit',
            companyId: Value(companyA),
            createdAt: now,
            updatedAt: now,
            isGroup: const Value(false),
            isActive: const Value(true),
          ),
        );
    await accountingDb.into(accountingDb.accounts).insert(
          AccountsCompanion.insert(
            uuid: '10000000-0000-4000-8000-0000000000a2',
            accountCode: '5100-A',
            name: 'COGS Acc Company A',
            accountType: 'expense',
            normalBalance: 'debit',
            companyId: Value(companyA),
            createdAt: now,
            updatedAt: now,
            isGroup: const Value(false),
            isActive: const Value(true),
          ),
        );
    await accountingDb.into(accountingDb.accounts).insert(
          AccountsCompanion.insert(
            uuid: '10000000-0000-4000-8000-0000000000a3',
            accountCode: '2110-A',
            name: 'Payable Acc Company A',
            accountType: 'liability',
            normalBalance: 'credit',
            companyId: Value(companyA),
            createdAt: now,
            updatedAt: now,
            isGroup: const Value(false),
            isActive: const Value(true),
          ),
        );

    // Save Setup Configs for Company A
    await initRepoCompanyA.saveInventoryConfig(const CompanyInventoryConfig(
      companyId: companyA,
      inventoryBaseCurrencyId: 'YER',
    ));
    await initRepoCompanyA.saveAccountingConfig(const CompanyAccountingConfig(
      companyId: companyA,
      accountMappings: {
        AccountRole.inventory: '10000000-0000-4000-8000-0000000000a1',
        AccountRole.cogs: '10000000-0000-4000-8000-0000000000a2',
        AccountRole.payable: '10000000-0000-4000-8000-0000000000a3',
      },
    ));

    // Seed Accounts for Company B (Base: SAR)
    await accountingDb.into(accountingDb.accounts).insert(
          AccountsCompanion.insert(
            uuid: '20000000-0000-4000-8000-0000000000b1',
            accountCode: '1230-B',
            name: 'Inventory Acc Company B',
            accountType: 'asset',
            normalBalance: 'debit',
            companyId: Value(companyB),
            createdAt: now,
            updatedAt: now,
            isGroup: const Value(false),
            isActive: const Value(true),
          ),
        );
    await accountingDb.into(accountingDb.accounts).insert(
          AccountsCompanion.insert(
            uuid: '20000000-0000-4000-8000-0000000000b2',
            accountCode: '5100-B',
            name: 'COGS Acc Company B',
            accountType: 'expense',
            normalBalance: 'debit',
            companyId: Value(companyB),
            createdAt: now,
            updatedAt: now,
            isGroup: const Value(false),
            isActive: const Value(true),
          ),
        );
    await accountingDb.into(accountingDb.accounts).insert(
          AccountsCompanion.insert(
            uuid: '20000000-0000-4000-8000-0000000000b3',
            accountCode: '2110-B',
            name: 'Payable Acc Company B',
            accountType: 'liability',
            normalBalance: 'credit',
            companyId: Value(companyB),
            createdAt: now,
            updatedAt: now,
            isGroup: const Value(false),
            isActive: const Value(true),
          ),
        );

    // Save Setup Configs for Company B
    await initRepoCompanyB.saveInventoryConfig(const CompanyInventoryConfig(
      companyId: companyB,
      inventoryBaseCurrencyId: 'SAR',
    ));
    await initRepoCompanyB.saveAccountingConfig(const CompanyAccountingConfig(
      companyId: companyB,
      accountMappings: {
        AccountRole.inventory: '20000000-0000-4000-8000-0000000000b1',
        AccountRole.cogs: '20000000-0000-4000-8000-0000000000b2',
        AccountRole.payable: '20000000-0000-4000-8000-0000000000b3',
      },
    ));
  });

  tearDown(() async {
    await accountingDb.close();
    await settingsBox.clear();
  });

  group('Phase 6 — Connect Inventory & Accounting to Company Configuration Tests', () {
    test('1. Multi-Company Posting: Company A (YER) uses exact Company A configured accounts & currency', () async {
      final posterCompanyA = InventoryAccountingPosterImpl(
        accountingDb,
        readCompanyId: () => companyA,
        initRepository: initRepoCompanyA,
      );

      final docRef = InventoryDocumentRef(
        documentId: 'doc-receipt-A',
        documentNumber: 'REC-A-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: 'wh-A',
        status: InventoryDocumentStatus.posted,
        currencyCode: 'YER',
        exchangeRate: 1.0,
      );

      await posterCompanyA.postAccountingEntry(
        document: docRef,
        totalAmount: 5000.0,
      );

      // Verify journal entry header
      final entries = await (accountingDb.select(accountingDb.journalEntries)
            ..where((t) => t.companyId.equals(companyA)))
          .get();

      expect(entries.length, equals(1));
      expect(entries.first.currencyCode, equals('YER'));

      // Verify journal lines
      final lines = await (accountingDb.select(accountingDb.journalLines)
            ..where((t) => t.entryUuid.equals(entries.first.uuid)))
          .get();

      expect(lines.length, equals(2));

      final debitLine = lines.firstWhere((l) => l.debit > 0);
      final creditLine = lines.firstWhere((l) => l.credit > 0);

      // Debit should be Company A Inventory account
      expect(debitLine.accountUuid, equals('10000000-0000-4000-8000-0000000000a1'));
      expect(debitLine.debit, equals(5000.0));

      // Credit should be Company A Payable account
      expect(creditLine.accountUuid, equals('10000000-0000-4000-8000-0000000000a3'));
      expect(creditLine.credit, equals(5000.0));
    });

    test('2. Multi-Company Posting: Company B (SAR) uses exact Company B configured accounts & currency', () async {
      final posterCompanyB = InventoryAccountingPosterImpl(
        accountingDb,
        readCompanyId: () => companyB,
        initRepository: initRepoCompanyB,
      );

      final docRef = InventoryDocumentRef(
        documentId: 'doc-issue-B',
        documentNumber: 'ISS-B-001',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: DateTime.now(),
        warehouseId: 'wh-B',
        status: InventoryDocumentStatus.posted,
        currencyCode: 'SAR',
        exchangeRate: 1.0,
      );

      await posterCompanyB.postAccountingEntry(
        document: docRef,
        totalAmount: 1200.0,
      );

      // Verify journal entry header
      final entries = await (accountingDb.select(accountingDb.journalEntries)
            ..where((t) => t.companyId.equals(companyB)))
          .get();

      expect(entries.length, equals(1));
      expect(entries.first.currencyCode, equals('SAR'));

      // Verify journal lines
      final lines = await (accountingDb.select(accountingDb.journalLines)
            ..where((t) => t.entryUuid.equals(entries.first.uuid)))
          .get();

      expect(lines.length, equals(2));

      final debitLine = lines.firstWhere((l) => l.debit > 0);
      final creditLine = lines.firstWhere((l) => l.credit > 0);

      // Debit should be Company B COGS account
      expect(debitLine.accountUuid, equals('20000000-0000-4000-8000-0000000000b2'));
      expect(debitLine.debit, equals(1200.0));

      // Credit should be Company B Inventory account
      expect(creditLine.accountUuid, equals('20000000-0000-4000-8000-0000000000b1'));
      expect(creditLine.credit, equals(1200.0));
    });

    test('3. Exact Currency Conversion Test (100 SAR * 145 = 14,500 YER base cost)', () async {
      final posterCompanyA = InventoryAccountingPosterImpl(
        accountingDb,
        readCompanyId: () => companyA,
        initRepository: initRepoCompanyA,
      );

      final docRef = InventoryDocumentRef(
        documentId: 'doc-receipt-fx',
        documentNumber: 'REC-FX-001',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: 'wh-A',
        status: InventoryDocumentStatus.posted,
        currencyCode: 'SAR',
        exchangeRate: 145.0,
      );

      await posterCompanyA.postAccountingEntry(
        document: docRef,
        totalAmount: 100.0,
      );

      final entries = await (accountingDb.select(accountingDb.journalEntries)
            ..where((t) => t.voucherNumber.equals('REC-FX-001')))
          .get();

      expect(entries.length, equals(1));
      expect(entries.first.currencyCode, equals('SAR'));

      final lines = await (accountingDb.select(accountingDb.journalLines)
            ..where((t) => t.entryUuid.equals(entries.first.uuid)))
          .get();

      expect(lines.length, equals(2));

      final debitLine = lines.firstWhere((l) => l.debit > 0);
      final creditLine = lines.firstWhere((l) => l.credit > 0);

      // Line amounts in Document Currency
      expect(debitLine.debit, equals(100.0));
      expect(creditLine.credit, equals(100.0));

      // Base amounts converted at 145 exchange rate = 14,500 YER
      expect(debitLine.baseDebit, equals(14500.0));
      expect(creditLine.baseCredit, equals(14500.0));
      expect(debitLine.exchangeRateToBase, equals(145.0));
    });

    test('4. Accounting Integrity Invariant: Sum(Debit) == Sum(Credit)', () async {
      final posterCompanyA = InventoryAccountingPosterImpl(
        accountingDb,
        readCompanyId: () => companyA,
        initRepository: initRepoCompanyA,
      );

      await posterCompanyA.postAccountingEntry(
        document: InventoryDocumentRef(
          documentId: 'doc-bal-1',
          documentNumber: 'REC-BAL-01',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now(),
          warehouseId: 'wh-A',
          status: InventoryDocumentStatus.posted,
          currencyCode: 'SAR',
          exchangeRate: 145.0,
        ),
        totalAmount: 350.0,
      );

      final allLines = await accountingDb.select(accountingDb.journalLines).get();
      final totalDebit = allLines.fold<double>(0.0, (sum, l) => sum + l.debit);
      final totalCredit = allLines.fold<double>(0.0, (sum, l) => sum + l.credit);
      final totalBaseDebit = allLines.fold<double>(0.0, (sum, l) => sum + l.baseDebit);
      final totalBaseCredit = allLines.fold<double>(0.0, (sum, l) => sum + l.baseCredit);

      expect(totalDebit, equals(totalCredit));
      expect(totalBaseDebit, equals(totalBaseCredit));
    });
  });
}
