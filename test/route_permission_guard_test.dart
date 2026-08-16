import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/modules/module_registry.dart';
import 'package:stock_count/core/modules/route_access_rule.dart';
import 'package:stock_count/modules/customers/customers_module.dart';
import 'package:stock_count/modules/sales/sales_module.dart';

void main() {
  group('RouteAccessRule', () {
    test('prefers exact create path over module prefix', () {
      final registry = ModuleRegistry([const SalesModule()]);
      expect(
        registry.requiredPermissionsForPath('/sales/create'),
        containsAll(['sales.documents.create', 'sales.create']),
      );
      expect(
        registry.requiredPermissionsForPath('/sales/list'),
        containsAll(['sales.documents.view', 'sales.view']),
      );
      expect(
        registry.requiredPermissionsForPath('/sales/42/edit'),
        containsAll(['sales.documents.update', 'sales.update']),
      );
    });

    test('gates customers import separately from view', () {
      final registry = ModuleRegistry([const CustomersModule()]);
      expect(
        registry.requiredPermissionsForPath('/customers/import'),
        equals(['customers.master.import']),
      );
      expect(
        registry.requiredPermissionsForPath('/customers/list'),
        containsAll(['customers.master.view', 'customers.view']),
      );
    });

    test('specificity prefers longer equals over prefix', () {
      final specific = RouteAccessRule(
        pathEquals: '/sales/create',
        anyOf: const ['sales.create'],
      );
      final prefix = RouteAccessRule(
        pathPrefix: '/sales',
        anyOf: const ['sales.view'],
      );
      expect(specific.specificity, greaterThan(prefix.specificity));
    });
  });
}
