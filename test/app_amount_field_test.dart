import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/widgets/app_amount_field.dart';

void main() {
  Widget wrap(Widget child, {TextDirection direction = TextDirection.ltr}) {
    return MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }

  testWidgets('shows initial formatted value', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppAmountField(
          value: 1250000.75,
          onChanged: (_) {},
          decimalPlaces: 2,
          trimTrailingZeros: false,
        ),
      ),
    );
    expect(find.text('1,250,000.75'), findsOneWidget);
  });

  testWidgets('onChanged receives raw double while typing', (tester) async {
    double? last;
    await tester.pumpWidget(
      wrap(
        AppAmountField(
          value: 0,
          emptyWhenZero: true,
          onChanged: (v) => last = v,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '1000');
    await tester.pump();
    expect(last, 1000);
    expect(find.text('1,000'), findsOneWidget);
  });

  testWidgets('focus places caret at end by default', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppAmountField(
          value: 1250000,
          onChanged: (_) {},
          decimalPlaces: 0,
          autofocus: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final field = tester.widget<TextField>(find.byType(TextField));
    final selection = field.controller!.selection;
    expect(selection.isCollapsed, isTrue);
    expect(selection.baseOffset, field.controller!.text.length);
  });

  testWidgets('disabled and readOnly states', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppAmountField(
          value: 10,
          onChanged: (_) {},
          enabled: false,
        ),
      ),
    );
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

    await tester.pumpWidget(
      wrap(
        AppAmountField(
          value: 10,
          onChanged: (_) {},
          readOnly: true,
        ),
      ),
    );
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
  });

  testWidgets('shows error text', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppAmountField(
          value: 0,
          onChanged: (_) {},
          errorText: 'Required',
        ),
      ),
    );
    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('RTL layout still formats western digits', (tester) async {
    double? last;
    await tester.pumpWidget(
      wrap(
        AppAmountField(
          value: 0,
          emptyWhenZero: true,
          onChanged: (v) => last = v,
        ),
        direction: TextDirection.rtl,
      ),
    );
    await tester.enterText(find.byType(TextField), '2500.5');
    await tester.pump();
    expect(last, 2500.5);
    expect(find.text('2,500.5'), findsOneWidget);
  });

  testWidgets('FinancialNumberField alias works', (tester) async {
    await tester.pumpWidget(
      wrap(
        FinancialNumberField(
          value: 1000,
          onChanged: (_) {},
          decimalPlaces: 0,
        ),
      ),
    );
    expect(find.text('1,000'), findsOneWidget);
  });
}
