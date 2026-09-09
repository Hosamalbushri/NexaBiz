import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/shared/data/repositories/currency_repository_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/repositories/currency_repository.dart';
import 'package:stock_count/modules/accounting/shared/presentation/pages/currencies_manage_page.dart';
import 'package:stock_count/modules/accounting/shared/presentation/providers/currency_providers.dart';
import 'package:stock_count/app/settings/company/functional_currency_providers.dart';
import 'package:stock_count/modules/inventory/cost_valuation/presentation/providers/inventory_valuation_currency_providers.dart';
import 'package:stock_count/modules/currency/presentation/widgets/app_searchable_currency_picker.dart';

void main() {
  late AccountingDatabase db;
  late CurrencyRepository repository;

  setUp(() async {
    db = AccountingDatabase.memory();
    repository = CurrencyRepositoryImpl(
      db,
      readCompanyId: () => 'default-company',
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestApp(AccountingDatabase db, CurrencyRepository repo) {
    return ProviderScope(
      overrides: [
        accountingDatabaseProvider.overrideWithValue(db),
        currentCompanyIdProvider.overrideWithValue('default-company'),
        currencyRepositoryProvider.overrideWithValue(repo),
        allCurrenciesProvider.overrideWith((ref) => Stream.fromFuture(repo.getAll(includeInactive: true))),
        activeCurrenciesProvider.overrideWith((ref) => Stream.fromFuture(repo.getAll(includeInactive: false))),
        functionalCurrencyStateInfoProvider.overrideWith((ref) => Future.value(const FunctionalCurrencyStateInfo(
              configState: FunctionalCurrencyConfigState.notConfigured,
              currencyCode: '',
              hasPostedActivity: false,
              canModify: true,
            ))),
        inventoryValuationCurrencyStateProvider.overrideWith((ref) => Future.value(const InventoryValuationCurrencyStateInfo(
              currency: null,
              currencyCode: '',
              configState: FunctionalCurrencyConfigState.notConfigured,
              scopeLabel: 'سجل المخزون',
              isLocked: false,
              canModify: true,
            ))),
      ],
      child: const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: CurrenciesManagePage(),
      ),
    );
  }

  group('Preset Searchable Currency Selection & Auto-Fill Tests', () {
    testWidgets('Selecting a preset currency from searchable picker auto-fills all fields', (tester) async {
      await tester.pumpWidget(buildTestApp(db, repository));
      await tester.pumpAndSettle();

      // Tap Add Currency FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Tap Searchable Currency Picker Field
      final pickerFinder = find.byType(AppSearchableCurrencyPickerField);
      expect(pickerFinder, findsOneWidget);
      await tester.tap(pickerFinder);
      await tester.pumpAndSettle();

      // Select SAR preset from searchable modal bottom sheet
      final sarInSheet = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('SAR'),
      );
      await tester.tap(sarInSheet.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify text fields auto-filled
      final dialogFields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );

      // 0: Code
      final codeField = tester.widget<TextField>(dialogFields.at(0));
      expect(codeField.controller?.text, 'SAR');

      // 1: Name Arabic
      final nameArField = tester.widget<TextField>(dialogFields.at(1));
      expect(nameArField.controller?.text, 'ريال سعودي');

      // 2: Name English
      final nameEnField = tester.widget<TextField>(dialogFields.at(2));
      expect(nameEnField.controller?.text, 'Saudi Riyal');

      // 3: Symbol
      final symbolField = tester.widget<TextField>(dialogFields.at(3));
      expect(symbolField.controller?.text, 'ر.س');

      // 4: Decimals
      final decimalsField = tester.widget<TextField>(dialogFields.at(4));
      expect(decimalsField.controller?.text, '2');

      // Save
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();

      // Check DB
      final savedSAR = await repository.getByCode('SAR');
      expect(savedSAR, isNotNull);
      expect(savedSAR?.code, 'SAR');
      expect(savedSAR?.nameAr, 'ريال سعودي');
      expect(savedSAR?.symbol, 'ر.س');
    });

    testWidgets('Searching preset by name filters list and auto-fills on selection', (tester) async {
      await tester.pumpWidget(buildTestApp(db, repository));
      await tester.pumpAndSettle();

      // Open Add dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Open Searchable Picker
      await tester.tap(find.byType(AppSearchableCurrencyPickerField));
      await tester.pumpAndSettle();

      // Type search query in modal search toolbar
      final searchField = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      );
      await tester.enterText(searchField, 'يورو');
      await tester.pumpAndSettle();

      // Select EUR
      final eurInSheet = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('EUR'),
      );
      await tester.tap(eurInSheet.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify auto-filled EUR data
      final dialogFields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );

      final codeField = tester.widget<TextField>(dialogFields.at(0));
      expect(codeField.controller?.text, 'EUR');

      final nameArField = tester.widget<TextField>(dialogFields.at(1));
      expect(nameArField.controller?.text, 'يورو');
    });

    testWidgets('User can customize auto-filled preset fields prior to saving', (tester) async {
      await tester.pumpWidget(buildTestApp(db, repository));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Open Searchable Picker
      await tester.tap(find.byType(AppSearchableCurrencyPickerField));
      await tester.pumpAndSettle();

      // Select AED
      final aedInSheet = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('AED'),
      );
      await tester.tap(aedInSheet.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      final dialogFields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );

      // Modify Arabic name
      await tester.enterText(dialogFields.at(1), 'درهم إماراتي (معدل)');
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();

      // Verify DB record has custom Arabic name
      final savedAED = await repository.getByCode('AED');
      expect(savedAED, isNotNull);
      expect(savedAED?.code, 'AED');
      expect(savedAED?.nameAr, 'درهم إماراتي (معدل)');
      expect(savedAED?.symbol, 'د.إ');
    });
  });
}
