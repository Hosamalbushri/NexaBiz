import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/import_engine/import_engine.dart';

void main() {
  group('Phase 04 — Universal Import Engine Schema & Header Detection Tests', () {
    test(
      '1. HeaderNormalizer tokenizes English and Arabic headers consistently',
      () {
        expect(
          HeaderNormalizer.normalize('Product Name'),
          equals('product_name'),
        );
        expect(
          HeaderNormalizer.normalize('PRODUCT_NAME'),
          equals('product_name'),
        );
        expect(HeaderNormalizer.normalize(r'Price ($)'), equals('price'));
        expect(
          HeaderNormalizer.normalize('   Unit-Price . '),
          equals('unit_price'),
        );

        // Arabic normalization (alef unification, diacritic removal, tatweel removal)
        expect(HeaderNormalizer.normalize('اسم المنتج'), equals('اسم_المنتج'));
        expect(HeaderNormalizer.normalize('أسم الإسرع'), equals('اسم_الاسرع'));
        expect(HeaderNormalizer.normalize('الـكـمـيـة'), equals('الكميه'));
      },
    );

    test(
      '2. TypeInferrer correctly detects integer, decimal, boolean, and date primitive types',
      () {
        // Integers
        final intResult = TypeInferrer.infer([10, 20, 30, '40']);
        expect(intResult.inferredType, equals(InferredPrimitiveType.integer));
        expect(intResult.confidence, equals(DetectionConfidence.high));

        // Decimals
        final decResult = TypeInferrer.infer([10.5, 20.0, '35.99']);
        expect(decResult.inferredType, equals(InferredPrimitiveType.decimal));
        expect(decResult.confidence, equals(DetectionConfidence.high));

        // Booleans (English & Arabic)
        final boolResult = TypeInferrer.infer(['نعم', 'لا', 'نعم']);
        expect(boolResult.inferredType, equals(InferredPrimitiveType.boolean));
        expect(boolResult.confidence, equals(DetectionConfidence.high));

        // Dates
        final dateResult = TypeInferrer.infer([
          '2026-09-01',
          '2026-09-02',
          '2026-09-03',
        ]);
        expect(dateResult.inferredType, equals(InferredPrimitiveType.date));
        expect(dateResult.confidence, equals(DetectionConfidence.high));
      },
    );

    test(
      '3. Conflicting / mixed column values infer nullOrMixed with LOW confidence',
      () {
        final mixedResult = TypeInferrer.infer([
          'Product A',
          4500,
          '2026-09-01',
          true,
        ]);
        expect(
          mixedResult.inferredType,
          equals(InferredPrimitiveType.nullOrMixed),
        );
        expect(mixedResult.confidence, equals(DetectionConfidence.low));
      },
    );

    test(
      '4. SchemaDetector flags duplicate and empty headers correctly',
      () async {
        const csvData = '''code,Name,Name,,price
P-101,Laptop,Notebook,,4500.00
P-102,Mouse,Pointer,,150.00''';

        final source = StringImportSource(
          sourceId: 'src_dup_headers',
          name: 'duplicate_headers.csv',
          content: csvData,
        );

        final parser = const CsvImportParser();
        final sheet = await parser.parseSheet(source);

        final detector = const SchemaDetector();
        final schema = detector.detectSheet(sheet);

        expect(schema.columnCount, equals(5));
        expect(schema.hasDuplicateHeaders, isTrue);
        expect(schema.hasEmptyHeaders, isTrue);

        final col1 = schema.getColumnByIndex(1)!; // First "Name"
        expect(col1.normalizedHeader, equals('name'));
        expect(col1.isDuplicate, isFalse);

        final col2 = schema.getColumnByIndex(2)!; // Second "Name"
        expect(col2.normalizedHeader, equals('name'));
        expect(col2.isDuplicate, isTrue);
        expect(col2.confidence, equals(DetectionConfidence.low));

        final col3 = schema.getColumnByIndex(3)!; // Empty header
        expect(col3.isEmptyHeader, isTrue);
        expect(col3.normalizedHeader, equals('column_4'));
        expect(col3.confidence, equals(DetectionConfidence.low));
      },
    );

    test('5. Complete Arabic & English dataset structure detection', () async {
      const arabicCsv =
          '''رمز_المنتج,اسم_المنتج,الكمية,سعر_الوحدة,تاريخ_الاستلام,مفعل
P-001,شاشة حاسوب,25,1200.50,2026-09-01,نعم
P-002,لوحة مفاتيح,100,150.00,2026-09-02,نعم''';

      final source = StringImportSource(
        sourceId: 'src_arabic_dataset',
        name: 'arabic_products.csv',
        content: arabicCsv,
      );

      final parser = const CsvImportParser();
      final sheet = await parser.parseSheet(source);

      final detector = const SchemaDetector();
      final schema = detector.detectSheet(sheet);

      expect(schema.columnCount, equals(6));
      expect(schema.hasDuplicateHeaders, isFalse);
      expect(schema.hasEmptyHeaders, isFalse);

      final codeCol = schema.getColumnByHeader('رمز_المنتج')!;
      expect(codeCol.inferredType, equals(InferredPrimitiveType.string));

      final qtyCol = schema.getColumnByHeader('الكمية')!;
      expect(qtyCol.inferredType, equals(InferredPrimitiveType.integer));

      final priceCol = schema.getColumnByHeader('سعر_الوحدة')!;
      expect(priceCol.inferredType, equals(InferredPrimitiveType.decimal));

      final dateCol = schema.getColumnByHeader('تاريخ_الاستلام')!;
      expect(dateCol.inferredType, equals(InferredPrimitiveType.date));

      final activeCol = schema.getColumnByHeader('مفعل')!;
      expect(activeCol.inferredType, equals(InferredPrimitiveType.boolean));
    });
  });
}
