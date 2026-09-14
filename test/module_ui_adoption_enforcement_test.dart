import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/presentation/scaffolds/module_list_scaffold.dart';
import 'package:stock_count/modules/currency/domain/entities/currency.dart';
import 'package:stock_count/modules/currency/presentation/pages/currencies_manage_page.dart';
import 'package:stock_count/modules/currency/presentation/providers/currency_providers.dart';
import 'package:stock_count/modules/currency/presentation/providers/functional_currency_providers.dart';
import 'package:stock_count/modules/inventory/cost_valuation/presentation/providers/inventory_valuation_currency_providers.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

void main() {
  group('Phase 6 — Module UI Adoption & Implementation Enforcement Tests', () {
    testWidgets(
      'CurrenciesManagePage adopts ModuleListScaffold and renders canonical AppCard items',
      (WidgetTester tester) async {
        final dummyCurrencies = <Currency>[
          Currency(
            id: 'cur-1',
            code: 'USD',
            nameAr: 'دولار أمريكي',
            nameEn: 'US Dollar',
            symbol: '\$',
            decimalDigits: 2,
            isDefault: true,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Currency(
            id: 'cur-2',
            code: 'EUR',
            nameAr: 'يورو',
            nameEn: 'Euro',
            symbol: '€',
            decimalDigits: 2,
            isDefault: false,
            isActive: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              allCurrenciesProvider.overrideWith(
                (ref) => Stream.value(dummyCurrencies),
              ),
              functionalCurrencyStateInfoProvider.overrideWith(
                (ref) async => FunctionalCurrencyStateInfo(
                  configState: FunctionalCurrencyConfigState.configured,
                  currencyCode: 'USD',
                  hasPostedActivity: false,
                  canModify: true,
                ),
              ),
              inventoryValuationCurrencyStateProvider.overrideWith(
                (ref) async => InventoryValuationCurrencyStateInfo(
                  currency: dummyCurrencies.first,
                  currencyCode: 'USD',
                  configState: FunctionalCurrencyConfigState.configured,
                  scopeLabel: 'Inventory Valuation',
                  isLocked: false,
                  canModify: true,
                ),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: CurrenciesManagePage(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Verify ModuleListScaffold presence
        expect(find.byType(ModuleListScaffold<Currency>), findsOneWidget);

        // 2. Verify currency cards render inside AppCard
        expect(find.byType(AppCard), findsNWidgets(2));
        expect(find.text('USD'), findsWidgets);
        expect(find.text('EUR'), findsOneWidget);
      },
    );
  });
}
