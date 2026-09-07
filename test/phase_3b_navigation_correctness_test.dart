import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/navigation/app_navigation_items.dart';
import 'package:stock_count/core/navigation/app_route_param_parser.dart';
import 'package:stock_count/modules/reports/shared/presentation/pages/reports_routes.dart';

void main() {
  group('NAV-003 — Reports Routing Namespace Consolidation', () {
    test('ReportsRoutes constants use canonical /reports/* namespace', () {
      expect(ReportsRoutes.root, equals('/reports'));
      expect(ReportsRoutes.salesPeriod, equals('/reports/sales-period'));
      expect(ReportsRoutes.accountStatement, equals('/reports/account-statement'));
      expect(
        ReportsRoutes.accountStatementTable,
        equals('/reports/account-statement/table'),
      );
      expect(ReportsRoutes.trialBalance, equals('/reports/trial-balance'));
      expect(ReportsRoutes.journalBook, equals('/reports/journal-book'));
      expect(ReportsRoutes.generalLedger, equals('/reports/general-ledger'));
      expect(ReportsRoutes.incomeStatement, equals('/reports/income-statement'));
      expect(ReportsRoutes.balanceSheet, equals('/reports/balance-sheet'));
      expect(ReportsRoutes.productStockMovement, equals('/reports/product-stock-movement'));
    });
  });

  group('NAV-013 — Safe Dynamic Path Parameter Parsing (AppRouteParamParser)', () {
    test('tryParseInt parses valid positive integer strings correctly', () {
      expect(AppRouteParamParser.tryParseInt('123'), equals(123));
      expect(AppRouteParamParser.tryParseInt('  456  '), equals(456));
      expect(AppRouteParamParser.tryParseInt('0'), isNull, reason: 'Zero is invalid');
      expect(AppRouteParamParser.tryParseInt('-789'), isNull, reason: 'Negative is invalid');
    });

    test('tryParseInt returns null on invalid or empty inputs without throwing', () {
      expect(AppRouteParamParser.tryParseInt(null), isNull);
      expect(AppRouteParamParser.tryParseInt(''), isNull);
      expect(AppRouteParamParser.tryParseInt('   '), isNull);
      expect(AppRouteParamParser.tryParseInt('abc'), isNull);
      expect(AppRouteParamParser.tryParseInt('12.34'), isNull);
      expect(AppRouteParamParser.tryParseInt('123a'), isNull);
    });

    test('tryParseString trims whitespace and filters empty values', () {
      expect(AppRouteParamParser.tryParseString('  hello  '), equals('hello'));
      expect(AppRouteParamParser.tryParseString('   '), isNull);
      expect(AppRouteParamParser.tryParseString(null), isNull);
    });

    test('tryParseDouble handles numeric doubles safely', () {
      expect(AppRouteParamParser.tryParseDouble('12.5'), equals(12.5));
      expect(AppRouteParamParser.tryParseDouble('invalid'), isNull);
      expect(AppRouteParamParser.tryParseDouble(null), isNull);
    });

    test('tryParseBool parses boolean indicators correctly', () {
      expect(AppRouteParamParser.tryParseBool('true'), isTrue);
      expect(AppRouteParamParser.tryParseBool('1'), isTrue);
      expect(AppRouteParamParser.tryParseBool('false'), isFalse);
      expect(AppRouteParamParser.tryParseBool('0'), isFalse);
      expect(AppRouteParamParser.tryParseBool('invalid'), isNull);
    });
  });

  group('NAV-016 — Sub-route Shell Tab Index Resolution', () {
    test('Root shell destinations resolve to correct branch indices', () {
      expect(selectedNavigationIndex('/dashboard'), equals(0));
      expect(selectedNavigationIndex('/services'), equals(1));
      expect(selectedNavigationIndex('/reports'), equals(2));
      expect(selectedNavigationIndex('/settings'), equals(3));
    });

    test('Core operational module sub-routes resolve to Services Tab (index 1)', () {
      expect(selectedNavigationIndex('/inventory/products'), equals(1));
      expect(selectedNavigationIndex('/sales/invoices/new'), equals(1));
      expect(selectedNavigationIndex('/customers/123/edit'), equals(1));
      expect(selectedNavigationIndex('/accounting/journals'), equals(1));
      expect(selectedNavigationIndex('/receipts-payments/receipts'), equals(1));
    });

    test('Report sub-routes and legacy paths resolve to Reports Tab (index 2)', () {
      expect(selectedNavigationIndex('/reports/trial-balance'), equals(2));
      expect(selectedNavigationIndex('/reports/income-statement'), equals(2));
      expect(selectedNavigationIndex('/module-reports/sales-period'), equals(2));
    });

    test('Administration sub-routes resolve to Settings Tab (index 3)', () {
      expect(selectedNavigationIndex('/administration'), equals(3));
      expect(selectedNavigationIndex('/administration/roles'), equals(3));
      expect(selectedNavigationIndex('/administration/roles/new'), equals(3));
      expect(selectedNavigationIndex('/administration/users'), equals(3));
    });
  });
}
