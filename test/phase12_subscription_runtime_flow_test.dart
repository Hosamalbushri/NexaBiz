import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/core/entitlements/domain/capability_registry.dart';
import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/core/entitlements/domain/package_registry.dart';

void main() {
  group('Phase 12 — Subscription Runtime Flow Tests', () {
    test('PackageRegistry contains valid commercial package definitions', () {
      final packages = PackageRegistry.allPackages;
      expect(packages.length, equals(3));

      final syncPkg = PackageRegistry.findByCode('cloud_sync');
      expect(syncPkg, isNotNull);
      expect(syncPkg!.name, equals('Cloud Data Synchronization'));
      expect(syncPkg.price, equals(29.0));
      expect(syncPkg.capabilities, contains(EntitlementCapability.sync));
    });

    test('CapabilityRegistry maps capabilities to required package metadata', () {
      final syncMeta = CapabilityRegistry.getMetadata(EntitlementCapability.sync);
      expect(syncMeta, isNotNull);
      expect(syncMeta!.displayName, equals('Cloud Data Synchronization'));
      expect(syncMeta.requiredPackageCode, equals('cloud_sync'));

      final branchMeta = CapabilityRegistry.getMetadata(EntitlementCapability.multiBranch);
      expect(branchMeta, isNotNull);
      expect(branchMeta!.requiredPackageCode, equals('multi_branch'));
    });
  });
}
