import '../common/financial_exceptions.dart';
import 'financial_side.dart';
import 'journal_line.dart';
import 'journal_status.dart';

/// Standalone Financial Package Journal Entry domain entity.
class JournalEntry {
  final String id;
  final String companyId;
  final String entryNumber;
  final String baseCurrencyCode;
  final DateTime postingDate;
  final JournalStatus status;
  final String? description;
  final String? sourceModule;
  final String? sourceDocumentId;
  final DateTime? postedAt;
  final String? createdById;
  final List<JournalLine> lines;

  JournalEntry({
    required this.id,
    required this.companyId,
    required this.entryNumber,
    required this.baseCurrencyCode,
    required this.postingDate,
    required this.lines,
    this.status = JournalStatus.draft,
    this.description,
    this.sourceModule,
    this.sourceDocumentId,
    this.postedAt,
    this.createdById,
  }) {
    if (baseCurrencyCode.trim().isEmpty) {
      throw ArgumentError('Base currency code cannot be empty');
    }
  }

  /// Calculates total debit base amount scaled.
  BigInt get totalDebitBaseScaled {
    BigInt sum = BigInt.zero;
    for (final line in lines) {
      if (line.side.isDebit) {
        sum += line.baseAmount.unitsScaled;
      }
    }
    return sum;
  }

  /// Calculates total credit base amount scaled.
  BigInt get totalCreditBaseScaled {
    BigInt sum = BigInt.zero;
    for (final line in lines) {
      if (line.side.isCredit) {
        sum += line.baseAmount.unitsScaled;
      }
    }
    return sum;
  }

  /// Validates all mandatory journal balance invariants for posting.
  void validateInvariants() {
    if (lines.isEmpty) {
      throw FinancialValidationException('Journal entry $entryNumber contains no lines');
    }

    final upperBaseCurrency = baseCurrencyCode.toUpperCase();

    // 1. Base Currency Invariant
    for (final line in lines) {
      if (line.baseAmount.currencyCode != upperBaseCurrency) {
        throw BaseCurrencyInvariantException(
          journalBaseCurrency: upperBaseCurrency,
          lineBaseCurrency: line.baseAmount.currencyCode,
        );
      }
    }

    // 2. Exact Debit / Credit Equality Invariant (Zero Tolerance)
    final totalDebit = totalDebitBaseScaled;
    final totalCredit = totalCreditBaseScaled;

    if (totalDebit != totalCredit) {
      throw UnbalancedJournalException(
        debitTotalScaled: totalDebit,
        creditTotalScaled: totalCredit,
        baseCurrency: upperBaseCurrency,
      );
    }
  }

  /// Posts this journal entry, setting status to POSTED and generating a timestamp.
  JournalEntry post({required DateTime timestamp}) {
    if (status.isPosted) {
      throw PostedJournalImmutableException(id);
    }
    validateInvariants();
    return JournalEntry(
      id: id,
      companyId: companyId,
      entryNumber: entryNumber,
      baseCurrencyCode: baseCurrencyCode,
      postingDate: postingDate,
      lines: List.unmodifiable(lines),
      status: JournalStatus.posted,
      description: description,
      sourceModule: sourceModule,
      sourceDocumentId: sourceDocumentId,
      postedAt: timestamp,
      createdById: createdById,
    );
  }

  /// Creates a canonical draft reversal entry with inverted debit/credit sides.
  /// Enforces same-company tenancy across header and all reversal lines.
  JournalEntry createReversal({
    required String reversalId,
    required String reversalEntryNumber,
    required DateTime postingDate,
    required String Function(int lineNumber) reversalLineIdGenerator,
    String? reversalDescription,
    String? createdById,
  }) {
    if (!status.isPosted) {
      throw FinancialValidationException(
        'Cannot reverse journal entry $entryNumber because its status is $status (must be POSTED)',
        'CANNOT_REVERSE_UNPOSTED',
      );
    }

    final reversalLines = <JournalLine>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Guarantee line companyId matches entry companyId
      if (line.companyId != companyId) {
        throw FinancialValidationException(
          'Transitive tenancy violation in line ${line.lineNumber}: line companyId (${line.companyId}) != entry companyId ($companyId)',
          'TENANCY_VIOLATION',
        );
      }

      final invertedSide = line.side == FinancialSide.debit ? FinancialSide.credit : FinancialSide.debit;
      final lineId = reversalLineIdGenerator(i + 1);

      reversalLines.add(
        JournalLine(
          id: lineId,
          companyId: companyId,
          journalEntryId: reversalId,
          lineNumber: i + 1,
          accountId: line.accountId,
          side: invertedSide,
          transactionAmount: line.transactionAmount,
          exchangeRate: line.exchangeRate,
          baseAmount: line.baseAmount,
          description: 'Reversal of line ${line.lineNumber}: ${line.description ?? ""}'.trim(),
          subjectId: line.subjectId,
        ),
      );
    }

    return JournalEntry(
      id: reversalId,
      companyId: companyId,
      entryNumber: reversalEntryNumber,
      baseCurrencyCode: baseCurrencyCode,
      postingDate: postingDate,
      status: JournalStatus.draft,
      description: reversalDescription ?? 'Reversal of Entry #$entryNumber',
      sourceModule: sourceModule,
      sourceDocumentId: id,
      createdById: createdById,
      lines: List.unmodifiable(reversalLines),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is JournalEntry &&
            id == other.id &&
            companyId == other.companyId &&
            entryNumber == other.entryNumber);
  }

  @override
  int get hashCode => Object.hash(id, companyId, entryNumber);

  @override
  String toString() =>
      'JournalEntry #$entryNumber [$status] Base:$baseCurrencyCode Lines:${lines.length}';
}
