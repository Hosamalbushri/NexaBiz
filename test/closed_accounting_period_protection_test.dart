import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:drift/drift.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/receipts_payments/shared/data/database/receipts_payments_database.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/data/repositories/fiscal_year_repository_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_validator.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_generator.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/fiscal_period_policy.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/entities/accounting_period_status.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/entities/fiscal_year.dart';
import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/posting_coordinator_impl.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/stock_validation_service.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_dependency_detector.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/receipts_payments/transactions/data/repositories/financial_transaction_repository_impl.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/financial_transaction.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_type.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_source.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/rp_payment_method.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_status.dart';

class _FakePostingEngine implements PostingEngine {
  @override
  Future<double> applyInboundPosting({
    required InventoryDocumentRef document,
    required List<InboundLineData> lines,
    required String? warehouseId,
    required DateTime documentDate,
  }) async =>
      100.0;

  @override
  Future<double> applyOutboundPosting({
    required InventoryDocumentRef document,
    required List<OutboundLineData> lines,
    required String? warehouseId,
    required CostValuationMethod valuationMethod,
  }) async =>
      100.0;

  @override
  Future<double> applyTransferPosting({
    required InventoryDocumentRef document,
    required List<TransferLineData> lines,
    required String fromWarehouseId,
    required String toWarehouseId,
    required CostValuationMethod valuationMethod,
  }) async =>
      100.0;

  @override
  Future<void> reversePosting({
    required InventoryDocumentRef document,
  }) async {}
}

class _FakeStockValidationService implements StockValidationService {
  @override
  Future<double> getPostedBalance({
    required String itemCode,
    String? warehouseId,
  }) async =>
      1000.0;

  @override
  Future<List<StockShortageItem>> validateOutboundLines({
    required List<OutboundLineRequest> lines,
    String? warehouseId,
  }) async =>
      [];
}

class _FakeDependencyDetector implements InventoryDependencyDetector {
  @override
  Future<List<InventoryDocumentRef>> findDependentDocuments({
    required InventoryDocumentRef document,
  }) async =>
      [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AccountingDatabase accDb;
  late InventoryDatabase invDb;
  late ReceiptsPaymentsDatabase rpDb;
  late AccountRepositoryImpl accountRepo;
  late FiscalYearRepositoryImpl fiscalYearRepo;
  late AccountingPeriodValidator periodValidator;
  late JournalRepositoryImpl journalRepo;
  late JournalPostingService journalService;
  late PostingCoordinatorImpl postingCoordinator;
  late FinancialTransactionRepositoryImpl rpRepo;
  late Directory tempDir;

  late String acc1;
  late String acc2;

  const companyId = 'TestCompany';
  final year2025Start = DateTime.utc(2025, 1, 1);
  final year2025End = DateTime.utc(2025, 12, 31, 23, 59, 59);

  Future<FiscalYear> createFY2025({bool openAllPeriods = true}) async {
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
    if (openAllPeriods) {
      final periodList = await fiscalYearRepo.listPeriods(fy.uuid);
      for (final p in periodList) {
        await fiscalYearRepo.openPeriod(periodUuid: p.uuid, openedBy: 'admin');
      }
    }
    return fy;
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('period_test_');
    Hive.init(tempDir.path);

    accDb = AccountingDatabase.memory();
    invDb = InventoryDatabase.memory();
    rpDb = ReceiptsPaymentsDatabase.memory();

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

    postingCoordinator = PostingCoordinatorImpl(
      db: invDb,
      stockValidationService: _FakeStockValidationService(),
      dependencyDetector: _FakeDependencyDetector(),
      postingEngine: _FakePostingEngine(),
      periodValidator: periodValidator,
      permissionGuard: const AllowAllPermissionGuard(),
      readCompanyId: () => companyId,
    );

    rpRepo = FinancialTransactionRepositoryImpl(
      rpDb,
      periodValidator: periodValidator,
      readCompanyId: () => companyId,
    );
  });

  tearDown(() async {
    await accDb.close();
    await invDb.close();
    await rpDb.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ROOT FIX 19 — Closed Accounting Period Protection', () {
    test('1. Posting in an open period MUST succeed', () async {
      await createFY2025();

      final draft = JournalEntryDraft(
        entryDate: DateTime.utc(2025, 1, 15),
        voucherNumber: 'V-001',
        voucherType: 'general',
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        description: 'Test entry',
        isPosted: true,
        lines: [
          JournalLineDraft(
            accountUuid: acc1,
            debit: 100,
            credit: 0,
            currencyCode: 'YER',
          ),
          JournalLineDraft(
            accountUuid: acc2,
            debit: 0,
            credit: 100,
            currencyCode: 'YER',
          ),
        ],
      );

      final posted = await journalService.post(draft);
      expect(posted.isPosted, true);
    });

    test('2. Posting in a closed period MUST be rejected', () async {
      final fy = await createFY2025();
      final periods = await fiscalYearRepo.listPeriods(fy.uuid);
      final janPeriod = periods.firstWhere((p) => p.startDate.month == 1);

      await fiscalYearRepo.closePeriodAtomically(
        periodUuid: janPeriod.uuid,
        closedBy: 'user-1',
        fxRevaluationEnabled: false,
        fxRevaluationExecuted: false,
      );

      final draftInClosedPeriod = JournalEntryDraft(
        entryDate: DateTime.utc(2025, 1, 15),
        voucherNumber: 'V-002',
        voucherType: 'general',
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        description: 'Entry in closed period',
        isPosted: true,
        lines: [
          JournalLineDraft(
            accountUuid: acc1,
            debit: 100,
            credit: 0,
            currencyCode: 'YER',
          ),
          JournalLineDraft(
            accountUuid: acc2,
            debit: 0,
            credit: 100,
            currencyCode: 'YER',
          ),
        ],
      );

      expect(
        () async => await journalService.post(draftInClosedPeriod),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            JournalException.periodClosed,
          ),
        ),
      );
    });

    test('3. Inventory document posting in closed period MUST fail cleanly', () async {
      final fy = await createFY2025();
      final periods = await fiscalYearRepo.listPeriods(fy.uuid);
      final janPeriod = periods.firstWhere((p) => p.startDate.month == 1);

      await fiscalYearRepo.closePeriodAtomically(
        periodUuid: janPeriod.uuid,
        closedBy: 'user-1',
        fxRevaluationEnabled: false,
        fxRevaluationExecuted: false,
      );

      const receiptUuid = '11111111-1111-4111-8111-111111111111';
      const lineUuid = '22222222-2222-4222-8222-222222222222';
      await invDb.into(invDb.stockReceipts).insert(
            StockReceiptsCompanion.insert(
              uuid: receiptUuid,
              receiptNumber: 'REC-CLOSED-1',
              receiptDate: DateTime.utc(2025, 1, 10).millisecondsSinceEpoch,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
              companyId: const Value(companyId),
            ),
          );

      await invDb.into(invDb.stockMovementLines).insert(
            StockMovementLinesCompanion.insert(
              uuid: lineUuid,
              movementUuid: receiptUuid,
              movementType: 'receipt',
              itemCode: 'ITEM-1',
              itemName: 'Item 1',
              quantity: const Value(10.0),
              unitCost: const Value(50.0),
              totalCost: const Value(500.0),
            ),
          );

      final docRef = InventoryDocumentRef(
        documentId: receiptUuid,
        documentNumber: 'REC-CLOSED-1',
        documentType: InventoryDocumentType.stockReceipt,
        documentDate: DateTime.utc(2025, 1, 10),
        warehouseId: 'WH-1',
        status: InventoryDocumentStatus.draft,
      );

      final result = await postingCoordinator.post(document: docRef);
      expect(result, isA<PostInvalidStatus>());
      final invalidResult = result as PostInvalidStatus;
      expect(invalidResult.reason, contains('الفترة المحاسبية مغلقة'));
    });

    test('4. Receipts & Payments in closed period MUST be rejected on insert', () async {
      final fy = await createFY2025();
      final periods = await fiscalYearRepo.listPeriods(fy.uuid);
      final janPeriod = periods.firstWhere((p) => p.startDate.month == 1);

      await fiscalYearRepo.closePeriodAtomically(
        periodUuid: janPeriod.uuid,
        closedBy: 'user-1',
        fxRevaluationEnabled: false,
        fxRevaluationExecuted: false,
      );

      final draftRP = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.manualReceipt,
        transactionDate: DateTime.utc(2025, 1, 20),
        amount: 1500,
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        exchangeRate: 1.0,
        counterAmount: 1500,
        counterCurrencyCode: 'YER',
        counterExchangeRate: 1.0,
        cashAccountId: acc1,
        counterAccountId: acc2,
        paymentMethod: RpPaymentMethod.cash,
        documentStatus: TransactionStatus.unposted,
        lines: const [],
      );

      expect(
        () async => await rpRepo.insert(draftRP, transactionNumber: 'RP-001'),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            JournalException.periodClosed,
          ),
        ),
      );
    });

    test('5. Reopening a closed period permits posting again', () async {
      final fy = await createFY2025();
      final periods = await fiscalYearRepo.listPeriods(fy.uuid);
      final janPeriod = periods.firstWhere((p) => p.startDate.month == 1);

      await fiscalYearRepo.closePeriodAtomically(
        periodUuid: janPeriod.uuid,
        closedBy: 'user-1',
        fxRevaluationEnabled: false,
        fxRevaluationExecuted: false,
      );

      final draft = JournalEntryDraft(
        entryDate: DateTime.utc(2025, 1, 15),
        voucherNumber: 'V-REOPEN',
        voucherType: 'general',
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        description: 'Reopen test entry',
        isPosted: true,
        lines: [
          JournalLineDraft(
            accountUuid: acc1,
            debit: 500,
            credit: 0,
            currencyCode: 'YER',
          ),
          JournalLineDraft(
            accountUuid: acc2,
            debit: 0,
            credit: 500,
            currencyCode: 'YER',
          ),
        ],
      );

      expect(
        () async => await journalService.post(draft),
        throwsA(isA<JournalException>()),
      );

      // Reopen period
      await fiscalYearRepo.reopenPeriod(
        periodUuid: janPeriod.uuid,
        reopenedBy: 'admin',
        reason: 'Authorized adjustment',
      );

      final posted = await journalService.post(draft);
      expect(posted.isPosted, true);
    });

    test('6. Reversing entry into a closed period MUST be rejected', () async {
      final fy = await createFY2025();
      final periods = await fiscalYearRepo.listPeriods(fy.uuid);
      final janPeriod = periods.firstWhere((p) => p.startDate.month == 1);

      final draft = JournalEntryDraft(
        entryDate: DateTime.utc(2025, 1, 15),
        voucherNumber: 'V-REV-1',
        voucherType: 'general',
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        description: 'Entry to be reversed',
        isPosted: true,
        lines: [
          JournalLineDraft(
            accountUuid: acc1,
            debit: 200,
            credit: 0,
            currencyCode: 'YER',
          ),
          JournalLineDraft(
            accountUuid: acc2,
            debit: 0,
            credit: 200,
            currencyCode: 'YER',
          ),
        ],
      );

      final posted = await journalService.post(draft);

      await fiscalYearRepo.closePeriodAtomically(
        periodUuid: janPeriod.uuid,
        closedBy: 'user-1',
        fxRevaluationEnabled: false,
        fxRevaluationExecuted: false,
      );

      expect(
        () async => await journalService.reverseByUuid(
          posted.uuid,
          reverseDate: DateTime.utc(2025, 1, 20),
        ),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            JournalException.periodClosed,
          ),
        ),
      );
    });

    test('7. Editing entry date to backdate into a closed period MUST be rejected', () async {
      final fy = await createFY2025();
      final periods = await fiscalYearRepo.listPeriods(fy.uuid);
      final janPeriod = periods.firstWhere((p) => p.startDate.month == 1);

      final draftFeb = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.manualReceipt,
        transactionDate: DateTime.utc(2025, 2, 10),
        amount: 300,
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        exchangeRate: 1.0,
        counterAmount: 300,
        counterCurrencyCode: 'YER',
        counterExchangeRate: 1.0,
        cashAccountId: acc1,
        counterAccountId: acc2,
        paymentMethod: RpPaymentMethod.cash,
        documentStatus: TransactionStatus.unposted,
        lines: const [],
      );

      final rp = await rpRepo.insert(draftFeb, transactionNumber: 'RP-FEB-1');

      await fiscalYearRepo.closePeriodAtomically(
        periodUuid: janPeriod.uuid,
        closedBy: 'user-1',
        fxRevaluationEnabled: false,
        fxRevaluationExecuted: false,
      );

      final backdatedDraft = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.manualReceipt,
        transactionDate: DateTime.utc(2025, 1, 15),
        amount: 300,
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        exchangeRate: 1.0,
        counterAmount: 300,
        counterCurrencyCode: 'YER',
        counterExchangeRate: 1.0,
        cashAccountId: acc1,
        counterAccountId: acc2,
        paymentMethod: RpPaymentMethod.cash,
        documentStatus: TransactionStatus.unposted,
        lines: const [],
      );

      expect(
        () async => await rpRepo.update(rp.id, backdatedDraft),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            JournalException.periodClosed,
          ),
        ),
      );
    });

    test('8. Soft deleting a record in a closed period MUST be rejected', () async {
      final fy = await createFY2025();
      final periods = await fiscalYearRepo.listPeriods(fy.uuid);
      final janPeriod = periods.firstWhere((p) => p.startDate.month == 1);

      final draftRP = FinancialTransactionDraft(
        transactionType: TransactionType.receipt,
        source: TransactionSource.manualReceipt,
        transactionDate: DateTime.utc(2025, 1, 10),
        amount: 100,
        currencyCode: 'YER',
        baseCurrencyCode: 'YER',
        exchangeRate: 1.0,
        counterAmount: 100,
        counterCurrencyCode: 'YER',
        counterExchangeRate: 1.0,
        cashAccountId: acc1,
        counterAccountId: acc2,
        paymentMethod: RpPaymentMethod.cash,
        documentStatus: TransactionStatus.unposted,
        lines: const [],
      );

      final rp = await rpRepo.insert(draftRP, transactionNumber: 'RP-DEL-1');

      await fiscalYearRepo.closePeriodAtomically(
        periodUuid: janPeriod.uuid,
        closedBy: 'user-1',
        fxRevaluationEnabled: false,
        fxRevaluationExecuted: false,
      );

      expect(
        () async => await rpRepo.softDelete(rp.id),
        throwsA(
          isA<JournalException>().having(
            (e) => e.code,
            'code',
            JournalException.periodClosed,
          ),
        ),
      );
    });
  });
}
