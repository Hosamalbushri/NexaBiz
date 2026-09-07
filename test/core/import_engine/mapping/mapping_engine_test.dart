import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/import_engine/import_engine.dart';

void main() {
  group('Phase 05 — Universal Import Engine Mapping Engine Tests', () {
    const targetFields = [
      ImportField(
        key: 'product_code',
        label: 'Product Code',
        aliases: ['code', 'SKU', 'item code', 'رمز_المنتج', 'رمز الصنف'],
        dataType: ImportDataType.text,
        isRequired: true,
      ),
      ImportField(
        key: 'product_name',
        label: 'Product Name',
        aliases: [
          'name',
          'product name',
          'item name',
          'اسم_المنتج',
          'اسم الصنف',
        ],
        dataType: ImportDataType.text,
        isRequired: true,
      ),
      ImportField(
        key: 'unit_price',
        label: 'Unit Price',
        aliases: ['price', 'cost', 'سعر_الوحدة'],
        dataType: ImportDataType.number,
        isRequired: false,
      ),
      ImportField(
        key: 'stock_quantity',
        label: 'Stock Quantity',
        aliases: ['quantity', 'qty', 'الكمية'],
        dataType: ImportDataType.integer,
        isRequired: false,
      ),
    ];

    test(
      '1. 6-stage priority resolution matches exact canonical keys and exact aliases',
      () async {
        const csvData = '''product_code,product_name,unit_price
P-101,Laptop,4500.00''';

        final source = StringImportSource(
          sourceId: 'src_map_1',
          name: 'test.csv',
          content: csvData,
        );

        final parser = const CsvImportParser();
        final sheet = await parser.parseSheet(source);
        final schema = const SchemaDetector().detectSheet(sheet);

        final engine = const MappingEngine();
        final report = engine.mapSchema(
          schema: schema,
          targetFields: targetFields,
        );

        expect(report.isValid, isTrue);
        expect(report.mappedColumns.length, equals(3));
        expect(report.missingRequiredFields, isEmpty);

        final codeMap = report.mappings[0];
        expect(codeMap.targetField?.key, equals('product_code'));
        expect(codeMap.matchStrategy, equals(MappingMatchStrategy.exactKey));

        final nameMap = report.mappings[1];
        expect(nameMap.targetField?.key, equals('product_name'));
        expect(nameMap.matchStrategy, equals(MappingMatchStrategy.exactKey));
      },
    );

    test('2. Arabic and English alias mapping works seamlessly', () async {
      const csvData = '''SKU,اسم الصنف,سعر_الوحدة,الكمية
P-201,شاشة حاسوب,1200.00,15''';

      final source = StringImportSource(
        sourceId: 'src_map_arabic',
        name: 'arabic.csv',
        content: csvData,
      );

      final parser = const CsvImportParser();
      final sheet = await parser.parseSheet(source);
      final schema = const SchemaDetector().detectSheet(sheet);

      final engine = const MappingEngine();
      final report = engine.mapSchema(
        schema: schema,
        targetFields: targetFields,
      );

      expect(report.isValid, isTrue);
      expect(report.mappedColumns.length, equals(4));

      final skuMap = report.mappings[0];
      expect(skuMap.targetField?.key, equals('product_code'));

      final nameMap = report.mappings[1];
      expect(nameMap.targetField?.key, equals('product_name'));

      final priceMap = report.mappings[2];
      expect(priceMap.targetField?.key, equals('unit_price'));

      final qtyMap = report.mappings[3];
      expect(qtyMap.targetField?.key, equals('stock_quantity'));
    });

    test(
      '3. Low-confidence fuzzy matches are rejected and left unmapped',
      () async {
        const csvData = '''unknown_random_col_123,unit_price
val1,100''';

        final source = StringImportSource(
          sourceId: 'src_low_confidence',
          name: 'random.csv',
          content: csvData,
        );

        final parser = const CsvImportParser();
        final sheet = await parser.parseSheet(source);
        final schema = const SchemaDetector().detectSheet(sheet);

        final engine = const MappingEngine();
        final report = engine.mapSchema(
          schema: schema,
          targetFields: targetFields,
        );

        final col1Map = report.mappings[0];
        expect(col1Map.isUnmapped, isTrue);
        expect(col1Map.confidence, equals(MappingConfidence.none));
        expect(
          report.missingRequiredFields,
          contains(targetFields[0]),
        ); // product_code missing
        expect(report.isValid, isFalse);
      },
    );

    test('4. Manual override updates mapping report cleanly', () async {
      const csvData = '''custom_code_col,product_name
P-301,Keyboard''';

      final source = StringImportSource(
        sourceId: 'src_manual_override',
        name: 'custom.csv',
        content: csvData,
      );

      final parser = const CsvImportParser();
      final sheet = await parser.parseSheet(source);
      final schema = const SchemaDetector().detectSheet(sheet);

      final engine = const MappingEngine();
      var report = engine.mapSchema(schema: schema, targetFields: targetFields);

      expect(report.mappings[0].isUnmapped, isTrue);

      // Manually map column 0 to 'product_code'
      report = engine.updateMapping(
        currentReport: report,
        columnIndex: 0,
        newTargetField: targetFields[0],
      );

      expect(report.mappings[0].isMapped, isTrue);
      expect(report.mappings[0].targetField?.key, equals('product_code'));
      expect(
        report.mappings[0].matchStrategy,
        equals(MappingMatchStrategy.manual),
      );
      expect(report.isValid, isTrue);
    });

    test(
      '5. MappingProfile preset creation, JSON serialization, and re-application works',
      () async {
        const csvData = '''custom_sku_header,custom_name_header,unit_price
P-401,Mouse,150.00''';

        final source = StringImportSource(
          sourceId: 'src_profile_test',
          name: 'profile_test.csv',
          content: csvData,
        );

        final parser = const CsvImportParser();
        final sheet = await parser.parseSheet(source);
        final schema = const SchemaDetector().detectSheet(sheet);

        final engine = const MappingEngine();
        var report = engine.mapSchema(
          schema: schema,
          targetFields: targetFields,
        );

        // Manually assign custom headers
        report = engine.updateMapping(
          currentReport: report,
          columnIndex: 0,
          newTargetField: targetFields[0], // product_code
        );
        report = engine.updateMapping(
          currentReport: report,
          columnIndex: 1,
          newTargetField: targetFields[1], // product_name
        );

        // Create saved profile
        final profile = engine.createProfileFromReport(
          profileId: 'prof_prod_custom',
          profileName: 'Custom Product CSV Template',
          entityType: 'product',
          report: report,
        );

        // Test JSON round-trip
        final jsonMap = profile.toJson();
        final restoredProfile = MappingProfile.fromJson(jsonMap);

        expect(restoredProfile.id, equals('prof_prod_custom'));
        expect(
          restoredProfile.fieldMappings['custom_sku_header'],
          equals('product_code'),
        );
        expect(
          restoredProfile.fieldMappings['custom_name_header'],
          equals('product_name'),
        );

        // Re-apply restored preset to new import job with identical custom headers
        final newReport = engine.mapSchema(
          schema: schema,
          targetFields: targetFields,
          presetProfile: restoredProfile,
        );

        expect(newReport.isValid, isTrue);
        expect(newReport.mappings[0].targetField?.key, equals('product_code'));
        expect(newReport.mappings[1].targetField?.key, equals('product_name'));
      },
    );
  });
}
