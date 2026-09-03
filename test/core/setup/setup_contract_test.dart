import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/setup/setup.dart';

void main() {
  group('Phase 1 — Core Setup Contracts & Validator Unit Tests', () {
    const validator = PackageSetupDefinitionValidator();

    test('1. Valid setup definition passes validation and localized accessors work', () {
      const field = SetupField(
        id: 'costing_method_field',
        sectionId: 'costing_section',
        key: 'costing_method',
        labelAr: 'طريقة التكلفة',
        labelEn: 'Costing Method',
        fieldType: SetupFieldType.select,
        isRequired: true,
        defaultValue: 'FIFO',
        allowedValues: ['FIFO', 'WAVG'],
      );

      const section = SetupSection(
        id: 'costing_section',
        packageId: 'inventory',
        titleAr: 'سياسة التكلفة',
        titleEn: 'Costing Policy',
        descriptionAr: 'إعدادات طريقة حساب التكلفة للمخزون',
        descriptionEn: 'Inventory cost valuation configuration',
        fields: [field],
      );

      const dependency = SetupDependency(
        targetPackageId: 'accounting',
        dependencyType: SetupDependencyType.required,
        reasonAr: 'يتطلب إعداد المحاسبة أولاً',
        reasonEn: 'Requires accounting setup first',
      );

      const inventorySetup = PackageSetupDefinition(
        packageId: 'inventory',
        displayNameAr: 'إعدادات المخزون',
        displayNameEn: 'Inventory Setup',
        sections: [section],
        dependencies: [dependency],
      );

      expect(() => validator.validateDefinition(inventorySetup), returnsNormally);
      expect(inventorySetup.displayName('ar'), equals('إعدادات المخزون'));
      expect(inventorySetup.displayName('en'), equals('Inventory Setup'));
      expect(section.title('ar'), equals('سياسة التكلفة'));
      expect(section.description('en'), equals('Inventory cost valuation configuration'));
      expect(field.label('ar'), equals('طريقة التكلفة'));
      expect(field.isValidValue('FIFO'), isTrue);
      expect(field.isValidValue('INVALID_VALUE'), isFalse);
    });

    test('2. Duplicate package ID in registry is rejected', () {
      const pkg1 = PackageSetupDefinition(
        packageId: 'sales',
        displayNameAr: 'إعدادات المبيعات',
        displayNameEn: 'Sales Setup',
      );

      const pkg2 = PackageSetupDefinition(
        packageId: 'sales',
        displayNameAr: 'إعدادات المبيعات 2',
        displayNameEn: 'Sales Setup 2',
      );

      expect(
        () => validator.validateRegistry([pkg1, pkg2]),
        throwsA(isA<PackageSetupValidationException>().having(
          (e) => e.message,
          'message',
          contains('Duplicate package setup registration'),
        )),
      );
    });

    test('3. Duplicate section ID within a package setup is rejected', () {
      const section1 = SetupSection(
        id: 'general',
        packageId: 'accounting',
        titleAr: 'عام',
        titleEn: 'General',
        descriptionAr: 'وصف',
        descriptionEn: 'Description',
      );

      const section2 = SetupSection(
        id: 'general',
        packageId: 'accounting',
        titleAr: 'عام 2',
        titleEn: 'General 2',
        descriptionAr: 'وصف 2',
        descriptionEn: 'Description 2',
      );

      const accountingSetup = PackageSetupDefinition(
        packageId: 'accounting',
        displayNameAr: 'المحاسبة',
        displayNameEn: 'Accounting',
        sections: [section1, section2],
      );

      expect(
        () => validator.validateDefinition(accountingSetup),
        throwsA(isA<PackageSetupValidationException>().having(
          (e) => e.message,
          'message',
          contains('duplicate section ID "general"'),
        )),
      );
    });

    test('4. Empty packageId or blank field key is rejected', () {
      const emptyPackageSetup = PackageSetupDefinition(
        packageId: '   ',
        displayNameAr: 'اختبار',
        displayNameEn: 'Test',
      );

      expect(
        () => validator.validateDefinition(emptyPackageSetup),
        throwsA(isA<PackageSetupValidationException>().having(
          (e) => e.message,
          'message',
          contains('packageId cannot be empty'),
        )),
      );

      const invalidFieldSection = SetupSection(
        id: 'sec1',
        packageId: 'sales',
        titleAr: 'عنوان',
        titleEn: 'Title',
        descriptionAr: 'وصف',
        descriptionEn: 'Description',
        fields: [
          SetupField(
            id: 'f1',
            sectionId: 'sec1',
            key: '',
            labelAr: 'عنصر',
            labelEn: 'Item',
            fieldType: SetupFieldType.text,
          ),
        ],
      );

      const salesSetup = PackageSetupDefinition(
        packageId: 'sales',
        displayNameAr: 'المبيعات',
        displayNameEn: 'Sales',
        sections: [invalidFieldSection],
      );

      expect(
        () => validator.validateDefinition(salesSetup),
        throwsA(isA<PackageSetupValidationException>().having(
          (e) => e.message,
          'message',
          contains('contains a field with an empty key'),
        )),
      );
    });

    test('5. Self-referential dependency is rejected', () {
      const selfDep = SetupDependency(
        targetPackageId: 'inventory',
        dependencyType: SetupDependencyType.required,
      );

      const invalidInventorySetup = PackageSetupDefinition(
        packageId: 'inventory',
        displayNameAr: 'المخزون',
        displayNameEn: 'Inventory',
        dependencies: [selfDep],
      );

      expect(
        () => validator.validateDefinition(invalidInventorySetup),
        throwsA(isA<PackageSetupValidationException>().having(
          (e) => e.message,
          'message',
          contains('cannot declare a setup dependency on itself'),
        )),
      );
    });

    test('6. SetupStatus correctly evaluates operational and attention states', () {
      expect(SetupStatus.configured.isOperational, isTrue);
      expect(SetupStatus.configured.requiresAttention, isFalse);

      expect(SetupStatus.notConfigured.isOperational, isFalse);
      expect(SetupStatus.notConfigured.requiresAttention, isTrue);

      expect(SetupStatus.partiallyConfigured.isOperational, isFalse);
      expect(SetupStatus.partiallyConfigured.requiresAttention, isTrue);

      expect(SetupStatus.invalid.isOperational, isFalse);
      expect(SetupStatus.invalid.requiresAttention, isTrue);
    });
  });
}
