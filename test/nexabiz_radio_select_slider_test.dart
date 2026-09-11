import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

void main() {
  group('Direct shadcn RadioGroup Tests', () {
    testWidgets('ControlledRadioGroup renders RadioItems and handles selection', (tester) async {
      String? selectedValue = 'item1';

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: shadcn.Scaffold(
            child: StateSwitch<String>(
              initialValue: selectedValue,
              builder: (context, value, updateValue) {
                return shadcn.ControlledRadioGroup<String>(
                  initialValue: value,
                  onChanged: (val) {
                    selectedValue = val;
                    updateValue(val);
                  },
                  child: Column(
                    children: const [
                      shadcn.RadioItem<String>(
                        value: 'item1',
                        trailing: Text('الخيار الأول'),
                      ),
                      shadcn.RadioItem<String>(
                        value: 'item2',
                        trailing: Text('الخيار الثاني'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('الخيار الأول'), findsOneWidget);
      expect(find.text('الخيار الثاني'), findsOneWidget);

      await tester.tap(find.text('الخيار الثاني'));
      await tester.pumpAndSettle();

      expect(selectedValue, equals('item2'));
    });
  });

  group('AppSearchableSelect Tests', () {
    testWidgets('AppSearchableSelect renders label, value, and options list', (tester) async {
      String? selectedFruit = 'تفاح';

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: shadcn.Scaffold(
            child: AppSearchableSelect<String>(
              label: 'الفواكه',
              value: selectedFruit,
              items: const ['تفاح', 'موز', 'برتقال'],
              itemBuilder: (context, item) => Text(item),
              onChanged: (val) => selectedFruit = val,
            ),
          ),
        ),
      );

      expect(find.text('الفواكه'), findsOneWidget);
      expect(find.text('تفاح'), findsOneWidget);
    });
  });

  group('AppSliderField Tests', () {
    testWidgets('AppSliderField renders label, formatted value badge, and slider track', (tester) async {
      shadcn.SliderValue sliderVal = const shadcn.SliderValue.single(40.0);

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: shadcn.Scaffold(
            child: AppSliderField(
              label: 'نسبة الخصم',
              value: sliderVal,
              min: 0.0,
              max: 100.0,
              onChanged: (val) => sliderVal = val,
            ),
          ),
        ),
      );

      expect(find.text('نسبة الخصم'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      expect(find.byType(shadcn.Slider), findsOneWidget);
    });

    testWidgets('Direct shadcn SliderValue.ranged represents start and end bounds', (tester) async {
      const rangeValue = shadcn.SliderValue.ranged(10.0, 80.0);

      expect(rangeValue.isRanged, isTrue);
      expect(rangeValue.start, equals(10.0));
      expect(rangeValue.end, equals(80.0));
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
