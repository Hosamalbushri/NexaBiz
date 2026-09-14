import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_accounting_poster_impl.dart';
import 'package:stock_count/modules/system_setup/data/repositories/company_initialization_repository_impl.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/journals/data/services/journal_builder_impl.dart';
import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/currency.dart';
import 'package:stock_count/modules/currency/data/repositories/currency_repository_impl.dart';
import 'package:stock_count/modules/currency/domain/services/functional_currency_service.dart';
import 'package:stock_count/modules/currency/data/repositories/currency_rate_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/warehouse_accounting_binding_repository_impl.dart';

import 'helpers/journal_posting_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NexabizDatabase accountingDb;
  late Box<dynamic> settingsBox;
  late CompanyInitializationRepositoryImpl initRepoCompanyA;
  late CompanyInitializationRepositoryImpl initRepoCompanyB;

  const companyA = 'COMPANY_ALPHA_YER';
  const companyB = 'COMPANY_BETA_SAR';
  const whA = '10000000-0000-4000-8000-0000000000w1';
  const whB = '20000000-0000-4000-8000-0000000000w2';

  setUp(() async {
    accountingDb = NexabizDatabase.memory();

    Hive.init('./test_hive_temp_p6');
    if (!Hive.isBoxOpen(HiveBoxes.settings)) {
      settingsBox = await Hive.openBox<dynamic>(HiveBoxes.settings);
    } else {
      settingsBox = Hive.box<dynamic>(HiveBoxes.settings);
    }
    await settingsBox.clear();

    // Seed active master currencies per company
    final currencyRepoA = CurrencyRepositoryImpl(
      accountingDb,
      readCompanyId: () => companyA,
    );
    await currencyRepoA.upsert(
      const CurrencyDraft(
        code: 'YER',
        nameAr: 'ريال يمني',
        nameEn: 'Yemeni Rial',
        symbol: 'ر.ي',
        decimalDigits: 2,
        isDefault: true,
        isActive: true,
      ),
    );
    await currencyRepoA.upsert(
      const CurrencyDraft(
        code: 'SAR',
        nameAr: 'ريال سعودي',
        nameEn: 'Saudi Riyal',
        symbol: 'ر.س',
        decimalDigits: 2,
        isActive: true,
      ),
    );

    final currencyRepoB = CurrencyRepositoryImpl(
      accountingDb,
      readCompanyId: () => companyB,
    );
    await currencyRepoB.upsert(
      const CurrencyDraft(
        code: 'SAR',
        nameAr: 'ريال سعودي',
        nameEn: 'Saudi Riyal',
        symbol: 'ر.س',
        decimalDigits: 2,
        isDefault: true,
        isActive: true,
      ),
    );
    await currencyRepoB.upsert(
      const CurrencyDraft(
        code: 'YER',
        nameAr: 'ريال يمني',
        nameEn: 'Yemeni Rial',
        symbol: 'ر.ي',
        decimalDigits: 2,
        isActive: true,
      ),
    );

    final settingsRepo = SettingsRepository(box: settingsBox);
    final funcCurrencyServiceA = FunctionalCurrencyService(
      settingsRepository: settingsRepo,
      currencyRepository: currencyRepoA,
      db: accountingDb,
    );
    await funcCurrencyServiceA.setFunctionalCurrency('YER', companyA);

    final funcCurrencyServiceB = FunctionalCurrencyService(
      settingsRepository: settingsRepo,
      currencyRepository: currencyRepoB,
      db: accountingDb,
    );
    await funcCurrencyServiceB.setFunctionalCurrency('SAR', companyB);

    initRepoCompanyA = CompanyInitializationRepositoryImpl(
      box: settingsBox,
      readCompanyId: () => companyA,
    );

    initRepoCompanyB = CompanyInitializationRepositoryImpl(
      box: settingsBox,
      readCompanyId: () => companyB,
    );

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now();

    // Seed Accounts for Company A (Base: YER)
    await accountingDb
        .into(accountingDb.accounts)
        .insert(
          AccountsCompanion.insert(
            id: const Value('10000000-0000-4000-8000-0000000000a1'),
            accountCode: '1230-A',
            name: 'Inventory Acc Company A',
            accountType: 'asset',
            normalBalance: 'debit',
            companyId: companyA,
            createdAt: Value(now),
            updatedAt: Value(now),
            isGroup: const Value(false),
            isActive: const Value(true),
          ),
        );
    await accountingDb
        .into(accountingDb.accounts)
        .insert(
          AccountsCompanion.insert(
            id: const Value('10000000-0000-4000-8000-0000000000a2'),
            accountCode: '5100-A',
            name: 'COGS Acc Company A',
            accountType: 'expense',
            normalBalance: 'debit',
            companyId: companyA,
            createdAt: Value(now),
            updatedAt: Value(now),
            isGroup: const Value(false),
            isActive: const Value(true),
          ),
        );
    await accountingDb
        .into(accountingDb.accounts)
        .insert(
          AccountsCompanion.insert(
            id: const Value('10000000-0000-4000-8000-0000000000a3'),
            accountCode: '2110-A',
            name: 'Payable Acc Company A',
            accountType: 'liability',
            normalBalance: 'credit',
            companyId: companyA,
            createdAt: Value(now),
            updatedAt: Value(now),
            isGroup: const Value(false),
            isActive: const Value(true),
          ),
        );

    // Save Setup Configs for Company A
    await initRepoCompanyA.saveInventoryConfig(
      const CompanyInventoryConfig(
        companyId: companyA,
        inventoryBaseCurrencyId: 'YER',
      ),
    );
    await initRepoCompanyA.saveAccountingConfig(
      const CompanyAccountingConfig(
        companyId: companyA,
        accountMappings: {
          AccountRole.inventory: '10000000-0000-4000-8000-0000000000a1',
          AccountRole.cogs: '10000000-0000-4000-8000-0000000000a2',
          AccountRole.payable: '10000000-0000-4000-8000-0000000000a3',
        },
      ),
    );

    // Seed Accounts for Company B (Base: SAR)
    await accountingDb
        .into(accountingDb.accounts)
        .insert(
          AccountsCompanion.insert(
            id: const Value('20000000-0000-4000-8000-0000000000b1'),
            accountCode: '1230-B',
            name: 'Inventory Acc Company B',
            accountType: 'asset',
            normalBalance: 'debit',
            companyId: companyB,
            createdAt: Value(now),
            updatedAt: Value(now),
            isGroup: const Value(false),
            isActive: const Value(true),
          ),
        );
    await accountingDb
        .into(accountingDb.accounts)
        .insert(
          AccountsCompanion.insert(
            id: const Value('20000000-0000-4000-8000-0000000000b2'),
            accountCode: '5100-B',
            name: 'COGS Acc Company B',
            accountType: 'expense',
            normalBalance: 'debit',
            companyId: companyB,
            createdAt: Value(now),
            updatedAt: Value(now),
            isGroup: const Value(false),
            isActive: const Value(true),
          ),
        );
    await accountingDb
        .into(accountingDb.accounts)
        .insert(
          AccountsCompanion.insert(
            id: const Value('20000000-0000-4000-8000-0000000000b3'),
            accountCode: '2110-B',
            name: 'Payable Acc Company B',
            accountType: 'liability',
            normalBalance: 'credit',
            companyId: companyB,
            createdAt: Value(now),
            updatedAt: Value(now),
            isGroup: const Value(false),
            isActive: const Value(true),
          ),
        );

    // Save Setup Configs for Company B
    await initRepoCompanyB.saveInventoryConfig(
      const CompanyInventoryConfig(
        companyId: companyB,
        inventoryBaseCurrencyId: 'SAR',
      ),
    );
    await initRepoCompanyB.saveAccountingConfig(
      const CompanyAccountingConfig(
        companyId: companyB,
        accountMappings: {
          AccountRole.inventory: '20000000-0000-4000-8000-0000000000b1',
          AccountRole.cogs: '20000000-0000-4000-8000-0000000000b2',
          AccountRole.payable: '20000000-0000-4000-8000-0000000000b3',
        },
      ),
    );

    // Seed default warehouse accounting bindings for Company A and Company B

    await accountingDb.into(accountingDb.warehouseAccountingBindings).insert(
      WarehouseAccountingBindingsCompanion.insert(
        id: const Value('10000000-0000-4000-8000-0000000000wb'),
        warehouseId: whA,
        companyId: companyA,
        inventoryAssetAccountId: const Value('10000000-0000-4000-8000-0000000000a1'),
        cogsAccountId: const Value('10000000-0000-4000-8000-0000000000a2'),
        inventoryAdjustmentAccountId: const Value('10000000-0000-4000-8000-0000000000a2'),
        createdAt: nowMs,
        updatedAt: nowMs,
      ),
    );

    await accountingDb.into(accountingDb.warehouseAccountingBindings).insert(
      WarehouseAccountingBindingsCompanion.insert(
        id: const Value('20000000-0000-4000-8000-0000000000wb'),
        warehouseId: whB,
        companyId: companyB,
        inventoryAssetAccountId: const Value('20000000-0000-4000-8000-0000000000b1'),
        cogsAccountId: const Value('20000000-0000-4000-8000-0000000000b2'),
        inventoryAdjustmentAccountId: const Value('20000000-0000-4000-8000-0000000000b2'),
        createdAt: nowMs,
        updatedAt: nowMs,
      ),
    );
  });

  tearDown(() async {
    await accountingDb.close();
    await settingsBox.clear();
  });

  InventoryAccountingPosterImpl createPoster(String compId) {
    final periodValidator = legacyPeriodValidator();
    final accountRepo = AccountRepositoryImpl(
      accountingDb,
      readCompanyId: () => compId,
    );
    final journalRepo = JournalRepositoryImpl(
      accountingDb,
      accounts: accountRepo,
      periodValidator: periodValidator,
      readCompanyId: () => compId,
    );
    final journalPostingService = JournalPostingService(
      journals: journalRepo,
      periodValidator: periodValidator,
    );
    final bindingRepo = WarehouseAccountingBindingRepositoryImpl(
      accountingDb,
      () => compId,
    );
    final settingsRepo = SettingsRepository(box: settingsBox);
    final currencyRepo = CurrencyRepositoryImpl(
      accountingDb,
      readCompanyId: () => compId,
    );
    final funcCurrencyService = FunctionalCurrencyService(
      settingsRepository: settingsRepo,
      currencyRepository: currencyRepo,
      db: accountingDb,
    );

    final journalBuilder = JournalBuilderImpl(
      accountRepository: accountRepo,
      currencyRateRepository: CurrencyRateRepositoryImpl(accountingDb),
      bindingRepo: bindingRepo,
      readCompanyId: () => compId,
      initRepository: compId == companyA ? initRepoCompanyA : initRepoCompanyB,
      functionalCurrencyService: funcCurrencyService,
    );
    return InventoryAccountingPosterImpl(
      journalPostingService,
      journalBuilder: journalBuilder,
    );
  }

  group(
    'Phase 6 — Connect Inventory & Accounting to Company Configuration Tests',
    () {
      test(
        '1. Multi-Company Posting: Company A (YER) uses exact Company A configured accounts & currency',
        () async {
          final posterCompanyA = createPoster(companyA);

          final docRef = InventoryDocumentRef(
            documentId: 'doc-receipt-A',
            documentNumber: 'REC-A-001',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: DateTime.now(),
            warehouseId: whA,
            status: InventoryDocumentStatus.posted,
            currencyCode: 'YER',
            exchangeRate: 1.0,
          );

          await posterCompanyA.postAccountingEntry(
            document: docRef,
            totalAmount: 5000.0,
            accountId: '10000000-0000-4000-8000-0000000000a3',
          );

          // Verify journal entry header
          final entries = await (accountingDb.select(
            accountingDb.journalEntries,
          )..where((t) => t.companyId.equals(companyA))).get();

          expect(entries.length, equals(1));
          expect(entries.first.currencyCode, equals('YER'));

          // Verify journal lines
          final lines = await (accountingDb.select(
            accountingDb.journalLines,
          )..where((t) => t.entryId.equals(entries.first.id))).get();

          expect(lines.length, equals(2));

          final debitLine = lines.firstWhere((l) => l.debit > 0);
          final creditLine = lines.firstWhere((l) => l.credit > 0);

          // Debit should be Company A Inventory account
          expect(
            debitLine.accountId,
            equals('10000000-0000-4000-8000-0000000000a1'),
          );
          expect(debitLine.debit, equals(5000.0));

          // Credit should be Company A Payable account
          expect(
            creditLine.accountId,
            equals('10000000-0000-4000-8000-0000000000a3'),
          );
          expect(creditLine.credit, equals(5000.0));
        },
      );

      test(
        '2. Multi-Company Posting: Company B (SAR) uses exact Company B configured accounts & currency',
        () async {
          final posterCompanyB = createPoster(companyB);

          final docRef = InventoryDocumentRef(
            documentId: 'doc-issue-B',
            documentNumber: 'ISS-B-001',
            documentType: InventoryDocumentType.stockIssue,
            documentDate: DateTime.now(),
            warehouseId: whB,
            status: InventoryDocumentStatus.posted,
            currencyCode: 'SAR',
            exchangeRate: 1.0,
          );

          await posterCompanyB.postAccountingEntry(
            document: docRef,
            totalAmount: 1200.0,
          );

          // Verify journal entry header
          final entries = await (accountingDb.select(
            accountingDb.journalEntries,
          )..where((t) => t.companyId.equals(companyB))).get();

          expect(entries.length, equals(1));
          expect(entries.first.currencyCode, equals('SAR'));

          // Verify journal lines
          final lines = await (accountingDb.select(
            accountingDb.journalLines,
          )..where((t) => t.entryId.equals(entries.first.id))).get();

          expect(lines.length, equals(2));

          final debitLine = lines.firstWhere((l) => l.debit > 0);
          final creditLine = lines.firstWhere((l) => l.credit > 0);

          // Debit should be Company B COGS account
          expect(
            debitLine.accountId,
            equals('20000000-0000-4000-8000-0000000000b2'),
          );
          expect(debitLine.debit, equals(1200.0));

          // Credit should be Company B Inventory account
          expect(
            creditLine.accountId,
            equals('20000000-0000-4000-8000-0000000000b1'),
          );
          expect(creditLine.credit, equals(1200.0));
        },
      );

      test(
        '3. Exact Currency Conversion Test (100 SAR * 145 = 14,500 YER base cost)',
        () async {
          final posterCompanyA = createPoster(companyA);

          final docRef = InventoryDocumentRef(
            documentId: 'doc-receipt-fx',
            documentNumber: 'REC-FX-001',
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: DateTime.now(),
            warehouseId: whA,
            status: InventoryDocumentStatus.posted,
            currencyCode: 'SAR',
            exchangeRate: 145.0,
          );

          await posterCompanyA.postAccountingEntry(
            document: docRef,
            totalAmount: 100.0,
            accountId: '10000000-0000-4000-8000-0000000000a3',
          );

          final entries = await (accountingDb.select(
            accountingDb.journalEntries,
          )..where((t) => t.voucherNumber.equals('REC-FX-001'))).get();

          expect(entries.length, equals(1));
          expect(entries.first.currencyCode, equals('SAR'));

          final lines = await (accountingDb.select(
            accountingDb.journalLines,
          )..where((t) => t.entryId.equals(entries.first.id))).get();

          expect(lines.length, equals(2));

          final debitLine = lines.firstWhere((l) => l.debit > 0);
          final creditLine = lines.firstWhere((l) => l.credit > 0);

          // Inventory debit line is in Inventory Valuation Currency (YER = 14,500 YER)
          expect(debitLine.debit, equals(14500.0));
          expect(debitLine.currencyCode, equals('YER'));
          // Payable credit line is in Document Currency (SAR = 100 SAR)
          expect(creditLine.credit, equals(100.0));
          expect(creditLine.currencyCode, equals('SAR'));

          // Base amounts converted at 145 exchange rate = 14,500 YER
          expect(debitLine.baseDebit, equals(14500.0));
          expect(creditLine.baseCredit, equals(14500.0));
          expect(creditLine.exchangeRateToBase, equals(145.0));
        },
      );

      test(
        '4. Accounting Integrity Invariant: Sum(Debit) == Sum(Credit)',
        () async {
          final posterCompanyA = createPoster(companyA);

          await posterCompanyA.postAccountingEntry(
            document: InventoryDocumentRef(
              documentId: 'doc-bal-1',
              documentNumber: 'REC-BAL-01',
              documentType: InventoryDocumentType.stockReceipt,
              documentDate: DateTime.now(),
              warehouseId: whA,
              status: InventoryDocumentStatus.posted,
              currencyCode: 'SAR',
              exchangeRate: 145.0,
            ),
            totalAmount: 350.0,
            accountId: '10000000-0000-4000-8000-0000000000a3',
          );

          final allLines = await accountingDb
              .select(accountingDb.journalLines)
              .get();
          final totalBaseDebit = allLines.fold<double>(
            0.0,
            (sum, l) => sum + l.baseDebit,
          );
          final totalBaseCredit = allLines.fold<double>(
            0.0,
            (sum, l) => sum + l.baseCredit,
          );

          expect(totalBaseDebit, equals(totalBaseCredit));
        },
      );
    },
  );
}
