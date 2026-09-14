import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_accounting_poster_impl.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/journals/data/services/journal_builder_impl.dart';
import 'package:stock_count/modules/currency/data/repositories/currency_rate_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/warehouse_accounting_binding_repository_impl.dart';
import 'package:stock_count/shared/contracts/errors/account_exception.dart';
import 'helpers/journal_posting_test_helper.dart';

void main() {
  late NexabizDatabase db;
  late AccountRepositoryImpl accountRepo;
  late JournalRepositoryImpl journalRepo;
  late JournalPostingService postingService;
  late InventoryAccountingPosterImpl poster;

  late String companyA;
  late String companyB;
  late String activeCompanyId;

  late String compAInventoryUuid;
  late String compACogsUuid;
  late String compBInventoryUuid;
  late String compAGroupUuid;
  late String compAInactiveUuid;

  setUp(() async {
    db = NexabizDatabase.memory();
    companyA = 'company_A';
    companyB = 'company_B';
    activeCompanyId = companyA;

    accountRepo = AccountRepositoryImpl(
      db,
      readCompanyId: () => activeCompanyId,
    );

    journalRepo = JournalRepositoryImpl(
      db,
      accounts: accountRepo,
      periodValidator: legacyPeriodValidator(),
      readCompanyId: () => activeCompanyId,
    );

    postingService = JournalPostingService(
      journals: journalRepo,
      periodValidator: legacyPeriodValidator(),
    );

    final bindingRepo = WarehouseAccountingBindingRepositoryImpl(
      db,
      () => activeCompanyId,
    );

    final journalBuilder = JournalBuilderImpl(
      accountRepository: accountRepo,
      currencyRateRepository: CurrencyRateRepositoryImpl(db),
      bindingRepo: bindingRepo,
      readCompanyId: () => activeCompanyId,
    );

    poster = InventoryAccountingPosterImpl(
      postingService,
      journalBuilder: journalBuilder,
      readCompanyId: () => activeCompanyId,
    );

    // Seed test accounts for Company A
    compAInventoryUuid = generateUuidV4();
    compACogsUuid = generateUuidV4();
    compAGroupUuid = generateUuidV4();
    compAInactiveUuid = generateUuidV4();

    final now = DateTime.now().toUtc();
    final nowMs = now.millisecondsSinceEpoch;

    // Company A: Active leaf accounts
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: Value(compAInventoryUuid),
            companyId: companyA,
            accountCode: '1230',
            name: 'مخزون بضائع أ',
            accountType: 'asset',
            normalBalance: 'debit',
            level: const Value(1),
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: Value(compACogsUuid),
            companyId: companyA,
            accountCode: '5100',
            name: 'تكلفة المبيعات أ',
            accountType: 'expense',
            normalBalance: 'debit',
            level: const Value(1),
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    // Company A: Group account
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: Value(compAGroupUuid),
            companyId: companyA,
            accountCode: '1000',
            name: 'الأصول أ',
            accountType: 'asset',
            normalBalance: 'debit',
            level: const Value(0),
            isGroup: const Value(true),
            isActive: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    // Company A: Inactive account
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: Value(compAInactiveUuid),
            companyId: companyA,
            accountCode: '1239',
            name: 'مخزون تالف أ (غير نشط)',
            accountType: 'asset',
            normalBalance: 'debit',
            level: const Value(1),
            isGroup: const Value(false),
            isActive: const Value(false),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    // Seed test accounts for Company B
    compBInventoryUuid = generateUuidV4();
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: Value(compBInventoryUuid),
            companyId: companyB,
            accountCode: '1230-B',
            name: 'مخزون بضائع ب',
            accountType: 'asset',
            normalBalance: 'debit',
            level: const Value(1),
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    // Seed Warehouse Accounting Binding for default warehouse under Company A
    await db.into(db.warehouseAccountingBindings).insert(
      WarehouseAccountingBindingsCompanion.insert(
        id: Value(generateUuidV4()),
        warehouseId: '',
        companyId: companyA,
        inventoryAssetAccountId: Value(compAInventoryUuid),
        cogsAccountId: Value(compACogsUuid),
        inventoryAdjustmentAccountId: Value(compACogsUuid),
        createdAt: nowMs,
        updatedAt: nowMs,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Account Resolution Security Tests', () {
    test(
      '1. Non-existent account requested -> fails, 0 journal entries created',
      () async {
        final doc = InventoryDocumentRef(
          documentId: generateUuidV4(),
          documentNumber: 'REC-001',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now(),
        );

        expect(
          () async => poster.postAccountingEntry(
            document: doc,
            totalAmount: 500.0,
            accountId: 'non_existent_account_uuid',
          ),
          throwsA(isA<MissingAccountException>()),
        );

        final entries = await db.select(db.journalEntries).get();
        expect(entries.length, equals(0));
      },
    );

    test(
      '2. Cross-Company Account (Company A requests Company B account) -> fails, 0 journal entries created',
      () async {
        final doc = InventoryDocumentRef(
          documentId: generateUuidV4(),
          documentNumber: 'REC-002',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now(),
        );

        // Active company is Company A, but we try to resolve Company B's inventory account UUID
        expect(
          () async => poster.postAccountingEntry(
            document: doc,
            totalAmount: 500.0,
            accountId: compBInventoryUuid,
          ),
          throwsA(isA<MissingAccountException>()),
        );

        final entries = await db.select(db.journalEntries).get();
        expect(entries.length, equals(0));
      },
    );

    test(
      '3. Unvalidated 36-char string UUID -> fails, 0 journal entries created',
      () async {
        final fakeUuid36 =
            '12345678-1234-1234-1234-123456789012'; // 36 chars but does not exist in DB
        final doc = InventoryDocumentRef(
          documentId: generateUuidV4(),
          documentNumber: 'REC-003',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now(),
        );

        expect(
          () async => poster.postAccountingEntry(
            document: doc,
            totalAmount: 500.0,
            accountId: fakeUuid36,
          ),
          throwsA(isA<MissingAccountException>()),
        );

        final entries = await db.select(db.journalEntries).get();
        expect(entries.length, equals(0));
      },
    );

    test(
      '4. Group Account specified -> fails, 0 journal entries created',
      () async {
        final doc = InventoryDocumentRef(
          documentId: generateUuidV4(),
          documentNumber: 'REC-004',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now(),
        );

        expect(
          () async => poster.postAccountingEntry(
            document: doc,
            totalAmount: 500.0,
            accountId: compAGroupUuid,
          ),
          throwsA(isA<MissingAccountException>()),
        );

        final entries = await db.select(db.journalEntries).get();
        expect(entries.length, equals(0));
      },
    );

    test(
      '5. Inactive Account specified -> fails, 0 journal entries created',
      () async {
        final doc = InventoryDocumentRef(
          documentId: generateUuidV4(),
          documentNumber: 'REC-005',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now(),
        );

        expect(
          () async => poster.postAccountingEntry(
            document: doc,
            totalAmount: 500.0,
            accountId: compAInactiveUuid,
          ),
          throwsA(isA<MissingAccountException>()),
        );

        final entries = await db.select(db.journalEntries).get();
        expect(entries.length, equals(0));
      },
    );

    test(
      '6. Account resolution by Code -> Company A picks ONLY Company A account',
      () async {
        final doc = InventoryDocumentRef(
          documentId: generateUuidV4(),
          documentNumber: 'REC-006',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now(),
        );

        // Post with accountCode '1230' under Company A
        await poster.postAccountingEntry(
          document: doc,
          totalAmount: 1000.0,
          accountId: '1230',
        );

        final entries = await db.select(db.journalEntries).get();
        expect(entries.length, equals(1));
        expect(entries.first.companyId, equals(companyA));

        final lines = await (db.select(
          db.journalLines,
        )..where((l) => l.entryId.equals(entries.first.id))).get();
        expect(lines.length, equals(2));

        final accountUuids = lines.map((l) => l.accountId).toList();
        // Must contain Company A's inventory account, NOT Company B's
        expect(accountUuids, contains(compAInventoryUuid));
        expect(accountUuids, isNot(contains(compBInventoryUuid)));
      },
    );

    test(
      '7. No arbitrary fallback / No limit(1) when code is missing -> fails',
      () async {
        // Delete Company A's COGS account ('5100')
        await (db.delete(
          db.accounts,
        )..where((t) => t.id.equals(compACogsUuid))).go();

        // Clear warehouse binding for COGS account to simulate missing configuration
        await (db.update(db.warehouseAccountingBindings)
              ..where((t) => t.companyId.equals(companyA)))
            .write(const WarehouseAccountingBindingsCompanion(
          cogsAccountId: Value(null),
        ));

        final doc = InventoryDocumentRef(
          documentId: generateUuidV4(),
          documentNumber: 'ISS-007',
          documentType: InventoryDocumentType.stockIssue,
          documentDate: DateTime.now(),
        );

        // Stock issue requires cost_of_goods account ('5100'). Since it was deleted and no accountId is specified,
        // the system MUST NOT arbitrarily pick compAInventoryUuid via limit(1). It MUST fail!
        expect(
          () async => poster.postAccountingEntry(
            document: doc,
            totalAmount: 750.0,
            accountId: null,
          ),
          throwsA(isA<MissingAccountException>()),
        );

        final entries = await db.select(db.journalEntries).get();
        expect(entries.length, equals(0));
      },
    );

    test(
      '8. Valid Company A account resolution -> posts correctly with scoped companyId',
      () async {
        final doc = InventoryDocumentRef(
          documentId: generateUuidV4(),
          documentNumber: 'REC-008',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now(),
        );

        await poster.postAccountingEntry(
          document: doc,
          totalAmount: 1200.0,
          accountId: compAInventoryUuid,
        );

        final entries = await db.select(db.journalEntries).get();
        expect(entries.length, equals(1));
        expect(entries.first.companyId, equals(companyA));
        expect(entries.first.voucherNumber, equals('REC-008'));
      },
    );
  });
}
