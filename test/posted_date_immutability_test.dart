import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/receipts_payments/shared/data/database/receipts_payments_database.dart';
import 'package:stock_count/modules/sales/shared/data/database/sales_database.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/data/repositories/fiscal_year_repository_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_validator.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_generator.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/fiscal_period_policy.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/entities/fiscal_year.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/entities/accounting_period_status.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/repositories/stock_movements_repository_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/warehouses/data/repositories/stock_transfer_repository_impl.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/entities/stock_transfer.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/receipts_payments/transactions/data/repositories/financial_transaction_repository_impl.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_source.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/rp_payment_method.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_status.dart';
import 'package:stock_count/modules/sales/invoices/data/repositories/sale_repository_impl.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_item.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/sale_settlement_type.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_status.dart';
import 'package:stock_count/modules/sales/invoices/domain/entities/payment_method.dart';
import 'package:stock_count/modules/sales/invoices/domain/repositories/sale_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AccountingDatabase accDb;
  late InventoryDatabase invDb;
  late ReceiptsPaymentsDatabase rpDb;
  late SalesDatabase salesDb;

  late AccountRepositoryImpl accountRepo;
  late FiscalYearRepositoryImpl fiscalYearRepo;
  late AccountingPeriodValidator periodValidator;
  late JournalRepositoryImpl journalRepo;
  late JournalPostingService journalService;
  late StockMovementsRepositoryImpl stockMovementsRepo;
  late StockTransferRepositoryImpl stockTransferRepo;
  late FinancialTransactionRepositoryImpl rpRepo;
  late SaleRepositoryImpl saleRepo;
  late Directory tempDir;

  late String acc1;
  late String acc2;

  const companyId = 'TestCompany';
  final year2025Start = DateTime.utc(2025, 1, 1);
  final year2025End = DateTime.utc(2025, 12, 31, 23, 59, 59);

  Future<FiscalYear> createFY2025() async {
    final generator = const AccountingPeriodGenerator();
    final periods = generator.generateMonthly(
      startDate: year2025Start,
      endDate: year2025End,
      periodCount: 12,
    );
    final fy = await fiscalYearRepo.createFiscalYear(
      draft: FiscalYearDraft(
        code: 'FY2025',
        name: 'FY 2025',
        startDate: year2025Start,
        endDate: year2025End,
        baseCurrencyCode: 'YER',
        periodCount: 12,
        periodFrequency: PeriodFrequency.monthly,
        fxRevaluationEnabled: false,
      ),
      periods: periods,
    );
    final periodList = await fiscalYearRepo.listPeriods(fy.uuid);
    for (final p in periodList) {
      await fiscalYearRepo.openPeriod(periodUuid: p.uuid, openedBy: 'admin');
    }
    return fy;
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('posted_date_test_');
    Hive.init(tempDir.path);

    accDb = AccountingDatabase.memory();
    invDb = InventoryDatabase.memory();
    rpDb = ReceiptsPaymentsDatabase.memory();
    salesDb = SalesDatabase.memory();

    accountRepo = AccountRepositoryImpl(
      accDb,
      readCompanyId: () => companyId,
    );
    await accountRepo.seedDefaultChart();
    await accountRepo.ensureDefaultChartSeeded();

    final activeAccounts = (await accDb.select(accDb.accounts).get())
        .where((a) => !a.isGroup && a.isActive)
        .toList();
    acc1 = activeAccounts[0].uuid;
    acc2 = activeAccounts[1].uuid;

    fiscalYearRepo = FiscalYearRepositoryImpl(
      accDb,
      readCompanyId: () => companyId,
    );

    periodValidator = AccountingPeriodValidator(
      repository: fiscalYearRepo,
      legacyPolicyReader: () => const FiscalPeriodPolicy(fiscalYearStartMonth: 1),
    );

    journalRepo = JournalRepositoryImpl(
      accDb,
      periodValidator: periodValidator,
      accounts: accountRepo,
      readCompanyId: () => companyId,
    );

    journalService = JournalPostingService(
      journals: journalRepo,
      periodValidator: periodValidator,
    );

    stockMovementsRepo = StockMovementsRepositoryImpl(
      db: invDb,
      readCompanyId: () => companyId,
    );

    stockTransferRepo = StockTransferRepositoryImpl(
      db: invDb,
      readCompanyId: () => companyId,
    );

    rpRepo = FinancialTransactionRepositoryImpl(
      rpDb,
      periodValidator: periodValidator,
      readCompanyId: () => companyId,
    );

    saleRepo = SaleRepositoryImpl(
      salesDb,
      readCompanyId: () => companyId,
    );
  });

  tearDown(() async {
    await accDb.close();
    await invDb.close();
    await rpDb.close();
    await salesDb.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ROOT FIX 20 — Posted Date Immutability Test Suite', () {
    test('1. Modifying posted JournalEntry date MUST be rejected (posted_immutable)', () async {
      await createFY2025();

      final draftJan = JournalEntryDraft(
        entryDate: DateTime.utc(2025, 1, 15),
        voucherNumber: 'V-20-1',
        voucherType: 'general',
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        description: 'Original Jan entry',
        isPosted: true,
        lines: [
          JournalLineDraft(accountUuid: acc1, debit: 1000, credit: 0, currencyCode: 'YER'),
          JournalLineDraft(accountUuid: acc2, debit: 0, credit: 1000, currencyCode: 'YER'),
        ],
      );

      final postedEntry = await journalService.post(draftJan);
      expect(postedEntry.isPosted, true);

      // Attempt to modify the entry date to February
      final modifiedDraft = JournalEntryDraft(
        uuid: postedEntry.uuid,
        entryDate: DateTime.utc(2025, 2, 15),
        voucherNumber: 'V-20-1',
        voucherType: 'general',
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        description: 'Attempt date change to Feb',
        isPosted: true,
        lines: [
          JournalLineDraft(accountUuid: acc1, debit: 1000, credit: 0, currencyCode: 'YER'),
          JournalLineDraft(accountUuid: acc2, debit: 0, credit: 1000, currencyCode: 'YER'),
        ],
      );

      expect(
        () async => await journalRepo.post(modifiedDraft),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            JournalException.postedImmutable,
          ),
        ),
      );

      // Verify original posted entry remains unchanged in January
      final reloaded = await journalRepo.getByUuid(postedEntry.uuid);
      expect(reloaded, isNotNull);
      expect(reloaded!.entryDate, DateTime.utc(2025, 1, 15));
    });

    test('2. Modifying date on posted StockReceipt MUST be rejected', () async {
      await createFY2025();

      final receipt = StockReceipt(
        id: '11111111-1111-4111-8111-111111111111',
        receiptNumber: 'REC-20-1',
        receiptDate: DateTime.utc(2025, 1, 10),
        status: InventoryDocumentStatus.posted,
        postedAt: DateTime.utc(2025, 1, 10),
        lines: [
          StockMovementLine(
            id: '22222222-2222-4222-8222-222222222222',
            movementUuid: '11111111-1111-4111-8111-111111111111',
            movementType: 'receipt',
            itemCode: 'ITEM-1',
            itemName: 'Item 1',
            quantity: 10,
            unitCost: 100,
            totalCost: 1000,
          ),
        ],
      );

      await stockMovementsRepo.saveReceipt(receipt);

      // Attempt to save receipt with modified date in March
      final modifiedReceipt = receipt.copyWith(
        receiptDate: DateTime.utc(2025, 3, 10),
      );

      expect(
        () async => await stockMovementsRepo.saveReceipt(modifiedReceipt),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            JournalException.postedImmutable,
          ),
        ),
      );

      // Verify original receipt date remains January 10
      final reloaded = await stockMovementsRepo.getReceiptById(receipt.id);
      expect(reloaded, isNotNull);
      expect(reloaded!.receiptDate, DateTime.utc(2025, 1, 10));
    });

    test('3. Modifying date on posted StockIssue MUST be rejected', () async {
      await createFY2025();

      final issue = StockIssue(
        id: '33333333-3333-4333-8333-333333333333',
        issueNumber: 'ISS-20-1',
        issueDate: DateTime.utc(2025, 1, 20),
        status: InventoryDocumentStatus.posted,
        postedAt: DateTime.utc(2025, 1, 20),
        lines: [
          StockMovementLine(
            id: '44444444-4444-4444-8444-444444444444',
            movementUuid: '33333333-3333-4333-8333-333333333333',
            movementType: 'issue',
            itemCode: 'ITEM-1',
            itemName: 'Item 1',
            quantity: 5,
            unitCost: 100,
            totalCost: 500,
          ),
        ],
      );

      await stockMovementsRepo.saveIssue(issue);

      // Attempt to modify date to April
      final modifiedIssue = issue.copyWith(
        issueDate: DateTime.utc(2025, 4, 20),
      );

      expect(
        () async => await stockMovementsRepo.saveIssue(modifiedIssue),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            JournalException.postedImmutable,
          ),
        ),
      );

      final reloaded = await stockMovementsRepo.getIssueById(issue.id);
      expect(reloaded, isNotNull);
      expect(reloaded!.issueDate, DateTime.utc(2025, 1, 20));
    });

    test('4. Modifying posted StockTransfer or deleting posted transfer MUST be rejected', () async {
      await createFY2025();

      final transfer = StockTransfer(
        id: '55555555-5555-4555-8555-555555555555',
        transferNumber: 'TRF-20-1',
        fromWarehouseId: 'WH-A',
        toWarehouseId: 'WH-B',
        transferDate: DateTime.utc(2025, 1, 25),
        status: InventoryDocumentStatus.posted,
        postedAt: DateTime.utc(2025, 1, 25),
        lines: const [
          StockTransferLine(
            id: '66666666-6666-4666-8666-666666666666',
            transferUuid: '55555555-5555-4555-8555-555555555555',
            itemCode: 'ITEM-1',
            itemName: 'Item 1',
            quantity: 2,
            unitCost: 100,
            totalCost: 200,
          ),
        ],
      );

      await stockTransferRepo.saveTransfer(transfer);

      // Attempt edit
      final modifiedTransfer = transfer.copyWith(
        transferDate: DateTime.utc(2025, 5, 25),
      );

      expect(
        () async => await stockTransferRepo.saveTransfer(modifiedTransfer),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            JournalException.postedImmutable,
          ),
        ),
      );

      // Attempt delete
      expect(
        () async => await stockTransferRepo.deleteTransfer(transfer.id),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            JournalException.postedImmutable,
          ),
        ),
      );
    });

    test('5. Modifying date on posted FinancialTransaction MUST be rejected', () async {
      await createFY2025();

      final draftRP = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.manualReceipt,
        transactionDate: DateTime.utc(2025, 1, 12),
        amount: 2500,
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        exchangeRate: 1.0,
        counterAmount: 2500,
        counterCurrencyCode: 'YER',
        counterExchangeRate: 1.0,
        cashAccountId: acc1,
        counterAccountId: acc2,
        paymentMethod: RpPaymentMethod.cash,
        documentStatus: TransactionStatus.unposted,
        lines: const [],
      );

      final inserted = await rpRepo.insert(draftRP, transactionNumber: 'RP-20-1');
      await rpRepo.markPosted(inserted.id);

      final updateDraft = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.manualReceipt,
        transactionDate: DateTime.utc(2025, 6, 12), // Attempt change to June
        amount: 2500,
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        exchangeRate: 1.0,
        counterAmount: 2500,
        counterCurrencyCode: 'YER',
        counterExchangeRate: 1.0,
        cashAccountId: acc1,
        counterAccountId: acc2,
        paymentMethod: RpPaymentMethod.cash,
        documentStatus: TransactionStatus.posted,
        lines: const [],
      );

      expect(
        () async => await rpRepo.update(inserted.id, updateDraft),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            JournalException.postedImmutable,
          ),
        ),
      );

      final reloaded = await rpRepo.getById(inserted.id);
      expect(reloaded, isNotNull);
      expect(reloaded!.transactionDate, DateTime.utc(2025, 1, 12));
    });

    test('6. Modifying date on posted Sale MUST be rejected', () async {
      await createFY2025();

      final draftSale = SaleDraft(
        voucherBookId: 'VB-1',
        cashAccountId: acc1,
        saleDate: DateTime.utc(2025, 1, 18),
        settlementType: SaleSettlementType.cash,
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        exchangeRate: 1.0,
        items: const [
          SaleItemDraft(
            productId: 'PROD-1',
            productName: 'Product 1',
            productCode: 'P1',
            mainQuantity: 1,
            unitPrice: 100,
            baseUnitPrice: 100,
          ),
        ],
        payments: const [],
        paidAmount: 100,
        paymentMethod: PaymentMethod.cash,
      );

      final created = await saleRepo.insert(draftSale, saleNumber: 'INV-20-1');
      await saleRepo.updateStatus(
        created.id,
        const SaleStatusUpdate(saleStatus: SaleStatus.posted),
      );

      final updateDraft = SaleDraft(
        voucherBookId: 'VB-1',
        cashAccountId: acc1,
        saleDate: DateTime.utc(2025, 7, 18), // Attempt change to July
        settlementType: SaleSettlementType.cash,
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        exchangeRate: 1.0,
        items: const [
          SaleItemDraft(
            productId: 'PROD-1',
            productName: 'Product 1',
            productCode: 'P1',
            mainQuantity: 1,
            unitPrice: 100,
            baseUnitPrice: 100,
          ),
        ],
        payments: const [],
        paidAmount: 0,
        paymentMethod: PaymentMethod.cash,
      );

      expect(
        () async => await saleRepo.update(created.id, updateDraft),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            JournalException.postedImmutable,
          ),
        ),
      );

      final reloaded = await saleRepo.getById(created.id);
      expect(reloaded, isNotNull);
      expect(reloaded!.saleDate, DateTime.utc(2025, 1, 18));
    });

    test('7. Reversal creates a NEW event while keeping original posted record intact', () async {
      await createFY2025();

      final draftJan = JournalEntryDraft(
        entryDate: DateTime.utc(2025, 1, 10),
        voucherNumber: 'V-REV-ORIG',
        voucherType: 'general',
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        description: 'Original entry to reverse',
        isPosted: true,
        lines: [
          JournalLineDraft(accountUuid: acc1, debit: 3000, credit: 0, currencyCode: 'YER'),
          JournalLineDraft(accountUuid: acc2, debit: 0, credit: 3000, currencyCode: 'YER'),
        ],
      );

      final original = await journalService.post(draftJan);

      // Perform reversal in February
      final reversalDate = DateTime.utc(2025, 2, 10);
      final reversed = await journalService.reverseByUuid(
        original.uuid,
        reverseDate: reversalDate,
      );

      // Verify original remains in January with unchanged date & amounts
      final reloadedOriginal = await journalRepo.getByUuid(original.uuid);
      expect(reloadedOriginal, isNotNull);
      expect(reloadedOriginal!.entryDate, DateTime.utc(2025, 1, 10));
      expect(reloadedOriginal.lines.first.debit, 3000);

      // Verify reversal is a distinct NEW entry in February with inverted amounts
      expect(reversed.uuid, isNot(original.uuid));
      expect(reversed.entryDate, DateTime.utc(2025, 2, 10));
      expect(reversed.lines.first.debit, 0);
      expect(reversed.lines.first.credit, 3000);
    });
  });
}
