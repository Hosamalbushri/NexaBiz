import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/widgets/app_currency_selector.dart';
import 'package:stock_count/modules/currency/domain/entities/currency.dart';
import 'package:stock_count/modules/currency/presentation/providers/currency_providers.dart';

void main() {
  final now = DateTime(2026, 1, 1);
  final sar = Currency(
    id: 1,
    uuid: 'c-sar',
    code: 'SAR',
    nameAr: 'ريال سعودي',
    nameEn: 'Saudi Riyal',
    symbol: 'ر.س',
    decimalDigits: 2,
    isDefault: true,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
  final usd = Currency(
    id: 2,
    uuid: 'c-usd',
    code: 'USD',
    nameAr: 'دولار أمريكي',
    nameEn: 'US Dollar',
    symbol: '\$',
    decimalDigits: 2,
    isDefault: false,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
  final yerInactive = Currency(
    id: 3,
    uuid: 'c-yer',
    code: 'YER',
    nameAr: 'ريال يمني',
    nameEn: 'Yemeni Rial',
    symbol: 'ر.ي',
    decimalDigits: 2,
    isDefault: false,
    isActive: false,
    createdAt: now,
    updatedAt: now,
  );

  group('Phase 1B: AppCurrencySelector Consolidation Tests', () {
    testWidgets('1. Canonical AppCurrencySelector renders explicit static currency list', (tester) async {
      Currency? selected;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AppCurrencySelector(
                currencies: [sar, usd],
                selectedCurrencyCode: 'SAR',
                onChanged: (c) => selected = c,
              ),
            ),
          ),
        ),
      );

      expect(find.text('SAR'), findsOneWidget);
      expect(find.text('ر.س'), findsOneWidget);

      await tester.tap(find.byType(AppCurrencySelector));
      await tester.pumpAndSettle();

      expect(find.text('USD'), findsWidgets);
      await tester.tap(find.text('USD').first);
      await tester.pumpAndSettle();

      expect(selected, usd);
    });

    testWidgets('2. Canonical AppCurrencySelector resolves currencies asynchronously via Riverpod provider', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeCurrenciesProvider.overrideWith((ref) => Stream.value([sar, usd])),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AppCurrencySelector(
                selectedCurrencyCode: 'USD',
                onChanged: _noop,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('USD'), findsOneWidget);
      expect(find.text('\$'), findsOneWidget);
    });

    testWidgets('3. Inactive currency status badge appears when includeInactive is true', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AppCurrencySelector(
                currencies: [sar, yerInactive],
                includeInactive: true,
                selectedCurrencyCode: 'YER',
                onChanged: _noop,
              ),
            ),
          ),
        ),
      );

      expect(find.text('YER'), findsOneWidget);
      expect(find.text('غير نشط'), findsOneWidget);
    });

    testWidgets('4. Form field validation triggers error message when required and empty', (tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Form(
                key: formKey,
                child: AppCurrencySelector(
                  currencies: [sar, usd],
                  selectedCurrencyCode: null,
                  isRequired: true,
                  onChanged: _noop,
                ),
              ),
            ),
          ),
        ),
      );

      formKey.currentState!.validate();
      await tester.pumpAndSettle();

      expect(find.text('يرجى اختيار العملة'), findsOneWidget);
    });
  });
}

void _noop(Currency? c) {}
