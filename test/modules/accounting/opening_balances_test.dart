import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/company/app_currency.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/models/account_import_row.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/models/opening_balance_line.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/account_import_opening_journal.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_opening_setup_provider.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/widgets/opening_balances_table.dart';

void main() {
  group('NEXABIZ — ACCOUNTING STEP 08: OPENING BALANCES TEST MATRIX', () {
    const defaultCurrency = 'SAR';
    const capitalUuid = 'CAPITAL-3100-UUID';

    test(
      '1. Balanced Opening Balances: Capital offset balances journal perfectly',
      () {
        final lines = [
          const OpeningBalanceLine(
            id: 'line-1',
            accountId: 'ACC-1',
            accountCode: '1001',
            accountName: 'Cash Account',
            debit: 5000,
            credit: 0,
            currencyCode: 'SAR',
          ),
          const OpeningBalanceLine(
            id: 'line-2',
            accountId: 'ACC-2',
            accountCode: '2001',
            accountName: 'Accounts Payable',
            debit: 0,
            credit: 2000,
            currencyCode: 'SAR',
          ),
        ];

        final draft = AccountImportOpeningJournal.buildFromBalanceLines(
          balances: lines,
          capitalAccountUuid: capitalUuid,
          defaultCurrencyCode: defaultCurrency,
          entryDate: DateTime(2026, 1, 1),
          voucherNumber: 'OI-TEST-1',
          voucherType: 'Opening Entry',
          description: 'Opening Balances Test',
        );

        expect(draft, isNotNull);
        expect(draft!.lines, hasLength(3));

        final capitalLine = draft.lines.firstWhere(
          (l) => l.accountUuid == capitalUuid,
        );
        // Total debit = 5000, Total credit = 2000. Net debit = 3000 -> Capital credit = 3000
        expect(capitalLine.credit, equals(3000));
        expect(capitalLine.debit, equals(0));

        final totalDebit = draft.lines.fold<double>(
          0,
          (sum, l) => sum + l.debit,
        );
        final totalCredit = draft.lines.fold<double>(
          0,
          (sum, l) => sum + l.credit,
        );
        expect(totalDebit, equals(totalCredit));
      },
    );

    test(
      '2. Unbalanced Opening Balances: Handled gracefully via Capital offset for currency group',
      () {
        final lines = [
          const OpeningBalanceLine(
            id: 'line-1',
            accountId: 'ACC-1',
            accountCode: '1001',
            accountName: 'Bank Account USD',
            debit: 1000,
            credit: 0,
            currencyCode: 'USD',
          ),
        ];

        final draft = AccountImportOpeningJournal.buildFromBalanceLines(
          balances: lines,
          capitalAccountUuid: capitalUuid,
          defaultCurrencyCode: defaultCurrency,
          entryDate: DateTime(2026, 1, 1),
          voucherNumber: 'OI-TEST-2',
          voucherType: 'Opening Entry',
          description: 'Single Sided USD',
        );

        expect(draft, isNotNull);
        expect(draft!.lines, hasLength(2));

        final capitalLine = draft.lines.firstWhere(
          (l) => l.accountUuid == capitalUuid,
        );
        expect(capitalLine.currencyCode, equals('USD'));
        expect(capitalLine.credit, equals(1000));

        final summaries = AccountImportOpeningJournal.summarize(
          lines,
          defaultCurrencyCode: defaultCurrency,
        );
        expect(summaries, hasLength(1));
        expect(summaries.first.currencyCode, equals('USD'));
        expect(summaries.first.totalDebit, equals(1000));
        expect(summaries.first.totalCredit, equals(0));
        expect(summaries.first.netDebit, equals(1000));
      },
    );

    test(
      '3. Zero Values: Skipped during journal generation without errors',
      () {
        final lines = [
          const OpeningBalanceLine(
            id: 'line-1',
            accountId: 'ACC-1',
            accountCode: '1001',
            accountName: 'Zero Account',
            debit: 0,
            credit: 0,
            currencyCode: 'SAR',
          ),
        ];

        final draft = AccountImportOpeningJournal.buildFromBalanceLines(
          balances: lines,
          capitalAccountUuid: capitalUuid,
          defaultCurrencyCode: defaultCurrency,
          entryDate: DateTime(2026, 1, 1),
          voucherNumber: 'OI-TEST-3',
          voucherType: 'Opening Entry',
        );

        expect(draft, isNull);

        final summaries = AccountImportOpeningJournal.summarize(
          lines,
          defaultCurrencyCode: defaultCurrency,
        );
        expect(summaries, isEmpty);
      },
    );

    test(
      '4. Invalid Values: Both sides populated throws AccountImportException.bothOpeningSides',
      () {
        final invalidLines = [
          const OpeningBalanceLine(
            id: 'line-invalid',
            accountId: 'ACC-1',
            accountCode: '1001',
            accountName: 'Conflicted Account',
            debit: 100,
            credit: 200,
            currencyCode: 'SAR',
          ),
        ];

        expect(
          () => AccountImportOpeningJournal.buildFromBalanceLines(
            balances: invalidLines,
            capitalAccountUuid: capitalUuid,
            defaultCurrencyCode: defaultCurrency,
            entryDate: DateTime(2026, 1, 1),
            voucherNumber: 'OI-TEST-4',
            voucherType: 'Opening Entry',
          ),
          throwsA(
            isA<AccountImportException>().having(
              (e) => e.code,
              'code',
              equals(AccountImportException.bothOpeningSides),
            ),
          ),
        );
      },
    );

    test(
      '5. Imported Opening Balances: Duplicate currency per account is strictly rejected',
      () {
        final duplicateLines = [
          const OpeningBalanceLine(
            id: 'line-1',
            accountId: 'ACC-1',
            accountCode: '1001',
            accountName: 'Cash',
            debit: 100,
            credit: 0,
            currencyCode: 'SAR',
          ),
          const OpeningBalanceLine(
            id: 'line-2',
            accountId: 'ACC-1',
            accountCode: '1001',
            accountName: 'Cash',
            debit: 0,
            credit: 50,
            currencyCode: 'SAR',
          ),
        ];

        expect(
          () => AccountImportOpeningJournal.buildFromBalanceLines(
            balances: duplicateLines,
            capitalAccountUuid: capitalUuid,
            defaultCurrencyCode: defaultCurrency,
            entryDate: DateTime(2026, 1, 1),
            voucherNumber: 'OI-TEST-5',
            voucherType: 'Opening Entry',
          ),
          throwsA(
            isA<AccountImportException>().having(
              (e) => e.code,
              'code',
              equals(AccountImportException.duplicateCurrency),
            ),
          ),
        );
      },
    );

    test(
      '6. Notifier State Transitions: Step navigation and line editing update state immutably',
      () {
        final state = const AccountOpeningSetupState();
        expect(state.stepIndex, equals(0));
        expect(state.canPostOpening, isFalse);

        final withLines = state.copyWith(
          stepIndex: 1,
          balanceLines: const [
            OpeningBalanceLine(
              id: 'line-1',
              accountId: 'ACC-1',
              accountCode: '1001',
              accountName: 'Test Account',
              debit: 1500,
              credit: 0,
              currencyCode: 'SAR',
            ),
          ],
        );

        expect(withLines.stepIndex, equals(1));
        expect(withLines.canPostOpening, isTrue);
        expect(withLines.balanceLines, hasLength(1));
        expect(withLines.balanceLines.first.debit, equals(1500));
      },
    );

    testWidgets(
      '7. Presentation Rendering: OpeningBalancesTables renders pure presentation tables',
      (WidgetTester tester) async {
        final groups = [
          const OpeningBalanceAccountGroup(
            accountId: 'ACC-1',
            accountCode: '1001',
            accountName: 'Cash on Hand',
            lines: [
              OpeningBalanceLine(
                id: 'line-1',
                accountId: 'ACC-1',
                accountCode: '1001',
                accountName: 'Cash on Hand',
                debit: 2500,
                credit: 0,
                currencyCode: 'SAR',
              ),
            ],
          ),
        ];

        final configuredCurrencies = [AppCurrencies.sar, AppCurrencies.usd];

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: OpeningBalancesTables(
                  groups: groups,
                  configuredCurrencies: configuredCurrencies,
                  defaultCurrencyCode: 'SAR',
                  enabled: true,
                  onChanged: (_) {},
                  onRemoveLine: (_) {},
                  onRemoveAccount: (_) {},
                  onAddCurrencyLine:
                      ({
                        required accountId,
                        required accountCode,
                        required accountName,
                      }) {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.textContaining('1001 — Cash on Hand'), findsOneWidget);
        expect(find.text('SAR'), findsOneWidget);
      },
    );
  });
}
