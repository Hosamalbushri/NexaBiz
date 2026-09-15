import 'package:drift/drift.dart';
import '../../../../core/database/nexabiz_database.dart';
import '../money/decimal_money.dart';

/// Account balance reconstruction result from posted journal lines.
class ReconstructedAccountBalance {
  final String companyId;
  final String accountId;
  final DecimalMoney totalDebitBase;
  final DecimalMoney totalCreditBase;
  final DecimalMoney netBalanceBase;

  const ReconstructedAccountBalance({
    required this.companyId,
    required this.accountId,
    required this.totalDebitBase,
    required this.totalCreditBase,
    required this.netBalanceBase,
  });
}

/// Subject currency bucket balance reconstruction result from posted journal lines.
class ReconstructedSubjectBucketBalance {
  final String companyId;
  final String subjectId;
  final String accountId;
  final String currencyCode;
  final DecimalMoney netBalance;

  const ReconstructedSubjectBucketBalance({
    required this.companyId,
    required this.subjectId,
    required this.accountId,
    required this.currencyCode,
    required this.netBalance,
  });
}

/// Domain/Persistence service to reconstruct projections from posted journal lines (Authoritative Source of Truth).
class FinancialProjectionReconstructionService {
  final NexabizDatabase db;

  FinancialProjectionReconstructionService(this.db);

  /// Reconstructs account balance from all POSTED journal lines in base currency.
  Future<ReconstructedAccountBalance> reconstructAccountBalance({
    required String companyId,
    required String accountId,
    required String baseCurrencyCode,
  }) async {
    final query = db.select(db.financialJournalLines).join([
      innerJoin(
        db.financialJournalEntries,
        db.financialJournalEntries.id.equalsExp(db.financialJournalLines.journalEntryId),
      ),
    ])
      ..where(
        db.financialJournalEntries.companyId.equals(companyId) &
            db.financialJournalLines.companyId.equals(companyId) &
            db.financialJournalLines.accountId.equals(accountId) &
            db.financialJournalEntries.status.equals('POSTED'),
      );

    final rows = await query.get();

    BigInt debitSum = BigInt.zero;
    BigInt creditSum = BigInt.zero;

    for (final row in rows) {
      final line = row.readTable(db.financialJournalLines);
      if (line.side == 'DEBIT') {
        debitSum += line.baseAmountScaled;
      } else {
        creditSum += line.baseAmountScaled;
      }
    }

    final debitMoney = DecimalMoney.fromScaled(debitSum, baseCurrencyCode);
    final creditMoney = DecimalMoney.fromScaled(creditSum, baseCurrencyCode);
    final netMoney = DecimalMoney.fromScaled(debitSum - creditSum, baseCurrencyCode);

    return ReconstructedAccountBalance(
      companyId: companyId,
      accountId: accountId,
      totalDebitBase: debitMoney,
      totalCreditBase: creditMoney,
      netBalanceBase: netMoney,
    );
  }

  /// Reconstructs subject account currency bucket balance from all POSTED journal lines.
  Future<ReconstructedSubjectBucketBalance> reconstructSubjectBucketBalance({
    required String companyId,
    required String subjectId,
    required String accountId,
    required String currencyCode,
  }) async {
    final currency = currencyCode.toUpperCase();

    final query = db.select(db.financialJournalLines).join([
      innerJoin(
        db.financialJournalEntries,
        db.financialJournalEntries.id.equalsExp(db.financialJournalLines.journalEntryId),
      ),
    ])
      ..where(
        db.financialJournalEntries.companyId.equals(companyId) &
            db.financialJournalLines.companyId.equals(companyId) &
            db.financialJournalLines.subjectId.equals(subjectId) &
            db.financialJournalLines.accountId.equals(accountId) &
            db.financialJournalLines.transactionCurrencyCode.equals(currency) &
            db.financialJournalEntries.status.equals('POSTED'),
      );

    final rows = await query.get();

    BigInt netSum = BigInt.zero;

    for (final row in rows) {
      final line = row.readTable(db.financialJournalLines);
      if (line.side == 'DEBIT') {
        // DEBIT increases asset/AR balance
        netSum += line.transactionAmountScaled;
      } else {
        // CREDIT decreases asset/AR balance
        netSum -= line.transactionAmountScaled;
      }
    }

    final netMoney = DecimalMoney.fromScaled(netSum, currency);

    return ReconstructedSubjectBucketBalance(
      companyId: companyId,
      subjectId: subjectId,
      accountId: accountId,
      currencyCode: currency,
      netBalance: netMoney,
    );
  }
}
