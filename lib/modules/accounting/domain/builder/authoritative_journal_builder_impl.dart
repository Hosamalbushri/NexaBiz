import 'package:uuid/uuid.dart';
import '../foundation/accounting_effect.dart';
import '../foundation/accounting_journal_contracts.dart';
import '../validation/accounting_validation_engine_port.dart';
import '../validation/accounting_validation_report.dart';
import 'authoritative_journal_builder_port.dart';

class AccountingJournalBuilderException implements Exception {
  AccountingJournalBuilderException(this.message, {this.report});

  final String message;
  final AccountingValidationReport? report;

  @override
  String toString() => message;
}

class AuthoritativeJournalBuilder implements AuthoritativeJournalBuilderPort {
  AuthoritativeJournalBuilder({
    required this._validationEngine,
    Uuid? uuidGenerator,
  })  : _uuid = uuidGenerator ?? const Uuid();

  final AccountingValidationEnginePort _validationEngine;
  final Uuid _uuid;

  @override
  Future<AccountingJournal> buildJournal(AccountingEffect effect) async {
    // 1. Validation Engine Gatekeeper
    final report = await _validationEngine.validateEffect(effect);
    if (!report.isValid) {
      final firstError = report.errors.isNotEmpty
          ? report.errors.first.reason
          : 'Unknown validation error';
      throw AccountingJournalBuilderException(
        'Accounting Validation Engine Rejected Effect: $firstError',
        report: report,
      );
    }

    final entryUuid = _uuid.v4();
    final now = DateTime.now().toUtc();
    final defaultRate = effect.context.exchangeRate ?? 1.0;

    final lines = <AccountingJournalLine>[];
    for (var i = 0; i < effect.lines.length; i++) {
      final line = effect.lines[i];
      final lineUuid = _uuid.v4();
      final lineRate = line.exchangeRateToBase ?? defaultRate;

      final baseDebit = line.debit > 0
          ? double.parse((line.debit * lineRate).toStringAsFixed(4))
          : 0.0;
      final baseCredit = line.credit > 0
          ? double.parse((line.credit * lineRate).toStringAsFixed(4))
          : 0.0;

      lines.add(AccountingJournalLine(
        uuid: lineUuid,
        entryUuid: entryUuid,
        accountUuid: line.accountUuid,
        debit: line.debit,
        credit: line.credit,
        currencyCode: line.currencyCode,
        exchangeRateToBase: lineRate,
        baseDebit: baseDebit,
        baseCredit: baseCredit,
        lineDescription: line.lineDescription,
        sortOrder: i,
      ));
    }

    final journal = AccountingJournal(
      uuid: entryUuid,
      context: effect.context,
      voucherNumber: effect.voucherNumber,
      voucherType: effect.voucherType,
      description: effect.lines.isNotEmpty ? effect.lines.first.lineDescription : null,
      isPosted: false, // Journal Builder does NOT post directly!
      lines: lines,
      createdAt: now,
      updatedAt: now,
    );

    // 2. Journal Integrity Validation
    if (!journal.isIntegrityValid) {
      throw AccountingJournalBuilderException(
        'Journal Integrity Validation Failed: Total Base Debit (${journal.totalBaseDebit}) != Total Base Credit (${journal.totalBaseCredit})',
      );
    }

    return journal;
  }
}
