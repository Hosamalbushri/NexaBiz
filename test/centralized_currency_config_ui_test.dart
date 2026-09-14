import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/company/functional_currency_providers.dart';
import 'package:stock_count/core/tenancy/tenant_context.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/accounting/shared/data/repositories/currency_repository_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/repositories/currency_repository.dart';
import 'package:stock_count/modules/accounting/shared/presentation/pages/currencies_manage_page.dart';
import 'package:stock_count/app/settings/company/functional_currency_config_page.dart';
import 'package:stock_count/modules/inventory/cost_valuation/presentation/widgets/inventory_valuation_currency_card.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/currency.dart';
import 'package:stock_count/modules/accounting/shared/presentation/providers/currency_providers.dart';
import 'package:stock_count/modules/inventory/cost_valuation/presentation/providers/inventory_valuation_currency_providers.dart';

void main() {
  late NexabizDatabase db;
  late CurrencyRepository repository;

  setUp(() async {
    db = NexabizDatabase.memory();
    repository = CurrencyRepositoryImpl(db, readCompanyId: () => 'default-company');
    await repository.ensureDefaultCurrenciesSeeded();
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestWidget(Widget child) {
    return ProviderScope(
      overrides: [
        accountingDatabaseProvider.overrideWithValue(db),
        currentCompanyIdProvider.overrideWithValue('default-company'),
        currencyRepositoryProvider.overrideWithValue(repository),
        allCurrenciesProvider.overrideWith((ref) => Stream.fromFuture(repository.getAll(includeInactive: true))),
        activeCurrenciesProvider.overrideWith((ref) => Stream.fromFuture(repository.getAll(includeInactive: false))),
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
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: child,
      ),
    );
  }

  group('CURRENCY-UI-15 — Centralized Currency Architecture & Verification Matrix', () {
    testWidgets('1. Currency Master UI displays role checkboxes in form dialog', (tester) async {
      await tester.pumpWidget(buildTestWidget(const CurrenciesManagePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('استخدام كعملة وظيفية'), findsWidgets);
      expect(find.textContaining('عملة تقييم المخزون'), findsWidgets);
      expect(find.byType(CheckboxListTile), findsNWidgets(2));
    });

    testWidgets('2. Currency record is persisted independently without requiring role assignment', (tester) async {
      await tester.pumpWidget(buildTestWidget(const CurrenciesManagePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final dialogFields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );

      await tester.enterText(dialogFields.at(0), 'OMR');
      await tester.enterText(dialogFields.at(1), 'ريال عماني');
      await tester.enterText(dialogFields.at(2), 'Omani Rial');
      await tester.enterText(dialogFields.at(3), 'ر.ع.');
      await tester.enterText(dialogFields.at(4), '3');

      // Do NOT check any role check boxes
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();

      final created = await repository.getByCode('OMR');
      expect(created, isNotNull);
      expect(created!.code, 'OMR');
      expect(created.nameAr, 'ريال عماني');
    });

    testWidgets('3. Unassigning or modifying role does not delete currency from Currency Master', (tester) async {
      final existing = await repository.getByCode('BHD');
      if (existing == null) {
        await repository.upsert(const CurrencyDraft(
          code: 'BHD',
          nameAr: 'دينار بحريني',
          nameEn: 'Bahraini Dinar',
          symbol: 'د.ب',
          decimalDigits: 3,
        ));
      }

      final created = await repository.getByCode('BHD');
      expect(created, isNotNull);

      // Verify toggling active or removing role leaves record intact
      await repository.toggleActive('BHD', false);
      final afterDeactivate = await repository.getByCode('BHD');
      expect(afterDeactivate, isNotNull);
      expect(afterDeactivate!.code, 'BHD');
    });

    testWidgets('4. FunctionalCurrencyConfigPage is read-only and includes Manage Currencies button', (tester) async {
      await tester.pumpWidget(buildTestWidget(const FunctionalCurrencyConfigPage()));
      await tester.pumpAndSettle();

      expect(find.textContaining('إدارة العملات'), findsWidgets);
      // Ensure no dropdown form selector is present on this page
      expect(find.byType(DropdownButtonFormField), findsNothing);
    });

    testWidgets('5. InventoryValuationCurrencyCard is read-only and includes Manage Currencies button', (tester) async {
      await tester.pumpWidget(buildTestWidget(const Scaffold(body: InventoryValuationCurrencyCard())));
      await tester.pumpAndSettle();

      expect(find.text('إدارة العملات'), findsWidgets);
      // Ensure no inline currency dropdown selector is present
      expect(find.byType(DropdownButtonFormField), findsNothing);
    });

    testWidgets('6. FunctionalCurrencyConfigPage does NOT display YER as default when unconfigured', (tester) async {
      await tester.pumpWidget(buildTestWidget(const FunctionalCurrencyConfigPage()));
      await tester.pumpAndSettle();

      // State should show not configured warning, not default to YER
      expect(find.textContaining('غير مضبوطة'), findsWidgets);
    });

    testWidgets('7. InventoryValuationCurrencyCard displays warning when unconfigured without YER default', (tester) async {
      await tester.pumpWidget(buildTestWidget(const Scaffold(body: InventoryValuationCurrencyCard())));
      await tester.pumpAndSettle();

      expect(find.textContaining('لم يتم تحديد عملة تقييم المخزون'), findsWidgets);
    });
  });
}
