import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/authentication/presentation/providers/auth_providers.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/journals/data/services/journal_builder_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_validator.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/fiscal_period_policy.dart';
import 'package:stock_count/modules/accounting/fiscal_years/data/repositories/fiscal_year_repository_impl.dart';
import 'package:stock_count/modules/currency/data/repositories/currency_rate_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/warehouse_accounting_binding_repository_impl.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_accounting_poster_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/inventory/stock_movements/presentation/providers/stock_movements_providers.dart';
import 'package:stock_count/core/utils/id_generator.dart';

class MockAccountingPoster implements InventoryAccountingPoster {
  String? lastPostedDocumentId;
  double? lastPostedTotalAmount;
  bool? lastPostedIsPosted;

  @override
  Future<void> postAccountingEntry({
    required InventoryDocumentRef document,
    required double totalAmount,
    double? valuationAmount,
    String? accountId,
    bool isPosted = true,
    bool useBaseCurrencyForPosting = false,
  }) async {
    lastPostedDocumentId = document.documentId;
    lastPostedTotalAmount = totalAmount;
    lastPostedIsPosted = isPosted;
  }

  @override
  Future<void> setAccountingEntryPostingStatus({
    required InventoryDocumentRef document,
    required bool isPosted,
  }) async {
    lastPostedDocumentId = document.documentId;
    lastPostedIsPosted = isPosted;
  }

  @override
  Future<void> reverseAccountingEntry({
    required InventoryDocumentRef document,
  }) async {
    lastPostedDocumentId = document.documentId;
  }
}

void main() {
  late NexabizDatabase db;
  late NexabizDatabase accountingDb;
  late String activeCompanyId;
  late MockAccountingPoster mockAccountingPoster;
  const whMainId = '00000000-0000-4000-8000-000000000001';

  setUp(() async {
    db = NexabizDatabase.memory();
    accountingDb = NexabizDatabase.memory();
    activeCompanyId = 'COMPANY_A';
    mockAccountingPoster = MockAccountingPoster();
  });

  tearDown(() async {
    await db.close();
    await accountingDb.close();
  });

  Future<InventoryDocumentRef> createDraftReceiptForCompany(
    String receiptUuid,
    String compId, {
    String? explicitAccountId,
  }) async {
    final nowDate = DateTime.now().toUtc();
    final now = nowDate.millisecondsSinceEpoch;
    final recNo = 'REC-$compId-${receiptUuid.substring(0, 6)}';

    // Seed warehouse for compId
    await db.into(db.warehouses).insertOnConflictUpdate(
      WarehousesCompanion.insert(
        id: const Value(whMainId),
        code: 'WH-MAIN',
        name: 'Main Warehouse',
        companyId: compId,
        createdAt: Value(nowDate),
        updatedAt: Value(nowDate),
      ),
    );

    await db
        .into(db.products)
        .insertOnConflictUpdate(
          ProductsCompanion(
            id: const Value('00000000-0000-4000-8000-000000000001'),
            itemCode: const Value('COMP-ITEM-1'),
            name: const Value('Company Test Item'),
            packSize: const Value(1),
            price: const Value(100.0),
            unitCost: const Value(50.0),
            companyId: Value(compId),
            createdAt: Value(nowDate),
            updatedAt: Value(nowDate),
          ),
        );

    await db
        .into(db.stockReceipts)
        .insert(
          StockReceiptsCompanion.insert(
            id: Value(receiptUuid),
            receiptNumber: recNo,
            receiptDate: DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
            currencyCode: 'SAR',
            createdAt: now,
            updatedAt: now,
            status: const Value('draft'),
            companyId: Value(compId),
            accountId: explicitAccountId != null ? Value(explicitAccountId) : const Value.absent(),
          ),
        );

    await db
        .into(db.stockMovementLines)
        .insert(
          StockMovementLinesCompanion.insert(
            id: Value(generateUuidV4()),
            receiptId: Value(receiptUuid),
            movementType: 'receipt',
            itemCode: 'COMP-ITEM-1',
            itemName: 'Company Test Item',
            quantity: const Value(10.0),
            unitCost: const Value(50.0),
            totalCost: const Value(500.0),
            companyId: compId,
          ),
        );

    return InventoryDocumentRef(
      documentId: receiptUuid,
      documentNumber: recNo,
      documentType: InventoryDocumentType.stockReceipt,
      documentDate: DateTime.utc(2026, 1, 1),
      warehouseId: whMainId,
    );
  }

  PostingCoordinator createCoordinatorWithDynamicCompany(
    String Function() getCompanyId, {
    InventoryAccountingPoster? poster,
    PermissionGuard? guard,
  }) {
    final costLayerService = CostLayerServiceImpl(
      db: db,
      readCompanyId: getCompanyId,
    );
    final postingEngine = PostingEngineImpl(
      db,
      costLayerService,
      null,
      getCompanyId,
    );
    final validationService = StockValidationServiceImpl(db, getCompanyId);
    final dependencyDetector = InventoryDependencyDetectorImpl(
      db,
      getCompanyId,
    );

    return PostingCoordinatorImpl(
      db: db,
      stockValidationService: validationService,
      dependencyDetector: dependencyDetector,
      postingEngine: postingEngine,
      permissionGuard: guard ?? CallbackPermissionGuard((codes) => true),
      accountingPoster: poster ?? mockAccountingPoster,
      readCompanyId: getCompanyId,
    );
  }

  group('PostingCoordinator Runtime Context & Multi-Company Regression Tests', () {
    test(
      'Scenario A: Company A active -> Post document A uses Company A',
      () async {
        activeCompanyId = 'COMPANY_A';
        final coordinator = createCoordinatorWithDynamicCompany(
          () => activeCompanyId,
        );

        final docA = await createDraftReceiptForCompany(
          generateUuidV4(),
          'COMPANY_A',
        );
        final res = await coordinator.post(document: docA, userId: 'user_a');

        expect(res, isA<PostSuccess>());

        final auditRows = await db.select(db.inventoryAuditTrail).get();
        expect(auditRows.length, 1);
        expect(auditRows.first.companyId, 'COMPANY_A');
        expect(mockAccountingPoster.lastPostedDocumentId, docA.documentId);
      },
    );

    test(
      'Scenario B: Switch to Company B -> Post document B uses Company B',
      () async {
        activeCompanyId = 'COMPANY_B';
        final coordinator = createCoordinatorWithDynamicCompany(
          () => activeCompanyId,
        );

        final docB = await createDraftReceiptForCompany(
          generateUuidV4(),
          'COMPANY_B',
        );
        final res = await coordinator.post(document: docB, userId: 'user_b');

        expect(res, isA<PostSuccess>());

        final auditRows = await db.select(db.inventoryAuditTrail).get();
        expect(auditRows.length, 1);
        expect(auditRows.first.companyId, 'COMPANY_B');
        expect(mockAccountingPoster.lastPostedDocumentId, docB.documentId);
      },
    );

    test(
      'Scenario C: Attempting to post/unpost document belonging to Company A during Company B session is rejected',
      () async {
        // 1. Post Document A while session is Company A
        activeCompanyId = 'COMPANY_A';
        final coordinatorA = createCoordinatorWithDynamicCompany(
          () => activeCompanyId,
        );
        final docA = await createDraftReceiptForCompany(
          generateUuidV4(),
          'COMPANY_A',
        );
        await coordinatorA.post(document: docA, userId: 'user_a');

        // 2. Switch session to Company B
        activeCompanyId = 'COMPANY_B';
        final coordinatorB = createCoordinatorWithDynamicCompany(
          () => activeCompanyId,
        );

        // 3. Create another document for Company A while session is Company B
        final docAUnposted = await createDraftReceiptForCompany(
          generateUuidV4(),
          'COMPANY_A',
        );

        // 4. Try posting Company A's document while in Company B session
        final postRes = await coordinatorB.post(
          document: docAUnposted,
          userId: 'user_b',
        );
        expect(postRes, isA<PostInvalidStatus>());
        expect(
          (postRes as PostInvalidStatus).reason,
          contains('مستند تابع لشركة أخرى'),
        );

        // 5. Try unposting Company A's already posted document while in Company B session
        final unpostRes = await coordinatorB.unpost(
          document: docA,
          requestedBy: 'user_b',
        );
        expect(unpostRes, isA<UnpostBlockedByDependencies>());
        expect(
          (unpostRes as UnpostBlockedByDependencies).message,
          contains('مستند تابع لشركة أخرى'),
        );
      },
    );

    test(
      'Scenario D: Verified AccountingPoster receives and respects active company context',
      () async {
        activeCompanyId = 'COMPANY_DYNAMIC_XYZ';
        final nowDate = DateTime.now().toUtc();
        final nowMs = nowDate.millisecondsSinceEpoch;
        final invAccUuid = generateUuidV4();
        final offsetAccUuid = generateUuidV4();

        await accountingDb
            .into(accountingDb.accounts)
            .insert(
              AccountsCompanion.insert(
                id: Value(invAccUuid),
                accountCode: '1230',
                name: 'حساب المخزون',
                accountType: 'asset',
                normalBalance: 'debit',
                companyId: 'COMPANY_DYNAMIC_XYZ',
                createdAt: Value(nowDate),
                updatedAt: Value(nowDate),
              ),
            );
        await accountingDb
            .into(accountingDb.accounts)
            .insert(
              AccountsCompanion.insert(
                id: Value(offsetAccUuid),
                accountCode: '2110',
                name: 'حساب الموردين',
                accountType: 'liability',
                normalBalance: 'credit',
                companyId: 'COMPANY_DYNAMIC_XYZ',
                createdAt: Value(nowDate),
                updatedAt: Value(nowDate),
              ),
            );

        await db.into(db.warehouseAccountingBindings).insert(
          WarehouseAccountingBindingsCompanion.insert(
            id: Value(generateUuidV4()),
            warehouseId: whMainId,
            companyId: 'COMPANY_DYNAMIC_XYZ',
            inventoryAssetAccountId: Value(invAccUuid),
            cogsAccountId: Value(offsetAccUuid),
            inventoryAdjustmentAccountId: Value(offsetAccUuid),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );

        final accountRepo = AccountRepositoryImpl(accountingDb, readCompanyId: () => activeCompanyId);
        final fiscalYearRepo = FiscalYearRepositoryImpl(accountingDb, readCompanyId: () => activeCompanyId);
        final periodValidator = AccountingPeriodValidator(
          repository: fiscalYearRepo,
          legacyPolicyReader: () => const FiscalPeriodPolicy(fiscalYearStartMonth: 1),
        );
        final journalRepo = JournalRepositoryImpl(
          accountingDb,
          accounts: accountRepo,
          periodValidator: periodValidator,
          readCompanyId: () => activeCompanyId,
        );
        final postingService = JournalPostingService(
          journals: journalRepo,
          periodValidator: periodValidator,
        );
        final bindingRepo = WarehouseAccountingBindingRepositoryImpl(
          db,
          () => activeCompanyId,
        );
        final journalBuilder = JournalBuilderImpl(
          accountRepository: accountRepo,
          currencyRateRepository: CurrencyRateRepositoryImpl(accountingDb),
          bindingRepo: bindingRepo,
          readCompanyId: () => activeCompanyId,
        );

        final realPoster = InventoryAccountingPosterImpl(
          postingService,
          journalBuilder: journalBuilder,
          readCompanyId: () => activeCompanyId,
        );

        final coordinator = createCoordinatorWithDynamicCompany(
          () => activeCompanyId,
          poster: realPoster,
        );

        final docRef = await createDraftReceiptForCompany(
          generateUuidV4(),
          'COMPANY_DYNAMIC_XYZ',
          explicitAccountId: offsetAccUuid,
        );
        final res = await coordinator.post(
          document: docRef,
          userId: 'user_xyz',
        );

        expect(res, isA<PostSuccess>());
        final entries = await accountingDb
            .select(accountingDb.journalEntries)
            .get();
        expect(entries.length, 1);
        expect(entries.first.companyId, 'COMPANY_DYNAMIC_XYZ');
      },
    );

    test(
      'Scenario E: postingCoordinatorProvider in Riverpod resolves production CallbackPermissionGuard',
      () {
        final container = ProviderContainer(
          overrides: [
            currentCompanyIdProvider.overrideWith((ref) => 'RIVERPOD_COMP_123'),
          ],
        );

        final coordinator = container.read(postingCoordinatorProvider);
        final guard = container.read(permissionGuardProvider);

        expect(coordinator, isA<PostingCoordinatorImpl>());
        expect(guard, isA<CallbackPermissionGuard>());
      },
    );
  });
}
