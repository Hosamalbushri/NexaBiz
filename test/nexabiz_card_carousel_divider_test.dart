import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

void main() {
  Widget buildTestApp(Widget child) {
    return shadcn.ShadcnApp(
      theme: shadcn.ThemeData(
        colorScheme: shadcn.ColorSchemes.lightNeutral,
        radius: 0.5,
      ),
      home: shadcn.Scaffold(
        child: Center(child: child),
      ),
    );
  }

  group('NexaBiz Design System - Card, Carousel & Divider Tests', () {
    testWidgets('Direct shadcn.Card and SurfaceCard render children correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Column(
            children: [
              shadcn.Card(
                padding: EdgeInsets.all(16),
                child: Text('Card Content'),
              ),
              shadcn.SurfaceCard(
                surfaceBlur: 5,
                child: Text('Surface Card Content'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.text('Surface Card Content'), findsOneWidget);
      expect(find.byType(shadcn.Card), findsNWidgets(2));
    });

    testWidgets(
        'Direct shadcn.Divider and VerticalDivider render with child labels',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Column(
            children: [
              Text('Top Section'),
              shadcn.Divider(
                child: Text('OR'),
              ),
              Text('Bottom Section'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Top Section'), findsOneWidget);
      expect(find.text('OR'), findsOneWidget);
      expect(find.text('Bottom Section'), findsOneWidget);
      expect(find.byType(shadcn.Divider), findsOneWidget);
    });

    testWidgets('Direct shadcn.Carousel renders items correctly',
        (WidgetTester tester) async {
      final items = ['Slide 1', 'Slide 2', 'Slide 3'];

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 200,
            width: 300,
            child: shadcn.Carousel(
              itemCount: items.length,
              transition: const shadcn.CarouselTransition.sliding(gap: 16),
              itemBuilder: (context, index) {
                return Center(child: Text(items[index]));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Slide 1'), findsOneWidget);
      expect(find.byType(shadcn.Carousel), findsOneWidget);
    });

    testWidgets(
        'AppCarousel renders generic items and navigates with controls',
        (WidgetTester tester) async {
      final items = ['Item Alpha', 'Item Beta', 'Item Gamma'];
      int? changedIndex;

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 250,
            width: 400,
            child: AppCarousel<String>(
              items: items,
              showControls: true,
              showIndicators: true,
              onIndexChanged: (index) {
                changedIndex = index;
              },
              itemBuilder: (context, item, index) {
                return Center(child: Text(item));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Item Alpha'), findsOneWidget);

      // Find next navigation button and tap
      final nextButton = find.byIcon(shadcn.LucideIcons.chevronRight);
      expect(nextButton, findsOneWidget);

      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(changedIndex, equals(1));

      // Find previous navigation button and tap
      final prevButton = find.byIcon(shadcn.LucideIcons.chevronLeft);
      expect(prevButton, findsOneWidget);

      await tester.tap(prevButton);
      await tester.pumpAndSettle();

      expect(changedIndex, equals(0));
    });
  });
}
