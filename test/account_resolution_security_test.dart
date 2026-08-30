import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_accounting_poster_impl.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'helpers/journal_posting_test_helper.dart';

void main() {
  late AccountingDatabase db;
  late AccountRepositoryImpl accountRepo;
  late JournalRepositoryImpl journalRepo;
  late JournalPostingService postingService;
  late InventoryAccountingPosterImpl poster;

  late String companyA;
  late String companyB;
  late String activeCompanyId;

  late String compA_inventoryUuid;
  late String compA_cogsUuid;
  late String compB_inventoryUuid;
  late String compA_groupUuid;
  late String compA_inactiveUuid;

  setUp(() async {
    db = AccountingDatabase(executor: NativeDatabase.memory());
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

    poster = InventoryAccountingPosterImpl(
      db,
      journalPostingService: postingService,
      readCompanyId: () => activeCompanyId,
    );

    // Seed test accounts for Company A
    compA_inventoryUuid = generateUuidV4();
    compA_cogsUuid = generateUuidV4();
    compA_groupUuid = generateUuidV4();
    compA_inactiveUuid = generateUuidV4();

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    // Company A: Active leaf accounts
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            uuid: compA_inventoryUuid,
            companyId: Value(companyA),
            accountCode: '1230',
            name: 'مخزون بضائع أ',
            accountType: 'asset',
            normalBalance: 'debit',
            level: const Value(1),
            isGroup: const Value(false),
            isActive: const Value(true),
            description: const Value('system:inventory'),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );

    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            uuid: compA_cogsUuid,
            companyId: Value(companyA),
            accountCode: '5100',
            name: 'تكلفة المبيعات أ',
            accountType: 'expense',
            normalBalance: 'debit',
            level: const Value(1),
            isGroup: const Value(false),
            isActive: const Value(true),
            description: const Value('system:cost_of_goods'),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );

    // Company A: Group account
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            uuid: compA_groupUuid,
            companyId: Value(companyA),
            accountCode: '1000',
            name: 'الأصول أ',
            accountType: 'asset',
            normalBalance: 'debit',
            level: const Value(0),
            isGroup: const Value(true),
            isActive: const Value(true),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );

    // Company A: Inactive account
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            uuid: compA_inactiveUuid,
            companyId: Value(companyA),
            accountCode: '1239',
            name: 'مخزون تالف أ (غير نشط)',
            accountType: 'asset',
            normalBalance: 'debit',
            level: const Value(1),
            isGroup: const Value(false),
            isActive: const Value(false),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );

    // Seed test accounts for Company B
    compB_inventoryUuid = generateUuidV4();
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            uuid: compB_inventoryUuid,
            companyId: Value(companyB),
            accountCode: '1230-B',
            name: 'مخزون بضائع ب',
            accountType: 'asset',
            normalBalance: 'debit',
            level: const Value(1),
            isGroup: const Value(false),
            isActive: const Value(true),
            description: const Value('system:inventory'),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('Account Resolution Security Tests', () {
    test('1. Non-existent account requested -> fails, 0 journal entries created', () async {
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
        throwsA(isA<StateError>()),
      );

      final entries = await db.select(db.journalEntries).get();
      expect(entries.length, equals(0));
    });

    test('2. Cross-Company Account (Company A requests Company B account) -> fails, 0 journal entries created', () async {
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
          accountId: compB_inventoryUuid,
        ),
        throwsA(isA<StateError>()),
      );

      final entries = await db.select(db.journalEntries).get();
      expect(entries.length, equals(0));
    });

    test('3. Unvalidated 36-char string UUID -> fails, 0 journal entries created', () async {
      final fakeUuid36 = '12345678-1234-1234-1234-123456789012'; // 36 chars but does not exist in DB
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
        throwsA(isA<StateError>()),
      );

      final entries = await db.select(db.journalEntries).get();
      expect(entries.length, equals(0));
    });

    test('4. Group Account specified -> fails, 0 journal entries created', () async {
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
          accountId: compA_groupUuid,
        ),
        throwsA(isA<StateError>()),
      );

      final entries = await db.select(db.journalEntries).get();
      expect(entries.length, equals(0));
    });

    test('5. Inactive Account specified -> fails, 0 journal entries created', () async {
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
          accountId: compA_inactiveUuid,
        ),
        throwsA(isA<StateError>()),
      );

      final entries = await db.select(db.journalEntries).get();
      expect(entries.length, equals(0));
    });

    test('6. Account resolution by Code -> Company A picks ONLY Company A account', () async {
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

      final lines = await (db.select(db.journalLines)
            ..where((l) => l.entryUuid.equals(entries.first.uuid)))
          .get();
      expect(lines.length, equals(2));

      final accountUuids = lines.map((l) => l.accountUuid).toList();
      // Must contain Company A's inventory account, NOT Company B's
      expect(accountUuids, contains(compA_inventoryUuid));
      expect(accountUuids, isNot(contains(compB_inventoryUuid)));
    });

    test('7. No arbitrary fallback / No limit(1) when code is missing -> fails', () async {
      // Delete Company A's COGS account ('5100')
      await (db.delete(db.accounts)..where((t) => t.uuid.equals(compA_cogsUuid))).go();

      final doc = InventoryDocumentRef(
        documentId: generateUuidV4(),
        documentNumber: 'ISS-007',
        documentType: InventoryDocumentType.stockIssue,
        documentDate: DateTime.now(),
      );

      // Stock issue requires cost_of_goods account ('5100'). Since it was deleted and no accountId is specified,
      // the system MUST NOT arbitrarily pick compA_inventoryUuid via limit(1). It MUST fail!
      expect(
        () async => poster.postAccountingEntry(
          document: doc,
          totalAmount: 750.0,
          accountId: null,
        ),
        throwsA(isA<StateError>()),
      );

      final entries = await db.select(db.journalEntries).get();
      expect(entries.length, equals(0));
    });

    test('8. Valid Company A account resolution -> posts correctly with scoped companyId', () async {
      final doc = InventoryDocumentRef(
        documentId: generateUuidV4(),
        documentNumber: 'REC-008',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
      );

      await poster.postAccountingEntry(
        document: doc,
        totalAmount: 1200.0,
        accountId: compA_inventoryUuid,
      );

      final entries = await db.select(db.journalEntries).get();
      expect(entries.length, equals(1));
      expect(entries.first.companyId, equals(companyA));
      expect(entries.first.voucherNumber, equals('REC-008'));
    });
  });
}
