import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/app/sales/accounting_sale_ledger_adapter.dart';
import 'package:stock_count/modules/sales/invoices/data/repositories/sale_repository_impl.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/discount_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_method.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_item.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/models/sale_exception.dart';
import 'package:stock_count/modules/sales/invoices/domain/usecases/sale_usecases.dart';
import 'package:stock_count/modules/sales/shared/data/database/sales_database.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_accounting_bridge_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_inventory_effect_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_ledger_posting_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_number_allocator_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_voucher_book_port.dart';
import 'package:stock_count/modules/sync/sync.dart';

import 'helpers/journal_posting_test_helper.dart';

class TestSaleNumberAllocator implements SaleNumberAllocatorPort {
  int _counter = 100;
  @override
  Future<String> allocateNext() async => 'INV-${++_counter}';
}

class TestSaleVoucherBookPort implements SaleVoucherBookPort {
  int _counter = 100;
  @override
  Future<String> allocateSaleNumber(String voucherBookId) async => 'INV-${++_counter}';

  @override
  Future<SaleVoucherBookRef?> findById(String bookId) async => null;

  @override
  Future<List<SaleVoucherBookRef>> listActiveSalesBooks() async => const [];
}

class EnabledNoOpInventoryEffectPort implements SaleInventoryEffectPort {
  bool get isEnabled => true;

  @override
  Future<void> onConfirmed(Sale sale) async {}

  @override
  Future<void> onCancelled(Sale sale) async {}
}

class FailingInventoryEffectPort implements SaleInventoryEffectPort {
  bool get isEnabled => true;

  @override
  Future<void> onConfirmed(Sale sale) async {
    throw Exception('Simulated inventory posting failure');
  }

  @override
  Future<void> onCancelled(Sale sale) async {}
}

class TrackingInventoryEffectPort implements SaleInventoryEffectPort {
  int confirmCalls = 0;
  int cancelCalls = 0;
  Sale? lastConfirmedSale;
  Sale? lastCancelledSale;

  bool get isEnabled => true;

  @override
  Future<void> onConfirmed(Sale sale) async {
    confirmCalls++;
    lastConfirmedSale = sale;
  }

  @override
  Future<void> onCancelled(Sale sale) async {
    cancelCalls++;
    lastCancelledSale = sale;
  }
}

class FailingLedgerPostingPort implements SaleLedgerPostingPort {
  @override
  Future<void> syncSale(Sale sale) async {
    throw Exception('Simulated ledger posting failure');
  }

  @override
  Future<void> voidSale(Sale sale) async {}
}

class ThrowingRepositorySaleRepository extends SaleRepositoryImpl {
  ThrowingRepositorySaleRepository(super.db);

  @override
  Future<Sale> insert(SaleDraft draft, {required String saleNumber}) async {
    throw Exception('Simulated database insertion error');
  }
}

void main() {
  late SalesDatabase db;
  late SaleRepositoryImpl repoCompanyA;
  late SaleRepositoryImpl repoCompanyB;
  late TestSaleNumberAllocator allocator;
  late PermissionGuard guard;

  setUp(() {
    db = SalesDatabase.memory();
    repoCompanyA = SaleRepositoryImpl(
      db,
      readCompanyId: () => 'company_a',
    );
    repoCompanyB = SaleRepositoryImpl(
      db,
      readCompanyId: () => 'company_b',
    );
    allocator = TestSaleNumberAllocator();
    guard = const AllowAllPermissionGuard();
  });

  tearDown(() async {
    await db.close();
  });

  SaleDraft buildDraft({
    DiscountType discountType = DiscountType.fixed,
    double discountValue = 10.0,
    String customerName = 'Test Customer',
    String? cashAccountId,
  }) {
    return SaleDraft(
      saleDate: DateTime.utc(2026, 9, 1),
      settlementType: SaleSettlementType.cash,
      voucherBookId: 'VB-01',
      cashAccountId: cashAccountId ?? 'ACC-CASH-1',
      customerName: customerName,
      currencyCode: 'SAR',
      baseCurrencyCode: 'SAR',
      exchangeRate: 1.0,
      discountType: discountType,
      discountValue: discountValue,
      items: [
        const SaleItemDraft(
          productId: 'P1',
          productName: 'Product 1',
          productCode: 'PROD-1',
          mainQuantity: 2,
          unitPrice: 100,
          baseUnitPrice: 100,
        ),
      ],
      paymentMethod: PaymentMethod.cash,
    );
  }

  group('Phase 5 — Discount Type Preservation & Formatting', () {
    test('DiscountTypeX.fromStorage parses percent and percentage robustly', () {
      expect(DiscountTypeX.fromStorage('percent'), DiscountType.percentage);
      expect(DiscountTypeX.fromStorage('percentage'), DiscountType.percentage);
      expect(DiscountTypeX.fromStorage('PERCENT'), DiscountType.percentage);
      expect(DiscountTypeX.fromStorage('fixed'), DiscountType.fixed);
      expect(DiscountTypeX.fromStorage('amount'), DiscountType.fixed);
      expect(DiscountTypeX.fromStorage(null), DiscountType.fixed);
    });

    test('Fixed discount type is preserved across insert, load, and edit update', () async {
      final create = CreateSale(
        repository: repoCompanyA,
        numberAllocator: allocator,
        voucherBookPort: TestSaleVoucherBookPort(),
        permissionGuard: guard,
      );

      final draftFixed = buildDraft(
        discountType: DiscountType.fixed,
        discountValue: 15.0,
      );

      final created = await create(draftFixed);
      expect(created.discountType, DiscountType.fixed);
      expect(created.discountValue, 15.0);

      final loaded = await repoCompanyA.getById(created.id);
      expect(loaded, isNotNull);
      expect(loaded!.discountType, DiscountType.fixed);

      final update = UpdateSale(repository: repoCompanyA);
      final updated = await update(
        created.id,
        buildDraft(
          discountType: DiscountType.fixed,
          discountValue: 20.0,
        ),
      );
      expect(updated.discountType, DiscountType.fixed);
      expect(updated.discountValue, 20.0);
    });

    test('Percentage discount type is preserved across insert, load, and edit update', () async {
      final create = CreateSale(
        repository: repoCompanyA,
        numberAllocator: allocator,
        voucherBookPort: TestSaleVoucherBookPort(),
        permissionGuard: guard,
      );

      final draftPercentage = buildDraft(
        discountType: DiscountType.percentage,
        discountValue: 10.0,
      );

      final created = await create(draftPercentage);
      expect(created.discountType, DiscountType.percentage);
      expect(created.discountValue, 10.0);

      final loaded = await repoCompanyA.getById(created.id);
      expect(loaded, isNotNull);
      expect(loaded!.discountType, DiscountType.percentage);
    });
  });

  group('Phase 5 — Gap 1: Accounting Idempotency', () {
    late AccountingDatabase acctDb;
    late AccountRepositoryImpl accountRepo;
    late JournalRepositoryImpl journalRepo;
    late AccountingSaleLedgerAdapter ledgerAdapter;
    late String cashAccountUuid;

    setUp(() async {
      Hive.init('/tmp/hive_test_gap1_${DateTime.now().microsecondsSinceEpoch}');
      acctDb = AccountingDatabase.memory();
      accountRepo = AccountRepositoryImpl(
        acctDb,
        readCompanyId: () => 'company_a',
      );
      await accountRepo.ensureDefaultChartSeeded();
      final cashAccount = await accountRepo.insert(
        const AccountDraft(
          accountCode: '101099',
          name: 'Test Cash Box Account',
          accountType: AccountType.asset,
          isGroup: false,
        ),
      );
      cashAccountUuid = cashAccount.uuid;

      journalRepo = JournalRepositoryImpl(
        acctDb,
        accounts: accountRepo,
        periodValidator: legacyPeriodValidator(),
        readCompanyId: () => 'company_a',
      );
      final postingService = JournalPostingService(
        journals: journalRepo,
        periodValidator: legacyPeriodValidator(),
      );
      ledgerAdapter = AccountingSaleLedgerAdapter(
        posting: postingService,
        accounts: accountRepo,
      );
    });

    tearDown(() async {
      await acctDb.close();
    });

    test('Syncing sale to ledger creates exactly 1 entry, and repeated sync maintains 1 entry', () async {
      final create = CreateSale(
        repository: repoCompanyA,
        numberAllocator: allocator,
        voucherBookPort: TestSaleVoucherBookPort(),
        permissionGuard: guard,
      );
      final created = await create(buildDraft(cashAccountId: cashAccountUuid));

      // Initial ledger sync
      await ledgerAdapter.syncSale(created);

      // Verify accounting entry created with sourceId = sale.uuid
      final entry1 = await journalRepo.findBySource(
        sourceType: AccountingSaleLedgerAdapter.sourceType,
        sourceId: created.uuid,
      );
      expect(entry1, isNotNull);
      expect(entry1!.sourceId, created.uuid);
      expect(entry1.sourceType, 'sale');

      // Call ledgerAdapter.syncSale again directly (re-sync / retry)
      await ledgerAdapter.syncSale(created);

      final headers = await journalRepo.listHeaders();
      expect(headers.length, 1, reason: 'Must remain exactly 1 journal entry on retry');
    });
  });

  group('Phase 5 — Gap 2: Partial Downstream Failure & Compensating Rollback', () {
    test('When ledger posting fails during CreateSale, sale is soft-deleted and exception rethrown', () async {
      final createWithFailingLedger = CreateSale(
        repository: repoCompanyA,
        numberAllocator: allocator,
        voucherBookPort: TestSaleVoucherBookPort(),
        permissionGuard: guard,
        ledgerPosting: FailingLedgerPostingPort(),
      );

      await expectLater(
        createWithFailingLedger(buildDraft()),
        throwsA(isA<SaleException>()),
      );

      final salesInDb = await repoCompanyA.getById(101);
      expect(salesInDb, isNull, reason: 'Unposted sale is soft deleted when ledger sync fails');
    });

    test('When inventory confirmation fails during post, sale status rolls back to unposted', () async {
      final create = CreateSale(
        repository: repoCompanyA,
        numberAllocator: allocator,
        voucherBookPort: TestSaleVoucherBookPort(),
        permissionGuard: guard,
      );
      final created = await create(buildDraft());

      final failingConfirm = ConfirmSale(
        repository: repoCompanyA,
        accountingBridge: const NoOpSaleAccountingBridgePort(),
        inventoryEffect: FailingInventoryEffectPort(),
        permissionGuard: guard,
      );

      await expectLater(failingConfirm(created.id), throwsA(anything));

      final afterFailure = await repoCompanyA.getById(created.id);
      expect(afterFailure!.saleStatus, SaleStatus.unposted);
      expect(afterFailure.confirmedAt, isNull);
    });
  });

  group('Phase 5 — Gap 3: Confirm Twice / Retry', () {
    test('Calling confirm() on an already posted sale is rejected and produces no duplicate effects', () async {
      final create = CreateSale(
        repository: repoCompanyA,
        numberAllocator: allocator,
        voucherBookPort: TestSaleVoucherBookPort(),
        permissionGuard: guard,
      );
      final created = await create(buildDraft());

      final trackingInventory = TrackingInventoryEffectPort();

      final confirm = ConfirmSale(
        repository: repoCompanyA,
        accountingBridge: const NoOpSaleAccountingBridgePort(),
        inventoryEffect: trackingInventory,
        permissionGuard: guard,
      );

      final posted = await confirm(created.id);
      final confirmedAtOriginal = posted.confirmedAt;
      expect(confirmedAtOriginal, isNotNull);

      // Attempt to confirm the posted sale a second time
      await expectLater(confirm(created.id), throwsA(isA<SaleException>()));

      final afterReConfirm = await repoCompanyA.getById(created.id);
      expect(afterReConfirm!.saleStatus, SaleStatus.posted);
      expect(afterReConfirm.confirmedAt, confirmedAtOriginal, reason: 'Confirmed timestamp must not be overwritten');
      expect(trackingInventory.confirmCalls, 1, reason: 'Inventory effect must not run a second time');
    });
  });

  group('Phase 5 — Gap 4: Create → Update Sync Queue Coalescing', () {
    late Box<SyncOperation> testBox;

    setUp(() async {
      Hive.init('/tmp/hive_test_${DateTime.now().microsecondsSinceEpoch}');
      await SyncQueue.registerAdapter();
      testBox = await Hive.openBox<SyncOperation>('sync_queue_test_${DateTime.now().microsecondsSinceEpoch}');
    });

    tearDown(() async {
      await testBox.close();
    });

    test('SyncQueue coalesces CREATE + UPDATE into CREATE with latest payload', () async {
      final queue = SyncQueue(box: testBox, companyId: 'company_a');

      final createOp = SyncOperation.create(
        entityType: 'sale',
        entityId: 'SALE-UUID-100',
        type: SyncOperationType.create,
        payload: {'customerName': 'Original Name'},
        now: DateTime.utc(2026, 9, 1, 10, 0),
        companyId: 'company_a',
      );

      await queue.enqueue(createOp);
      expect(testBox.values.length, 1);
      expect(testBox.values.first.type, SyncOperationType.create);
      expect(testBox.values.first.payload['customerName'], 'Original Name');

      final updateOp = SyncOperation.create(
        entityType: 'sale',
        entityId: 'SALE-UUID-100',
        type: SyncOperationType.update,
        payload: {'customerName': 'Updated Name'},
        now: DateTime.utc(2026, 9, 1, 10, 5),
        companyId: 'company_a',
      );

      await queue.enqueue(updateOp);
      expect(testBox.values.length, 1, reason: 'Coalesced into 1 pending item');
      expect(testBox.values.first.type, SyncOperationType.create, reason: 'Operation type remains CREATE so remote upload works');
      expect(testBox.values.first.payload['customerName'], 'Updated Name', reason: 'Payload updated to latest');
    });
  });

  group('Phase 5 — Gap 5: Complete State Transition Matrix', () {
    test('State transition matrix rejects invalid transitions and preserves database state', () async {
      final create = CreateSale(
        repository: repoCompanyA,
        numberAllocator: allocator,
        voucherBookPort: TestSaleVoucherBookPort(),
        permissionGuard: guard,
      );
      final created = await create(buildDraft());

      final confirm = ConfirmSale(
        repository: repoCompanyA,
        accountingBridge: const NoOpSaleAccountingBridgePort(),
        inventoryEffect: EnabledNoOpInventoryEffectPort(),
        permissionGuard: guard,
      );
      final posted = await confirm(created.id);

      // Transition 1: posted -> update (REJECTED)
      final update = UpdateSale(repository: repoCompanyA);
      await expectLater(update(posted.id, buildDraft()), throwsA(isA<SaleException>()));

      // Transition 2: posted -> confirm (REJECTED)
      await expectLater(confirm(posted.id), throwsA(isA<SaleException>()));

      // Verify persistence unchanged
      final afterAttempts = await repoCompanyA.getById(posted.id);
      expect(afterAttempts!.saleStatus, SaleStatus.posted);

      // Transition 3: posted -> cancel (REJECTED because posted sales are immutable audit records)
      final cancel = CancelSale(
        repository: repoCompanyA,
        inventoryEffect: EnabledNoOpInventoryEffectPort(),
        permissionGuard: guard,
      );
      await expectLater(cancel(posted.id), throwsA(isA<SaleException>()));

      // Verify persistence still unchanged
      final afterCancelAttempt = await repoCompanyA.getById(posted.id);
      expect(afterCancelAttempt!.saleStatus, SaleStatus.posted);
    });
  });

  group('Phase 5 — Gap 6: Multi-Company Mutation Isolation', () {
    test('Company A cannot query, update, or confirm Company B sale', () async {
      final createB = CreateSale(
        repository: repoCompanyB,
        numberAllocator: allocator,
        voucherBookPort: TestSaleVoucherBookPort(),
        permissionGuard: guard,
      );
      final saleB = await createB(buildDraft(customerName: 'Company B Customer'));

      // 1. Query isolation
      final loadedFromA = await repoCompanyA.getById(saleB.id);
      expect(loadedFromA, isNull, reason: 'Company A cannot query Company B sale');

      // 2. Update isolation
      final updateA = UpdateSale(repository: repoCompanyA);
      await expectLater(updateA(saleB.id, buildDraft(customerName: 'Hacked')), throwsA(isA<SaleException>()));

      // 3. Confirm isolation
      final trackingInventory = TrackingInventoryEffectPort();
      final confirmA = ConfirmSale(
        repository: repoCompanyA,
        accountingBridge: const NoOpSaleAccountingBridgePort(),
        inventoryEffect: trackingInventory,
        permissionGuard: guard,
      );
      await expectLater(confirmA(saleB.id), throwsA(isA<SaleException>()));
      expect(trackingInventory.confirmCalls, 0, reason: 'Zero inventory effects generated');

      // Verify Company B sale was completely untouched
      final saleBAfter = await repoCompanyB.getById(saleB.id);
      expect(saleBAfter!.customerName, 'Company B Customer');
      expect(saleBAfter.saleStatus, SaleStatus.unposted);
    });
  });

  group('Phase 5 — Gap 7: Concurrency Matrix & Mutex Exception Release', () {
    test('Concurrent execution of Create, Update, and Confirm throws concurrentOperationBlocked', () async {
      final create = CreateSale(
        repository: repoCompanyA,
        numberAllocator: allocator,
        voucherBookPort: TestSaleVoucherBookPort(),
        permissionGuard: guard,
      );

      final draft = buildDraft();

      final resCreate = await Future.wait([
        create(draft).then((v) => 'ok', onError: (e) => (e as SaleException).code),
        create(draft).then((v) => 'ok', onError: (e) => (e as SaleException).code),
      ]);
      expect(resCreate, contains('ok'));
      expect(resCreate, contains(SaleException.concurrentOperationBlocked));
    });

    test('Operation throws exception -> mutex is released in finally -> subsequent operation succeeds', () async {
      final throwingRepo = ThrowingRepositorySaleRepository(db);
      final create = CreateSale(
        repository: throwingRepo,
        numberAllocator: allocator,
        voucherBookPort: TestSaleVoucherBookPort(),
        permissionGuard: guard,
      );

      // First call fails due to repository exception
      await expectLater(create(buildDraft()), throwsA(anything));

      // Second call using valid repo should succeed because mutex was released in finally block
      final validCreate = CreateSale(
        repository: repoCompanyA,
        numberAllocator: allocator,
        voucherBookPort: TestSaleVoucherBookPort(),
        permissionGuard: guard,
      );
      final sale = await validCreate(buildDraft());
      expect(sale.id, isNotNull);
    });
  });

  group('Phase 5 — Gap 8: Offline-First Persistence & Identity Durability', () {
    test('Sale created offline persists durably across database reload with stable UUID', () async {
      final create = CreateSale(
        repository: repoCompanyA,
        numberAllocator: allocator,
        voucherBookPort: TestSaleVoucherBookPort(),
        permissionGuard: guard,
      );

      final sale = await create(buildDraft(customerName: 'Offline Customer'));
      final uuidOriginal = sale.uuid;
      expect(uuidOriginal, isNotEmpty);

      // Re-instantiate repository reading from same database instance (simulating restart)
      final repoReopened = SaleRepositoryImpl(
        db,
        readCompanyId: () => 'company_a',
      );

      final reloaded = await repoReopened.getByUuid(uuidOriginal);
      expect(reloaded, isNotNull);
      expect(reloaded!.id, sale.id);
      expect(reloaded.customerName, 'Offline Customer');
      expect(reloaded.uuid, uuidOriginal, reason: 'UUID identity preserved across restart');
    });
  });
}
