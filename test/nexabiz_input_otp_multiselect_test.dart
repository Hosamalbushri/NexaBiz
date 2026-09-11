import 'package:flutter/material.dart' hide Theme;
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

void main() {
  Widget buildTestApp(Widget child) {
    return shadcn.ShadcnApp(
      home: shadcn.Scaffold(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }

  group('Direct shadcn.InputOTP Behavioral Tests', () {
    testWidgets('renders InputOTP with digit children correctly', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          shadcn.InputOTP(
            children: [
              shadcn.InputOTPChild.character(allowDigit: true),
              shadcn.InputOTPChild.character(allowDigit: true),
              shadcn.InputOTPChild.separator,
              shadcn.InputOTPChild.character(allowDigit: true),
              shadcn.InputOTPChild.character(allowDigit: true),
            ],
          ),
        ),
      );

      expect(find.byType(shadcn.InputOTP), findsOneWidget);
      expect(find.byType(shadcn.OTPSeparator), findsOneWidget);
    });

    test('evaluates otpToString() correctly', () {
      final codes = <int?>[49, 50, 53, 57]; // '1', '2', '5', '9'
      expect(codes.otpToString(), equals('1259'));

      final partialCodes = <int?>[49, null, 51];
      expect(partialCodes.otpToString(), equals('13'));
    });
  });

  group('Direct shadcn.showItemPicker Behavioral Tests', () {
    testWidgets('displays items and allows selection in showItemPickerDialog', (tester) async {
      int? selectedValue;

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) {
              return shadcn.PrimaryButton(
                onPressed: () async {
                  selectedValue = await shadcn.showItemPickerDialog<int>(
                    context,
                    title: const Text('Select Number'),
                    items: const shadcn.ItemList([10, 20, 30]),
                    builder: (ctx, item) {
                      return shadcn.ItemPickerOption<int>(
                        value: item,
                        child: Text('Item $item'),
                      );
                    },
                  );
                },
                child: const Text('Open Picker'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Select Number'), findsOneWidget);
      expect(find.text('Item 10'), findsOneWidget);
      expect(find.text('Item 20'), findsOneWidget);
      expect(find.text('Item 30'), findsOneWidget);

      await tester.tap(find.text('Item 20'));
      await tester.pumpAndSettle();

      expect(selectedValue, equals(20));
    });
  });

  group('AppMultiSelectField<T> Behavioral Tests', () {
    testWidgets('renders label, hint, and items correctly', (tester) async {
      Iterable<String>? selectedValues;

      await tester.pumpWidget(
        buildTestApp(
          AppMultiSelectField<String>(
            label: 'الفروع المتاحة',
            required: true,
            hint: 'اختر الفرع',
            items: const ['فرع الرياض', 'فرع جدة', 'فرع الدمام'],
            itemLabelBuilder: (item) => item,
            value: const ['فرع الرياض'],
            onChanged: (val) => selectedValues = val,
          ),
        ),
      );

      expect(find.text('الفروع المتاحة'), findsOneWidget);
      expect(find.text('*'), findsOneWidget);
      expect(find.text('فرع الرياض'), findsOneWidget);
      expect(selectedValues, isNull);
    });

    testWidgets('displays error text when provided', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          AppMultiSelectField<String>(
            label: 'المستودعات',
            errorText: 'يجب اختيار مستودع واحد على الأقل',
            items: const ['مستودع 1', 'مستودع 2'],
            itemLabelBuilder: (item) => item,
          ),
        ),
      );

      expect(find.text('يجب اختيار مستودع واحد على الأقل'), findsOneWidget);
    });
  });
}
