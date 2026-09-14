import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/accounting/domain/builder/authoritative_journal_builder_impl.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_effect.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_source_reference.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_transaction_context.dart';
import 'package:stock_count/modules/accounting/domain/validation/accounting_validation_engine_port.dart';
import 'package:stock_count/modules/accounting/domain/validation/accounting_validation_report.dart';

class FakeValidationEngine implements AccountingValidationEnginePort {
  bool isValid = true;
  String? errorMessage;

  @override
  Future<AccountingValidationReport> validateEffect(AccountingEffect effect) async {
    final results = <AccountingValidationRuleResult>[];
    if (!isValid) {
      results.add(
        AccountingValidationRuleResult(
          rule: 'FAILED_VALIDATION',
          severity: AccountingRuleSeverity.error,
          reason: errorMessage ?? 'Validation failed',
          actionableMessage: errorMessage ?? 'Validation failed',
        ),
      );
    }
    return AccountingValidationReport.evaluate(results);
  }

}

void main() {
  late FakeValidationEngine fakeValidationEngine;
  late AuthoritativeJournalBuilder builder;

  final companyId = 'comp-uuid-100';
  final validDate = DateTime.utc(2026, 9, 12);
  final sourceRef = AccountingSourceReference(
    sourceType: 'sale',
    sourceId: 'c2e8b0a1-4321-4def-89ab-0123456789cd',
  );

  setUp(() {
    fakeValidationEngine = FakeValidationEngine();
    builder = AuthoritativeJournalBuilder(
      validationEngine: fakeValidationEngine,
    );
  });

  group('AuthoritativeJournalBuilder Tests', () {
    test('builds AccountingJournal from valid single debit / single credit effect', () async {
      final context = AccountingTransactionContext(
        companyId: companyId,
        sourceReference: sourceRef,
        transactionDate: validDate,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final effect = AccountingEffect(
        context: context,
        voucherNumber: 'INV-100',
        voucherType: 'Sale',
        lines: [
          AccountingEffectLine(
            accountId: 'acc-cash-001',
            debit: 100.0,
            credit: 0.0,
            currencyCode: 'USD',
            lineDescription: 'Cash received',
          ),
          AccountingEffectLine(
            accountId: 'acc-rev-001',
            debit: 0.0,
            credit: 100.0,
            currencyCode: 'USD',
            lineDescription: 'Revenue credited',
          ),
        ],
      );

      final journal = await builder.buildJournal(effect);

      expect(journal, isNotNull);
      expect(journal.id, isNotEmpty);
      expect(journal.context.companyId, companyId);
      expect(journal.context.sourceReference.sourceId, sourceRef.sourceId);
      expect(journal.voucherNumber, 'INV-100');
      expect(journal.voucherType, 'Sale');
      expect(journal.isPosted, isFalse); // Journal Builder does NOT post!
      expect(journal.lines.length, 2);

      expect(journal.lines[0].accountId, 'acc-cash-001');
      expect(journal.lines[0].debit, 100.0);
      expect(journal.lines[0].credit, 0.0);
      expect(journal.lines[0].baseDebit, 100.0);

      expect(journal.lines[1].accountId, 'acc-rev-001');
      expect(journal.lines[1].debit, 0.0);
      expect(journal.lines[1].credit, 100.0);
      expect(journal.lines[1].baseCredit, 100.0);

      expect(journal.isIntegrityValid, isTrue);
    });

    test('builds multi-line journal preserving exact amounts and exchange rates', () async {
      final context = AccountingTransactionContext(
        companyId: companyId,
        sourceReference: sourceRef,
        transactionDate: validDate,
        currencyCode: 'EUR',
        baseCurrencyCode: 'USD',
        exchangeRate: 1.10,
      );

      final effect = AccountingEffect(
        context: context,
        voucherNumber: 'INV-101',
        voucherType: 'Multi-line Sale',
        lines: [
          AccountingEffectLine(
            accountId: 'acc-cash-001',
            debit: 100.0,
            credit: 0.0,
            currencyCode: 'EUR',
            exchangeRateToBase: 1.10,
          ),
          AccountingEffectLine(
            accountId: 'acc-discount-001',
            debit: 10.0,
            credit: 0.0,
            currencyCode: 'EUR',
            exchangeRateToBase: 1.10,
          ),
          AccountingEffectLine(
            accountId: 'acc-rev-001',
            debit: 0.0,
            credit: 110.0,
            currencyCode: 'EUR',
            exchangeRateToBase: 1.10,
          ),
        ],
      );

      final journal = await builder.buildJournal(effect);

      expect(journal.lines.length, 3);
      expect(journal.lines[0].baseDebit, 110.0); // 100 * 1.10
      expect(journal.lines[1].baseDebit, 11.0);  // 10 * 1.10
      expect(journal.lines[2].baseCredit, 121.0); // 110 * 1.10
      expect(journal.totalBaseDebit, 121.0);
      expect(journal.totalBaseCredit, 121.0);
      expect(journal.isIntegrityValid, isTrue);
    });

    test('rejects effect when Accounting Validation Engine fails', () async {
      fakeValidationEngine.isValid = false;
      fakeValidationEngine.errorMessage = 'Account inactive';

      final context = AccountingTransactionContext(
        companyId: companyId,
        sourceReference: sourceRef,
        transactionDate: validDate,
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );

      final effect = AccountingEffect(
        context: context,
        voucherNumber: 'INV-102',
        voucherType: 'Sale',
        lines: [
          AccountingEffectLine(
            accountId: 'acc-cash-001',
            debit: 100.0,
            credit: 0.0,
            currencyCode: 'USD',
          ),
          AccountingEffectLine(
            accountId: 'acc-rev-001',
            debit: 0.0,
            credit: 100.0,
            currencyCode: 'USD',
          ),
        ],
      );

      expect(
        () async => await builder.buildJournal(effect),
        throwsA(isA<AccountingJournalBuilderException>().having(
          (e) => e.message,
          'message',
          contains('Account inactive'),
        )),
      );
    });
  });
}
