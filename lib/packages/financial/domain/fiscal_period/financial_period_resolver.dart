import 'fiscal_period.dart';

enum PeriodResolutionStatus {
  periodNotFound('PERIOD_NOT_FOUND'),
  periodValid('PERIOD_VALID'),
  periodAmbiguous('PERIOD_AMBIGUOUS');

  final String code;
  const PeriodResolutionStatus(this.code);
}

class PeriodResolutionResult {
  final PeriodResolutionStatus status;
  final FinancialFiscalPeriod? period;
  final String? errorMessage;

  const PeriodResolutionResult._({
    required this.status,
    this.period,
    this.errorMessage,
  });

  factory PeriodResolutionResult.notFound() {
    return const PeriodResolutionResult._(
      status: PeriodResolutionStatus.periodNotFound,
      errorMessage: 'No fiscal period found for company and posting date',
    );
  }

  factory PeriodResolutionResult.valid(FinancialFiscalPeriod period) {
    return PeriodResolutionResult._(
      status: PeriodResolutionStatus.periodValid,
      period: period,
    );
  }

  factory PeriodResolutionResult.ambiguous(int count) {
    return PeriodResolutionResult._(
      status: PeriodResolutionStatus.periodAmbiguous,
      errorMessage: 'Ambiguous period resolution: $count periods match the posting date',
    );
  }

  bool get isValid => status == PeriodResolutionStatus.periodValid && period != null;
  bool get isNotFound => status == PeriodResolutionStatus.periodNotFound;
  bool get isAmbiguous => status == PeriodResolutionStatus.periodAmbiguous;
}

/// Interface for searching candidate fiscal periods for a company.
abstract class FiscalPeriodSearchRepository {
  Future<List<FinancialFiscalPeriod>> findPeriodsContainingDate({
    required String companyId,
    required DateTime postingDate,
  });

  Future<FinancialFiscalPeriod?> getPeriodById({
    required String companyId,
    required String periodId,
  });
}

/// Canonical Financial Period Resolver (GATE-08 V4).
/// Strictly resolves period by `companyId` and `postingDate`.
/// Caller-supplied `periodId` override is strictly IGNORED.
class FinancialPeriodResolver {
  final FiscalPeriodSearchRepository repository;

  const FinancialPeriodResolver(this.repository);

  /// Resolves the canonical operational fiscal period for a posting date.
  ///
  /// - 0 matches => PERIOD_NOT_FOUND
  /// - 1 match => PERIOD_VALID
  /// - >1 matches => PERIOD_AMBIGUOUS
  Future<PeriodResolutionResult> resolvePeriod({
    required String companyId,
    required DateTime postingDate,
    String? ignoredCallerPeriodId, // Strictly ignored per V4 spec
  }) async {
    final matches = await repository.findPeriodsContainingDate(
      companyId: companyId,
      postingDate: postingDate,
    );

    if (matches.isEmpty) {
      return PeriodResolutionResult.notFound();
    }

    if (matches.length > 1) {
      return PeriodResolutionResult.ambiguous(matches.length);
    }

    return PeriodResolutionResult.valid(matches.first);
  }
}
