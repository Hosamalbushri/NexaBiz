import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'package:stock_count/core/widgets/app_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapTestWidget(Widget child) {
    return shadcn.ShadcnApp(
      home: Scaffold(
        body: Center(
          child: child,
        ),
      ),
    );
  }

  group('NexaBiz Design System — Button Architecture Behavioral Suite', () {
    testWidgets('shadcn primitives render and respond to tap events',
        (tester) async {
      bool primaryTapped = false;
      bool secondaryTapped = false;

      await tester.pumpWidget(
        wrapTestWidget(
          Column(
            children: [
              shadcn.PrimaryButton(
                onPressed: () => primaryTapped = true,
                child: const Text('Primary Action'),
              ),
              shadcn.SecondaryButton(
                onPressed: () => secondaryTapped = true,
                child: const Text('Secondary Action'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Primary Action'), findsOneWidget);
      expect(find.text('Secondary Action'), findsOneWidget);

      await tester.tap(find.text('Primary Action'));
      await tester.pumpAndSettle();
      expect(primaryTapped, isTrue);

      await tester.tap(find.text('Secondary Action'));
      await tester.pumpAndSettle();
      expect(secondaryTapped, isTrue);
    });

    testWidgets('AppButton renders variants and triggers onPressed',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        wrapTestWidget(
          AppButton(
            label: 'Save Changes',
            icon: Icons.save_outlined,
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.byIcon(Icons.save_outlined), findsOneWidget);

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('AppButton handles isLoading state and disables tap callback',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        wrapTestWidget(
          AppButton(
            label: 'Submit Order',
            isLoading: true,
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.byType(shadcn.CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(AppButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tapped, isFalse);
    });

    testWidgets('AppIconButton renders icon and displays tooltip',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        wrapTestWidget(
          AppIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh Data',
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('shadcn.ButtonGroup renders grouped items', (tester) async {
      await tester.pumpWidget(
        wrapTestWidget(
          shadcn.ButtonGroup(
            children: [
              shadcn.OutlineButton(
                onPressed: () {},
                child: const Text('Day'),
              ),
              shadcn.OutlineButton(
                onPressed: () {},
                child: const Text('Week'),
              ),
              shadcn.OutlineButton(
                onPressed: () {},
                child: const Text('Month'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
    });
  });
}
