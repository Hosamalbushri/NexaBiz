import '../../../../core/permissions/permission_guard.dart';
import '../../../../core/utils/business_date.dart';
import '../../../../core/utils/id_generator.dart';
import '../../permissions/accounting_permissions.dart';
import '../entities/accounting_period_status.dart';
import '../entities/fiscal_year.dart';
import '../entities/journal_entry.dart';
import '../models/fiscal_year_exception.dart';
import '../repositories/account_repository.dart';
import '../repositories/currency_rate_repository.dart';
import '../repositories/fiscal_year_repository.dart';
import '../repositories/journal_repository.dart';
import 'accounting_period_generator.dart';
import 'fx_revaluation_service.dart';
import 'journal_posting_service.dart';

/// Creates fiscal years with generated closed periods.
class CreateFiscalYear {
  CreateFiscalYear({
    required FiscalYearRepository repository,
    required AccountRepository accounts,
    PermissionGuard permissionGuard = const AllowAllPermissionGuard(),
    AccountingPeriodGenerator generator = const AccountingPeriodGenerator(),
  }) : _repository = repository,
       _accounts = accounts,
       _guard = permissionGuard,
       _generator = generator;

  final FiscalYearRepository _repository;
  final AccountRepository _accounts;
  final PermissionGuard _guard;
  final AccountingPeriodGenerator _generator;

  Future<FiscalYear> call(FiscalYearDraft draft) async {
    _guard.requireAny(AccountingPermissions.fiscalYearsCreate);
    if (draft.fxRevaluationEnabled) {
      final gain = draft.fxGainAccountUuid?.trim() ?? '';
      final loss = draft.fxLossAccountUuid?.trim() ?? '';
      if (gain.isEmpty || loss.isEmpty) {
        throw const FiscalYearException(FiscalYearException.fxAccountsRequired);
      }
      await _assertPostingAccount(gain);
      await _assertPostingAccount(loss);
    }

    final periods = _generator.generate(
      startDate: draft.startDate,
      endDate: draft.endDate,
      periodCount: draft.periodCount,
      frequency: draft.periodFrequency,
    );

    return _repository.createFiscalYear(draft: draft, periods: periods);
  }

  Future<void> _assertPostingAccount(String uuid) async {
    final account = await _accounts.getByUuid(uuid);
    if (account == null || !account.canPost) {
      throw FiscalYearException(
        FiscalYearException.fxAccountInvalid,
        uuid,
      );
    }
  }
}

/// Opens a closed/reopened-eligible period for posting.
class OpenAccountingPeriod {
  OpenAccountingPeriod(
    this._repository, [
    this._guard = const AllowAllPermissionGuard(),
  ]);

  final FiscalYearRepository _repository;
  final PermissionGuard _guard;

  Future<AccountingPeriod> call({
    required String periodUuid,
    required String openedBy,
  }) {
    _guard.requireAny(AccountingPermissions.openPeriod);
    return _repository.openPeriod(periodUuid: periodUuid, openedBy: openedBy);
  }
}

/// Reopens a closed period with an audit reason.
class ReopenAccountingPeriod {
  ReopenAccountingPeriod(
    this._repository, [
    this._guard = const AllowAllPermissionGuard(),
  ]);

  final FiscalYearRepository _repository;
  final PermissionGuard _guard;

  Future<AccountingPeriod> call({
    required String periodUuid,
    required String reopenedBy,
    required String reason,
  }) {
    _guard.requireAny(AccountingPermissions.reopenPeriod);
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw const FiscalYearException(FiscalYearException.reopenReasonRequired);
    }
    return _repository.reopenPeriod(
      periodUuid: periodUuid,
      reopenedBy: reopenedBy,
      reason: trimmed,
    );
  }
}

/// Validates and closes an accounting period (idempotent).
class PeriodClosingService {
  PeriodClosingService({
    required FiscalYearRepository repository,
    required CurrencyRateRepository rates,
    required JournalPostingService posting,
    required JournalRepository journals,
    PermissionGuard permissionGuard = const AllowAllPermissionGuard(),
  }) : _repository = repository,
       _rates = rates,
       _posting = posting,
       _journals = journals,
       _guard = permissionGuard;

  final FiscalYearRepository _repository;
  final CurrencyRateRepository _rates;
  final JournalPostingService _posting;
  final JournalRepository _journals;
  final PermissionGuard _guard;

  static const fxSkipInsufficientData = 'insufficient_currency_position_data';
  static const fxSourceType = 'period_fx';

  Future<PeriodClosingPreflight> preflight(String periodUuid) async {
    final period = await _repository.getPeriodByUuid(periodUuid);
    if (period == null) {
      throw const FiscalYearException(FiscalYearException.periodNotFound);
    }
    final fy = await _repository.getByUuid(period.fiscalYearUuid);
    if (fy == null) {
      throw const FiscalYearException(FiscalYearException.notFound);
    }

    final unposted = await _repository.countUnpostedJournals(
      startInclusive: period.startDate,
      endInclusive: period.endDate,
    );

    final missingRates = <String>[];
    if (fy.fxRevaluationEnabled) {
      final currencies = await _repository.listForeignCurrenciesInRange(
        startInclusive: period.startDate,
        endInclusive: period.endDate,
        baseCurrencyCode: fy.baseCurrencyCode,
      );
      for (final code in currencies) {
        final rate = await _rates.getRateOn(code, period.endDate);
        if (rate == null || rate <= 0) {
          missingRates.add(code);
        }
      }
    }

    final blockers = <String>[];
    if (period.status == AccountingPeriodStatus.closing) {
      blockers.add(FiscalYearException.closingInProgress);
    }
    if (period.status != AccountingPeriodStatus.open &&
        period.status != AccountingPeriodStatus.reopened) {
      if (!(period.status == AccountingPeriodStatus.closed &&
          await _repository.getCompletedClosing(period.uuid) != null)) {
        blockers.add(FiscalYearException.periodNotCloseable);
      }
    }
    if (unposted > 0) {
      blockers.add(FiscalYearException.unpostedJournals);
    }
    if (missingRates.isNotEmpty) {
      blockers.add(FiscalYearException.missingExchangeRates);
    }

    final alreadyClosed =
        period.status == AccountingPeriodStatus.closed &&
        await _repository.getCompletedClosing(period.uuid) != null;

    return PeriodClosingPreflight(
      period: AccountingPeriodRef(
        uuid: period.uuid,
        periodNumber: period.periodNumber,
        name: period.name,
        startDate: period.startDate,
        endDate: period.endDate,
      ),
      unpostedJournalCount: unposted,
      missingExchangeRateCodes: missingRates,
      fxRevaluationEnabled: fy.fxRevaluationEnabled,
      canClose: alreadyClosed || blockers.isEmpty,
      blockers: alreadyClosed ? const [] : blockers,
    );
  }

  Future<PeriodClosingResult> close({
    required String periodUuid,
    required String closedBy,
  }) async {
    _guard.requireAny(AccountingPermissions.closePeriod);
    final period = await _repository.getPeriodByUuid(periodUuid);
    if (period == null) {
      throw const FiscalYearException(FiscalYearException.periodNotFound);
    }

    final existing = await _repository.getCompletedClosing(periodUuid);
    if (period.status == AccountingPeriodStatus.closed && existing != null) {
      return PeriodClosingResult(
        periodUuid: periodUuid,
        record: _view(existing),
        idempotentReplay: true,
      );
    }

    final pre = await preflight(periodUuid);
    if (!pre.canClose) {
      throw FiscalYearException(
        pre.blockers.isNotEmpty
            ? pre.blockers.first
            : FiscalYearException.periodNotCloseable,
        pre.blockers.join(','),
      );
    }

    final fy = await _repository.getByUuid(period.fiscalYearUuid);
    if (fy == null) {
      throw const FiscalYearException(FiscalYearException.notFound);
    }

    var fxExecuted = false;
    String? fxSkip;
    var fxGain = 0.0;
    var fxLoss = 0.0;
    String? journalUuid;

    if (fy.fxRevaluationEnabled) {
      final gainUuid = fy.fxGainAccountUuid?.trim() ?? '';
      final lossUuid = fy.fxLossAccountUuid?.trim() ?? '';
      if (gainUuid.isEmpty || lossUuid.isEmpty) {
        fxSkip = FiscalYearException.fxAccountsRequired;
      } else {
        final plan = await FxRevaluationService(
          journals: _journals,
          rates: _rates,
        ).build(
          asOfInclusive: period.endDate,
          baseCurrencyCode: fy.baseCurrencyCode,
          fxGainAccountUuid: gainUuid,
          fxLossAccountUuid: lossUuid,
        );
        if (plan.hasDifferences) {
          final entry = await _posting.post(
            JournalEntryDraft(
              entryDate: period.endDate,
              voucherNumber: 'FX-${period.periodNumber}',
              voucherType: 'إعادة تقييم عملة',
              currencyCode: fy.baseCurrencyCode.trim().toUpperCase(),
              baseCurrencyCode: fy.baseCurrencyCode,
              description: 'FX revaluation ${period.name}',
              isPosted: true,
              sourceType: fxSourceType,
              sourceId: period.uuid,
              lines: plan.lines,
            ),
          );
          journalUuid = entry.uuid;
          fxGain = plan.totalGain;
          fxLoss = plan.totalLoss;
          fxExecuted = true;
        } else {
          fxExecuted = true;
          fxSkip = null;
        }
      }
    }

    final record = await _repository.closePeriodAtomically(
      periodUuid: periodUuid,
      closedBy: closedBy,
      fxRevaluationEnabled: fy.fxRevaluationEnabled,
      fxRevaluationExecuted: fxExecuted,
      fxSkipReason: fxSkip,
      fxGain: fxGain,
      fxLoss: fxLoss,
      netFxDifference: fxGain - fxLoss,
      journalEntryUuid: journalUuid,
    );

    return PeriodClosingResult(
      periodUuid: periodUuid,
      record: _view(record),
      idempotentReplay: false,
    );
  }

  PeriodClosingRecordView _view(PeriodClosingRecord record) {
    return PeriodClosingRecordView(
      uuid: record.uuid,
      fxRevaluationEnabled: record.fxRevaluationEnabled,
      fxRevaluationExecuted: record.fxRevaluationExecuted,
      fxSkipReason: record.fxSkipReason,
      fxGain: record.fxGain,
      fxLoss: record.fxLoss,
      netFxDifference: record.netFxDifference,
      journalEntryUuid: record.journalEntryUuid,
    );
  }
}

/// Preview helper for the create wizard (no persistence).
List<GeneratedPeriodSpec> previewFiscalPeriods({
  required DateTime startDate,
  required DateTime endDate,
  required int periodCount,
  PeriodFrequency frequency = PeriodFrequency.monthly,
}) {
  return const AccountingPeriodGenerator().generate(
    startDate: startDate,
    endDate: endDate,
    periodCount: periodCount,
    frequency: frequency,
  );
}

/// Convenience for generating a default calendar FY end from start + months.
DateTime defaultFiscalYearEnd({
  required DateTime startDate,
  required int periodCount,
}) {
  final start = BusinessDate.utcDay(startDate);
  final next = DateTime.utc(start.year, start.month + periodCount, start.day);
  return next.subtract(const Duration(days: 1));
}

/// Stable id for tests / callers that need a uuid without importing core.
String newFiscalEntityUuid() => generateUuidV4();
