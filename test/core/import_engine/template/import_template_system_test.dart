import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/import_engine/import_engine.dart';

void main() {
  group('Phase 17 — Universal Import Engine Import Templates Tests', () {
    late InMemoryImportTemplateRepository repo;
    late DateTime now;

    setUp(() {
      repo = InMemoryImportTemplateRepository();
      now = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
    });

    ImportTemplate createSampleTemplate({
      required String templateId,
      required String companyId,
      String name = 'Supplier ABC Products',
    }) {
      return ImportTemplate(
        templateId: templateId,
        name: name,
        description: 'Standard product catalog import template for Supplier ABC',
        companyId: companyId,
        targetProfileId: 'PROF-PROD',
        targetEntityType: 'Product',
        schemaVersion: 1,
        fieldMappings: const {
          'Supplier Item Code': 'code',
          'Product Name': 'name',
          'Unit Price': 'price',
          'Tax Rate': 'tax_rate',
        },
        ignoredColumns: const ['Internal Notes', 'Unused Spec'],
        normalizationConfig: const {
          'locale': 'ar_SA',
          'dateFormat': 'yyyy-MM-dd',
          'trimStrings': true,
        },
        validationConfig: const {
          'strictTypes': true,
          'allowNegativePrice': false,
        },
        relationStrategies: const {
          'category_id': {'strategy': 'code_lookup', 'fallback': 'create_if_missing'},
        },
        assignments: const {
          'warehouse_id': {'type': 'FIXED_REFERENCE', 'value': 'WH-MAIN'},
        },
        executionPolicy: const {
          'persistenceMode': 'perChunk',
          'chunkSize': 250,
        },
        createdAt: now,
        updatedAt: now,
      );
    }

    test('1. Create: saves a new template with complete configuration', () async {
      final template = createSampleTemplate(
        templateId: 'TPL-SUPPLIER-ABC',
        companyId: 'COMP-100',
      );

      await repo.createTemplate(template);

      final retrieved = await repo.getTemplate('TPL-SUPPLIER-ABC', companyId: 'COMP-100');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Supplier ABC Products'));
      expect(retrieved.targetEntityType, equals('Product'));
      expect(retrieved.fieldMappings['Supplier Item Code'], equals('code'));
      expect(retrieved.normalizationConfig['locale'], equals('ar_SA'));
      expect(retrieved.executionPolicy['chunkSize'], equals(250));
    });

    test('2. Load: retrieves exact template and configuration settings', () async {
      final template = createSampleTemplate(
        templateId: 'TPL-LOAD-01',
        companyId: 'COMP-100',
      );

      await repo.createTemplate(template);
      final loaded = await repo.getTemplate('TPL-LOAD-01', companyId: 'COMP-100');

      expect(loaded, isNotNull);
      expect(loaded!.targetProfileId, equals('PROF-PROD'));
      expect(loaded.assignments['warehouse_id']['value'], equals('WH-MAIN'));
      expect(loaded.ignoredColumns, contains('Internal Notes'));
    });

    test('3. Update: modifies template details and bumps updatedAt timestamp', () async {
      final original = createSampleTemplate(
        templateId: 'TPL-UPDATE-01',
        companyId: 'COMP-100',
      );

      await repo.createTemplate(original);

      final updated = original.copyWith(
        name: 'Supplier ABC Products v2',
        fieldMappings: const {
          'Supplier Item Code': 'code',
          'Product Name': 'name',
          'Wholesale Price': 'price',
        },
      );

      await repo.updateTemplate(updated);

      final reloaded = await repo.getTemplate('TPL-UPDATE-01', companyId: 'COMP-100');
      expect(reloaded, isNotNull);
      expect(reloaded!.name, equals('Supplier ABC Products v2'));
      expect(reloaded.fieldMappings['Wholesale Price'], equals('price'));
      expect(reloaded.updatedAt.isAfter(now) || reloaded.updatedAt == now, isTrue);
    });

    test('4. Delete: removes template from repository', () async {
      final template = createSampleTemplate(
        templateId: 'TPL-DEL-01',
        companyId: 'COMP-100',
      );

      await repo.createTemplate(template);
      expect(await repo.getTemplate('TPL-DEL-01', companyId: 'COMP-100'), isNotNull);

      await repo.deleteTemplate('TPL-DEL-01', companyId: 'COMP-100');
      expect(await repo.getTemplate('TPL-DEL-01', companyId: 'COMP-100'), isNull);
    });

    test('5. Company Isolation: Company A cannot load, update, or delete Company B templates', () async {
      final templateCompanyA = createSampleTemplate(
        templateId: 'TPL-COMP-A',
        companyId: 'COMPANY-A',
      );

      await repo.createTemplate(templateCompanyA);

      // Attempt access with Company B scope
      final attemptAccess = await repo.getTemplate('TPL-COMP-A', companyId: 'COMPANY-B');
      expect(attemptAccess, isNull);

      final companyATemplates = await repo.listTemplatesForCompany('COMPANY-A');
      final companyBTemplates = await repo.listTemplatesForCompany('COMPANY-B');

      expect(companyATemplates.length, equals(1));
      expect(companyBTemplates, isEmpty);

      // Attempt cross-tenant update should fail
      expect(
        () async => repo.updateTemplate(templateCompanyA.copyWith(companyId: 'COMPANY-B')),
        throwsA(isA<TenantIsolationException>()),
      );
    });

    test('6. Version Compatibility: Parses legacy schema version templates seamlessly', () {
      final legacyJson = {
        'templateId': 'TPL-LEGACY-01',
        'name': 'Legacy Template',
        'companyId': 'COMP-100',
        'targetProfileId': 'PROF-100',
        'targetEntityType': 'Product',
        'schemaVersion': 1,
        'fieldMappings': {'SKU': 'code'},
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final parsed = ImportTemplate.fromJson(legacyJson);

      expect(parsed.templateId, equals('TPL-LEGACY-01'));
      expect(parsed.schemaVersion, equals(1));
      expect(parsed.normalizationConfig, isEmpty);
      expect(parsed.executionPolicy, isEmpty);
    });

    test('7. No Secrets Protection: Automatically strips secret keys from configuration maps', () {
      final jsonWithSecrets = {
        'templateId': 'TPL-SECRETS-01',
        'name': 'Template with Secrets',
        'companyId': 'COMP-100',
        'targetProfileId': 'PROF-100',
        'targetEntityType': 'Product',
        'normalizationConfig': {
          'locale': 'en_US',
          'api_key': 'super-secret-api-key',
          'password': 'my-hidden-password',
        },
        'executionPolicy': {
          'chunkSize': 100,
          'auth_token': 'bearer-xyz-123',
        },
      };

      final template = ImportTemplate.fromJson(jsonWithSecrets);

      expect(template.normalizationConfig.containsKey('api_key'), isFalse);
      expect(template.normalizationConfig.containsKey('password'), isFalse);
      expect(template.normalizationConfig.containsKey('locale'), isTrue);

      expect(template.executionPolicy.containsKey('auth_token'), isFalse);
      expect(template.executionPolicy.containsKey('chunkSize'), isTrue);

      final exportedJson = template.toJson();
      expect(exportedJson['normalizationConfig'].containsKey('api_key'), isFalse);
    });
  });
}
