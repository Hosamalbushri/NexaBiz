import 'package:drift/drift.dart';
import '../../../../core/database/nexabiz_database.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import '../account/financial_account.dart';
import '../common/financial_exceptions.dart';
import '../fiscal_period/financial_period_gate.dart';
import '../journal/financial_side.dart';
import '../journal/journal_entry.dart';
import '../journal/journal_line.dart';
import '../money/decimal_money.dart';
import '../money/decimal_rate.dart';
import '../posting/posting_engine.dart';
import 'fx_revaluation_engine.dart';
import 'period_closing_operation_service.dart';

class AccountYearEndBalance {
  final FinancialAccount account;
  final DecimalMoney balanceBase;

  const AccountYearEndBalance({
    required this.account,
    required this.balanceBase,
  });
}

class YearEndClosingRequest {
  final String companyId;
  final String fiscalYearId;
  final String baseCurrencyCode;
  final String retainedEarningsAccountId;
  final List<AccountYearEndBalance> accountBalances;
  final Map<String, DecimalRate>? closingRatesByCurrency;
  final String? unrealizedGainAccountId;
  final String? unrealizedLossAccountId;
  final List<AccountForeignBalance>? foreignBalances;
  final String? actorId;

  const YearEndClosingRequest({
    required this.companyId,
    required this.fiscalYearId,
    required this.baseCurrencyCode,
    required this.retainedEarningsAccountId,
    required this.accountBalances,
    this.closingRatesByCurrency,
    this.unrealizedGainAccountId,
    this.unrealizedLossAccountId,
    this.foreignBalances,
    this.actorId,
  });
}

class YearEndClosingResult {
  final String fiscalYearClosingRecordId;
  final String companyId;
  final String closedFiscalYearId;
  final String nextFiscalYearId;
  final String yearEndJournalId;
  final String openingBalanceJournalId;

  const YearEndClosingResult({
    required this.fiscalYearClosingRecordId,
    required this.companyId,
    required this.closedFiscalYearId,
    required this.nextFiscalYearId,
    required this.yearEndJournalId,
    required this.openingBalanceJournalId,
  });
}

/// Canonical Fiscal Year-End Closing Engine (GATE-08 V4).
/// Handles final period close, P&L closing journals, next fiscal year activation,
/// opening balance journals, opening boundary projections, and irreversible locking.
class YearEndClosingEngine {
  final NexabizDatabase db;
  final FinancialPeriodGate periodGate;
  final PeriodClosingOperationService periodClosingService;

  YearEndClosingEngine({
    required this.db,
    required this.periodGate,
    required this.periodClosingService,
  });

  /// Executes complete Year-End Closing flow in an atomic transaction.
  Future<YearEndClosingResult> executeYearEndClosing(YearEndClosingRequest request) async {
    // 1. Check if Fiscal Year is already closed/locked
    final existingCloseRecord = await (db.select(db.financialFiscalYearClosingRecords)
          ..where((t) => t.companyId.equals(request.companyId) & t.fiscalYearId.equals(request.fiscalYearId)))
        .getSingleOrNull();

    if (existingCloseRecord != null) {
      return YearEndClosingResult(
        fiscalYearClosingRecordId: existingCloseRecord.id,
        companyId: existingCloseRecord.companyId,
        closedFiscalYearId: existingCloseRecord.fiscalYearId,
        nextFiscalYearId: existingCloseRecord.nextFiscalYearId,
        yearEndJournalId: existingCloseRecord.yearEndJournalId,
        openingBalanceJournalId: existingCloseRecord.openingBalanceJournalId,
      );
    }

    // 2. Fetch Fiscal Year and its child periods
    final fyData = await (db.select(db.financialFiscalYears)
          ..where((t) => t.companyId.equals(request.companyId) & t.id.equals(request.fiscalYearId)))
        .getSingleOrNull();

    if (fyData == null) {
      throw FinancialValidationException(
        'Fiscal Year ${request.fiscalYearId} not found',
        'FISCAL_YEAR_NOT_FOUND',
      );
    }

    if (fyData.status == 'locked') {
      throw const FinancialValidationException(
        'Cannot close locked Fiscal Year',
        'FY_LOCKED',
      );
    }

    final periods = await (db.select(db.financialFiscalPeriods)
          ..where((t) => t.companyId.equals(request.companyId) & t.fiscalYearId.equals(request.fiscalYearId))
          ..orderBy([(t) => OrderingTerm(expression: t.periodNumber, mode: OrderingMode.asc)]))
        .get();

    if (periods.isEmpty) {
      throw const FinancialValidationException(
        'Fiscal Year has no periods',
        'FY_NO_PERIODS',
      );
    }

    // Identify final period
    final finalPeriodRow = periods.last;

    // 3. Execute Period Closing for final period if not already closed
    if (finalPeriodRow.status == 'open' || finalPeriodRow.status == 'reopened') {
      await periodClosingService.executePeriodClosing(
        PeriodClosingRequest(
          companyId: request.companyId,
          periodId: finalPeriodRow.id,
          closeWithFx: request.foreignBalances != null && request.closingRatesByCurrency != null,
          baseCurrencyCode: request.baseCurrencyCode,
          closingRatesByCurrency: request.closingRatesByCurrency,
          unrealizedGainAccountId: request.unrealizedGainAccountId,
          unrealizedLossAccountId: request.unrealizedLossAccountId,
          foreignBalances: request.foreignBalances,
          actorId: request.actorId,
        ),
      );
    }

    // Atomic Year-End Business Transaction
    return await db.transaction(() async {
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // Ensure final period status is set to CLOSING so PeriodGate authorizes YEAR_END_CLOSE capability
      await (db.update(db.financialFiscalPeriods)
            ..where((t) => t.id.equals(finalPeriodRow.id)))
          .write(const FinancialFiscalPeriodsCompanion(
        status: Value('closing'),
      ));

      // 4. Calculate P&L Net Result (Revenue - Expense)
      BigInt totalRevenueScaled = BigInt.zero;
      BigInt totalExpenseScaled = BigInt.zero;

      final yearEndJournalId = generateUuidV7();
      final List<JournalLine> yearEndLines = [];
      int lineNo = 1;

      for (final item in request.accountBalances) {
        final acc = item.account;
        final amountScaled = item.balanceBase.unitsScaled;

        if (acc.accountType == FinancialAccountType.revenue) {
          totalRevenueScaled += amountScaled;
          // Zero out revenue (debit line)
          if (amountScaled != BigInt.zero) {
            yearEndLines.add(
              JournalLine.create(
                id: generateUuidV7(),
                companyId: request.companyId,
                journalEntryId: yearEndJournalId,
                lineNumber: lineNo++,
                accountId: acc.id,
                side: FinancialSide.debit,
                transactionAmount: DecimalMoney.fromScaled(amountScaled, request.baseCurrencyCode),
                exchangeRate: DecimalRate.identity(request.baseCurrencyCode),
                baseCurrencyCode: request.baseCurrencyCode,
              ),
            );
          }
        } else if (acc.accountType == FinancialAccountType.expense) {
          totalExpenseScaled += amountScaled;
          // Zero out expense (credit line)
          if (amountScaled != BigInt.zero) {
            yearEndLines.add(
              JournalLine.create(
                id: generateUuidV7(),
                companyId: request.companyId,
                journalEntryId: yearEndJournalId,
                lineNumber: lineNo++,
                accountId: acc.id,
                side: FinancialSide.credit,
                transactionAmount: DecimalMoney.fromScaled(amountScaled, request.baseCurrencyCode),
                exchangeRate: DecimalRate.identity(request.baseCurrencyCode),
                baseCurrencyCode: request.baseCurrencyCode,
              ),
            );
          }
        }
      }

      final netResultScaled = totalRevenueScaled - totalExpenseScaled;

      // 5. Transfer Net Result to Retained Earnings
      if (netResultScaled > BigInt.zero) {
        // Net Profit -> Credit Retained Earnings
        yearEndLines.add(
          JournalLine.create(
            id: generateUuidV7(),
            companyId: request.companyId,
            journalEntryId: yearEndJournalId,
            lineNumber: lineNo++,
            accountId: request.retainedEarningsAccountId,
            side: FinancialSide.credit,
            transactionAmount: DecimalMoney.fromScaled(netResultScaled, request.baseCurrencyCode),
            exchangeRate: DecimalRate.identity(request.baseCurrencyCode),
            baseCurrencyCode: request.baseCurrencyCode,
          ),
        );
      } else if (netResultScaled < BigInt.zero) {
        // Net Loss -> Debit Retained Earnings
        final absLoss = netResultScaled.abs();
        yearEndLines.add(
          JournalLine.create(
            id: generateUuidV7(),
            companyId: request.companyId,
            journalEntryId: yearEndJournalId,
            lineNumber: lineNo++,
            accountId: request.retainedEarningsAccountId,
            side: FinancialSide.debit,
            transactionAmount: DecimalMoney.fromScaled(absLoss, request.baseCurrencyCode),
            exchangeRate: DecimalRate.identity(request.baseCurrencyCode),
            baseCurrencyCode: request.baseCurrencyCode,
          ),
        );
      }

      // Post P&L Year-End Journal Entry if balanced/needed
      if (yearEndLines.length >= 2) {
        final yearEndEntry = JournalEntry(
          id: yearEndJournalId,
          companyId: request.companyId,
          entryNumber: 'YE-CLOSE-${fyData.code}',
          baseCurrencyCode: request.baseCurrencyCode,
          postingDate: DateTime.fromMillisecondsSinceEpoch(finalPeriodRow.endDate),
          description: 'P&L Year-End Closing Journal ${fyData.code}',
          sourceModule: 'year_end_close',
          lines: yearEndLines,
        );

        final prepResult = await PostingEngine.prepareAndValidateForPosting(
          entry: yearEndEntry,
          accountsById: {for (final b in request.accountBalances) b.account.id: b.account},
          postingTimestamp: DateTime.now(),
          periodGate: periodGate,
          capability: FinancialPostingCapability.yearEndClose,
        );

        await db.into(db.financialJournalEntries).insert(
              FinancialJournalEntriesCompanion.insert(
                id: Value(prepResult.preparedEntry.id),
                companyId: prepResult.preparedEntry.companyId,
                entryNumber: prepResult.preparedEntry.entryNumber,
                baseCurrencyCode: prepResult.preparedEntry.baseCurrencyCode,
                postingDate: prepResult.preparedEntry.postingDate,
                status: Value(prepResult.preparedEntry.status.toDbValue()),
                postedAt: Value(prepResult.preparedEntry.postedAt),
                description: Value(prepResult.preparedEntry.description),
                sourceModule: Value(prepResult.preparedEntry.sourceModule),
              ),
            );

        for (final line in prepResult.preparedEntry.lines) {
          await db.into(db.financialJournalLines).insert(
                FinancialJournalLinesCompanion.insert(
                  id: Value(line.id),
                  companyId: line.companyId,
                  journalEntryId: line.journalEntryId,
                  lineNumber: line.lineNumber,
                  accountId: line.accountId,
                  side: line.side.toDbValue(),
                  transactionCurrencyCode: line.transactionAmount.currencyCode,
                  transactionAmountScaled: line.transactionAmount.unitsScaled,
                  exchangeRateScaled: line.exchangeRate.rateScaled,
                  baseAmountScaled: line.baseAmount.unitsScaled,
                ),
              );
        }
      }

      // 6. Update target Fiscal Year -> CLOSED
      await (db.update(db.financialFiscalYears)
            ..where((t) => t.id.equals(request.fiscalYearId)))
          .write(FinancialFiscalYearsCompanion(
        status: const Value('closed'),
        closedAt: Value(nowMs),
        closedBy: request.actorId != null ? Value(request.actorId) : const Value.absent(),
      ));

      // 7. Create Next Fiscal Year & Period 1
      final nextFyId = generateUuidV7();
      final nextFyStartMs = fyData.endDate + 1;
      final nextFyEndMs = nextFyStartMs + (365 * 86400 * 1000) - 1;

      final nextFyCode = 'FY-${DateTime.fromMillisecondsSinceEpoch(nextFyStartMs).year}';

      await db.into(db.financialFiscalYears).insert(
            FinancialFiscalYearsCompanion.insert(
              id: Value(nextFyId),
              companyId: request.companyId,
              code: nextFyCode,
              name: 'Fiscal Year ${DateTime.fromMillisecondsSinceEpoch(nextFyStartMs).year}',
              startDate: nextFyStartMs,
              endDate: nextFyEndMs,
              status: 'open',
              createdAt: nowMs,
              updatedAt: nowMs,
              createdBy: request.actorId != null ? Value(request.actorId) : const Value.absent(),
            ),
          );

      final nextPeriod1Id = generateUuidV7();
      await db.into(db.financialFiscalPeriods).insert(
            FinancialFiscalPeriodsCompanion.insert(
              id: Value(nextPeriod1Id),
              companyId: request.companyId,
              fiscalYearId: nextFyId,
              periodNumber: 1,
              name: 'Period 1 ${DateTime.fromMillisecondsSinceEpoch(nextFyStartMs).year}',
              startDate: nextFyStartMs,
              endDate: nextFyStartMs + (30 * 86400 * 1000) - 1,
              status: 'open',
              openedAt: Value(nowMs),
            ),
          );

      // 8. Create Opening Balance Journal Entry in Next Fiscal Year
      final openingJournalId = generateUuidV7();
      final List<JournalLine> openingLines = [];
      int openLineNo = 1;

      for (final item in request.accountBalances) {
        final acc = item.account;
        // Skip P&L accounts (opening balance = 0)
        if (acc.accountType == FinancialAccountType.revenue || acc.accountType == FinancialAccountType.expense) {
          continue;
        }

        BigInt openingBal = item.balanceBase.unitsScaled;

        // If Retained Earnings account, include netResultScaled
        if (acc.id == request.retainedEarningsAccountId) {
          openingBal += netResultScaled;
        }

        FinancialSide side;
        if (acc.accountType == FinancialAccountType.asset) {
          side = openingBal >= BigInt.zero ? FinancialSide.debit : FinancialSide.credit;
        } else {
          side = openingBal >= BigInt.zero ? FinancialSide.credit : FinancialSide.debit;
        }
        final absBal = openingBal.abs();

        openingLines.add(
          JournalLine.create(
            id: generateUuidV7(),
            companyId: request.companyId,
            journalEntryId: openingJournalId,
            lineNumber: openLineNo++,
            accountId: acc.id,
            side: side,
            transactionAmount: DecimalMoney.fromScaled(absBal, request.baseCurrencyCode),
            exchangeRate: DecimalRate.identity(request.baseCurrencyCode),
            baseCurrencyCode: request.baseCurrencyCode,
          ),
        );

        // Build Opening Boundary projection snapshot
        await db.into(db.financialFiscalYearOpeningBoundaries).insert(
              FinancialFiscalYearOpeningBoundariesCompanion.insert(
                id: Value(generateUuidV7()),
                companyId: request.companyId,
                fiscalYearId: nextFyId,
                accountId: acc.id,
                currencyCode: request.baseCurrencyCode,
                openingBalanceScaled: openingBal,
                createdAt: nowMs,
              ),
            );
      }

      if (openingLines.length >= 2) {
        final openingEntry = JournalEntry(
          id: openingJournalId,
          companyId: request.companyId,
          entryNumber: 'OP-BAL-$nextFyCode',
          baseCurrencyCode: request.baseCurrencyCode,
          postingDate: DateTime.fromMillisecondsSinceEpoch(nextFyStartMs),
          description: 'Opening Balance Journal $nextFyCode',
          sourceModule: 'opening_balance',
          lines: openingLines,
        );

        final prepOpening = await PostingEngine.prepareAndValidateForPosting(
          entry: openingEntry,
          accountsById: {for (final b in request.accountBalances) b.account.id: b.account},
          postingTimestamp: DateTime.now(),
          periodGate: periodGate,
          capability: FinancialPostingCapability.openingBalance,
        );

        await db.into(db.financialJournalEntries).insert(
              FinancialJournalEntriesCompanion.insert(
                id: Value(prepOpening.preparedEntry.id),
                companyId: prepOpening.preparedEntry.companyId,
                entryNumber: prepOpening.preparedEntry.entryNumber,
                baseCurrencyCode: prepOpening.preparedEntry.baseCurrencyCode,
                postingDate: prepOpening.preparedEntry.postingDate,
                status: Value(prepOpening.preparedEntry.status.toDbValue()),
                postedAt: Value(prepOpening.preparedEntry.postedAt),
                description: Value(prepOpening.preparedEntry.description),
                sourceModule: Value(prepOpening.preparedEntry.sourceModule),
              ),
            );

        for (final line in prepOpening.preparedEntry.lines) {
          await db.into(db.financialJournalLines).insert(
                FinancialJournalLinesCompanion.insert(
                  id: Value(line.id),
                  companyId: line.companyId,
                  journalEntryId: line.journalEntryId,
                  lineNumber: line.lineNumber,
                  accountId: line.accountId,
                  side: line.side.toDbValue(),
                  transactionCurrencyCode: line.transactionAmount.currencyCode,
                  transactionAmountScaled: line.transactionAmount.unitsScaled,
                  exchangeRateScaled: line.exchangeRate.rateScaled,
                  baseAmountScaled: line.baseAmount.unitsScaled,
                ),
              );
        }
      }

      // 9. Persist Fiscal Year Closing Record Fact
      final fyClosingRecordId = generateUuidV7();
      await db.into(db.financialFiscalYearClosingRecords).insert(
            FinancialFiscalYearClosingRecordsCompanion.insert(
              id: Value(fyClosingRecordId),
              companyId: request.companyId,
              fiscalYearId: request.fiscalYearId,
              finalPeriodId: finalPeriodRow.id,
              nextFiscalYearId: nextFyId,
              yearEndJournalId: yearEndJournalId,
              openingBalanceJournalId: openingJournalId,
              closedAt: nowMs,
              closedBy: request.actorId != null ? Value(request.actorId) : const Value.absent(),
            ),
          );

      // 10. Lock target Fiscal Year & all child periods (irreversible)
      await (db.update(db.financialFiscalYears)
            ..where((t) => t.id.equals(request.fiscalYearId)))
          .write(const FinancialFiscalYearsCompanion(
        status: Value('locked'),
      ));

      await (db.update(db.financialFiscalPeriods)
            ..where((t) => t.fiscalYearId.equals(request.fiscalYearId)))
          .write(const FinancialFiscalPeriodsCompanion(
        status: Value('locked'),
      ));

      return YearEndClosingResult(
        fiscalYearClosingRecordId: fyClosingRecordId,
        companyId: request.companyId,
        closedFiscalYearId: request.fiscalYearId,
        nextFiscalYearId: nextFyId,
        yearEndJournalId: yearEndJournalId,
        openingBalanceJournalId: openingJournalId,
      );
    });
  }
}
