import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/setup/setup.dart';

void main() {
  group('Phase 2 — CentralSetupRegistry Unit Tests', () {
    late CentralSetupRegistry registry;

    setUp(() {
      registry = CentralSetupRegistry();
    });

    test('1. Registration and retrieval by packageId works', () {
      const inventorySetup = PackageSetupDefinition(
        packageId: 'inventory',
        displayNameAr: 'إعدادات المخزون',
        displayNameEn: 'Inventory Setup',
        sortOrder: 20,
      );

      registry.register(inventorySetup);

      expect(registry.isRegistered('inventory'), isTrue);
      expect(registry.get('inventory'), equals(inventorySetup));
      expect(registry.findByPackageId('inventory'), equals(inventorySetup));
    });

    test('2. Enumeration getAll returns items deterministically sorted by sortOrder', () {
      const salesSetup = PackageSetupDefinition(
        packageId: 'sales',
        displayNameAr: 'المبيعات',
        displayNameEn: 'Sales',
        sortOrder: 30,
      );

      const accountingSetup = PackageSetupDefinition(
        packageId: 'accounting',
        displayNameAr: 'المحاسبة',
        displayNameEn: 'Accounting',
        sortOrder: 10,
      );

      const inventorySetup = PackageSetupDefinition(
        packageId: 'inventory',
        displayNameAr: 'المخزون',
        displayNameEn: 'Inventory',
        sortOrder: 20,
      );

      registry.register(salesSetup);
      registry.register(accountingSetup);
      registry.register(inventorySetup);

      final all = registry.getAll();
      expect(all.length, equals(3));
      expect(all[0].packageId, equals('accounting'));
      expect(all[1].packageId, equals('inventory'));
      expect(all[2].packageId, equals('sales'));
    });

    test('3. Rejects duplicate package ID registration', () {
      const setup1 = PackageSetupDefinition(
        packageId: 'accounting',
        displayNameAr: 'المحاسبة',
        displayNameEn: 'Accounting',
      );

      const setup2 = PackageSetupDefinition(
        packageId: 'accounting',
        displayNameAr: 'المحاسبة مكرر',
        displayNameEn: 'Accounting Duplicate',
      );

      registry.register(setup1);

      expect(
        () => registry.register(setup2),
        throwsA(isA<PackageSetupValidationException>().having(
          (e) => e.message,
          'message',
          contains('is already registered'),
        )),
      );
    });

    test('4. Rejects setup definitions containing duplicate section IDs', () {
      const section1 = SetupSection(
        id: 'tax_section',
        packageId: 'sales',
        titleAr: 'الضرائب',
        titleEn: 'Taxes',
        descriptionAr: 'وصف الضرائب',
        descriptionEn: 'Tax description',
      );

      const section2 = SetupSection(
        id: 'tax_section',
        packageId: 'sales',
        titleAr: 'الضرائب 2',
        titleEn: 'Taxes 2',
        descriptionAr: 'وصف الضرائب 2',
        descriptionEn: 'Tax description 2',
      );

      const invalidSalesSetup = PackageSetupDefinition(
        packageId: 'sales',
        displayNameAr: 'المبيعات',
        displayNameEn: 'Sales',
        sections: [section1, section2],
      );

      expect(
        () => registry.register(invalidSalesSetup),
        throwsA(isA<PackageSetupValidationException>().having(
          (e) => e.message,
          'message',
          contains('duplicate section ID "tax_section"'),
        )),
      );
    });

    test('5. Unknown package lookup safely returns null', () {
      expect(registry.get('unknown_package'), isNull);
      expect(registry.findByPackageId('non_existent'), isNull);
      expect(registry.isRegistered('unknown_package'), isFalse);
    });

    test('6. Dynamic unregistration and clear work correctly', () {
      const pkgA = PackageSetupDefinition(
        packageId: 'pkg_a',
        displayNameAr: 'حزمة أ',
        displayNameEn: 'Package A',
      );
      const pkgB = PackageSetupDefinition(
        packageId: 'pkg_b',
        displayNameAr: 'حزمة ب',
        displayNameEn: 'Package B',
      );

      registry.register(pkgA);
      registry.register(pkgB);
      expect(registry.getAll().length, equals(2));

      registry.unregister('pkg_a');
      expect(registry.isRegistered('pkg_a'), isFalse);
      expect(registry.getAll().length, equals(1));

      registry.clear();
      expect(registry.getAll(), isEmpty);
    });
  });
}
