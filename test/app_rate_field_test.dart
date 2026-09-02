import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/widgets/app_rate_field.dart';

void main() {
  group('AppRateField Widget Tests', () {
    testWidgets('renders input label and accepts user text changes', (WidgetTester tester) async {
      String? entered;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppRateField(
              initialValue: '1.0',
              onChanged: (val) => entered = val,
            ),
          ),
        ),
      );

      expect(find.text('سعر الصرف'), findsOneWidget);
      expect(find.text('1.0'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '530.5');
      expect(entered, '530.5');
    });
  });
}
