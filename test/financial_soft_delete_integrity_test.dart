import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:stock_count/core/utils/id_generator.dart';

import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/models/account_exception.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';

import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_returns_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_return.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/stock_transfer_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/stock_transfer.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';

import 'package:stock_count/modules/receipts_payments/shared/data/database/receipts_payments_database.dart';
import 'package:stock_count/modules/receipts_payments/transactions/data/repositories/financial_transaction_repository_impl.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_source.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_status.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/rp_payment_method.dart';

import 'package:stock_count/modules/sales/shared/data/database/sales_database.dart';
import 'package:stock_count/modules/sales/invoices/data/repositories/sale_repository_impl.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_item.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_method.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/discount_type.dart';

import 'helpers/journal_posting_test_helper.dart';

void main() {
  late AccountingDatabase accDb;
  late AccountRepositoryImpl accountRepo;
  late JournalRepositoryImpl journalRepo;
  late JournalPostingService journalPostingService;

  late InventoryDatabase invDb;
  late StockMovementsRepositoryImpl stockMovementRepo;
  late StockTransferRepositoryImpl stockTransferRepo;
  late StockReturnsRepositoryImpl stockReturnRepo;

  late ReceiptsPaymentsDatabase rpDb;
  late FinancialTransactionRepositoryImpl rpRepo;

  late SalesDatabase saleDb;
  late SaleRepositoryImpl saleRepo;

  late String companyA;
  late String companyB;
  late String activeCompanyId;

  late String acc1Uuid;
  late String acc2Uuid;

  setUp(() async {
    companyA = 'company_A';
    companyB = 'company_B';
    activeCompanyId = companyA;

    // Databases
    accDb = AccountingDatabase(executor: NativeDatabase.memory());
    invDb = InventoryDatabase(executor: NativeDatabase.memory());
    rpDb = ReceiptsPaymentsDatabase(executor: NativeDatabase.memory());
    saleDb = SalesDatabase(executor: NativeDatabase.memory());

    // Accounting Repos
    accountRepo = AccountRepositoryImpl(accDb, readCompanyId: () => activeCompanyId);
    journalRepo = JournalRepositoryImpl(
      accDb,
      accounts: accountRepo,
      periodValidator: legacyPeriodValidator(),
      readCompanyId: () => activeCompanyId,
    );
    journalPostingService = JournalPostingService(
      journals: journalRepo,
      periodValidator: legacyPeriodValidator(),
    );

    // Inventory Repos
    stockMovementRepo = StockMovementsRepositoryImpl(db: invDb, readCompanyId: () => activeCompanyId);
    stockTransferRepo = StockTransferRepositoryImpl(db: invDb, readCompanyId: () => activeCompanyId);
    stockReturnRepo = StockReturnsRepositoryImpl(db: invDb, readCompanyId: () => activeCompanyId);

    // RP Repo
    rpRepo = FinancialTransactionRepositoryImpl(rpDb, readCompanyId: () => activeCompanyId);

    // Sale Repo
    saleRepo = SaleRepositoryImpl(saleDb, readCompanyId: () => activeCompanyId);

    acc1Uuid = generateUuidV4();
    acc2Uuid = generateUuidV4();
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    // Seed Accounts for Company A
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

  group('ROOT FIX 22 — Financial Soft Delete Integrity Suite', () {
    test('1. Posted Journal Entry: Attempted soft delete is rejected (JournalException.postedImmutable)', () async {
      activeCompanyId = companyA;
      final draft = JournalEntryDraft(
        voucherNumber: 'JE-POSTED-01',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Posted journal entry',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: acc1Uuid, debit: 500, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: acc2Uuid, debit: 0, credit: 500, currencyCode: 'SAR'),
        ],
      );

      final posted = await journalPostingService.post(draft);
      expect(posted.isPosted, isTrue);

      expect(
        () async => journalRepo.softDeleteByUuid(posted.uuid),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', JournalException.postedImmutable)),
      );

      // Verify record is still intact
      final fetched = await journalRepo.getByUuid(posted.uuid);
      expect(fetched, isNotNull);
      expect(fetched!.deletedAt, isNull);
    });

    test('2. Posted Stock Receipt: Attempted delete is rejected', () async {
      activeCompanyId = companyA;
      final receipt = StockReceipt(
        id: generateUuidV4(),
        receiptNumber: 'REC-POSTED-01',
        warehouse: 'WH-Main',
        notes: 'Posted receipt',
        receiptDate: DateTime.now().toUtc(),
        lines: [
          StockMovementLine(
            movementUuid: 'rec-1',
            movementType: 'receipt',
            itemCode: 'ITEM-01',
            itemName: 'Item 1',
            mainQuantity: 10,
            quantity: 10,
            unitCost: 50,
            totalCost: 500,
          ),
        ],
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        status: InventoryDocumentStatus.posted,
        postedAt: DateTime.now().toUtc(),
        companyId: companyA,
      );

      await stockMovementRepo.saveReceipt(receipt);

      expect(
        () async => stockMovementRepo.deleteReceipt(receipt.id),
        throwsA(isA<StateError>()),
      );

      final fetched = await stockMovementRepo.getReceiptById(receipt.id);
      expect(fetched, isNotNull);
      expect(fetched!.deletedAt, isNull);
    });

    test('3. Posted Stock Issue: Attempted delete is rejected', () async {
      activeCompanyId = companyA;
      final issue = StockIssue(
        id: generateUuidV4(),
        issueNumber: 'ISS-POSTED-01',
        warehouse: 'WH-Main',
        notes: 'Posted issue',
        issueDate: DateTime.now().toUtc(),
        lines: [
          StockMovementLine(
            movementUuid: 'iss-1',
            movementType: 'issue',
            itemCode: 'ITEM-01',
            itemName: 'Item 1',
            mainQuantity: 5,
            quantity: 5,
            unitCost: 50,
            totalCost: 250,
          ),
        ],
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        status: InventoryDocumentStatus.posted,
        postedAt: DateTime.now().toUtc(),
        companyId: companyA,
      );

      await stockMovementRepo.saveIssue(issue);

      expect(
        () async => stockMovementRepo.deleteIssue(issue.id),
        throwsA(isA<StateError>()),
      );

      final fetched = await stockMovementRepo.getIssueById(issue.id);
      expect(fetched, isNotNull);
      expect(fetched!.deletedAt, isNull);
    });

    test('4. Posted Stock Transfer: Attempted delete is rejected', () async {
      activeCompanyId = companyA;
      final transfer = StockTransfer(
        id: generateUuidV4(),
        transferNumber: 'TRF-POSTED-01',
        fromWarehouseId: 'WH-01',
        toWarehouseId: 'WH-02',
        transferDate: DateTime.now().toUtc(),
        lines: const [],
        status: InventoryDocumentStatus.posted,
        postedAt: DateTime.now().toUtc(),
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        companyId: companyA,
      );

      await stockTransferRepo.saveTransfer(transfer);

      expect(
        () async => stockTransferRepo.deleteTransfer(transfer.id),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', JournalException.postedImmutable)),
      );

      final fetched = await stockTransferRepo.getTransferById(transfer.id);
      expect(fetched, isNotNull);
      expect(fetched!.deletedAt, isNull);
    });

    test('5. Posted Stock Return: Attempted delete is rejected', () async {
      activeCompanyId = companyA;
      final returnDoc = StockReturn(
        id: generateUuidV4(),
        returnNumber: 'RET-POSTED-01',
        returnType: StockReturnType.salesReturn,
        partyName: 'Customer A',
        warehouse: 'WH-01',
        returnDate: DateTime.now().toUtc(),
        lines: const [],
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        status: InventoryDocumentStatus.posted,
        postedAt: DateTime.now().toUtc(),
        companyId: companyA,
      );

      await stockReturnRepo.saveReturn(returnDoc);

      expect(
        () async => stockReturnRepo.deleteReturn(returnDoc.id),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', JournalException.postedImmutable)),
      );

      final fetched = await stockReturnRepo.getReturnById(returnDoc.id);
      expect(fetched, isNotNull);
      expect(fetched!.deletedAt, isNull);
    });

    test('6. Posted Financial Transaction: Attempted delete is rejected', () async {
      activeCompanyId = companyA;
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

      final inserted = await rpRepo.insert(draft, transactionNumber: 'TX-POSTED-01');
      expect(inserted.documentStatus, equals(TransactionStatus.posted));

      expect(
        () async => rpRepo.softDelete(inserted.id),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', JournalException.postedImmutable)),
      );

      final fetched = await rpRepo.getById(inserted.id);
      expect(fetched, isNotNull);
      expect(fetched!.deletedAt, isNull);
    });

    test('7. Posted Sale Invoice: Attempted delete is rejected', () async {
      activeCompanyId = companyA;
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

      final sale = await saleRepo.insert(draft, saleNumber: 'INV-POSTED-01');
      expect(sale.saleStatus, equals(SaleStatus.posted));

      expect(
        () async => saleRepo.softDelete(sale.id),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', JournalException.postedImmutable)),
      );

      final fetched = await saleRepo.getById(sale.id);
      expect(fetched, isNotNull);
      expect(fetched!.deletedAt, isNull);
    });

    test('8. Master Account Protection: Account used in transactions cannot be soft-deleted', () async {
      activeCompanyId = companyA;

      // Post journal entry referencing acc1Uuid
      final draft = JournalEntryDraft(
        voucherNumber: 'JE-DEP-01',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Account dependency check',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: acc1Uuid, debit: 100, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: acc2Uuid, debit: 0, credit: 100, currencyCode: 'SAR'),
        ],
      );
      await journalPostingService.post(draft);

      final acc = await accountRepo.getByUuid(acc1Uuid);
      expect(acc, isNotNull);

      expect(
        () async => accountRepo.softDelete(acc!.id),
        throwsA(isA<AccountException>().having((e) => e.code, 'code', AccountException.accountInUse)),
      );
    });

    test('9. Master Account Protection: System accounts cannot be soft-deleted', () async {
      activeCompanyId = companyA;
      final sysAccUuid = generateUuidV4();
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

      final id = await accDb.into(accDb.accounts).insert(
            AccountsCompanion.insert(
              uuid: sysAccUuid,
              companyId: Value(companyA),
              accountCode: '9999',
              name: 'System Account',
              accountType: 'asset',
              normalBalance: 'debit',
              level: const Value(1),
              isGroup: const Value(false),
              isActive: const Value(true),
              isSystemAccount: const Value(true),
              createdAt: nowMs,
              updatedAt: nowMs,
            ),
          );

      expect(
        () async => accountRepo.softDelete(id),
        throwsA(isA<AccountException>().having((e) => e.code, 'code', AccountException.systemAccountProtected)),
      );
    });

    test('10. Draft Record Soft Delete: Draft records can be safely soft-deleted', () async {
      activeCompanyId = companyA;

      // Draft Stock Transfer
      final transfer = StockTransfer(
        id: generateUuidV4(),
        transferNumber: 'TRF-DRAFT-01',
        fromWarehouseId: 'WH-01',
        toWarehouseId: 'WH-02',
        transferDate: DateTime.now().toUtc(),
        lines: const [],
        status: InventoryDocumentStatus.draft,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        companyId: companyA,
      );
      await stockTransferRepo.saveTransfer(transfer);

      await stockTransferRepo.deleteTransfer(transfer.id);
      final deletedTransfer = await stockTransferRepo.getTransferById(transfer.id);
      expect(deletedTransfer, isNull);

      // Draft Financial Transaction
      final txDraft = FinancialTransactionDraft(
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
      final tx = await rpRepo.insert(txDraft, transactionNumber: 'TX-DRAFT-01');
      await rpRepo.softDelete(tx.id);
      final deletedTx = await rpRepo.getById(tx.id);
      expect(deletedTx, isNull);
    });

    test('11. Cross-Tenant Deletion Isolation: Company B cannot soft delete Company A records', () async {
      activeCompanyId = companyA;

      final transfer = StockTransfer(
        id: generateUuidV4(),
        transferNumber: 'TRF-TENANT-01',
        fromWarehouseId: 'WH-01',
        toWarehouseId: 'WH-02',
        transferDate: DateTime.now().toUtc(),
        lines: const [],
        status: InventoryDocumentStatus.draft,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        companyId: companyA,
      );
      await stockTransferRepo.saveTransfer(transfer);

      // Switch context to Company B
      activeCompanyId = companyB;

      // Attempt deletion as Company B
      await stockTransferRepo.deleteTransfer(transfer.id);

      // Switch back to Company A and verify transfer was NOT deleted
      activeCompanyId = companyA;
      final checkDoc = await stockTransferRepo.getTransferById(transfer.id);
      expect(checkDoc, isNotNull);
      expect(checkDoc!.deletedAt, isNull);
    });

    test('12. Historical Report Integrity: Posted financial history is preserved intact in queries', () async {
      activeCompanyId = companyA;

      final draft1 = JournalEntryDraft(
        voucherNumber: 'JE-HIST-01',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'First posted entry',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: acc1Uuid, debit: 1500, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: acc2Uuid, debit: 0, credit: 1500, currencyCode: 'SAR'),
        ],
      );
      await journalPostingService.post(draft1);

      final draft2 = JournalEntryDraft(
        voucherNumber: 'JE-HIST-02',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Second posted entry',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: acc1Uuid, debit: 2500, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: acc2Uuid, debit: 0, credit: 2500, currencyCode: 'SAR'),
        ],
      );
      await journalPostingService.post(draft2);

      final headers = await journalRepo.listHeaders();
      expect(headers.length, equals(2));

      final netDebit = await journalRepo.sumNetBefore(
        accountUuid: acc1Uuid,
        beforeDate: DateTime.now().add(const Duration(days: 1)),
      );
      expect(netDebit, equals(4000));
    });
  });
}
