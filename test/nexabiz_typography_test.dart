import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

void main() {
  group('NexaBiz Shadcn Typography & Text Extensions Suite', () {
    testWidgets('Heading extensions (.h1, .h2, .h3, .h4) render with canonical styles', (
      tester,
    ) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.shadcnLight(),
          home: Column(
            children: [
              const Text('Headline 1').h1,
              const Text('Headline 2').h2,
              const Text('Headline 3').h3,
              const Text('Headline 4').h4,
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Headline 1'), findsOneWidget);
      expect(find.text('Headline 2'), findsOneWidget);
      expect(find.text('Headline 3'), findsOneWidget);
      expect(find.text('Headline 4'), findsOneWidget);

      // Verify Container wrapper for h2 (has bottom border decoration)
      final h2Container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Headline 2'),
          matching: find.byType(Container),
        ).first,
      );
      expect(h2Container.decoration, isA<BoxDecoration>());
    });

    testWidgets('Prose & Blockquote extensions (.p, .firstP, .blockQuote) render correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.shadcnLight(),
          home: Column(
            children: [
              const Text('First paragraph').firstP,
              const Text('Second paragraph').p,
              const Text('Contextual quote').blockQuote,
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('First paragraph'), findsOneWidget);
      expect(find.text('Second paragraph'), findsOneWidget);
      expect(find.text('Contextual quote'), findsOneWidget);

      // Verify Blockquote container wrapper with left border decoration
      final blockQuoteContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('Contextual quote'),
          matching: find.byType(Container),
        ).first,
      );
      expect(blockQuoteContainer.decoration, isA<BoxDecoration>());
      final boxDecoration = blockQuoteContainer.decoration as BoxDecoration;
      expect(boxDecoration.border, isNotNull);
    });

    testWidgets('List item extension (.li) builds bullet layout with depth tracking', (
      tester,
    ) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.shadcnLight(),
          home: Column(
            children: [
              const Text('Top level item').li,
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Top level item'), findsOneWidget);

      // .li wraps content in a Row with bullet and Expanded child
      expect(
        find.ancestor(
          of: find.text('Top level item'),
          matching: find.byType(shadcn.Row),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Inline code extension (.inlineCode) applies monospace styling and background', (
      tester,
    ) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.shadcnLight(),
          home: Column(
            children: [
              const Text('flutter pub add shadcn_flutter').inlineCode,
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('flutter pub add shadcn_flutter'), findsOneWidget);

      final codeContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('flutter pub add shadcn_flutter'),
          matching: find.byType(Container),
        ).first,
      );
      expect(codeContainer.decoration, isA<BoxDecoration>());
    });

    testWidgets('Muted & hierarchy text modifiers (.lead, .textLarge, .textSmall, .muted)', (
      tester,
    ) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.shadcnLight(),
          home: Column(
            children: [
              const Text('Intro lead').lead,
              const Text('Large label').textLarge,
              const Text('Small footnote').textSmall,
              const Text('Secondary info').muted,
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Intro lead'), findsOneWidget);
      expect(find.text('Large label'), findsOneWidget);
      expect(find.text('Small footnote'), findsOneWidget);
      expect(find.text('Secondary info'), findsOneWidget);
    });

    testWidgets('Font family & size utilities (.sans, .mono, .xSmall, .small, .base, .large, .xLarge)', (
      tester,
    ) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.shadcnLight(),
          home: Column(
            children: [
              const Text('Sans text').sans,
              const Text('SKU-100234').mono,
              const Text('Tiny').xSmall,
              const Text('Small').small,
              const Text('Base').base,
              const Text('Large').large,
              const Text('XLarge').xLarge,
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Sans text'), findsOneWidget);
      expect(find.text('SKU-100234'), findsOneWidget);
      expect(find.text('Tiny'), findsOneWidget);
      expect(find.text('Small'), findsOneWidget);
      expect(find.text('Base'), findsOneWidget);
      expect(find.text('Large'), findsOneWidget);
      expect(find.text('XLarge'), findsOneWidget);
    });

    testWidgets('Text alignment & layout modifiers (.singleLine, .ellipsis, .textStart, .textEnd)', (
      tester,
    ) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.shadcnLight(),
          home: Column(
            children: [
              const Text('Long single line text').singleLine,
              const Text('Overflowing text').ellipsis,
              const Text('Start text').textStart,
              const Text('End text').textEnd,
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Long single line text'), findsOneWidget);
      expect(find.text('Overflowing text'), findsOneWidget);
      expect(find.text('Start text'), findsOneWidget);
      expect(find.text('End text'), findsOneWidget);
    });

    testWidgets('Chaining extensions (.thenText, .thenInlineCode)', (
      tester,
    ) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.shadcnLight(),
          home: Column(
            children: [
              const Text('Hello ').thenText('World'),
              const Text('Run ').thenInlineCode('flutter analyze'),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('RTL & Arabic Localization rendering with typography extensions', (
      tester,
    ) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          theme: AppTheme.shadcnLight(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                const Text('نظام نكسا بيز للإدارة').h1,
                const Text('تفاصيل الحساب والتسوية').lead,
                const Text('رمز المنتج: SKU-8890').mono,
                const Text('ملاحظات المراجعة').blockQuote,
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('نظام نكسا بيز للإدارة'), findsOneWidget);
      expect(find.text('تفاصيل الحساب والتسوية'), findsOneWidget);
      expect(find.text('رمز المنتج: SKU-8890'), findsOneWidget);
      expect(find.text('ملاحظات المراجعة'), findsOneWidget);
    });
  });
}
