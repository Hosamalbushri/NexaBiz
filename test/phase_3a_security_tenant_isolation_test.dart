import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/app/exit/app_exit_scope.dart';
import 'package:stock_count/app/router/app_routes.dart';
import 'package:stock_count/core/modules/module_registry.dart';
import 'package:stock_count/core/tenancy/tenant_lifecycle.dart';
import 'package:stock_count/modules/administration/administration_module.dart';

void main() {
  late ModuleRegistry registry;

  setUp(() {
    ModuleRegistry.clearCatalog();
    AdministrationModule.register();
    registry = ModuleRegistry();
  });

  tearDown(() {
    ModuleRegistry.clearCatalog();
  });

  group('NAV-014 — Administration Route Permission Security Enforcement', () {
    test('Role list route requires roles.view or roles.manage', () {
      final perms = registry.requiredPermissionsForPath(
        AppRoutes.administrationRoles,
      );
      expect(perms, containsAll(['roles.view', 'roles.manage']));
    });

    test('Role creation route requires roles.create or roles.manage', () {
      final perms = registry.requiredPermissionsForPath(
        AppRoutes.administrationRolesCreate,
      );
      expect(perms, containsAll(['roles.create', 'roles.manage']));
      expect(perms, isNot(contains('roles.view')));
    });

    test('Role edit route requires roles.update or roles.manage', () {
      final perms = registry.requiredPermissionsForPath(
        '${AppRoutes.administrationRolesEdit}/role_123',
      );
      expect(perms, containsAll(['roles.update', 'roles.manage']));
      expect(perms, isNot(contains('roles.view')));
    });

    test('Path formatting variations do not bypass permission specificity', () {
      // Query parameters
      final withQueryParams = registry.requiredPermissionsForPath(
        '${AppRoutes.administrationRolesCreate}?source=modal',
      );
      expect(withQueryParams, containsAll(['roles.create', 'roles.manage']));

      // Trailing slash
      final withTrailingSlash = registry.requiredPermissionsForPath(
        '${AppRoutes.administrationRolesEdit}/123/',
      );
      expect(withTrailingSlash, containsAll(['roles.update', 'roles.manage']));
    });
  });

  group('NAV-008 — Module Reports Logical Parent Back Route', () {
    test('All /module-reports/* paths resolve to /reports as logical parent', () {
      expect(
        getLogicalParentRoute('/module-reports/trial-balance'),
        equals(AppRoutes.reports),
      );
      expect(
        getLogicalParentRoute('/module-reports/income-statement'),
        equals(AppRoutes.reports),
      );
      expect(
        getLogicalParentRoute('/module-reports/balance-sheet'),
        equals(AppRoutes.reports),
      );
      expect(
        getLogicalParentRoute('/module-reports/general-ledger'),
        equals(AppRoutes.reports),
      );
      expect(
        getLogicalParentRoute('/module-reports/account-statement'),
        equals(AppRoutes.reports),
      );
      expect(
        getLogicalParentRoute('/module-reports'),
        equals(AppRoutes.reports),
      );
    });
  });

  group('NAV-012 — Company Switch Tenant Isolation & History Reset', () {
    test('ShellHistoryNotifier.reset() clears visited history back to Dashboard', () {
      final container = ProviderContainer();
      final notifier = container.read(shellHistoryProvider.notifier);

      notifier.pushLocation(AppRoutes.services);
      notifier.pushLocation(AppRoutes.reports);
      expect(container.read(shellHistoryProvider).length, equals(3));

      notifier.reset();
      expect(container.read(shellHistoryProvider), equals([AppRoutes.dashboard]));
    });

    test('performTenantContextReset clears history stack and resets navigation', () {
      final container = ProviderContainer();
      final notifier = container.read(shellHistoryProvider.notifier);

      notifier.pushLocation(AppRoutes.settings);
      expect(container.read(shellHistoryProvider).length, equals(2));

      performTenantContextReset(container);
      expect(container.read(shellHistoryProvider), equals([AppRoutes.dashboard]));
    });
  });
}
