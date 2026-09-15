import 'package:drift/drift.dart';
import '../../../../core/database/nexabiz_database.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import '../account/account_currency_policy.dart';
import '../account/financial_account.dart';
import '../common/financial_exceptions.dart';
import '../fiscal_period/financial_period_gate.dart';
import '../fiscal_period/fiscal_period.dart';
import '../fiscal_period/fiscal_period_state_machine.dart';
import '../money/decimal_rate.dart';
import '../posting/posting_engine.dart';
import 'fx_revaluation_engine.dart';

class PeriodClosingRequest {
  final String companyId;
  final String periodId;
  final bool closeWithFx;
  final String baseCurrencyCode;
  final Map<String, DecimalRate>? closingRatesByCurrency;
  final String? unrealizedGainAccountId;
  final String? unrealizedLossAccountId;
  final List<AccountForeignBalance>? foreignBalances;
  final String? actorId;

  const PeriodClosingRequest({
    required this.companyId,
    required this.periodId,
    this.closeWithFx = false,
    required this.baseCurrencyCode,
    this.closingRatesByCurrency,
    this.unrealizedGainAccountId,
    this.unrealizedLossAccountId,
    this.foreignBalances,
    this.actorId,
  });
}

class PeriodClosingResult {
  final String operationId;
  final String closingRecordId;
  final String companyId;
  final String periodId;
  final bool fxExecuted;
  final String? fxJournalEntryId;
  final int closingDateMs;
  final bool wasAlreadyClosed;

  const PeriodClosingResult({
    required this.operationId,
    required this.closingRecordId,
    required this.companyId,
    required this.periodId,
    required this.fxExecuted,
    this.fxJournalEntryId,
    required this.closingDateMs,
    this.wasAlreadyClosed = false,
  });
}

/// Canonical Period Closing Operation Service (GATE-08 V4).
/// Orchestrates period closing with 3-phase failure-survives atomic boundaries.
class PeriodClosingOperationService {
  final NexabizDatabase db;
  final FinancialPeriodGate periodGate;

  PeriodClosingOperationService({
    required this.db,
    required this.periodGate,
  });

  /// Executes period closing operation adhering to V4 3-phase execution semantics.
  Future<PeriodClosingResult> executePeriodClosing(PeriodClosingRequest request) async {
    // 1. Idempotency Check: check if already closed
    final existingRecord = await (db.select(db.financialPeriodClosingRecords)
          ..where((t) => t.companyId.equals(request.companyId) & t.periodId.equals(request.periodId)))
        .getSingleOrNull();

    if (existingRecord != null) {
      return PeriodClosingResult(
        operationId: existingRecord.closingOperationId,
        closingRecordId: existingRecord.id,
        companyId: existingRecord.companyId,
        periodId: existingRecord.periodId,
        fxExecuted: existingRecord.fxRevaluationExecuted,
        fxJournalEntryId: existingRecord.journalEntryId,
        closingDateMs: existingRecord.closingDate,
        wasAlreadyClosed: true,
      );
    }

    // 2. Fetch period and validate operational state
    final periodData = await (db.select(db.financialFiscalPeriods)
          ..where((t) => t.companyId.equals(request.companyId) & t.id.equals(request.periodId)))
        .getSingleOrNull();

    if (periodData == null) {
      throw FinancialValidationException(
        'Period ${request.periodId} not found for company ${request.companyId}',
        'PERIOD_NOT_FOUND',
      );
    }

    final currentStatus = FiscalPeriodStatus.parse(periodData.status);

    // Validate transition to CLOSING
    PeriodStateMachine.validatePeriodTransition(
      currentStatus: currentStatus,
      targetStatus: FiscalPeriodStatus.closing,
    );

    // PHASE 1: Durable Operation Identity Registration (Independent Transaction)
    final operationId = generateUuidV7();
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.into(db.financialPeriodClosingOperations).insert(
          FinancialPeriodClosingOperationsCompanion.insert(
            id: Value(operationId),
            companyId: request.companyId,
            periodId: request.periodId,
            status: 'initiated',
            closeWithFx: Value(request.closeWithFx),
            initiatedAt: nowMs,
            initiatedBy: Value(request.actorId),
          ),
        );

    // PHASE 2: Atomic Business Transaction
    try {
      return await db.transaction(() async {
        // Double-checked locking inside transaction for concurrent calls
        final existingInside = await (db.select(db.financialPeriodClosingRecords)
              ..where((t) => t.companyId.equals(request.companyId) & t.periodId.equals(request.periodId)))
            .getSingleOrNull();

        if (existingInside != null) {
          return PeriodClosingResult(
            operationId: existingInside.closingOperationId,
            closingRecordId: existingInside.id,
            companyId: existingInside.companyId,
            periodId: existingInside.periodId,
            fxExecuted: existingInside.fxRevaluationExecuted,
            fxJournalEntryId: existingInside.journalEntryId,
            closingDateMs: existingInside.closingDate,
            wasAlreadyClosed: true,
          );
        }

        // Mark operation IN_PROGRESS
        await (db.update(db.financialPeriodClosingOperations)
              ..where((t) => t.id.equals(operationId)))
            .write(const FinancialPeriodClosingOperationsCompanion(
          status: Value('in_progress'),
        ));

        // Transition period to CLOSING
        await (db.update(db.financialFiscalPeriods)
              ..where((t) => t.id.equals(request.periodId)))
            .write(const FinancialFiscalPeriodsCompanion(
          status: Value('closing'),
        ));

        String? fxJournalId;
        bool fxExecuted = false;

        // Execute FX Revaluation if requested
        if (request.closeWithFx) {
          if (request.closingRatesByCurrency == null ||
              request.unrealizedGainAccountId == null ||
              request.unrealizedLossAccountId == null ||
              request.foreignBalances == null) {
            throw const FinancialValidationException(
              'FX Revaluation requires closing rates, gain/loss accounts, and foreign balances',
              'FX_PARAM_MISSING',
            );
          }

          final fxResult = FxRevaluationEngine.calculatePeriodFxRevaluation(
            companyId: request.companyId,
            baseCurrencyCode: request.baseCurrencyCode,
            closingDate: DateTime.fromMillisecondsSinceEpoch(periodData.endDate),
            foreignBalances: request.foreignBalances!,
            closingRatesByCurrency: request.closingRatesByCurrency!,
            unrealizedGainAccountId: request.unrealizedGainAccountId!,
            unrealizedLossAccountId: request.unrealizedLossAccountId!,
            closingOperationId: operationId,
          );

          // Snapshot closing rates
          for (final rateMap in fxResult.rateSnapshots) {
            await db.into(db.financialPeriodClosingRates).insert(
                  FinancialPeriodClosingRatesCompanion.insert(
                    id: Value(rateMap['id'] as String),
                    companyId: rateMap['company_id'],
                    closingOperationId: rateMap['closing_operation_id'],
                    fromCurrencyCode: rateMap['from_currency_code'],
                    toCurrencyCode: rateMap['to_currency_code'],
                    exchangeRateScaled: BigInt.parse(rateMap['exchange_rate_scaled'].toString()),
                  ),
                );
          }

          if (fxResult.hasJournal) {
            final fxAccountsMap = <String, FinancialAccount>{};
            for (final fb in request.foreignBalances!) {
              fxAccountsMap[fb.account.id] = fb.account;
            }
            fxAccountsMap[request.unrealizedGainAccountId!] = FinancialAccount(
              id: request.unrealizedGainAccountId!,
              companyId: request.companyId,
              code: '4999',
              nameAr: 'Unrealized Gain',
              nameEn: 'Unrealized Gain',
              accountType: FinancialAccountType.revenue,
              currencyPolicy: AccountCurrencyPolicy.functionalOnly,
            );
            fxAccountsMap[request.unrealizedLossAccountId!] = FinancialAccount(
              id: request.unrealizedLossAccountId!,
              companyId: request.companyId,
              code: '5999',
              nameAr: 'Unrealized Loss',
              nameEn: 'Unrealized Loss',
              accountType: FinancialAccountType.expense,
              currencyPolicy: AccountCurrencyPolicy.functionalOnly,
            );

            final prepResult = await PostingEngine.prepareAndValidateForPosting(
              entry: fxResult.fxJournalEntry!,
              accountsById: fxAccountsMap,
              postingTimestamp: DateTime.now(),
              periodGate: periodGate,
              capability: FinancialPostingCapability.periodCloseFx,
            );

            // Persist FX journal entry
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

            fxJournalId = prepResult.preparedEntry.id;
          }

          fxExecuted = true;
        }

        // Transition period to CLOSED
        await (db.update(db.financialFiscalPeriods)
              ..where((t) => t.id.equals(request.periodId)))
            .write(FinancialFiscalPeriodsCompanion(
          status: const Value('closed'),
          closedAt: Value(nowMs),
        ));

        // Create completed closing record fact
        final closingRecordId = generateUuidV7();
        await db.into(db.financialPeriodClosingRecords).insert(
              FinancialPeriodClosingRecordsCompanion.insert(
                id: Value(closingRecordId),
                companyId: request.companyId,
                fiscalYearId: periodData.fiscalYearId,
                periodId: request.periodId,
                closingOperationId: operationId,
                closingDate: periodData.endDate,
                fxRevaluationExecuted: Value(fxExecuted),
                journalEntryId: Value(fxJournalId),
                createdBy: Value(request.actorId),
                createdAt: nowMs,
              ),
            );

        // Mark operation COMPLETED
        await (db.update(db.financialPeriodClosingOperations)
              ..where((t) => t.id.equals(operationId)))
            .write(FinancialPeriodClosingOperationsCompanion(
          status: const Value('completed'),
          completedAt: Value(nowMs),
        ));

        return PeriodClosingResult(
          operationId: operationId,
          closingRecordId: closingRecordId,
          companyId: request.companyId,
          periodId: request.periodId,
          fxExecuted: fxExecuted,
          fxJournalEntryId: fxJournalId,
          closingDateMs: periodData.endDate,
        );
      });
    } catch (e) {
      // PHASE 3: Isolated Attempt Failure Audit Log (Survives Phase 2 Rollback)
      final failureReason = e.toString();
      final attemptId = generateUuidV7();

      try {
        // Record failure audit entry
        await db.into(db.financialPeriodClosingAttempts).insert(
              FinancialPeriodClosingAttemptsCompanion.insert(
                id: Value(attemptId),
                companyId: request.companyId,
                periodId: request.periodId,
                closingOperationId: Value(operationId),
                attemptedAt: nowMs,
                status: 'failed',
                failureReason: failureReason,
                attemptedBy: Value(request.actorId),
              ),
            );
      } catch (_) {}

      // Mark operation FAILED
      await (db.update(db.financialPeriodClosingOperations)
            ..where((t) => t.id.equals(operationId)))
          .write(const FinancialPeriodClosingOperationsCompanion(
        status: Value('failed'),
      ));

      // Revert period back to its previous status (OPEN or REOPENED)
      await (db.update(db.financialFiscalPeriods)
            ..where((t) => t.id.equals(request.periodId)))
          .write(FinancialFiscalPeriodsCompanion(
        status: Value(currentStatus.value),
      ));

      rethrow;
    }
  }
}
