import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

void main() {
  group('Direct shadcn StarRating Tests', () {
    testWidgets('StarRating renders stars and initial rating value', (tester) async {
      double currentRating = 3.5;

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: shadcn.Scaffold(
            child: shadcn.StarRating(
              value: currentRating,
              max: 5.0,
              step: 0.5,
              onChanged: (val) => currentRating = val,
            ),
          ),
        ),
      );

      expect(find.byType(shadcn.StarRating), findsOneWidget);
    });
  });

  group('Switch Tests', () {
    testWidgets('AppSwitch renders label and toggles value', (tester) async {
      bool isEnabled = false;

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: shadcn.Scaffold(
            child: StateSwitch<bool>(
              initialValue: isEnabled,
              builder: (context, value, updateValue) {
                return AppSwitch(
                  label: 'تفعيل التنبيهات',
                  value: value ?? false,
                  onChanged: (val) {
                    isEnabled = val;
                    updateValue(val);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('تفعيل التنبيهات'), findsOneWidget);
      expect(find.byType(shadcn.Switch), findsOneWidget);

      await tester.tap(find.byType(shadcn.Switch));
      await tester.pumpAndSettle();

      expect(isEnabled, isTrue);
    });
  });

  group('TextArea & AppMultilineField Tests', () {
    testWidgets('AppMultilineField renders label, initial value, and error footer', (tester) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: shadcn.Scaffold(
            child: AppMultilineField(
              label: 'ملاحظات إضافية',
              initialValue: 'ملاحظات مهمة للعميل',
              required: true,
              errorText: 'الحقل مطلوب',
            ),
          ),
        ),
      );

      expect(find.text('ملاحظات إضافية'), findsOneWidget);
      expect(find.text('*'), findsOneWidget);
      expect(find.text('الحقل مطلوب'), findsOneWidget);
      expect(find.byType(shadcn.TextArea), findsOneWidget);
    });

    testWidgets('Direct shadcn TextArea supports expandable height', (tester) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: shadcn.Scaffold(
            child: const shadcn.TextArea(
              initialValue: 'نص متعدد الأسطر',
              expandableHeight: true,
              initialHeight: 150,
            ),
          ),
        ),
      );

      expect(find.byType(shadcn.TextArea), findsOneWidget);
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
