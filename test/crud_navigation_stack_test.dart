import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stock_count/modules/sales/shared/presentation/pages/sales_routes.dart';
import 'package:stock_count/modules/receipts_payments/shared/presentation/pages/receipts_payments_routes.dart';
import 'package:stock_count/modules/receipts_payments/transactions/domain/entities/transaction_type.dart';

void main() {
  group('NAV-02.4 CRUD Navigation Stack Semantics Tests', () {
    testWidgets('SalesRoutes.backToList pops when stack has history', (
      tester,
    ) async {
      late BuildContext outerContext;
      final router = GoRouter(
        initialLocation: '/sales/list',
        routes: [
          GoRoute(
            path: '/sales/list',
            builder: (context, state) {
              outerContext = context;
              return const Scaffold(body: Text('Sales List'));
            },
          ),
          GoRoute(
            path: '/sales/123',
            builder: (context, state) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () => SalesRoutes.backToList(context),
                  child: const Text('Back Button'),
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      expect(find.text('Sales List'), findsOneWidget);

      // Push details onto stack
      SalesRoutes.pushDetails(outerContext, 123);
      await tester.pumpAndSettle();
      expect(find.text('Back Button'), findsOneWidget);

      // Tap back button in details
      await tester.tap(find.text('Back Button'));
      await tester.pumpAndSettle();

      // Should return to Sales List (popped)
      expect(find.text('Sales List'), findsOneWidget);
    });

    testWidgets(
      'ReceiptsPaymentsRoutes.backToList pops when stack has history',
      (tester) async {
        late BuildContext outerContext;
        final router = GoRouter(
          initialLocation: '/receipts-payments/receipts/list',
          routes: [
            GoRoute(
              path: '/receipts-payments/receipts/list',
              builder: (context, state) {
                outerContext = context;
                return const Scaffold(body: Text('Receipts List'));
              },
            ),
            GoRoute(
              path: '/receipts-payments/456',
              builder: (context, state) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () => ReceiptsPaymentsRoutes.backToList(
                      context,
                      type: TransactionType.receipt,
                    ),
                    child: const Text('Back Button'),
                  ),
                );
              },
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        expect(find.text('Receipts List'), findsOneWidget);

        // Push details onto stack
        ReceiptsPaymentsRoutes.pushDetails(outerContext, 456);
        await tester.pumpAndSettle();
        expect(find.text('Back Button'), findsOneWidget);

        // Tap back button in details
        await tester.tap(find.text('Back Button'));
        await tester.pumpAndSettle();

        // Should return to Receipts List (popped)
        expect(find.text('Receipts List'), findsOneWidget);
      },
    );
  });
}
