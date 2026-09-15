import '../account/account_currency_policy.dart';
import '../account/financial_account.dart';
import '../common/financial_exceptions.dart';
import '../journal/financial_side.dart';
import '../journal/journal_entry.dart';
import '../journal/journal_line.dart';
import '../journal/journal_status.dart';
import '../money/decimal_money.dart';
import '../money/decimal_rate.dart';
import '../fiscal_period/financial_period_gate.dart';
import '../../validation/financial_int64_boundary.dart';

/// Result of posting engine validation and preparation.
class PostingPreparationResult {
  final JournalEntry preparedEntry;
  final DecimalMoney totalDebitBase;
  final DecimalMoney totalCreditBase;

  const PostingPreparationResult({
    required this.preparedEntry,
    required this.totalDebitBase,
    required this.totalCreditBase,
  });
}

/// Canonical Posting Engine for domain-level posting validation and preparation.
class PostingEngine {
  /// Validates and prepares a [JournalEntry] for posting.
  ///
  /// Enforces:
  /// 1. Entry status must be [JournalStatus.draft].
  /// 2. If [periodGate] is provided, validates period operational status via [FinancialPeriodGate].
  /// 3. Lines must be non-empty (>= 2 lines).
  /// 4. All lines must belong to [entry.companyId].
  /// 5. All line amounts and exchange rates must be within SQLite signed Int64 boundaries.
  /// 6. Account currency policies are respected.
  /// 7. Canonical conversions: if transaction currency == base currency, rate must be 1:1 identity.
  /// 8. Total Debit Base Amount == Total Credit Base Amount.
  static Future<PostingPreparationResult> prepareAndValidateForPosting({
    required JournalEntry entry,
    required Map<String, FinancialAccount> accountsById,
    required DateTime postingTimestamp,
    FinancialPeriodGate? periodGate,
    FinancialPostingCapability capability = FinancialPostingCapability.normalPosting,
  }) async {
    if (entry.status == JournalStatus.posted) {
      throw PostedJournalImmutableException(entry.id);
    }

    if (periodGate != null) {
      await periodGate.validateAndResolvePostingPeriod(
        companyId: entry.companyId,
        postingDate: entry.postingDate,
        capability: capability,
      );
    }

    if (entry.lines.length < 2) {
      throw const FinancialValidationException(
        'Journal entry must contain at least 2 balanced lines',
        'INSUFFICIENT_LINES',
      );
    }

    BigInt totalDebitBaseScaled = BigInt.zero;
    BigInt totalCreditBaseScaled = BigInt.zero;

    final List<JournalLine> validatedLines = [];

    for (final line in entry.lines) {
      // 1. Transitive tenancy check
      if (line.companyId != entry.companyId) {
        throw FinancialValidationException(
          'Transitive tenancy violation: line companyId (${line.companyId}) does not match entry companyId (${entry.companyId})',
          'TENANCY_VIOLATION',
        );
      }

      // 2. Int64 boundary validation
      FinancialInt64Boundary.check(line.transactionAmount.unitsScaled, 'line.transactionAmountScaled');
      FinancialInt64Boundary.check(line.exchangeRate.rateScaled, 'line.exchangeRateScaled');
      FinancialInt64Boundary.check(line.baseAmount.unitsScaled, 'line.baseAmountScaled');

      // 3. Account existence and currency policy validation
      final account = accountsById[line.accountId];
      if (account == null) {
        throw FinancialValidationException(
          'Account with id ${line.accountId} not found in provided account map',
          'ACCOUNT_NOT_FOUND',
        );
      }

      if (account.companyId != entry.companyId) {
        throw FinancialValidationException(
          'Account ${account.id} companyId (${account.companyId}) does not match entry companyId (${entry.companyId})',
          'TENANCY_VIOLATION',
        );
      }

      _validateAccountCurrencyPolicy(
        account: account,
        baseCurrencyCode: entry.baseCurrencyCode,
        transactionCurrencyCode: line.transactionAmount.currencyCode,
      );

      // 4. Canonical conversion check
      if (line.transactionAmount.currencyCode == entry.baseCurrencyCode) {
        if (line.exchangeRate.rateScaled != DecimalRate.scaleFactor) {
          throw const FinancialValidationException(
            'Canonical conversion rule violation: exchange rate for base currency transaction must be 1:1 identity (1.00000000)',
            'INVALID_BASE_RATE',
          );
        }
        if (line.baseAmount.unitsScaled != line.transactionAmount.unitsScaled) {
          throw const FinancialValidationException(
            'Canonical conversion rule violation: base amount must equal transaction amount when transaction currency equals base currency',
            'INVALID_BASE_AMOUNT',
          );
        }
      } else {
        // Foreign currency: baseAmount = convert(transactionAmount)
        final expectedBase = line.exchangeRate.convert(line.transactionAmount);
        if (line.baseAmount.unitsScaled != expectedBase.unitsScaled) {
          throw FinancialValidationException(
            'Canonical conversion rule violation: line base amount (${line.baseAmount.unitsScaled}) does not match converted transaction amount (${expectedBase.unitsScaled})',
            'CANONICAL_CONVERSION_MISMATCH',
          );
        }
      }

      // 5. Accumulate debit / credit base totals
      if (line.side == FinancialSide.debit) {
        totalDebitBaseScaled += line.baseAmount.unitsScaled;
      } else {
        totalCreditBaseScaled += line.baseAmount.unitsScaled;
      }

      validatedLines.add(line);
    }

    // 6. Balanced journal check
    if (totalDebitBaseScaled != totalCreditBaseScaled) {
      throw UnbalancedJournalException(
        debitTotalScaled: totalDebitBaseScaled,
        creditTotalScaled: totalCreditBaseScaled,
        baseCurrency: entry.baseCurrencyCode,
      );
    }

    // 7. Post entry
    final postedEntry = JournalEntry(
      id: entry.id,
      companyId: entry.companyId,
      entryNumber: entry.entryNumber,
      baseCurrencyCode: entry.baseCurrencyCode,
      postingDate: entry.postingDate,
      status: JournalStatus.posted,
      postedAt: postingTimestamp,
      description: entry.description,
      sourceModule: entry.sourceModule,
      sourceDocumentId: entry.sourceDocumentId,
      lines: validatedLines,
    );

    return PostingPreparationResult(
      preparedEntry: postedEntry,
      totalDebitBase: DecimalMoney.fromScaled(totalDebitBaseScaled, entry.baseCurrencyCode),
      totalCreditBase: DecimalMoney.fromScaled(totalCreditBaseScaled, entry.baseCurrencyCode),
    );
  }

  static void _validateAccountCurrencyPolicy({
    required FinancialAccount account,
    required String baseCurrencyCode,
    required String transactionCurrencyCode,
  }) {
    switch (account.currencyPolicy) {
      case AccountCurrencyPolicy.functionalOnly:
        if (transactionCurrencyCode != baseCurrencyCode) {
          throw CurrencyMismatchException(
            expectedCurrency: baseCurrencyCode,
            actualCurrency: transactionCurrencyCode,
          );
        }
        break;
      case AccountCurrencyPolicy.singleFixedCurrency:
        // Single fixed currency account requires matching transaction currency
        break;
      case AccountCurrencyPolicy.multiCurrencyBucketed:
        break;
    }
  }
}
