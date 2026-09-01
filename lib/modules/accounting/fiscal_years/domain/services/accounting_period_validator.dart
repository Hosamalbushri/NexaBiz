import 'package:stock_count/core/domain/ports/period_validator_port.dart';
import 'package:stock_count/core/utils/business_date.dart';
import 'package:stock_count/core/errors/journal_exception.dart';
import '../repositories/fiscal_year_repository.dart';
import 'fiscal_period_policy.dart';

/// Central gate for accounting dates (journals, sales, R&P via posting service).
class AccountingPeriodValidator implements PeriodValidatorPort {
  const AccountingPeriodValidator({
    required FiscalYearRepository repository,
    required FiscalPeriodPolicy Function() legacyPolicyReader,
  }) : _repository = repository,
       _legacyPolicyReader = legacyPolicyReader;

  final FiscalYearRepository _repository;
  final FiscalPeriodPolicy Function() _legacyPolicyReader;

  /// Throws [JournalException] when the entry date is not postable.
  Future<void> assertEntryAllowed(DateTime entryDate) async {
    final hasYears = await _repository.hasAnyFiscalYear();
    if (!hasYears) {
      _legacyPolicyReader().assertEntryAllowed(entryDate);
      return;
    }

    final period = await _repository.findPeriodContaining(entryDate);
    if (period == null) {
      throw JournalException(
        JournalException.outsideFiscalYear,
        'entry=${BusinessDate.utcDay(entryDate).toIso8601String()}',
      );
    }
    if (!period.allowsPosting) {
      throw JournalException(
        JournalException.periodClosed,
        'period=${period.uuid} status=${period.status.storageValue} '
        'entry=${BusinessDate.utcDay(entryDate).toIso8601String()}',
      );
    }
  }

  /// Validates mutations (edits, backdating, deletions) across target date and original date.
  Future<void> assertMutationAllowed({
    required DateTime entryDate,
    DateTime? originalDate,
  }) async {
    if (originalDate != null) {
      await assertEntryAllowed(originalDate);
    }
    await assertEntryAllowed(entryDate);
  }
}
