import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/widgets/app_date_field.dart';
import 'package:stock_count/core/widgets/app_field_shell.dart';
import 'package:stock_count/core/widgets/app_form_grid.dart';
import 'package:stock_count/core/widgets/app_select_field.dart';
import 'package:stock_count/core/widgets/app_text_field.dart';

void main() {
  group('Form Field System Unit Tests', () {
    testWidgets('AppFieldShell renders label, required star, and child', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppFieldShell(
              label: 'اسم العميل',
              required: true,
              child: Text('محتوى الحقـل'),
            ),
          ),
        ),
      );

      expect(find.text('محتوى الحقـل'), findsOneWidget);
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('AppTextField renders and accepts text input', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'العنوان البريدي',
              hint: 'أدخل العنوان',
            ),
          ),
        ),
      );

      expect(find.text('العنوان البريدي'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'الرياض - الملقا');
      expect(controller.text, 'الرياض - الملقا');
    });

    testWidgets('AppSelectField renders selection items', (WidgetTester tester) async {
      String? selected = 'SAR';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: AppSelectField<String>(
                  value: selected,
                  label: 'العملة الحالية',
                  items: const [
                    AppSelectItem(value: 'SAR', label: 'ريال سعودي'),
                    AppSelectItem(value: 'USD', label: 'دولار أمريكي'),
                  ],
                  onChanged: (val) {
                    setState(() => selected = val);
                  },
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('العملة الحالية'), findsOneWidget);
      expect(find.text('ريال سعودي'), findsOneWidget);
    });

    testWidgets('AppDateField renders date value', (WidgetTester tester) async {
      final date = DateTime(2026, 9, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDateField(
              value: date,
              label: 'تاريخ الفاتورة',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('تاريخ الفاتورة'), findsOneWidget);
      expect(find.text('2026-09-01'), findsOneWidget);
    });

    testWidgets('AppFormGrid arranges children responsively', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppFormGrid(
              children: [
                Text('حقل 1'),
                Text('حقل 2'),
                Text('حقل 3'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('حقل 1'), findsOneWidget);
      expect(find.text('حقل 2'), findsOneWidget);
      expect(find.text('حقل 3'), findsOneWidget);
    });
  });
}
