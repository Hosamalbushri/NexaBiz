import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

void main() {
  group('AppNumberField Tests', () {
    testWidgets('AppNumberField renders label, placeholder, and parses input value', (tester) async {
      num? capturedValue;

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: shadcn.Scaffold(
            child: AppNumberField(
              label: 'الكمية',
              hint: 'أدخل الرقم',
              value: 10,
              onChanged: (val) => capturedValue = val,
            ),
          ),
        ),
      );

      expect(find.text('الكمية'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);

      await tester.enterText(find.byType(shadcn.TextField), '25');
      await tester.pumpAndSettle();

      expect(capturedValue, equals(25));
    });

    testWidgets('AppNumberField renders spinner feature when enabled', (tester) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: shadcn.Scaffold(
            child: AppNumberField(
              label: 'عدد العلب',
              value: 5,
              step: 1.0,
              enableSpinner: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(shadcn.TextField), findsOneWidget);
    });
  });

  group('AppPhoneField Tests', () {
    testWidgets('AppPhoneField renders label, phone input, and handles country selector', (tester) async {
      shadcn.PhoneNumber? capturedPhone;

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: shadcn.Scaffold(
            child: AppPhoneField(
              label: 'رقم الهاتف',
              initialValue: const shadcn.PhoneNumber(shadcn.Country.saudiArabia, '501234567'),
              onChanged: (phone) => capturedPhone = phone,
            ),
          ),
        ),
      );

      expect(find.text('رقم الهاتف'), findsOneWidget);
      expect(find.byType(shadcn.PhoneInput), findsOneWidget);
      expect(capturedPhone, isNull);
    });
  });

  group('AppChoiceCardGroup Tests', () {
    testWidgets('AppChoiceCardGroup renders choice options as RadioCards and updates selection', (tester) async {
      String? selectedValue = 'local';

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: shadcn.Scaffold(
            child: StateSwitch<String>(
              initialValue: selectedValue,
              builder: (context, value, updateValue) {
                return AppChoiceCardGroup<String>(
                  label: 'طريقة التشغيل',
                  value: value,
                  onChanged: (val) {
                    selectedValue = val;
                    updateValue(val);
                  },
                  items: const [
                    AppChoiceOption<String>(
                      value: 'server',
                      title: 'الاتصال بالسيرفر الرئيسي',
                      subtitle: 'مزامنة مباشرة مع القاعدة المركزية',
                    ),
                    AppChoiceOption<String>(
                      value: 'local',
                      title: 'التشغيل المحلي (Standalone)',
                      subtitle: 'عمل محلي مستقل على جهاز الهاتف/التأشير',
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('طريقة التشغيل'), findsOneWidget);
      expect(find.text('الاتصال بالسيرفر الرئيسي'), findsOneWidget);
      expect(find.text('التشغيل المحلي (Standalone)'), findsOneWidget);
      expect(find.byType(shadcn.RadioCard<String>), findsNWidgets(2));

      await tester.tap(find.text('الاتصال بالسيرفر الرئيسي'));
      await tester.pumpAndSettle();

      expect(selectedValue, equals('server'));
    });
  });
}

class StateSwitch<T> extends StatefulWidget {
  const StateSwitch({
    super.key,
    required this.initialValue,
    required this.builder,
  });

  final T? initialValue;
  final Widget Function(BuildContext context, T? value, ValueChanged<T?> update) builder;

  @override
  State<StateSwitch<T>> createState() => _StateSwitchState<T>();
}

class _StateSwitchState<T> extends State<StateSwitch<T>> {
  late T? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _value, (val) => setState(() => _value = val));
  }
}
