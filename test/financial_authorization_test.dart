import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';

import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/permissions/accounting_permissions.dart';

import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_engine_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/inventory_dependency_detector_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/stock_validation_service_impl.dart';

import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/permissions/inventory_permission_package.dart';

import 'package:stock_count/modules/receipts_payments/shared/data/database/receipts_payments_database.dart';
import 'package:stock_count/modules/receipts_payments/transactions/data/repositories/financial_transaction_repository_impl.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_source.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_status.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/rp_payment_method.dart';
import 'package:stock_count/modules/receipts_payments/permissions/receipts_payments_permission_package.dart';

import 'package:stock_count/modules/sales/shared/data/database/sales_database.dart';
import 'package:stock_count/modules/sales/invoices/data/repositories/sale_repository_impl.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_item.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_method.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/discount_type.dart';
import 'package:stock_count/modules/sales/permissions/sales_permission_package.dart';

import 'helpers/journal_posting_test_helper.dart';

void main() {
  late AccountingDatabase accDb;
  late AccountRepositoryImpl accountRepo;
  late JournalRepositoryImpl journalRepo;

  late InventoryDatabase invDb;
  late ReceiptsPaymentsDatabase rpDb;
  late SalesDatabase saleDb;

  late String companyA;
  late String acc1Uuid;
  late String acc2Uuid;

  setUp(() async {
    companyA = 'company_A';

    accDb = AccountingDatabase(executor: NativeDatabase.memory());
    invDb = InventoryDatabase(executor: NativeDatabase.memory());
    rpDb = ReceiptsPaymentsDatabase(executor: NativeDatabase.memory());
    saleDb = SalesDatabase(executor: NativeDatabase.memory());

    accountRepo = AccountRepositoryImpl(accDb, readCompanyId: () => companyA);
    journalRepo = JournalRepositoryImpl(
      accDb,
      accounts: accountRepo,
      periodValidator: legacyPeriodValidator(),
      readCompanyId: () => companyA,
    );

    acc1Uuid = generateUuidV4();
    acc2Uuid = generateUuidV4();
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    await accDb.into(accDb.accounts).insert(
          AccountsCompanion.insert(
            uuid: acc1Uuid,
            companyId: Value(companyA),
            accountCode: '1010',
            name: 'Cash Box',
            accountType: 'asset',
            normalBalance: 'debit',
            level: const Value(1),
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );

    await accDb.into(accDb.accounts).insert(
          AccountsCompanion.insert(
            uuid: acc2Uuid,
            companyId: Value(companyA),
            accountCode: '4010',
            name: 'Sales Revenue',
            accountType: 'revenue',
            normalBalance: 'credit',
            level: const Value(1),
            isGroup: const Value(false),
            isActive: const Value(true),
            createdAt: nowMs,
            updatedAt: nowMs,
          ),
        );
  });

  tearDown(() async {
    await accDb.close();
    await invDb.close();
    await rpDb.close();
    await saleDb.close();
  });

  group('ROOT FIX 23 — Financial Authorization Model Test Suite', () {
    test('1. Direct Service Call (JournalPostingService.post): Denies user without POST permission', () async {
      // Create user guard with VIEW-only permission
      final userGuard = CallbackPermissionGuard(
        (codes) => codes.any((c) => c == 'accounting.journals.view'),
      );

      final postingService = JournalPostingService(
        journals: journalRepo,
        periodValidator: legacyPeriodValidator(),
        permissionGuard: userGuard,
      );

      final draft = JournalEntryDraft(
        voucherNumber: 'JE-AUTH-01',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Unauthorized post attempt',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: acc1Uuid, debit: 500, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: acc2Uuid, debit: 0, credit: 500, currencyCode: 'SAR'),
        ],
      );

      // Direct service call must throw PermissionDeniedException
      expect(
        () async => postingService.post(draft),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('2. Direct Service Call (JournalPostingService.reverseByUuid): Denies user without REVERSE permission', () async {
      // First post entry using admin guard
      const adminGuard = AllowAllPermissionGuard();
      final adminPostingService = JournalPostingService(
        journals: journalRepo,
        periodValidator: legacyPeriodValidator(),
        permissionGuard: adminGuard,
      );

      final draft = JournalEntryDraft(
        voucherNumber: 'JE-AUTH-02',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Posted entry',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: acc1Uuid, debit: 500, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: acc2Uuid, debit: 0, credit: 500, currencyCode: 'SAR'),
        ],
      );
      final posted = await adminPostingService.post(draft);

      // Now create restricted guard with CREATE only, but NO REVERSE permission
      final restrictedGuard = CallbackPermissionGuard(
        (codes) => codes.any((c) => c == 'accounting.journals.create'),
      );

      final restrictedPostingService = JournalPostingService(
        journals: journalRepo,
        periodValidator: legacyPeriodValidator(),
        permissionGuard: restrictedGuard,
      );

      expect(
        () async => restrictedPostingService.reverseByUuid(posted.uuid),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('3. Direct Service Call (PostingCoordinator.post): Denies user without Inventory POST permission', () async {
      final viewOnlyGuard = CallbackPermissionGuard(
        (codes) => codes.any((c) => c == 'inventory.receipts.view'),
      );

      final coordinator = PostingCoordinatorImpl(
        db: invDb,
        stockValidationService: StockValidationServiceImpl(invDb),
        dependencyDetector: InventoryDependencyDetectorImpl(invDb),
        postingEngine: PostingEngineImpl(invDb, CostLayerServiceImpl(db: invDb)),

        periodValidator: legacyPeriodValidator(),
        permissionGuard: viewOnlyGuard,
        readCompanyId: () => companyA,
      );

      final docRef = InventoryDocumentRef(
        documentId: generateUuidV4(),
        documentNumber: 'REC-AUTH-01',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: 'WH-01',
        status: InventoryDocumentStatus.draft,
      );

      expect(
        () async => coordinator.post(document: docRef),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('4. Direct Service Call (PostingCoordinator.unpost): Denies user without Inventory REVERSE permission', () async {
      final postOnlyGuard = CallbackPermissionGuard(
        (codes) => codes.any((c) => c == 'inventory.receipts.post' || c == 'inventory.receipts.create'),
      );

      final coordinator = PostingCoordinatorImpl(
        db: invDb,
        stockValidationService: StockValidationServiceImpl(invDb),
        dependencyDetector: InventoryDependencyDetectorImpl(invDb),
        postingEngine: PostingEngineImpl(invDb, CostLayerServiceImpl(db: invDb)),

        periodValidator: legacyPeriodValidator(),
        permissionGuard: postOnlyGuard,
        readCompanyId: () => companyA,
      );

      final docRef = InventoryDocumentRef(
        documentId: generateUuidV4(),
        documentNumber: 'REC-AUTH-02',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.now(),
        warehouseId: 'WH-01',
        status: InventoryDocumentStatus.posted,
      );

      expect(
        () async => coordinator.unpost(document: docRef),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('5. Direct Repository Call (FinancialTransactionRepositoryImpl.insert posted): Denies unauthorized user', () async {
      final viewOnlyGuard = CallbackPermissionGuard(
        (codes) => codes.any((c) => c == 'receipts.view'),
      );

      final rpRepo = FinancialTransactionRepositoryImpl(
        rpDb,
        permissionGuard: viewOnlyGuard,
        readCompanyId: () => companyA,
      );

      final draft = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.manualReceipt,
        transactionDate: DateTime.now().toUtc(),
        amount: 1000,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        counterAmount: 1000,
        counterCurrencyCode: 'SAR',
        counterExchangeRate: 1.0,
        cashAccountId: acc1Uuid,
        counterAccountId: acc2Uuid,
        paymentMethod: RpPaymentMethod.cash,
        documentStatus: TransactionStatus.posted,
      );

      expect(
        () async => rpRepo.insert(draft, transactionNumber: 'TX-AUTH-01'),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('6. Direct Repository Call (FinancialTransactionRepositoryImpl.softDelete): Denies unauthorized user', () async {
      const adminGuard = AllowAllPermissionGuard();
      final adminRepo = FinancialTransactionRepositoryImpl(
        rpDb,
        permissionGuard: adminGuard,
        readCompanyId: () => companyA,
      );

      final draft = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.manualReceipt,
        transactionDate: DateTime.now().toUtc(),
        amount: 500,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        counterAmount: 500,
        counterCurrencyCode: 'SAR',
        counterExchangeRate: 1.0,
        cashAccountId: acc1Uuid,
        counterAccountId: acc2Uuid,
        paymentMethod: RpPaymentMethod.cash,
        documentStatus: TransactionStatus.unposted,
      );
      final tx = await adminRepo.insert(draft, transactionNumber: 'TX-AUTH-02');

      final viewOnlyGuard = CallbackPermissionGuard(
        (codes) => codes.any((c) => c == 'receipts.view'),
      );

      final restrictedRepo = FinancialTransactionRepositoryImpl(
        rpDb,
        permissionGuard: viewOnlyGuard,
        readCompanyId: () => companyA,
      );

      expect(
        () async => restrictedRepo.softDelete(tx.id),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('7. Direct Repository Call (SaleRepositoryImpl.insert posted): Denies unauthorized user', () async {
      final viewOnlyGuard = CallbackPermissionGuard(
        (codes) => codes.any((c) => c == 'sales.documents.view'),
      );

      final saleRepo = SaleRepositoryImpl(
        saleDb,
        permissionGuard: viewOnlyGuard,
        readCompanyId: () => companyA,
      );

      final draft = SaleDraft(
        voucherBookId: 'VB-01',
        cashAccountId: acc1Uuid,
        saleDate: DateTime.now().toUtc(),
        settlementType: SaleSettlementType.cash,
        customerId: 'CUST-01',
        customerName: 'Customer One',
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        items: const [
          SaleItemDraft(
            productId: 'PROD-01',
            productName: 'Product 1',
            productCode: 'P01',
            mainQuantity: 2,
            subQuantity: 0,
            unitPrice: 100,
            baseUnitPrice: 100,
          ),
        ],
        discountType: DiscountType.fixed,
        discountValue: 0,
        taxRate: 0,
        paidAmount: 200,
        paymentMethod: PaymentMethod.cash,
        saleStatus: SaleStatus.posted,
      );

      expect(
        () async => saleRepo.insert(draft, saleNumber: 'INV-AUTH-01'),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('8. Direct Repository Call (SaleRepositoryImpl.softDelete): Denies unauthorized user', () async {
      const adminGuard = AllowAllPermissionGuard();
      final adminSaleRepo = SaleRepositoryImpl(
        saleDb,
        permissionGuard: adminGuard,
        readCompanyId: () => companyA,
      );

      final draft = SaleDraft(
        voucherBookId: 'VB-01',
        cashAccountId: acc1Uuid,
        saleDate: DateTime.now().toUtc(),
        settlementType: SaleSettlementType.cash,
        customerId: 'CUST-01',
        customerName: 'Customer One',
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        items: const [
          SaleItemDraft(
            productId: 'PROD-01',
            productName: 'Product 1',
            productCode: 'P01',
            mainQuantity: 2,
            subQuantity: 0,
            unitPrice: 100,
            baseUnitPrice: 100,
          ),
        ],
        discountType: DiscountType.fixed,
        discountValue: 0,
        taxRate: 0,
        paidAmount: 200,
        paymentMethod: PaymentMethod.cash,
        saleStatus: SaleStatus.unposted,
      );

      final sale = await adminSaleRepo.insert(draft, saleNumber: 'INV-AUTH-02');

      final viewOnlyGuard = CallbackPermissionGuard(
        (codes) => codes.any((c) => c == 'sales.documents.view'),
      );

      final restrictedSaleRepo = SaleRepositoryImpl(
        saleDb,
        permissionGuard: viewOnlyGuard,
        readCompanyId: () => companyA,
      );

      expect(
        () async => restrictedSaleRepo.softDelete(sale.id),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('9. Background Sync & System Operations: AllowAllPermissionGuard permits system jobs', () async {
      const systemGuard = AllowAllPermissionGuard();

      final postingService = JournalPostingService(
        journals: journalRepo,
        periodValidator: legacyPeriodValidator(),
        permissionGuard: systemGuard,
      );

      final draft = JournalEntryDraft(
        voucherNumber: 'JE-SYSTEM-01',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'System background sync entry',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: acc1Uuid, debit: 100, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: acc2Uuid, debit: 0, credit: 100, currencyCode: 'SAR'),
        ],
      );

      final posted = await postingService.post(draft);
      expect(posted.isPosted, isTrue);

      final reversed = await postingService.reverseByUuid(posted.uuid);
      expect(reversed, isNotNull);
    });
  });
}
