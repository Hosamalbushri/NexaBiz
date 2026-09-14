import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/inventory/inventory_accounting_poster_adapter.dart';
import 'package:stock_count/shared/contracts/errors/account_exception.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/warehouse_accounting_binding_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/data/services/warehouse_accounting_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/warehouse_accounting_binding.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/services/warehouse_accounting_validation_service.dart';

void main() {
  late NexabizDatabase inventoryDb;
  late NexabizDatabase accountingDb;
  late String currentCompanyId;
  late WarehouseAccountingBindingRepositoryImpl bindingRepo;
  late WarehouseAccountingValidationServiceImpl validationService;
  late InventoryAccountingPosterAdapter poster;

  setUp(() async {
    inventoryDb = NexabizDatabase.memory();
    accountingDb = NexabizDatabase.memory();
    currentCompanyId = 'company_in04_test';

    bindingRepo = WarehouseAccountingBindingRepositoryImpl(
      inventoryDb,
      () => currentCompanyId,
    );

    validationService = WarehouseAccountingValidationServiceImpl(
      accountingDb: accountingDb,
    );

    poster = InventoryAccountingPosterAdapter(
      accountingDb,
      readCompanyId: () => currentCompanyId,
      bindingRepo: bindingRepo,
      validationService: validationService,
    );
  });

  tearDown(() async {
    await inventoryDb.close();
    await accountingDb.close();
  });

  Future<void> insertTestAccount({
    required String uuid,
    required String code,
    required String name,
    required String type,
    bool isActive = true,
    bool isGroup = false,
    String? companyId,
    int? deletedAt,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await accountingDb
        .into(accountingDb.accounts)
        .insert(
          AccountsCompanion.insert(
            id: uuid,
            accountCode: code,
            name: name,
            accountType: type,
            normalBalance: type == 'asset' || type == 'expense'
                ? 'debit'
                : 'credit',
            isActive: Value(isActive),
            isGroup: Value(isGroup),
            companyId: Value(companyId ?? currentCompanyId),
            createdAt: now,
            updatedAt: now,
            deletedAt: Value(deletedAt),
          ),
        );
  }

  group('IN-04 — Warehouse Accounting Binding Architecture Tests', () {
    test(
      '1. Valid warehouse binding resolves correct inventory asset account for receipt',
      () async {
        final whId = generateUuidV4();
        final assetAccUuid = generateUuidV4();
        final payableAccUuid = generateUuidV4();

        await insertTestAccount(
          uuid: assetAccUuid,
          code: '1201',
          name: 'مخزون مستودع أ',
          type: 'asset',
        );
        await insertTestAccount(
          uuid: payableAccUuid,
          code: '2101',
          name: 'حساب الموردين',
          type: 'liability',
        );

        await bindingRepo.saveBinding(
          WarehouseAccountingBinding(
            id: generateUuidV4(),
            warehouseId: whId,
            inventoryAssetAccountId: assetAccUuid,
            companyId: currentCompanyId,
          ),
        );

        final doc = InventoryDocumentRef(
          documentId: generateUuidV4(),
          documentNumber: 'REC-IN04-1',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now().toUtc(),
          status: InventoryDocumentStatus.posted,
          warehouseId: whId,
        );

        await poster.postAccountingEntry(
          document: doc,
          totalAmount: 1000.0,
          accountId: payableAccUuid,
        );

        final entries = await accountingDb
            .select(accountingDb.journalEntries)
            .get();
        expect(entries.length, equals(1));

        final lines = await (accountingDb.select(
          accountingDb.journalLines,
        )..where((tbl) => tbl.entryId.equals(entries.first.uuid))).get();
        expect(lines.length, equals(2));

        final debitLine = lines.firstWhere((l) => l.debit > 0);
        final creditLine = lines.firstWhere((l) => l.credit > 0);

        expect(debitLine.accountId, equals(assetAccUuid));
        expect(debitLine.debit, equals(1000.0));
        expect(creditLine.accountId, equals(payableAccUuid));
        expect(creditLine.credit, equals(1000.0));
      },
    );

    test(
      '2. Missing binding or account throws MissingAccountException and blocks posting',
      () async {
        final doc = InventoryDocumentRef(
          documentId: generateUuidV4(),
          documentNumber: 'REC-MISSING',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now().toUtc(),
          status: InventoryDocumentStatus.posted,
          warehouseId: 'WH-UNBOUND',
        );

        expect(
          () => poster.postAccountingEntry(document: doc, totalAmount: 500.0),
          throwsA(isA<MissingAccountException>()),
        );
      },
    );

    test(
      '3. Inactive account in warehouse binding is rejected by validation service',
      () async {
        final whId = generateUuidV4();
        final inactiveAccUuid = generateUuidV4();

        await insertTestAccount(
          uuid: inactiveAccUuid,
          code: '1209',
          name: 'مخزون معطل',
          type: 'asset',
          isActive: false,
        );

        await bindingRepo.saveBinding(
          WarehouseAccountingBinding(
            id: generateUuidV4(),
            warehouseId: whId,
            inventoryAssetAccountId: inactiveAccUuid,
            companyId: currentCompanyId,
          ),
        );

        final doc = InventoryDocumentRef(
          documentId: generateUuidV4(),
          documentNumber: 'REC-INACTIVE',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now().toUtc(),
          status: InventoryDocumentStatus.posted,
          warehouseId: whId,
        );

        expect(
          () => poster.postAccountingEntry(document: doc, totalAmount: 100.0),
          throwsA(isA<MissingAccountException>()),
        );
      },
    );

    test(
      '4. Group account or wrong account type in binding is rejected',
      () async {
        final whId = generateUuidV4();
        final groupAccUuid = generateUuidV4();

        await insertTestAccount(
          uuid: groupAccUuid,
          code: '1200',
          name: 'مجموعة المخزون الرئيسية',
          type: 'asset',
          isGroup: true,
        );

        await bindingRepo.saveBinding(
          WarehouseAccountingBinding(
            id: generateUuidV4(),
            warehouseId: whId,
            inventoryAssetAccountId: groupAccUuid,
            companyId: currentCompanyId,
          ),
        );

        final doc = InventoryDocumentRef(
          documentId: generateUuidV4(),
          documentNumber: 'REC-GROUP',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.now().toUtc(),
          status: InventoryDocumentStatus.posted,
          warehouseId: whId,
        );

        expect(
          () => poster.postAccountingEntry(document: doc, totalAmount: 150.0),
          throwsA(isA<MissingAccountException>()),
        );
      },
    );

    test(
      '5. Cross-company account reference is rejected (tenant isolation)',
      () async {
        final accUuid = generateUuidV4();
        await insertTestAccount(
          uuid: accUuid,
          code: '1201',
          name: 'مخزون الشركة أ',
          type: 'asset',
          companyId: currentCompanyId,
        );

        final valRes = await validationService.validateAccount(
          accountIdOrCode: '1201',
          role: AccountRole.inventory,
          companyId: 'company_OTHER',
        );

        expect(valRes, isA<WarehouseAccountingValidationFailure>());
        final failure = valRes as WarehouseAccountingValidationFailure;
        expect(failure.reason, contains('تابع لشركة أخرى'));
      },
    );

    test(
      '6. Historical transactions retain original account references when binding changes',
      () async {
        final whId = generateUuidV4();
        final oldAssetUuid = generateUuidV4();
        final newAssetUuid = generateUuidV4();
        final payableUuid = generateUuidV4();

        await insertTestAccount(
          uuid: oldAssetUuid,
          code: '1201',
          name: 'مخزون قديم',
          type: 'asset',
        );
        await insertTestAccount(
          uuid: newAssetUuid,
          code: '1202',
          name: 'مخزون جديد',
          type: 'asset',
        );
        await insertTestAccount(
          uuid: payableUuid,
          code: '2101',
          name: 'موردين',
          type: 'liability',
        );

        // Bind old asset account
        await bindingRepo.saveBinding(
          WarehouseAccountingBinding(
            id: generateUuidV4(),
            warehouseId: whId,
            inventoryAssetAccountId: oldAssetUuid,
            companyId: currentCompanyId,
          ),
        );

        // Post historical document
        final docHist = InventoryDocumentRef(
          documentId: 'DOC-HIST-001',
          documentNumber: 'REC-HIST-1',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.utc(2026, 1, 1),
          status: InventoryDocumentStatus.posted,
          warehouseId: whId,
        );
        await poster.postAccountingEntry(
          document: docHist,
          totalAmount: 500.0,
          accountId: payableUuid,
        );

        // Update binding to new asset account
        await bindingRepo.saveBinding(
          WarehouseAccountingBinding(
            id: generateUuidV4(),
            warehouseId: whId,
            inventoryAssetAccountId: newAssetUuid,
            companyId: currentCompanyId,
          ),
        );

        // Post new document
        final docNew = InventoryDocumentRef(
          documentId: 'DOC-NEW-001',
          documentNumber: 'REC-NEW-1',
          documentType: InventoryDocumentType.stockReceipt,
          documentDate: DateTime.utc(2026, 2, 1),
          status: InventoryDocumentStatus.posted,
          warehouseId: whId,
        );
        await poster.postAccountingEntry(
          document: docNew,
          totalAmount: 700.0,
          accountId: payableUuid,
        );

        // Verify historical entry retained oldAssetUuid
        final histEntry = await (accountingDb.select(
          accountingDb.journalEntries,
        )..where((tbl) => tbl.sourceId.equals('DOC-HIST-001'))).getSingle();
        final histLines = await (accountingDb.select(
          accountingDb.journalLines,
        )..where((tbl) => tbl.entryId.equals(histEntry.uuid))).get();
        expect(histLines.any((l) => l.accountId == oldAssetUuid), isTrue);

        // Verify new entry uses newAssetUuid
        final newEntry = await (accountingDb.select(
          accountingDb.journalEntries,
        )..where((tbl) => tbl.sourceId.equals('DOC-NEW-001'))).getSingle();
        final newLines = await (accountingDb.select(
          accountingDb.journalLines,
        )..where((tbl) => tbl.entryId.equals(newEntry.uuid))).get();
        expect(newLines.any((l) => l.accountId == newAssetUuid), isTrue);
      },
    );

    test(
      '7. Stock Transfer between warehouses with SAME asset account is value-neutral',
      () async {
        final whA = generateUuidV4();
        final whB = generateUuidV4();
        final sharedAssetUuid = generateUuidV4();

        await insertTestAccount(
          uuid: sharedAssetUuid,
          code: '1201',
          name: 'المخزون العام',
          type: 'asset',
        );

        await bindingRepo.saveBinding(
          WarehouseAccountingBinding(
            id: generateUuidV4(),
            warehouseId: whA,
            inventoryAssetAccountId: sharedAssetUuid,
            companyId: currentCompanyId,
          ),
        );
        await bindingRepo.saveBinding(
          WarehouseAccountingBinding(
            id: generateUuidV4(),
            warehouseId: whB,
            inventoryAssetAccountId: sharedAssetUuid,
            companyId: currentCompanyId,
          ),
        );

        final transferDoc = InventoryDocumentRef(
          documentId: 'TRF-001',
          documentNumber: 'TRF-SAME-ACC',
          documentType: InventoryDocumentType.stockTransfer,
          documentDate: DateTime.now().toUtc(),
          status: InventoryDocumentStatus.posted,
          warehouseId: whA,
          destinationWarehouseId: whB,
        );

        await poster.postAccountingEntry(
          document: transferDoc,
          totalAmount: 1200.0,
        );

        final entries = await accountingDb
            .select(accountingDb.journalEntries)
            .get();
        expect(entries.length, equals(1));
        final entry = entries.first;

        final lines = await (accountingDb.select(
          accountingDb.journalLines,
        )..where((tbl) => tbl.entryId.equals(entry.id))).get();

        // Total debit equals total credit, value neutral
        final totalDebit = lines.fold(0.0, (sum, l) => sum + l.debit);
        final totalCredit = lines.fold(0.0, (sum, l) => sum + l.credit);
        expect(totalDebit, equals(1200.0));
        expect(totalCredit, equals(1200.0));
        expect(lines.every((l) => l.accountId == sharedAssetUuid), isTrue);
      },
    );

    test(
      '8. Stock Transfer between warehouses with DIFFERENT asset accounts is value-neutral (0 revenue/COGS)',
      () async {
        final whA = generateUuidV4();
        final whB = generateUuidV4();
        final assetA = generateUuidV4();
        final assetB = generateUuidV4();

        await insertTestAccount(
          uuid: assetA,
          code: '1201',
          name: 'مخزون أ',
          type: 'asset',
        );
        await insertTestAccount(
          uuid: assetB,
          code: '1202',
          name: 'مخزون ب',
          type: 'asset',
        );

        await bindingRepo.saveBinding(
          WarehouseAccountingBinding(
            id: generateUuidV4(),
            warehouseId: whA,
            inventoryAssetAccountId: assetA,
            companyId: currentCompanyId,
          ),
        );
        await bindingRepo.saveBinding(
          WarehouseAccountingBinding(
            id: generateUuidV4(),
            warehouseId: whB,
            inventoryAssetAccountId: assetB,
            companyId: currentCompanyId,
          ),
        );

        final transferDoc = InventoryDocumentRef(
          documentId: 'TRF-002',
          documentNumber: 'TRF-DIFF-ACC',
          documentType: InventoryDocumentType.stockTransfer,
          documentDate: DateTime.now().toUtc(),
          status: InventoryDocumentStatus.posted,
          warehouseId: whA,
          destinationWarehouseId: whB,
        );

        await poster.postAccountingEntry(
          document: transferDoc,
          totalAmount: 2500.0,
        );

        final entry = await (accountingDb.select(
          accountingDb.journalEntries,
        )..where((tbl) => tbl.sourceId.equals('TRF-002'))).getSingle();

        final lines = await (accountingDb.select(
          accountingDb.journalLines,
        )..where((tbl) => tbl.entryId.equals(entry.id))).get();

        expect(lines.length, equals(2));
        final debitLine = lines.firstWhere((l) => l.debit > 0);
        final creditLine = lines.firstWhere((l) => l.credit > 0);

        // Debit Warehouse B asset, Credit Warehouse A asset
        expect(debitLine.accountId, equals(assetB));
        expect(debitLine.debit, equals(2500.0));
        expect(creditLine.accountId, equals(assetA));
        expect(creditLine.credit, equals(2500.0));
      },
    );

    test(
      '9. Stock Issue posts Dr COGS, Cr Warehouse Inventory Asset',
      () async {
        final whId = generateUuidV4();
        final assetUuid = generateUuidV4();
        final cogsUuid = generateUuidV4();

        await insertTestAccount(
          uuid: assetUuid,
          code: '1201',
          name: 'مخزون أ',
          type: 'asset',
        );
        await insertTestAccount(
          uuid: cogsUuid,
          code: '5101',
          name: 'تكلفة البضاعة',
          type: 'expense',
        );

        await bindingRepo.saveBinding(
          WarehouseAccountingBinding(
            id: generateUuidV4(),
            warehouseId: whId,
            inventoryAssetAccountId: assetUuid,
            cogsAccountId: cogsUuid,
            companyId: currentCompanyId,
          ),
        );

        final issueDoc = InventoryDocumentRef(
          documentId: 'ISS-001',
          documentNumber: 'ISS-TEST-1',
          documentType: InventoryDocumentType.stockIssue,
          documentDate: DateTime.now().toUtc(),
          status: InventoryDocumentStatus.posted,
          warehouseId: whId,
        );

        await poster.postAccountingEntry(
          document: issueDoc,
          totalAmount: 450.0,
        );

        final entry = await (accountingDb.select(
          accountingDb.journalEntries,
        )..where((tbl) => tbl.sourceId.equals('ISS-001'))).getSingle();

        final lines = await (accountingDb.select(
          accountingDb.journalLines,
        )..where((tbl) => tbl.entryId.equals(entry.id))).get();

        final debitLine = lines.firstWhere((l) => l.debit > 0);
        final creditLine = lines.firstWhere((l) => l.credit > 0);

        expect(debitLine.accountId, equals(cogsUuid));
        expect(creditLine.accountId, equals(assetUuid));
      },
    );
  });
}
