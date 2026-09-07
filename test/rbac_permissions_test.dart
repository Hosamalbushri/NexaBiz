import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/permissions/permission_guard.dart';

void main() {
  group('RBAC & Permissions Integration (AU-07)', () {
    test(
      'CallbackPermissionGuard throws PermissionDeniedException when permission missing',
      () {
        final userPermissions = {'sales.view', 'customers.view'};

        final guard = CallbackPermissionGuard((codes) {
          return codes.any((code) => userPermissions.contains(code));
        });

        // User with sales.view can view sales
        expect(() => guard.requireAny(['sales.view']), returnsNormally);

        // User without sales.create cannot create sales
        expect(
          () => guard.requireAny(['sales.create']),
          throwsA(isA<PermissionDeniedException>()),
        );

        // User without accounting permissions cannot access accounting
        expect(
          () => guard.requireAny(['accounting.entries.create']),
          throwsA(isA<PermissionDeniedException>()),
        );
      },
    );

    test(
      'AllowAllPermissionGuard allows all operations for test/system jobs',
      () {
        const guard = AllowAllPermissionGuard();

        expect(
          () => guard.requireAny(['accounting.entries.create']),
          returnsNormally,
        );
        expect(() => guard.requireAny(['sales.create']), returnsNormally);
      },
    );
  });
}
