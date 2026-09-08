import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/widgets/app_currency_selector.dart';
import 'package:stock_count/modules/accounting/shared/domain/entities/currency.dart';

void main() {
  final now = DateTime(2026, 1, 1);
  final yer = Currency(
    id: 1,
    uuid: 'c-yer',
    code: 'YER',
    nameAr: 'ريال يمني',
    nameEn: 'Yemeni Rial',
    symbol: 'ر.ي',
    decimalDigits: 2,
    isDefault: true,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
  final sar = Currency(
    id: 2,
    uuid: 'c-sar',
    code: 'SAR',
    nameAr: 'ريال سعودي',
    nameEn: 'Saudi Riyal',
    symbol: 'ر.س',
    decimalDigits: 2,
    isDefault: false,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
  final usdInactive = Currency(
    id: 3,
    uuid: 'c-usd',
    code: 'USD',
    nameAr: 'دولار أمريكي',
    nameEn: 'US Dollar',
    symbol: '\$',
    decimalDigits: 2,
    isDefault: false,
    isActive: false,
    createdAt: now,
    updatedAt: now,
  );

  group('AppCurrencySelector Canonical Widget Tests', () {
    testWidgets('renders selected currency code and symbol', (tester) async {
      Currency? selected;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppCurrencySelector(
                currencies: [yer, sar, usdInactive],
                selectedCurrencyCode: 'YER',
                onChanged: (c) => selected = c,
              ),
            ),
          ),
        ),
      );

      expect(find.text('YER'), findsOneWidget);
      expect(find.text('ر.ي'), findsOneWidget);

      await tester.tap(find.byType(AppCurrencySelector));
      await tester.pumpAndSettle();

      expect(find.text('SAR'), findsWidgets);
      expect(find.text('— Saudi Riyal'), findsOneWidget);

      await tester.tap(find.text('SAR').first);
      await tester.pumpAndSettle();

      expect(selected, sar);
    });

    testWidgets('supports searching currency by code or name', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('ar'),
            home: Scaffold(
              body: AppCurrencySelector(
                currencies: [yer, sar, usdInactive],
                selectedCurrencyCode: 'YER',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppCurrencySelector));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Saudi');
      await tester.pumpAndSettle();

      final sheetFinder = find.byType(BottomSheet);
      expect(find.descendant(of: sheetFinder, matching: find.text('SAR')), findsOneWidget);
      expect(find.descendant(of: sheetFinder, matching: find.text('YER')), findsNothing);
    });

    testWidgets('displays status badge for inactive currency', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('ar'),
            home: Scaffold(
              body: AppCurrencySelector(
                currencies: [yer, sar, usdInactive],
                includeInactive: true,
                selectedCurrencyCode: 'USD',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('USD'), findsOneWidget);
      expect(find.text('غير نشط'), findsOneWidget);
    });

    testWidgets('triggers validation error when required and empty', (tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Form(
                key: formKey,
                child: AppCurrencySelector(
                  currencies: [yer, sar],
                  selectedCurrencyCode: null,
                  isRequired: true,
                  onChanged: (_) {},
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
