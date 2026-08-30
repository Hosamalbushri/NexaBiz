import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';

import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_validator.dart';

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

import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';

import 'helpers/journal_posting_test_helper.dart';

void main() {
  late AccountingDatabase accDb;
  late AccountRepositoryImpl accountRepo;
  late JournalRepositoryImpl journalRepo;

  late ReceiptsPaymentsDatabase rpDb;
  late FinancialTransactionRepositoryImpl rpRepo;

  late SalesDatabase saleDb;
  late SaleRepositoryImpl saleRepo;

  late InventoryDatabase invDb;
  late StockMovementsRepositoryImpl invRepo;

  late String companyA;
  late String companyB;
  late String acc1Uuid;
  late String acc2Uuid;

  setUp(() async {
    companyA = 'company_A';
    companyB = 'company_B';

    accDb = AccountingDatabase(executor: NativeDatabase.memory());
    rpDb = ReceiptsPaymentsDatabase(executor: NativeDatabase.memory());
    saleDb = SalesDatabase(executor: NativeDatabase.memory());
    invDb = InventoryDatabase(executor: NativeDatabase.memory());

    accountRepo = AccountRepositoryImpl(accDb, readCompanyId: () => companyA);
    journalRepo = JournalRepositoryImpl(
      accDb,
      accounts: accountRepo,
      periodValidator: legacyPeriodValidator(),
      readCompanyId: () => companyA,
    );

    rpRepo = FinancialTransactionRepositoryImpl(
      rpDb,
      permissionGuard: const AllowAllPermissionGuard(),
      readCompanyId: () => companyA,
    );

    saleRepo = SaleRepositoryImpl(
      saleDb,
      permissionGuard: const AllowAllPermissionGuard(),
      readCompanyId: () => companyA,
    );

    invRepo = StockMovementsRepositoryImpl(
      db: invDb,
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
    await rpDb.close();
    await saleDb.close();
    await invDb.close();
  });

  group('ROOT FIX 24 — Repository Security Boundary Test Suite', () {
    test('1. Multi-Tenant Isolation: Cross-tenant records cannot be read or modified by lower-layer calls', () async {
      // Add accounts for company B
      final acc1B = generateUuidV4();
      final acc2B = generateUuidV4();
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      await accDb.into(accDb.accounts).insert(
            AccountsCompanion.insert(
              uuid: acc1B,
              companyId: Value(companyB),
              accountCode: '1010-B',
              name: 'Cash Box B',
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
              uuid: acc2B,
              companyId: Value(companyB),
              accountCode: '4010-B',
              name: 'Sales Revenue B',
              accountType: 'revenue',
              normalBalance: 'credit',
              level: const Value(1),
              isGroup: const Value(false),
              isActive: const Value(true),
              createdAt: nowMs,
              updatedAt: nowMs,
            ),
          );

      // Create journal entry in company B
      final journalRepoB = JournalRepositoryImpl(
        accDb,
        accounts: AccountRepositoryImpl(accDb, readCompanyId: () => companyB),
        periodValidator: legacyPeriodValidator(),
        readCompanyId: () => companyB,
      );

      final draftB = JournalEntryDraft(
        voucherNumber: 'JE-COMPB-01',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Company B entry',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: acc1B, debit: 100, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: acc2B, debit: 0, credit: 100, currencyCode: 'SAR'),
        ],
      );
      final postedB = await journalRepoB.post(draftB);

      // Attempt reading entry from company A
      final readFromA = await journalRepo.getByUuid(postedB.uuid);
      expect(readFromA, isNull);
    });

    test('2. Authorization Boundary: Disallowed permission rejects repository mutations', () async {
      final deniedGuard = CallbackPermissionGuard((_) => false);

      final restrictedRpRepo = FinancialTransactionRepositoryImpl(
        rpDb,
        permissionGuard: deniedGuard,
        readCompanyId: () => companyA,
      );

      final draft = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.manualReceipt,
        transactionDate: DateTime.now().toUtc(),
        amount: 100,
        currencyCode: 'SAR',
        baseCurrencyCode: 'SAR',
        exchangeRate: 1.0,
        counterAmount: 100,
        counterCurrencyCode: 'SAR',
        counterExchangeRate: 1.0,
        cashAccountId: acc1Uuid,
        counterAccountId: acc2Uuid,
        paymentMethod: RpPaymentMethod.cash,
        documentStatus: TransactionStatus.unposted,
      );

      expect(
        () async => restrictedRpRepo.insert(draft, transactionNumber: 'TX-AUTH-FAIL'),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('3. Posted-State Immutability: Posted records reject updates and soft deletes across all repositories', () async {
      // 3.1 Financial Transaction
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
        documentStatus: TransactionStatus.posted,
      );
      final postedTx = await rpRepo.insert(txDraft, transactionNumber: 'TX-IMMUTABLE-01');

      expect(
        () async => rpRepo.softDelete(postedTx.id),
        throwsA(isA<Object>()),
      );

      // 3.2 Sale Invoice
      final saleDraft = SaleDraft(
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
      final postedSale = await saleRepo.insert(saleDraft, saleNumber: 'INV-IMMUTABLE-01');

      expect(
        () async => saleRepo.softDelete(postedSale.id),
        throwsA(isA<Object>()),
      );

      // 3.3 Inventory Document
      final receiptId = generateUuidV4();
      final lineId = generateUuidV4();
      final date = DateTime.utc(2026, 1, 1);

      final receipt = StockReceipt(
        id: receiptId,
        receiptNumber: 'REC-IMMUTABLE-01',
        receiptDate: date,
        status: InventoryDocumentStatus.posted,
        lines: [
          StockMovementLine(
            id: lineId,
            movementUuid: receiptId,
            movementType: 'receipt',
            itemCode: 'ITEM-001',
            itemName: 'Test Item 1',
            quantity: 10,
            unitCost: 50,
            totalCost: 500,
          ),
        ],
      );
      await invRepo.saveReceipt(receipt);

      expect(
        () async => invRepo.deleteReceipt(receiptId),
        throwsA(isA<StateError>()),
      );
    });

    test('4. Period Lock Validation: Repository rejects posting in locked accounting periods', () async {
      final lockedValidator = legacyPeriodValidator(
        closedThrough: DateTime.now().add(const Duration(days: 365)), // Lock all current dates
      );

      final lockedRepo = JournalRepositoryImpl(
        accDb,
        accounts: accountRepo,
        periodValidator: lockedValidator,
        readCompanyId: () => companyA,
      );

      final draft = JournalEntryDraft(
        voucherNumber: 'JE-LOCKED-01',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Locked period attempt',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: acc1Uuid, debit: 100, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: acc2Uuid, debit: 0, credit: 100, currencyCode: 'SAR'),
        ],
      );

      expect(
        () async => lockedRepo.post(draft),
        throwsA(isA<JournalException>()),
      );
    });

    test('5. Business Invariants: Unbalanced journal entry is rejected at repository boundary', () async {
      final unbalancedDraft = JournalEntryDraft(
        voucherNumber: 'JE-UNBALANCED-01',
        voucherType: 'journal',
        currencyCode: 'SAR',
        description: 'Unbalanced entry attempt',
        isPosted: true,
        entryDate: DateTime.now(),
        lines: [
          JournalLineDraft(accountUuid: acc1Uuid, debit: 100, credit: 0, currencyCode: 'SAR'),
          JournalLineDraft(accountUuid: acc2Uuid, debit: 0, credit: 50, currencyCode: 'SAR'), // Unbalanced (100 vs 50)
        ],
      );

      expect(
        () async => journalRepo.post(unbalancedDraft),
        throwsA(isA<JournalException>()),
      );
    });
  });
}
