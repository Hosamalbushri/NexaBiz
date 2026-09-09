import 'package:stock_count/core/domain/ports/period_validator_port.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';

import 'fx_settlement_engine.dart';

class FxSettlementService {
  const FxSettlementService({
    required this.engine,
    required this.postingService,
    required this.periodValidator,
    required this.fxGainAccountUuid,
    required this.fxLossAccountUuid,
    required this.functionalCurrencyCode,
  });

  final FxSettlementEngine engine;
  final JournalPostingService postingService;
  final PeriodValidatorPort periodValidator;
  final String fxGainAccountUuid;
  final String fxLossAccountUuid;
  final String functionalCurrencyCode;

  Future<JournalEntry> settleAndPost({
    required String settlementUuid,
    required SettlementPartyType partyType,
    required String accountUuid,
    required String cashAccountUuid,
    required String currencyCode,
    required double settledAmountFc,
    required double originalExchangeRate,
    required double settlementExchangeRate,
    required DateTime settlementDate,
    String? description,
    String? createdBy,
  }) async {
    // 1. Period check: Throws JournalException if accounting period is closed or invalid
    await periodValidator.assertEntryAllowed(settlementDate);

    // 2. Idempotency check: Return existing entry if already posted for this settlementUuid
    final existing = await postingService.findBySource(
      sourceType: 'fx_settlement',
      sourceId: settlementUuid,
    );
    if (existing != null) {
      return existing;
    }

    // 3. Calculate FX Settlement using pure engine
    final calc = engine.calculate(
      settlementUuid: settlementUuid,
      partyType: partyType,
      accountUuid: accountUuid,
      cashAccountUuid: cashAccountUuid,
      currencyCode: currencyCode,
      settledAmountFc: settledAmountFc,
      originalExchangeRate: originalExchangeRate,
      settlementExchangeRate: settlementExchangeRate,
    );

    // 4. Build journal lines according to party type and gain/loss
    final lines = _buildJournalLines(calc);

    final draft = JournalEntryDraft(
      uuid: settlementUuid,
      voucherNumber: 'SETTLE-${settlementUuid.substring(0, 8)}',
      voucherType: 'JV',
      entryDate: settlementDate,
      currencyCode: currencyCode,
      baseCurrencyCode: functionalCurrencyCode,
      description:
          description ??
          'FX Settlement $currencyCode ($settlementExchangeRate vs $originalExchangeRate)',
      sourceType: 'fx_settlement',
      sourceId: settlementUuid,
      lines: lines,
    );

    // 5. Post journal with balance validation & per-currency account balances update
    return postingService.post(draft, userId: createdBy);
  }

  List<JournalLineDraft> _buildJournalLines(FxSettlementCalculation calc) {
    final lines = <JournalLineDraft>[];
    int sort = 0;

    if (calc.partyType == SettlementPartyType.payable) {
      // Payable (AP): Paying liability
      lines.add(
        JournalLineDraft(
          accountUuid: calc.accountUuid,
          debit: calc.settledAmountFc,
          credit: 0.0,
          currencyCode: calc.currencyCode,
          exchangeRateToBase: calc.originalExchangeRate,
          baseDebit: calc.originalBaseAmount,
          baseCredit: 0.0,
          lineDescription:
              'Settlement of AP (${calc.currencyCode}) @ original rate ${calc.originalExchangeRate}',
          sortOrder: sort++,
        ),
      );

      if (calc.differenceType == FxDifferenceType.loss) {
        lines.add(
          JournalLineDraft(
            accountUuid: fxLossAccountUuid,
            debit: calc.fxDifferenceBase,
            credit: 0.0,
            currencyCode: functionalCurrencyCode,
            exchangeRateToBase: 1.0,
            baseDebit: calc.fxDifferenceBase,
            baseCredit: 0.0,
            lineDescription: 'FX Loss on AP settlement',
            sortOrder: sort++,
          ),
        );
      } else if (calc.differenceType == FxDifferenceType.gain) {
        lines.add(
          JournalLineDraft(
            accountUuid: fxGainAccountUuid,
            debit: 0.0,
            credit: calc.fxDifferenceBase,
            currencyCode: functionalCurrencyCode,
            exchangeRateToBase: 1.0,
            baseDebit: 0.0,
            baseCredit: calc.fxDifferenceBase,
            lineDescription: 'FX Gain on AP settlement',
            sortOrder: sort++,
          ),
        );
      }

      lines.add(
        JournalLineDraft(
          accountUuid: calc.cashAccountUuid,
          debit: 0.0,
          credit: calc.settledAmountFc,
          currencyCode: calc.currencyCode,
          exchangeRateToBase: calc.settlementExchangeRate,
          baseDebit: 0.0,
          baseCredit: calc.settlementBaseAmount,
          lineDescription:
              'Cash payment for AP settlement @ rate ${calc.settlementExchangeRate}',
          sortOrder: sort++,
        ),
      );
    } else {
      // Receivable (AR): Collecting asset
      lines.add(
        JournalLineDraft(
          accountUuid: calc.cashAccountUuid,
          debit: calc.settledAmountFc,
          credit: 0.0,
          currencyCode: calc.currencyCode,
          exchangeRateToBase: calc.settlementExchangeRate,
          baseDebit: calc.settlementBaseAmount,
          baseCredit: 0.0,
          lineDescription:
              'Cash collection for AR settlement @ rate ${calc.settlementExchangeRate}',
          sortOrder: sort++,
        ),
      );

      if (calc.differenceType == FxDifferenceType.loss) {
        lines.add(
          JournalLineDraft(
            accountUuid: fxLossAccountUuid,
            debit: calc.fxDifferenceBase,
            credit: 0.0,
            currencyCode: functionalCurrencyCode,
            exchangeRateToBase: 1.0,
            baseDebit: calc.fxDifferenceBase,
            baseCredit: 0.0,
            lineDescription: 'FX Loss on AR settlement',
            sortOrder: sort++,
          ),
        );
      } else if (calc.differenceType == FxDifferenceType.gain) {
        lines.add(
          JournalLineDraft(
            accountUuid: fxGainAccountUuid,
            debit: 0.0,
            credit: calc.fxDifferenceBase,
            currencyCode: functionalCurrencyCode,
            exchangeRateToBase: 1.0,
            baseDebit: 0.0,
            baseCredit: calc.fxDifferenceBase,
            lineDescription: 'FX Gain on AR settlement',
            sortOrder: sort++,
          ),
        );
      }

      lines.add(
        JournalLineDraft(
          accountUuid: calc.accountUuid,
          debit: 0.0,
          credit: calc.settledAmountFc,
          currencyCode: calc.currencyCode,
          exchangeRateToBase: calc.originalExchangeRate,
          baseDebit: 0.0,
          baseCredit: calc.originalBaseAmount,
          lineDescription:
              'Settlement of AR (${calc.currencyCode}) @ original rate ${calc.originalExchangeRate}',
          sortOrder: sort++,
        ),
      );
    }

    return lines;
  }
}
