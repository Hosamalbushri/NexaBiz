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

void main() {
  late AccountingDatabase db;
  late CurrencyRepository repository;

  setUp(() async {
    db = AccountingDatabase.memory();
    repository = refToRepository(db);
    await repository.ensureDefaultCurrenciesSeeded();
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

  group('CURRENCY-UI-02 — Currency Master UI Widget & Integration Tests', () {
    testWidgets('1. Displays list of seeded currencies with codes and symbols', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(db, repository));
      await tester.pumpAndSettle();

      expect(find.text('AED'), findsWidgets);
      expect(find.text('BHD'), findsWidgets);
      expect(find.text('CNY'), findsWidgets);
    });

    testWidgets('2. Search filters list by code or name', (tester) async {
      await tester.pumpWidget(buildTestApp(db, repository));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'USD');
      await tester.pumpAndSettle();

      expect(find.text('USD'), findsWidgets);
      expect(find.text('AED'), findsNothing);
      expect(find.text('BHD'), findsNothing);
    });

    testWidgets('3. Status filter chips filter list by active status', (tester) async {
      await repository.toggleActive('USD', false);

      await tester.pumpWidget(buildTestApp(db, repository));
      await tester.pumpAndSettle();

      // Tap 'غير نشط' filter chip
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w is FilterChip &&
              w.label is Text &&
              (w.label as Text).data == 'غير نشط',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('USD'), findsWidgets);
      expect(find.text('AED'), findsNothing);

      // Tap 'نشط فقط' filter chip
      await tester.tap(find.text('نشط فقط'));
      await tester.pumpAndSettle();

      expect(find.text('USD'), findsNothing);
      expect(find.text('AED'), findsWidgets);
    });

    testWidgets('4. Creates a new currency successfully', (tester) async {
      await tester.pumpWidget(buildTestApp(db, repository));
      await tester.pumpAndSettle();

      // Tap Add Currency FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Fill in currency details within AlertDialog
      final dialogFields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );

      await tester.enterText(dialogFields.at(0), 'CAD');
      await tester.enterText(dialogFields.at(1), 'دولار كندي');
      await tester.enterText(dialogFields.at(2), 'Canadian Dollar');
      await tester.enterText(dialogFields.at(3), r'C$');
      await tester.enterText(dialogFields.at(4), '2');

      // Tap Save button
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();

      // Verify persistence in repository
      final created = await repository.getByCode('CAD');
      expect(created, isNotNull);
      expect(created!.code, 'CAD');
      expect(created.nameAr, 'دولار كندي');
      expect(created.symbol, r'C$');
    });

    testWidgets('5. Duplicate currency code creation is rejected', (tester) async {
      await tester.pumpWidget(buildTestApp(db, repository));
      await tester.pumpAndSettle();

      // Tap Add Currency FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final dialogFields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );

      await tester.enterText(dialogFields.at(0), 'SAR');
      await tester.enterText(dialogFields.at(1), 'ريال سعودي مكرر');
      await tester.enterText(dialogFields.at(2), 'Duplicate SAR');

      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();

      expect(find.textContaining('مستخدم بالفعل'), findsOneWidget);
    });

    testWidgets('6. Invalid decimal precision is rejected by validation', (tester) async {
      await tester.pumpWidget(buildTestApp(db, repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final dialogFields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );

      await tester.enterText(dialogFields.at(0), 'JPY');
      await tester.enterText(dialogFields.at(4), '99');

      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();

      expect(find.text('الخانات العشرية يجب أن تكون بين 0 و 6'), findsOneWidget);
    });

    testWidgets('7. Deactivates active currency with explicit confirmation dialog', (tester) async {
      await tester.pumpWidget(buildTestApp(db, repository));
      await tester.pumpAndSettle();

      // Open Popup Menu for first card (AED)
      final popups = find.byType(PopupMenuButton<String>);
      await tester.tap(popups.first);
      await tester.pumpAndSettle();

      // Tap 'تعطيل'
      await tester.tap(find.text('تعطيل'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('تأكيد التعطيل'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'تعطيل'));
      await tester.pumpAndSettle();

      final updated = await repository.getByCode('AED');
      expect(updated!.isActive, isFalse);
    });

    testWidgets('8. Edits an existing currency precision and name', (tester) async {
      await tester.pumpWidget(buildTestApp(db, repository));
      await tester.pumpAndSettle();

      // Search for EUR to isolate it in the list
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'EUR');
      await tester.pumpAndSettle();

      final popups = find.byType(PopupMenuButton<String>);
      await tester.tap(popups.first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('تعديل'));
      await tester.pumpAndSettle();

      final dialogFields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );

      await tester.enterText(dialogFields.at(1), 'يورو معدل');
      await tester.enterText(dialogFields.at(4), '4');

      await tester.tap(find.text('تحديث'));
      await tester.pumpAndSettle();

      final updated = await repository.getByCode('EUR');
      expect(updated!.nameAr, 'يورو معدل');
      expect(updated.decimalDigits, 4);
    });
  });
}

CurrencyRepository refToRepository(AccountingDatabase db) {
  return CurrencyRepositoryImpl(db, readCompanyId: () => 'default-company');
}
