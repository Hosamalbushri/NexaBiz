import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/widgets/app_load_more_footer.dart';

void main() {
  testWidgets('renders progress indicator centered', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppLoadMoreFooter(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Center), findsOneWidget);
  });
}
