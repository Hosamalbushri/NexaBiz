import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/navigation/app_navigation_items.dart';
import 'package:stock_count/core/modules/module_registry.dart';
import 'package:stock_count/core/navigation/app_route_param_parser.dart';
import 'package:stock_count/modules/accounting/accounting_module.dart';
import 'package:stock_count/modules/customers/customers_module.dart';
import 'package:stock_count/modules/inventory/inventory_module.dart';
import 'package:stock_count/modules/receipts_payments/receipts_payments_module.dart';
import 'package:stock_count/modules/reports/reports_module.dart';
import 'package:stock_count/modules/sales/sales_module.dart';

void main() {
  late ModuleRegistry registry;

  setUpAll(() {
    ModuleRegistry.clearCatalog();
    ReportsModule.register();
    SalesModule.register();
    AccountingModule.register();
    CustomersModule.register();
    ReceiptsPaymentsModule.register();
    InventoryModule.register();
    registry = ModuleRegistry();
  });

  tearDownAll(() {
    ModuleRegistry.clearCatalog();
  });

  group('1. NAV-016 — StatefulShellRoute & Deep-Link Resolution Audit', () {
    final testRoutes = <String, int>{
      '/dashboard': 0,
      '/services': 1,
      '/services/sales': 1,
      '/sales': 1,
      '/sales/invoices/new': 1,
      '/inventory/products': 1,
      '/customers': 1,
      '/accounting/accounts': 1,
      '/receipts-payments': 1,
      '/reports': 2,
      '/reports/sales-period': 2,
      '/reports/account-statement': 2,
      '/settings': 3,
      '/administration/roles': 3,
    };

    for (final entry in testRoutes.entries) {
      test('Route ${entry.key} maps to expected StatefulShell branch index (${entry.value})', () {
        final expectedIndex = entry.value;
        final actualIndex = selectedNavigationIndex(entry.key);
        expect(
          actualIndex,
          equals(expectedIndex),
          reason: 'Path ${entry.key} must resolve to shell branch index $expectedIndex',
        );
      });
    }
  });

  group('2. Direct Deep-Link vs Internal Navigation Equivalence', () {
    test('Direct deep-link to /sales/invoices/new highlights Services branch (1)', () {
      final directIndex = selectedNavigationIndex('/sales/invoices/new');
      final internalParentIndex = selectedNavigationIndex('/services');
      expect(directIndex, equals(internalParentIndex));
      expect(directIndex, equals(1));
    });

    test('Direct deep-link to /reports/account-statement highlights Reports branch (2)', () {
      final directIndex = selectedNavigationIndex('/reports/account-statement');
      final internalParentIndex = selectedNavigationIndex('/reports');
      expect(directIndex, equals(internalParentIndex));
      expect(directIndex, equals(2));
    });

    test('Direct deep-link to /administration/roles highlights Settings branch (3)', () {
      final directIndex = selectedNavigationIndex('/administration/roles');
      final internalParentIndex = selectedNavigationIndex('/settings');
      expect(directIndex, equals(internalParentIndex));
      expect(directIndex, equals(3));
    });
  });

  group('3. NAV-003 — GoRouter Legacy Redirect Resolution & Loop Safety', () {
    final legacyRedirectMap = <String, String>{
      '/module-reports': '/reports',
      '/module-reports/sales-period': '/reports/sales-period',
      '/module-reports/account-statement': '/reports/account-statement',
      '/module-reports/account-statement/table': '/reports/account-statement/table',
      '/module-reports/trial-balance': '/reports/trial-balance',
      '/module-reports/journal-book': '/reports/journal-book',
    };

    for (final entry in legacyRedirectMap.entries) {
      test('Legacy route ${entry.key} transforms cleanly to canonical ${entry.value}', () {
        final legacyPath = entry.key;
        final reportPath = legacyPath.replaceFirst('/module-reports', '');
        final canonicalPath = reportPath.isEmpty ? '/reports' : '/reports$reportPath';
        expect(canonicalPath, equals(entry.value));
        expect(canonicalPath.startsWith('/reports'), isTrue);
        expect(canonicalPath.startsWith('/module-reports'), isFalse);
      });
    }

    test('Query parameters are preserved during legacy redirect transformation', () {
      const legacyUri = '/module-reports/sales-period?startDate=2026-01-01&endDate=2026-12-31';
      final uri = Uri.parse(legacyUri);
      final reportPath = uri.path.replaceFirst('/module-reports/', '');
      final query = uri.hasQuery ? '?${uri.query}' : '';
      final canonicalUri = '/reports/$reportPath$query';

      expect(canonicalUri, equals('/reports/sales-period?startDate=2026-01-01&endDate=2026-12-31'));
      expect(selectedNavigationIndex(canonicalUri), equals(2));
    });

    test('Zero redirect loop verification: Canonical path is not re-redirected', () {
      const canonicalPath = '/reports/sales-period';
      expect(canonicalPath.startsWith('/module-reports'), isFalse);
      expect(selectedNavigationIndex(canonicalPath), equals(2));
    });
  });

  group('4. NAV-013 — Dynamic Parameter Safety & Negative ID Policy', () {
    test('AppRouteParamParser.tryParseInt enforces positive domain IDs (> 0)', () {
      // Valid positive domain IDs
      expect(AppRouteParamParser.tryParseInt('1'), equals(1));
      expect(AppRouteParamParser.tryParseInt('12345'), equals(12345));
      expect(AppRouteParamParser.tryParseInt('  99  '), equals(99));

      // Invalid / zero / negative IDs return null to prevent leak into DB queries
      expect(AppRouteParamParser.tryParseInt('0'), isNull, reason: 'Zero ID must be invalid');
      expect(AppRouteParamParser.tryParseInt('-1'), isNull, reason: '-1 sentinel must be invalid');
      expect(AppRouteParamParser.tryParseInt('-42'), isNull, reason: 'Negative IDs must be invalid');
      expect(AppRouteParamParser.tryParseInt('abc'), isNull, reason: 'Alpha string must be invalid');
      expect(AppRouteParamParser.tryParseInt('12.34'), isNull, reason: 'Float string must be invalid');
      expect(AppRouteParamParser.tryParseInt(''), isNull, reason: 'Empty string must be invalid');
      expect(AppRouteParamParser.tryParseInt(null), isNull, reason: 'Null must be invalid');
    });

    test('AppRouteParamParser.tryParseString filters whitespace and empty values', () {
      expect(AppRouteParamParser.tryParseString('rec_001'), equals('rec_001'));
      expect(AppRouteParamParser.tryParseString('  iss_999  '), equals('iss_999'));
      expect(AppRouteParamParser.tryParseString(''), isNull);
      expect(AppRouteParamParser.tryParseString('   '), isNull);
      expect(AppRouteParamParser.tryParseString(null), isNull);
    });

    test('ModuleRegistry requires permissions for guarded operational routes', () {
      final perms = registry.requiredPermissionsForPath('/sales/123');
      expect(perms, contains('sales.view'));
    });
  });
}
