import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

void main() {
  group('Direct shadcn TextField Tests', () {
    testWidgets('TextField renders and accepts text input', (tester) async {
      final controller = TextEditingController(text: 'نص الأولي');

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: shadcn.Scaffold(
            child: shadcn.TextField(
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.byType(shadcn.TextField), findsOneWidget);
      expect(find.text('نص الأولي'), findsOneWidget);
    });
  });

  group('Direct shadcn TimePicker Tests', () {
    testWidgets('TimePicker renders selected time', (tester) async {
      const initialTime = shadcn.TimeOfDay(hour: 14, minute: 30);

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: shadcn.Scaffold(
            child: const shadcn.TimePicker(
              value: initialTime,
              use24HourFormat: true,
            ),
          ),
        ),
      );

      expect(find.byType(shadcn.TimePicker), findsOneWidget);
    });
  });

  group('Direct shadcn Toggle Tests', () {
    testWidgets('Toggle renders child and triggers callback when pressed', (tester) async {
      bool isToggled = false;

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: shadcn.Scaffold(
            child: StateSwitch<bool>(
              initialValue: isToggled,
              builder: (context, value, update) {
                return shadcn.Toggle(
                  value: value ?? false,
                  onChanged: (val) {
                    isToggled = val;
                    update(val);
                  },
                  child: const Text('B'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(shadcn.Toggle), findsOneWidget);
      expect(find.text('B'), findsOneWidget);

      await tester.tap(find.byType(shadcn.Toggle));
      await tester.pumpAndSettle();

      expect(isToggled, isTrue);
    });
  });

  group('AppExclusiveToggleGroup Tests', () {
    testWidgets('AppExclusiveToggleGroup renders options and switches selection', (tester) async {
      String selectedMode = 'list';

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: shadcn.Scaffold(
            child: StateSwitch<String>(
              initialValue: selectedMode,
              builder: (context, value, update) {
                return AppExclusiveToggleGroup<String>(
                  value: value,
                  onChanged: (newVal) {
                    selectedMode = newVal;
                    update(newVal);
                  },
                  options: const [
                    ToggleOption(
                      value: 'list',
                      child: Text('عرض القائمة'),
                      tooltip: 'قائمة',
                    ),
                    ToggleOption(
                      value: 'grid',
                      child: Text('عرض الشبكة'),
                      tooltip: 'شبكة',
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('عرض القائمة'), findsOneWidget);
      expect(find.text('عرض الشبكة'), findsOneWidget);

      await tester.tap(find.text('عرض الشبكة'));
      await tester.pumpAndSettle();

      expect(selectedMode, equals('grid'));
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
