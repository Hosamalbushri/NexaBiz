import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/widgets/app_currency_selector.dart';

void main() {
  group('AppCurrencySelector Widget Tests', () {
    testWidgets('renders selected currency and handles selection changes', (WidgetTester tester) async {
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCurrencySelector(
              currencies: const ['YER', 'SAR', 'USD'],
              selectedCurrency: 'YER',
              onChanged: (val) => selected = val,
            ),
          ),
        ),
      );

      expect(find.text('YER'), findsOneWidget);

      await tester.tap(find.byType(AppCurrencySelector));
      await tester.pumpAndSettle();

      expect(find.text('SAR').last, findsOneWidget);
      await tester.tap(find.text('SAR').last);
      await tester.pumpAndSettle();

      expect(selected, 'SAR');
    });
  });
}
