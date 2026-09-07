import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/navigation/app_navigation_items.dart';
import 'package:stock_count/core/navigation/app_route_param_parser.dart';
import 'package:stock_count/modules/reports/shared/presentation/pages/reports_routes.dart';

void main() {
  group('NAV-003 — Reports Route Namespace Consolidation', () {
    test('All ReportsRoutes constants use canonical /reports/* namespace', () {
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

    test('Canonical path construction matches expected pattern without loops', () {
      const legacyPath = '/module-reports/sales-period';
      final cleanPath = legacyPath.replaceFirst('/module-reports', '/reports');
      expect(cleanPath, equals('/reports/sales-period'));
      expect(cleanPath.startsWith('/reports'), isTrue);
      expect(cleanPath.startsWith('/module-reports'), isFalse);
    });
  });

  group('NAV-013 — Route Parameter Handling & Parsing Safety', () {
    group('AppRouteParamParser.tryParseInt', () {
      test('Parses valid positive integers and rejects zero or negative IDs', () {
        expect(AppRouteParamParser.tryParseInt('1'), equals(1));
        expect(AppRouteParamParser.tryParseInt('999999'), equals(999999));
        expect(AppRouteParamParser.tryParseInt('0'), isNull, reason: 'Zero is invalid');
        expect(AppRouteParamParser.tryParseInt('-42'), isNull, reason: 'Negative is invalid');
      });

      test('Trims surrounding whitespace prior to parsing', () {
        expect(AppRouteParamParser.tryParseInt('  123  '), equals(123));
        expect(AppRouteParamParser.tryParseInt('\n456\t'), equals(456));
      });

      test('Returns null safely for invalid syntax without throwing FormatException', () {
        expect(AppRouteParamParser.tryParseInt('abc'), isNull);
        expect(AppRouteParamParser.tryParseInt('12.34'), isNull);
        expect(AppRouteParamParser.tryParseInt('12a'), isNull);
        expect(AppRouteParamParser.tryParseInt('undefined'), isNull);
        expect(AppRouteParamParser.tryParseInt('null'), isNull);
      });

      test('Returns null for empty or null inputs', () {
        expect(AppRouteParamParser.tryParseInt(null), isNull);
        expect(AppRouteParamParser.tryParseInt(''), isNull);
        expect(AppRouteParamParser.tryParseInt('   '), isNull);
      });
    });

    group('AppRouteParamParser.tryParseString', () {
      test('Trims whitespace and returns valid string', () {
        expect(AppRouteParamParser.tryParseString('  invoice_123  '), equals('invoice_123'));
      });

      test('Returns null for whitespace-only or null string', () {
        expect(AppRouteParamParser.tryParseString('   '), isNull);
        expect(AppRouteParamParser.tryParseString(null), isNull);
      });
    });

    group('AppRouteParamParser.tryParseDouble', () {
      test('Parses valid floating point numbers', () {
        expect(AppRouteParamParser.tryParseDouble('12.50'), equals(12.50));
        expect(AppRouteParamParser.tryParseDouble('-0.99'), equals(-0.99));
      });

      test('Returns null for malformed numbers', () {
        expect(AppRouteParamParser.tryParseDouble('abc'), isNull);
        expect(AppRouteParamParser.tryParseDouble(null), isNull);
      });
    });

    group('AppRouteParamParser.tryParseBool', () {
      test('Parses true/false indicators', () {
        expect(AppRouteParamParser.tryParseBool('true'), isTrue);
        expect(AppRouteParamParser.tryParseBool('1'), isTrue);
        expect(AppRouteParamParser.tryParseBool('false'), isFalse);
        expect(AppRouteParamParser.tryParseBool('0'), isFalse);
        expect(AppRouteParamParser.tryParseBool('invalid'), isNull);
      });
    });
  });

  group('NAV-016 — Deep-Link & Sub-route Shell Tab Index Mapping', () {
    test('Primary shell root destinations map to exact shell tab indices', () {
      expect(selectedNavigationIndex('/dashboard'), equals(0));
      expect(selectedNavigationIndex('/services'), equals(1));
      expect(selectedNavigationIndex('/reports'), equals(2));
      expect(selectedNavigationIndex('/settings'), equals(3));
    });

    test('Operational module sub-routes map consistently to Services Tab (index 1)', () {
      expect(selectedNavigationIndex('/services/sales'), equals(1));
      expect(selectedNavigationIndex('/inventory'), equals(1));
      expect(selectedNavigationIndex('/inventory/products'), equals(1));
      expect(selectedNavigationIndex('/inventory/products/123/edit'), equals(1));
      expect(selectedNavigationIndex('/sales'), equals(1));
      expect(selectedNavigationIndex('/sales/invoices/new'), equals(1));
      expect(selectedNavigationIndex('/sales/456'), equals(1));
      expect(selectedNavigationIndex('/customers'), equals(1));
      expect(selectedNavigationIndex('/customers/789/edit'), equals(1));
      expect(selectedNavigationIndex('/accounting'), equals(1));
      expect(selectedNavigationIndex('/accounting/accounts'), equals(1));
      expect(selectedNavigationIndex('/receipts-payments'), equals(1));
      expect(selectedNavigationIndex('/receipts-payments/receipts'), equals(1));
    });

    test('Reports sub-routes map consistently to Reports Tab (index 2)', () {
      expect(selectedNavigationIndex('/reports/sales-period'), equals(2));
      expect(selectedNavigationIndex('/reports/trial-balance'), equals(2));
      expect(selectedNavigationIndex('/reports/account-statement'), equals(2));
      expect(selectedNavigationIndex('/module-reports/general-ledger'), equals(2));
    });

    test('Administration sub-routes map consistently to Settings Tab (index 3)', () {
      expect(selectedNavigationIndex('/settings/profile'), equals(3));
      expect(selectedNavigationIndex('/administration'), equals(3));
      expect(selectedNavigationIndex('/administration/roles'), equals(3));
      expect(selectedNavigationIndex('/administration/roles/new'), equals(3));
      expect(selectedNavigationIndex('/administration/users'), equals(3));
    });

    test('Query parameters do not pollute tab index selection', () {
      expect(selectedNavigationIndex('/services?tab=all'), equals(1));
      expect(selectedNavigationIndex('/inventory/products?scan=1'), equals(1));
      expect(selectedNavigationIndex('/reports/trial-balance?startDate=2026-01-01'), equals(2));
      expect(selectedNavigationIndex('/administration/roles?page=2'), equals(3));
    });
  });
}
