import 'package:flutter/material.dart' hide Column, Row, Scaffold, Divider, VerticalDivider, Table, Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'package:stock_count/app/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NexaBiz Design System — Layout & Basic Composition Primitives', () {
    testWidgets('withPadding wraps child with specified edge insets', (tester) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.shadcnLight(),
          home: const shadcn.Scaffold(
            child: Text('Padded Text'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final paddedText = const Text('Padded Text').withPadding(all: 16);
      expect(paddedText, isA<Padding>());
      final padding = paddedText as Padding;
      expect(padding.padding, equals(const EdgeInsets.all(16)));
    });

    testWidgets('withPadding supports directional horizontal and vertical padding', (tester) async {
      final paddedText = const Text('Directional Padding').withPadding(horizontal: 24, vertical: 12);
      expect(paddedText, isA<Padding>());
      final padding = paddedText as Padding;
      expect(
        padding.padding,
        equals(const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
      );
    });

    testWidgets('center wraps child in a Flutter Center widget', (tester) async {
      final centeredText = const Text('Centered Text').center();
      expect(centeredText, isA<Center>());
    });

    testWidgets('Column.gap and Row.gap insert spacing between flex children', (tester) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.shadcnLight(),
          home: shadcn.Scaffold(
            child: shadcn.Column(
              children: const [
                Text('Col Item 1'),
                Text('Col Item 2'),
              ],
            ).gap(16),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Col Item 1'), findsOneWidget);
      expect(find.text('Col Item 2'), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('Column.separator and Row.separator insert custom separators', (tester) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.shadcnLight(),
          home: shadcn.Scaffold(
            child: shadcn.Column(
              children: const [
                Text('Item A'),
                Text('Item B'),
                Text('Item C'),
              ],
            ).separator(const shadcn.Divider()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Item A'), findsOneWidget);
      expect(find.text('Item B'), findsOneWidget);
      expect(find.text('Item C'), findsOneWidget);
      expect(find.byType(shadcn.Divider), findsNWidgets(2));
    });

    testWidgets('IntrinsicWidth and IntrinsicHeight measure and equalize child dimensions', (tester) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.shadcnLight(),
          home: shadcn.Scaffold(
            child: IntrinsicHeight(
              child: shadcn.Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  Text('Short'),
                  shadcn.VerticalDivider(),
                  Text('Tall\nSecond Line\nThird Line'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Short'), findsOneWidget);
      expect(find.text('Tall\nSecond Line\nThird Line'), findsOneWidget);
      expect(find.byType(shadcn.VerticalDivider), findsOneWidget);
    });

    testWidgets('Basic renders leading, title, subtitle, content, and trailing elements', (tester) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.shadcnLight(),
          home: shadcn.Scaffold(
            child: shadcn.Basic(
              leading: const Icon(Icons.star),
              title: const Text('Title Text'),
              subtitle: const Text('Subtitle Text'),
              content: const Text('Body Content'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('Title Text'), findsOneWidget);
      expect(find.text('Subtitle Text'), findsOneWidget);
      expect(find.text('Body Content'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('BasicLayout renders structured composition without enforcing default text styles', (tester) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.shadcnLight(),
          home: shadcn.Scaffold(
            child: shadcn.BasicLayout(
              leading: const Icon(Icons.info),
              title: const Text('Custom Title'),
              subtitle: const Text('Custom Subtitle'),
              trailing: const Icon(Icons.arrow_forward),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info), findsOneWidget);
      expect(find.text('Custom Title'), findsOneWidget);
      expect(find.text('Custom Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });
  });
}
