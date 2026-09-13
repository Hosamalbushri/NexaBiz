import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_domain_authority_impl.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_effect.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_failure.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_source_reference.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_transaction_context.dart';

void main() {
  group('AccountingSourceReference Tests', () {
    test('creates valid source reference with canonical key', () {
      final ref = AccountingSourceReference(
        sourceType: 'sale',
        sourceId: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
      );
      expect(ref.sourceType, 'sale');
      expect(ref.sourceId, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11');
      expect(ref.canonicalKey, 'sale:a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11');
    });

    test('rejects empty sourceType or sourceId', () {
      expect(
        () => AccountingSourceReference(sourceType: '', sourceId: 'uuid-123'),
        throwsArgumentError,
      );
      expect(
        () => AccountingSourceReference(sourceType: 'sale', sourceId: '  '),
        throwsArgumentError,
      );
    });

    test('rejects local integer ID as cross-domain identity', () {
      expect(
        () => AccountingSourceReference(sourceType: 'sale', sourceId: '101'),
        throwsArgumentError,
      );
    });
  });

  group('AccountingTransactionContext & Company Scope Tests', () {
    final validRef = AccountingSourceReference(
      sourceType: 'sale',
      sourceId: 'c2e8b0a1-4321-4def-89ab-0123456789cd',
    );

    test('creates valid transaction context', () {
      final context = AccountingTransactionContext(
        companyId: 'comp-uuid-001',
        sourceReference: validRef,
        transactionDate: DateTime.utc(2026, 9, 12),
        currencyCode: 'USD',
        baseCurrencyCode: 'USD',
      );
      expect(context.companyId, 'comp-uuid-001');
      expect(context.currencyCode, 'USD');
    });

    test('rejects missing or empty company scope', () {
      expect(
        () => AccountingTransactionContext(
          companyId: '',
          sourceReference: validRef,
          transactionDate: DateTime.utc(2026, 9, 12),
          currencyCode: 'USD',
          baseCurrencyCode: 'USD',
        ),
        throwsA(isA<MissingCompanyScopeFailure>()),
      );

      expect(
        () => AccountingTransactionContext(
          companyId: '   ',
          sourceReference: validRef,
          transactionDate: DateTime.utc(2026, 9, 12),
          currencyCode: 'USD',
          baseCurrencyCode: 'USD',
        ),
        throwsA(isA<MissingCompanyScopeFailure>()),
      );
    });

    test('rejects illegal fallback company scope identities', () {
      final forbiddenScopes = [
        'fallback',
        'default',
        'legacy_company',
        'global',
        'legacyCompanyId',
      ];

      for (final scope in forbiddenScopes) {
        expect(
          () => AccountingTransactionContext(
            companyId: scope,
            sourceReference: validRef,
            transactionDate: DateTime.utc(2026, 9, 12),
            currencyCode: 'USD',
            baseCurrencyCode: 'USD',
          ),
          throwsA(isA<MissingCompanyScopeFailure>()),
          reason: 'Company scope "$scope" should be rejected as fallback identity',
        );
      }
    });

    test('rejects invalid transaction date outside operational bounds', () {
      expect(
        () => AccountingTransactionContext(
          companyId: 'comp-001',
          sourceReference: validRef,
          transactionDate: DateTime.utc(1999, 12, 31),
          currencyCode: 'USD',
          baseCurrencyCode: 'USD',
        ),
        throwsA(isA<InvalidTransactionDateFailure>()),
      );
    });
  });

  group('AccountingEffect & Line Tests', () {
    final context = AccountingTransactionContext(
      companyId: 'comp-001',
      sourceReference: AccountingSourceReference(
        sourceType: 'sale',
        sourceId: 'c2e8b0a1-4321-4def-89ab-0123456789cd',
      ),
      transactionDate: DateTime.utc(2026, 9, 12),
      currencyCode: 'USD',
      baseCurrencyCode: 'USD',
    );

    test('creates valid balanced effect', () {
      final effect = AccountingEffect(
        context: context,
        voucherNumber: 'INV-1001',
        voucherType: 'Sale',
        lines: [
          AccountingEffectLine(
            accountUuid: 'acc-ar-001',
            debit: 150.0,
            credit: 0.0,
            currencyCode: 'USD',
          ),
          AccountingEffectLine(
            accountUuid: 'acc-rev-001',
            debit: 0.0,
            credit: 150.0,
            currencyCode: 'USD',
          ),
        ],
      );

      expect(effect.isBalanced, isTrue);
      expect(effect.totalDebit, 150.0);
      expect(effect.totalCredit, 150.0);
    });

    test('detects unbalanced effect', () {
      final effect = AccountingEffect(
        context: context,
        voucherNumber: 'INV-1002',
        voucherType: 'Sale',
        lines: [
          AccountingEffectLine(
            accountUuid: 'acc-ar-001',
            debit: 200.0,
            credit: 0.0,
            currencyCode: 'USD',
          ),
          AccountingEffectLine(
            accountUuid: 'acc-rev-001',
            debit: 0.0,
            credit: 150.0,
            currencyCode: 'USD',
          ),
        ],
      );

      expect(effect.isBalanced, isFalse);
    });

    test('rejects negative debit or credit in effect line', () {
      expect(
        () => AccountingEffectLine(
          accountUuid: 'acc-001',
          debit: -50.0,
          credit: 0.0,
          currencyCode: 'USD',
        ),
        throwsA(isA<InvalidAccountingEffectFailure>()),
      );
    });
  });

  group('AccountingDomainAuthority Pipeline Tests', () {
    final authority = AccountingDomainAuthority();
    final context = AccountingTransactionContext(
      companyId: 'comp-001',
      sourceReference: AccountingSourceReference(
        sourceType: 'receipt',
        sourceId: 'd3f9c1b2-5432-4ef0-9ab1-123456789abc',
      ),
      transactionDate: DateTime.utc(2026, 9, 12),
      currencyCode: 'USD',
      baseCurrencyCode: 'USD',
    );

    test('executes full posting pipeline successfully', () async {
      final effect = AccountingEffect(
        context: context,
        voucherNumber: 'RCT-5001',
        voucherType: 'Receipt',
        lines: [
          AccountingEffectLine(
            accountUuid: 'acc-cash-001',
            debit: 500.0,
            credit: 0.0,
            currencyCode: 'USD',
          ),
          AccountingEffectLine(
            accountUuid: 'acc-ar-001',
            debit: 0.0,
            credit: 500.0,
            currencyCode: 'USD',
          ),
        ],
      );

      final valResult = authority.validateEffect(effect);
      expect(valResult.isValid, isTrue);

      final journal = authority.constructJournal(effect);
      expect(journal.lines.length, 2);

      final integrityResult = authority.validateJournalIntegrity(journal);
      expect(integrityResult.isValid, isTrue);

      final postingResult = await authority.post(effect);
      expect(postingResult.isSuccess, isTrue);
      expect(postingResult.postedJournal?.isPosted, isTrue);
    });

    test('rejects posting unbalanced effect', () async {
      final effect = AccountingEffect(
        context: context,
        voucherNumber: 'RCT-5002',
        voucherType: 'Receipt',
        lines: [
          AccountingEffectLine(
            accountUuid: 'acc-cash-001',
            debit: 500.0,
            credit: 0.0,
            currencyCode: 'USD',
          ),
          AccountingEffectLine(
            accountUuid: 'acc-ar-001',
            debit: 0.0,
            credit: 400.0,
            currencyCode: 'USD',
          ),
        ],
      );

      final result = await authority.post(effect);
      expect(result.isSuccess, isFalse);
      expect(result.failure, isA<UnbalancedJournalFailure>());
    });
  });
}
