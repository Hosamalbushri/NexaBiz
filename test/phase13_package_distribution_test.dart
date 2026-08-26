import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/core/entitlements/domain/entities/entitlement.dart';
import 'package:stock_count/core/entitlements/domain/package_contract.dart';
import 'package:stock_count/core/entitlements/domain/package_registry.dart';

void main() {
  group('Phase 13 — Package Distribution & Contract Tests', () {
    test('StandardPackageContract evaluates build target inclusion accurately', () {
      const addonContract = StandardPackageContract(
        code: 'cloud_sync',
        name: 'Cloud Data Synchronization',
        category: 'core',
        description: 'Sync data across devices',
        price: 29.0,
        currency: 'USD',
        capabilities: [EntitlementCapability.sync],
        isAddonBuildOnly: true,
      );

      expect(addonContract.isIncludedInBuildTarget(BuildFlavor.free), isFalse);
      expect(addonContract.isIncludedInBuildTarget(BuildFlavor.premium), isTrue);
    });

    test('PackageRegistry lists commercial add-on packages correctly', () {
      final packages = PackageRegistry.allPackages;
      expect(packages.isNotEmpty, isTrue);
      expect(packages.any((p) => p.code == 'cloud_sync'), isTrue);
    });
  });
}
