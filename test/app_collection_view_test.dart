import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/widgets/app_collection_view.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  testWidgets('renders ListView in list mode', (tester) async {
    final items = List.generate(5, (i) => 'Item $i');

    await tester.pumpWidget(
      wrap(
        AppCollectionView<String>(
          items: items,
          viewMode: AppCollectionViewMode.list,
          itemBuilder: (context, item, index) => Text(item),
        ),
      ),
    );

    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 4'), findsOneWidget);
  });

  testWidgets('renders GridView in grid mode', (tester) async {
    final items = List.generate(6, (i) => 'GridItem $i');

    await tester.pumpWidget(
      wrap(
        AppCollectionView<String>(
          items: items,
          viewMode: AppCollectionViewMode.grid,
          itemBuilder: (context, item, index) => Text(item),
        ),
      ),
    );

    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    expect(find.text('GridItem 0'), findsOneWidget);
    expect(find.text('GridItem 5'), findsOneWidget);
  });

  testWidgets('renders footer when footerItemCount > 0', (tester) async {
    final items = ['Alpha', 'Beta'];

    await tester.pumpWidget(
      wrap(
        AppCollectionView<String>(
          items: items,
          viewMode: AppCollectionViewMode.list,
          footerItemCount: 1,
          footerBuilder: (context) => const Text('FooterWidget'),
          itemBuilder: (context, item, index) => Text(item),
        ),
      ),
    );

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('FooterWidget'), findsOneWidget);
  });
}
