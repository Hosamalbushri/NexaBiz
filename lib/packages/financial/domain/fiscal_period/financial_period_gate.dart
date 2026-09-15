import 'fiscal_period.dart';
import 'financial_period_resolver.dart';
import '../common/financial_exceptions.dart';

class PeriodNotFoundException extends FinancialException {
  final String companyId;
  final DateTime postingDate;

  PeriodNotFoundException({
    required this.companyId,
    required this.postingDate,
  }) : super(
          'No fiscal period found for company $companyId and posting date ${postingDate.toIso8601String()}',
          'PERIOD_NOT_FOUND',
        );
}

class PeriodAmbiguousException extends FinancialException {
  final String companyId;
  final DateTime postingDate;

  PeriodAmbiguousException({
    required this.companyId,
    required this.postingDate,
  }) : super(
          'Ambiguous fiscal period resolution for company $companyId and posting date ${postingDate.toIso8601String()}',
          'PERIOD_AMBIGUOUS',
        );
}

class PeriodNotOperationalException extends FinancialException {
  final String periodId;
  final FiscalPeriodStatus status;

  PeriodNotOperationalException({
    required this.periodId,
    required this.status,
  }) : super(
          'Fiscal period $periodId in status ${status.value} is non-operational',
          'PERIOD_NOT_OPERATIONAL',
        );
}

class PeriodClosedException extends FinancialException {
  final String periodId;
  final FiscalPeriodStatus status;

  PeriodClosedException({
    required this.periodId,
    required this.status,
  }) : super(
          'Fiscal period $periodId in status ${status.value} rejects financial postings',
          'PERIOD_CLOSED',
        );
}

class PeriodClosingInProgressException extends FinancialException {
  final String periodId;

  PeriodClosingInProgressException({
    required this.periodId,
  }) : super(
          'Fiscal period $periodId is currently CLOSING and requires specialized capability for posting',
          'PERIOD_CLOSING_IN_PROGRESS',
        );
}

/// Authorization capabilities for posting entries.
enum FinancialPostingCapability {
  normalPosting('NORMAL_POSTING'),
  periodCloseFx('PERIOD_CLOSE_FX'),
  yearEndClose('YEAR_END_CLOSE'),
  openingBalance('OPENING_BALANCE');

  final String code;
  const FinancialPostingCapability(this.code);
}

/// Canonical Financial Period Gate (GATE-08 V4).
/// All financial document posting flows MUST pass through this gate.
class FinancialPeriodGate {
  final FinancialPeriodResolver resolver;

  const FinancialPeriodGate(this.resolver);

  /// Validates and resolves period authorization for a posting operation.
  /// Returns the authoritative [FinancialFiscalPeriod].
  Future<FinancialFiscalPeriod> validateAndResolvePostingPeriod({
    required String companyId,
    required DateTime postingDate,
    FinancialPostingCapability capability = FinancialPostingCapability.normalPosting,
  }) async {
    final resolution = await resolver.resolvePeriod(
      companyId: companyId,
      postingDate: postingDate,
    );

    if (resolution.isNotFound) {
      throw PeriodNotFoundException(
        companyId: companyId,
        postingDate: postingDate,
      );
    }

    if (resolution.isAmbiguous) {
      throw PeriodAmbiguousException(
        companyId: companyId,
        postingDate: postingDate,
      );
    }

    final period = resolution.period!;

    // Tenancy check
    if (period.companyId != companyId) {
      throw FinancialValidationException(
        'Cross-tenant period violation: period companyId (${period.companyId}) != $companyId',
        'CROSS_TENANT_PERIOD',
      );
    }

    // Status validation based on capability
    switch (period.status) {
      case FiscalPeriodStatus.draft:
        throw PeriodNotOperationalException(
          periodId: period.id,
          status: period.status,
        );

      case FiscalPeriodStatus.open:
      case FiscalPeriodStatus.reopened:
        // Open and Reopened allow all valid postings
        return period;

      case FiscalPeriodStatus.closing:
        // Closing period requires specialized FX or Year-End capabilities
        if (capability == FinancialPostingCapability.periodCloseFx ||
            capability == FinancialPostingCapability.yearEndClose) {
          return period;
        }
        throw PeriodClosingInProgressException(periodId: period.id);

      case FiscalPeriodStatus.closed:
      case FiscalPeriodStatus.locked:
        throw PeriodClosedException(
          periodId: period.id,
          status: period.status,
        );
    }
  }
}
