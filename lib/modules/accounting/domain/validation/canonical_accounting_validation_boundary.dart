import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/fiscal_years/domain/repositories/fiscal_year_repository.dart';
import 'package:stock_count/modules/accounting/domain/foundation/posting_intent.dart';

class AccountingValidationException implements Exception {
  const AccountingValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CanonicalAccountingValidationBoundary {
  const CanonicalAccountingValidationBoundary({
    required AccountRepository accountRepository,
    FiscalYearRepository? fiscalYearRepository,
  })  : _accounts = accountRepository,
        _fiscalYears = fiscalYearRepository;

  final AccountRepository _accounts;
  final FiscalYearRepository? _fiscalYears;

  /// Validates explicit account line drafts for tenant isolation, postability, active status, and period eligibility.
  Future<void> validateExplicitPosting({
    required ExplicitAccountPostingIntent intent,
  }) async {
    final companyId = intent.companyId.trim();
    if (companyId.isEmpty) {
      throw const AccountingValidationException(
        'Accounting Validation Failure: Active company scope context is required.',
      );
    }

    if (intent.lines.isEmpty) {
      throw const AccountingValidationException(
        'Accounting Validation Failure: Journal entry must contain at least one line.',
      );
    }

    if (_fiscalYears != null) {
      final period = await _fiscalYears.findPeriodContaining(intent.transactionDate);
      if (period == null || !period.allowsPosting) {
        throw AccountingValidationException(
          'Accounting Validation Failure: Fiscal period for transaction date ${intent.transactionDate} is closed or undefined.',
        );
      }
    }

    for (final line in intent.lines) {
      final accountUuid = line.accountUuid.trim();
      if (accountUuid.isEmpty) {
        throw const AccountingValidationException(
          'Accounting Validation Failure: Line account UUID cannot be empty.',
        );
      }

      final account = await _accounts.getByUuid(accountUuid);
      if (account == null) {
        throw AccountingValidationException(
          'Accounting Validation Failure: Target account "$accountUuid" does not exist.',
        );
      }

      _validateAccountEligible(account: account, companyId: companyId);
    }
  }

  /// Validates a concrete resolved account entity against tenant scoping and postability rules.
  void validateResolvedAccount({
    required Account account,
    required String companyId,
  }) {
    _validateAccountEligible(account: account, companyId: companyId);
  }

  void _validateAccountEligible({
    required Account account,
    required String companyId,
  }) {
    final targetCompany = companyId.trim();
    final acctCompany = account.companyId?.trim() ?? '';
    if (acctCompany.isNotEmpty && acctCompany != targetCompany) {
      throw AccountingValidationException(
        'Accounting Validation Failure: Tenant isolation violation! Account "${account.id}" '
        'belongs to company "${account.companyId}" but active context is "$targetCompany".',
      );
    }

    if (account.isDeleted) {
      throw AccountingValidationException(
        'Accounting Validation Failure: Target account "${account.id}" (${account.name}) is deleted.',
      );
    }

    if (!account.isActive) {
      throw AccountingValidationException(
        'Accounting Validation Failure: Target account "${account.id}" (${account.name}) is inactive.',
      );
    }

    if (account.isGroup) {
      throw AccountingValidationException(
        'Accounting Validation Failure: Cannot post directly to parent group account "${account.id}" (${account.name}).',
      );
    }

    if (!account.canPost) {
      throw AccountingValidationException(
        'Accounting Validation Failure: Target account "${account.id}" (${account.name}) is not postable.',
      );
    }
  }
}
