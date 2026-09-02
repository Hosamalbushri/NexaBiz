import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/widgets/app_view_mode_toggle.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  testWidgets('renders all options and calls onChanged when clicked', (tester) async {
    String selected = 'list';
    String? changedTo;

    final options = const [
      AppViewModeOption<String>(
        value: 'list',
        icon: Icons.list,
        tooltip: 'List View',
      ),
      AppViewModeOption<String>(
        value: 'grid',
        icon: Icons.grid_view,
        tooltip: 'Grid View',
      ),
    ];

    await tester.pumpWidget(
      wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return AppViewModeToggle<String>(
              options: options,
              selected: selected,
              onChanged: (val) {
                changedTo = val;
                setState(() => selected = val);
              },
            );
          },
        ),
      ),
    );

    expect(find.byIcon(Icons.list), findsOneWidget);
    expect(find.byIcon(Icons.grid_view), findsOneWidget);

    await tester.tap(find.byIcon(Icons.grid_view));
    await tester.pump();

    expect(changedTo, equals('grid'));
  });
}
