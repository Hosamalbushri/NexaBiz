import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/ports/period_validator_port.dart';
import 'package:stock_count/shared/contracts/errors/journal_exception.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_currency_balance_repository_impl.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/data/repositories/account_repository_impl.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/services/accounting_period_validator.dart';

import 'package:stock_count/modules/accounting/journals/data/repositories/journal_repository_impl.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/fx_settlement_engine.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/fx_settlement_service.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/stock_movements/data/services/cost_layer_service_impl.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';

class MockPeriodValidator implements PeriodValidatorPort, AccountingPeriodValidator {
  bool allow = true;

  @override
  Future<void> assertEntryAllowed(DateTime entryDate) async {
    if (!allow) {
      throw const JournalException(JournalException.periodClosed, 'Period is closed');
    }
  }

  @override
  Future<void> assertMutationAllowed({
    required DateTime entryDate,
    DateTime? originalDate,
  }) async {
    if (!allow) {
      throw const JournalException(JournalException.periodClosed, 'Period is closed');
    }
  }
}

Future<void> _insertAccount(
  AccountingDatabase db, {
  required String uuid,
  required String code,
  required String name,
  required String accountType,
  required String normalBalance,
  required String companyId,
}) async {
  final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
  await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          uuid: uuid,
          accountCode: code,
          name: name,
          accountType: accountType,
          normalBalance: normalBalance,
          createdAt: nowMs,
          updatedAt: nowMs,
          companyId: Value(companyId),
        ),
      );
}

void main() {
  group('CURRENCY-09 — Foreign Exchange Gain/Loss Tests', () {
    late AccountingDatabase db;
    late InventoryDatabase invDb;
    late CostLayerServiceImpl costLayerService;
    late AccountRepositoryImpl accountRepo;
    late AccountCurrencyBalanceRepositoryImpl balanceRepo;
    late JournalRepositoryImpl journalRepo;
    late JournalPostingService postingService;
    late MockPeriodValidator periodValidator;
    late FxSettlementService settlementService;

    const companyId = 'COMP-CURRENCY-09';
    const fxGainAccountUuid = '11111111-1111-1111-1111-111111111101';
    const fxLossAccountUuid = '11111111-1111-1111-1111-111111111102';
    const apAccountUuid = '11111111-1111-1111-1111-111111111103';
    const arAccountUuid = '11111111-1111-1111-1111-111111111104';
    const cashAccountUuid = '11111111-1111-1111-1111-111111111105';

    setUp(() async {
      db = AccountingDatabase(executor: NativeDatabase.memory());
      invDb = InventoryDatabase(executor: NativeDatabase.memory());
      costLayerService = CostLayerServiceImpl(
        db: invDb,
        readCompanyId: () => companyId,
      );

      accountRepo = AccountRepositoryImpl(db, readCompanyId: () => companyId);
      balanceRepo = AccountCurrencyBalanceRepositoryImpl(db, readCompanyId: () => companyId);
      periodValidator = MockPeriodValidator();

      journalRepo = JournalRepositoryImpl(
        db,
        accounts: accountRepo,
        periodValidator: periodValidator,
        readCompanyId: () => companyId,
      );

      postingService = JournalPostingService(
        journals: journalRepo,
        periodValidator: periodValidator,
      );

      settlementService = FxSettlementService(
        engine: const FxSettlementEngine(),
        postingService: postingService,
        periodValidator: periodValidator,
        fxGainAccountUuid: fxGainAccountUuid,
        fxLossAccountUuid: fxLossAccountUuid,
        functionalCurrencyCode: 'YER',
      );

      // Seed accounts
      await _insertAccount(
        db,
        uuid: apAccountUuid,
        code: '2100',
        name: 'Accounts Payable',
        accountType: 'liability',
        normalBalance: 'credit',
        companyId: companyId,
      );

      await _insertAccount(
        db,
        uuid: arAccountUuid,
        code: '1200',
        name: 'Accounts Receivable',
        accountType: 'asset',
        normalBalance: 'debit',
        companyId: companyId,
      );

      await _insertAccount(
        db,
        uuid: cashAccountUuid,
        code: '1010',
        name: 'Cash Box',
        accountType: 'asset',
        normalBalance: 'debit',
        companyId: companyId,
      );

      await _insertAccount(
        db,
        uuid: fxGainAccountUuid,
        code: '4200',
        name: 'Foreign Exchange Gain',
        accountType: 'revenue',
        normalBalance: 'credit',
        companyId: companyId,
      );

      await _insertAccount(
        db,
        uuid: fxLossAccountUuid,
        code: '5200',
        name: 'Foreign Exchange Loss',
        accountType: 'expense',
        normalBalance: 'debit',
        companyId: companyId,
      );
    });

    tearDown(() async {
      await db.close();
      await invDb.close();
    });

    test('1. Supplier AP settlement with FX Loss (rate 140 -> 145 YER/SAR)', () async {
      // Supplier Liability booked originally: 100 SAR @ 140 YER/SAR = 14,000 YER
      // Settlement: 100 SAR @ 145 YER/SAR = 14,500 YER
      // Difference = 500 YER FX Loss
      final postedEntry = await settlementService.settleAndPost(
        settlementUuid: generateUuidV4(),
        partyType: SettlementPartyType.payable,
        accountUuid: apAccountUuid,
        cashAccountUuid: cashAccountUuid,
        currencyCode: 'SAR',
        settledAmountFc: 100.0,
        originalExchangeRate: 140.0,
        settlementExchangeRate: 145.0,
        settlementDate: DateTime.utc(2026, 1, 20),
      );

      final entry = await journalRepo.getByUuid(postedEntry.uuid);
      expect(entry, isNotNull);
      final baseDebitSum = entry!.lines.fold(0.0, (s, l) => s + l.baseDebit);
      final baseCreditSum = entry.lines.fold(0.0, (s, l) => s + l.baseCredit);
      expect(baseDebitSum, equals(14500.0));
      expect(baseCreditSum, equals(14500.0));

      // Verify balances
      final apMulti = await balanceRepo.getBalancesForAccount(apAccountUuid);
      final apSar = apMulti.balances['SAR'];
      expect(apSar?.totalDebit, equals(100.0));

      final lossMulti = await balanceRepo.getBalancesForAccount(fxLossAccountUuid);
      final lossYer = lossMulti.balances['YER'];
      expect(lossYer?.totalDebit, equals(500.0));
    });

    test('2. Supplier AP settlement with FX Gain (rate 140 -> 135 YER/SAR)', () async {
      // Supplier Liability booked originally: 100 SAR @ 140 YER/SAR = 14,000 YER
      // Settlement: 100 SAR @ 135 YER/SAR = 13,500 YER
      // Difference = 500 YER FX Gain
      final postedEntry = await settlementService.settleAndPost(
        settlementUuid: generateUuidV4(),
        partyType: SettlementPartyType.payable,
        accountUuid: apAccountUuid,
        cashAccountUuid: cashAccountUuid,
        currencyCode: 'SAR',
        settledAmountFc: 100.0,
        originalExchangeRate: 140.0,
        settlementExchangeRate: 135.0,
        settlementDate: DateTime.utc(2026, 1, 20),
      );

      final entry = await journalRepo.getByUuid(postedEntry.uuid);
      final baseDebitSum = entry!.lines.fold(0.0, (s, l) => s + l.baseDebit);
      final baseCreditSum = entry.lines.fold(0.0, (s, l) => s + l.baseCredit);
      expect(baseDebitSum, equals(14000.0));
      expect(baseCreditSum, equals(14000.0));

      final gainMulti = await balanceRepo.getBalancesForAccount(fxGainAccountUuid);
      final gainYer = gainMulti.balances['YER'];
      expect(gainYer?.totalCredit, equals(500.0));
    });

    test('3. Settlement with Zero FX difference (rate 140 -> 140 YER/SAR)', () async {
      final calc = const FxSettlementEngine().calculate(
        settlementUuid: generateUuidV4(),
        partyType: SettlementPartyType.payable,
        accountUuid: apAccountUuid,
        cashAccountUuid: cashAccountUuid,
        currencyCode: 'SAR',
        settledAmountFc: 100.0,
        originalExchangeRate: 140.0,
        settlementExchangeRate: 140.0,
      );

      expect(calc.differenceType, equals(FxDifferenceType.none));
      expect(calc.fxDifferenceBase, equals(0.0));

      final postedEntry = await settlementService.settleAndPost(
        settlementUuid: calc.settlementUuid,
        partyType: calc.partyType,
        accountUuid: calc.accountUuid,
        cashAccountUuid: calc.cashAccountUuid,
        currencyCode: calc.currencyCode,
        settledAmountFc: calc.settledAmountFc,
        originalExchangeRate: calc.originalExchangeRate,
        settlementExchangeRate: calc.settlementExchangeRate,
        settlementDate: DateTime.utc(2026, 1, 20),
      );

      final entry = await journalRepo.getByUuid(postedEntry.uuid);
      expect(entry!.lines.length, equals(2)); // Only AP and Cash lines, no FX Gain/Loss line
    });

    test('4. Partial settlement computes FX Gain/Loss strictly on settled portion', () async {
      // Total Invoice = 100 SAR @ 140 YER/SAR.
      // Partial Settlement = 50 SAR @ 145 YER/SAR.
      // Expected FX Loss on 50 SAR = 50 * (145 - 140) = 250 YER.
      await settlementService.settleAndPost(
        settlementUuid: generateUuidV4(),
        partyType: SettlementPartyType.payable,
        accountUuid: apAccountUuid,
        cashAccountUuid: cashAccountUuid,
        currencyCode: 'SAR',
        settledAmountFc: 50.0,
        originalExchangeRate: 140.0,
        settlementExchangeRate: 145.0,
        settlementDate: DateTime.utc(2026, 1, 20),
      );

      final lossMulti = await balanceRepo.getBalancesForAccount(fxLossAccountUuid);
      final lossYer = lossMulti.balances['YER'];
      expect(lossYer?.totalDebit, equals(250.0));
    });

    test('5. Customer AR settlement with FX Gain (rate 140 -> 145 YER/SAR)', () async {
      // Customer Asset: 100 SAR @ 140 YER/SAR = 14,000 YER
      // Collection: 100 SAR @ 145 YER/SAR = 14,500 YER received
      // Difference = 500 YER FX Gain
      await settlementService.settleAndPost(
        settlementUuid: generateUuidV4(),
        partyType: SettlementPartyType.receivable,
        accountUuid: arAccountUuid,
        cashAccountUuid: cashAccountUuid,
        currencyCode: 'SAR',
        settledAmountFc: 100.0,
        originalExchangeRate: 140.0,
        settlementExchangeRate: 145.0,
        settlementDate: DateTime.utc(2026, 1, 20),
      );

      final gainMulti = await balanceRepo.getBalancesForAccount(fxGainAccountUuid);
      final gainYer = gainMulti.balances['YER'];
      expect(gainYer?.totalCredit, equals(500.0));
    });

    test('6. Customer AR settlement with FX Loss (rate 140 -> 135 YER/SAR)', () async {
      // Customer Asset: 100 SAR @ 140 YER/SAR = 14,000 YER
      // Collection: 100 SAR @ 135 YER/SAR = 13,500 YER received
      // Difference = 500 YER FX Loss
      await settlementService.settleAndPost(
        settlementUuid: generateUuidV4(),
        partyType: SettlementPartyType.receivable,
        accountUuid: arAccountUuid,
        cashAccountUuid: cashAccountUuid,
        currencyCode: 'SAR',
        settledAmountFc: 100.0,
        originalExchangeRate: 140.0,
        settlementExchangeRate: 135.0,
        settlementDate: DateTime.utc(2026, 1, 20),
      );

      final lossMulti = await balanceRepo.getBalancesForAccount(fxLossAccountUuid);
      final lossYer = lossMulti.balances['YER'];
      expect(lossYer?.totalDebit, equals(500.0));
    });

    test('7. Multiple settlements over time at varying exchange rates', () async {
      // Settle 1: 50 SAR @ 142 YER/SAR (orig 140) -> 100 YER FX Loss
      await settlementService.settleAndPost(
        settlementUuid: generateUuidV4(),
        partyType: SettlementPartyType.payable,
        accountUuid: apAccountUuid,
        cashAccountUuid: cashAccountUuid,
        currencyCode: 'SAR',
        settledAmountFc: 50.0,
        originalExchangeRate: 140.0,
        settlementExchangeRate: 142.0,
        settlementDate: DateTime.utc(2026, 1, 20),
      );

      // Settle 2: 50 SAR @ 138 YER/SAR (orig 140) -> 100 YER FX Gain
      await settlementService.settleAndPost(
        settlementUuid: generateUuidV4(),
        partyType: SettlementPartyType.payable,
        accountUuid: apAccountUuid,
        cashAccountUuid: cashAccountUuid,
        currencyCode: 'SAR',
        settledAmountFc: 50.0,
        originalExchangeRate: 140.0,
        settlementExchangeRate: 138.0,
        settlementDate: DateTime.utc(2026, 1, 25),
      );

      final lossMulti = await balanceRepo.getBalancesForAccount(fxLossAccountUuid);
      final lossYer = lossMulti.balances['YER'];
      expect(lossYer?.totalDebit, equals(100.0));

      final gainMulti = await balanceRepo.getBalancesForAccount(fxGainAccountUuid);
      final gainYer = gainMulti.balances['YER'];
      expect(gainYer?.totalCredit, equals(100.0));
    });

    test('8. Closed period prevents settlement posting', () async {
      periodValidator.allow = false;

      expect(
        () => settlementService.settleAndPost(
          settlementUuid: generateUuidV4(),
          partyType: SettlementPartyType.payable,
          accountUuid: apAccountUuid,
          cashAccountUuid: cashAccountUuid,
          currencyCode: 'SAR',
          settledAmountFc: 100.0,
          originalExchangeRate: 140.0,
          settlementExchangeRate: 145.0,
          settlementDate: DateTime.utc(2026, 1, 20),
        ),
        throwsA(isA<JournalException>().having((e) => e.code, 'code', equals(JournalException.periodClosed))),
      );
    });

    test('9. Idempotency prevents duplicate settlement posting', () async {
      final settlementUuid = generateUuidV4();

      final res1 = await settlementService.settleAndPost(
        settlementUuid: settlementUuid,
        partyType: SettlementPartyType.payable,
        accountUuid: apAccountUuid,
        cashAccountUuid: cashAccountUuid,
        currencyCode: 'SAR',
        settledAmountFc: 100.0,
        originalExchangeRate: 140.0,
        settlementExchangeRate: 145.0,
        settlementDate: DateTime.utc(2026, 1, 20),
      );

      final res2 = await settlementService.settleAndPost(
        settlementUuid: settlementUuid,
        partyType: SettlementPartyType.payable,
        accountUuid: apAccountUuid,
        cashAccountUuid: cashAccountUuid,
        currencyCode: 'SAR',
        settledAmountFc: 100.0,
        originalExchangeRate: 140.0,
        settlementExchangeRate: 145.0,
        settlementDate: DateTime.utc(2026, 1, 20),
      );

      expect(res2.uuid, equals(res1.uuid));
    });

    test('10. STRICT INVARIANT: FX Gain/Loss settlement DOES NOT mutate inventory cost layers', () async {
      // 1. Create Inbound Inventory Cost Layer (10 units @ 1,400 YER valuation cost)
      await costLayerService.createLayer(
        CostLayer(
          itemCode: 'ITEM-INV-001',
          warehouseId: 'WH-01',
          movementUuid: generateUuidV4(),
          movementType: 'receipt',
          receivedDate: DateTime.utc(2026, 1, 10),
          receivedQty: 10.0,
          unitCost: 1400.0,
          inventoryCurrencyId: 'YER',
          companyId: companyId,
        ),
      );

      final layersBefore = await costLayerService.getOpenLayers('ITEM-INV-001', companyId: companyId);
      expect(layersBefore.first.unitCost, equals(1400.0));
      expect(layersBefore.first.totalCost, equals(14000.0));

      // 2. Perform AP FX Settlement with huge FX Loss (rate jumps to 200 YER/SAR)
      await settlementService.settleAndPost(
        settlementUuid: generateUuidV4(),
        partyType: SettlementPartyType.payable,
        accountUuid: apAccountUuid,
        cashAccountUuid: cashAccountUuid,
        currencyCode: 'SAR',
        settledAmountFc: 100.0,
        originalExchangeRate: 140.0,
        settlementExchangeRate: 200.0, // 6,000 YER FX Loss!
        settlementDate: DateTime.utc(2026, 1, 20),
      );

      // 3. Verify Inventory Cost Layer remains 100% UNCHANGED
      final layersAfter = await costLayerService.getOpenLayers('ITEM-INV-001', companyId: companyId);
      expect(layersAfter.length, equals(1));
      expect(layersAfter.first.unitCost, equals(1400.0)); // Still 1,400 YER!
      expect(layersAfter.first.totalCost, equals(14000.0)); // Still 14,000 YER!
    });
  });
}
