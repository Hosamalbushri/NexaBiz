import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/widgets/account_search_field.dart';

void main() {
  testWidgets('AccountSearchField builds without dependOnInheritedWidgetOfExactType assertion', (tester) async {
    final account = Account(
      id: 1,
      uuid: 'acc-1',
      accountCode: '101000',
      name: 'Cash in Hand',
      accountType: AccountType.asset,
      normalBalance: NormalBalance.debit,
      level: 2,
      isGroup: false,
      isActive: true,
      isSystemAccount: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Account? selected;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return AccountSearchField(
                label: 'Search Account',
                accounts: [account],
                selectedUuid: account.uuid,
                onSelected: (acc) => selected = acc,
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('101000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
