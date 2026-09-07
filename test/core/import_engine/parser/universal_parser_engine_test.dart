import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/import_engine/import_engine.dart';

void main() {
  group('Phase 03 — Universal Import Engine Source & Parser Engine Tests', () {
    test(
      '1. Normal CSV parsing with headers and auto-delimiter detection works',
      () async {
        const csvData = '''code,name,price,quantity
P-001,Laptop,4500.00,10
P-002,Mouse,150.50,50
P-003,Keyboard,299.99,25''';

        final source = StringImportSource(
          sourceId: 'src_csv_1',
          name: 'products.csv',
          content: csvData,
        );

        final parser = const CsvImportParser();
        final doc = await parser.parseDocument(source);

        expect(doc.format, equals(ImportFileFormat.csv));
        expect(doc.sheets.length, equals(1));

        final sheet = doc.activeSheet!;
        expect(sheet.headers, equals(['code', 'name', 'price', 'quantity']));
        expect(sheet.totalRows, equals(3));

        expect(
          sheet.rows[0].toMap(),
          equals({
            'code': 'P-001',
            'name': 'Laptop',
            'price': '4500.00',
            'quantity': '10',
          }),
        );
        expect(sheet.rows[2].cells[1].textValue, equals('Keyboard'));
      },
    );

    test('2. Arabic CSV text with UTF-8 BOM is parsed correctly', () async {
      const arabicCsvWithBom =
          '\uFEFFرمز_العميل;اسم_العميل;رقم_الهاتف;المدينة\n'
          'C-101;شركة الأمل التجارية;0501234567;الرياض\n'
          'C-102;مؤسسة النور;0559876543;جدة';

      final source = StringImportSource(
        sourceId: 'src_arabic_csv',
        name: 'customers_arabic.csv',
        content: arabicCsvWithBom,
      );

      final parser = const CsvImportParser();
      final sheet = await parser.parseSheet(source);

      expect(
        sheet.headers,
        equals(['رمز_العميل', 'اسم_العميل', 'رقم_الهاتف', 'المدينة']),
      );
      expect(sheet.totalRows, equals(2));

      final row1Map = sheet.rows[0].toMap();
      expect(row1Map['رمز_العميل'], equals('C-101'));
      expect(row1Map['اسم_العميل'], equals('شركة الأمل التجارية'));
      expect(row1Map['المدينة'], equals('الرياض'));
    });

    test(
      '3. CSV with escaped quotes, semicolons, and newlines inside quotes',
      () async {
        const complexCsv =
            'id,"description","notes"\n'
            '101,"Heavy Duty ""Pro"" Scanner","Line 1;\nLine 2"\n'
            '102,"Standard Printer","No notes"';

        final source = StringImportSource(
          sourceId: 'src_complex_csv',
          name: 'complex.csv',
          content: complexCsv,
        );

        final parser = const CsvImportParser();
        final sheet = await parser.parseSheet(source);

        expect(sheet.headers, equals(['id', 'description', 'notes']));
        expect(sheet.totalRows, equals(2));
        expect(
          sheet.rows[0].toMap()['description'],
          equals('Heavy Duty "Pro" Scanner'),
        );
        expect(sheet.rows[0].toMap()['notes'], equals('Line 1;\nLine 2'));
      },
    );

    test('4. XLSX multi-sheet workbook parsing', () async {
      final excel = Excel.createExcel();

      // Sheet 1: Products
      final Sheet sheet1 = excel['Products'];
      sheet1.appendRow([
        TextCellValue('code'),
        TextCellValue('name'),
        IntCellValue(100),
      ]);
      sheet1.appendRow([
        TextCellValue('PROD-1'),
        TextCellValue('Product One'),
        IntCellValue(50),
      ]);

      // Sheet 2: Categories
      final Sheet sheet2 = excel['Categories'];
      sheet2.appendRow([TextCellValue('cat_id'), TextCellValue('cat_name')]);
      sheet2.appendRow([TextCellValue('CAT-A'), TextCellValue('Electronics')]);

      final bytes = Uint8List.fromList(excel.encode()!);
      final source = BytesImportSource(
        sourceId: 'src_xlsx_multisheet',
        name: 'catalog.xlsx',
        bytes: bytes,
      );

      final parser = const XlsxImportParser();
      final doc = await parser.parseDocument(source);

      expect(doc.format, equals(ImportFileFormat.xlsx));
      expect(doc.sheets.length, greaterThanOrEqualTo(2));

      final prodSheet = doc.getSheetByName('Products');
      expect(prodSheet, isNotNull);
      expect(prodSheet!.headers.sublist(0, 2), equals(['code', 'name']));
      expect(prodSheet.rows.first.cells[0].textValue, equals('PROD-1'));

      final catSheet = doc.getSheetByName('Categories');
      expect(catSheet, isNotNull);
      expect(catSheet!.headers, equals(['cat_id', 'cat_name']));
      expect(catSheet.rows.first.cells[1].textValue, equals('Electronics'));
    });

    test('5. JSON array and nested object flattening strategy', () async {
      const jsonText = '''[
        {
          "account_code": "110101",
          "account_name": "Main Cash Vault",
          "details": {
            "currency": "SAR",
            "is_active": true
          }
        },
        {
          "account_code": "110102",
          "account_name": "Petty Cash",
          "details": {
            "currency": "USD",
            "is_active": false
          }
        }
      ]''';

      final source = StringImportSource(
        sourceId: 'src_json_array',
        name: 'accounts.json',
        content: jsonText,
      );

      final parser = const JsonImportParser(
        flatteningStrategy: JsonFlatteningStrategy.dotNotation,
      );
      final sheet = await parser.parseSheet(source);

      expect(
        sheet.headers,
        containsAll([
          'account_code',
          'account_name',
          'details.currency',
          'details.is_active',
        ]),
      );
      expect(sheet.totalRows, equals(2));

      final row1 = sheet.rows[0].toMap();
      expect(row1['account_code'], equals('110101'));
      expect(row1['details.currency'], equals('SAR'));
      expect(row1['details.is_active'], isTrue);
    });

    test('6. Wrapped JSON object structure detection', () async {
      const jsonWrapped = '''{
        "status": "success",
        "items": [
          {"id": 1, "sku": "SKU-A"},
          {"id": 2, "sku": "SKU-B"}
        ]
      }''';

      final source = StringImportSource(
        sourceId: 'src_json_wrapped',
        name: 'payload.json',
        content: jsonWrapped,
      );

      final parser = const JsonImportParser(rootArrayKey: 'items');
      final sheet = await parser.parseSheet(source);

      expect(sheet.headers, equals(['id', 'sku']));
      expect(sheet.totalRows, equals(2));
      expect(sheet.rows[1].toMap()['sku'], equals('SKU-B'));
    });

    test(
      '7. Empty and malformed inputs produce clean error handling',
      () async {
        final emptySource = StringImportSource(
          sourceId: 'src_empty',
          name: 'empty.csv',
          content: '',
        );

        final csvParser = const CsvImportParser();
        final emptyDoc = await csvParser.parseDocument(emptySource);
        expect(emptyDoc.isEmpty, isTrue);

        final malformedJsonSource = StringImportSource(
          sourceId: 'src_bad_json',
          name: 'bad.json',
          content: '{ invalid json structure ...',
        );

        final jsonParser = const JsonImportParser();
        final badJsonSheet = await jsonParser.parseSheet(malformedJsonSource);
        expect(badJsonSheet.isEmpty, isTrue);
      },
    );

    test('8. UniversalParserFactory resolves correct parser per extension', () {
      expect(
        UniversalParserFactory.forFileName('test.csv'),
        isA<CsvImportParser>(),
      );
      expect(
        UniversalParserFactory.forFileName('test.xlsx'),
        isA<XlsxImportParser>(),
      );
      expect(
        UniversalParserFactory.forFileName('test.json'),
        isA<JsonImportParser>(),
      );
      expect(
        () => UniversalParserFactory.forFileName('test.pdf'),
        throwsA(isA<ImportEngineException>()),
      );
    });

    test(
      '9. Large dataset simulation parses cleanly without memory explosion',
      () async {
        final buffer = StringBuffer('id,code,name,val\n');
        for (var i = 1; i <= 1000; i++) {
          buffer.writeln('$i,CODE-$i,Product Item $i,${i * 10.5}');
        }

        final source = StringImportSource(
          sourceId: 'src_large_sim',
          name: 'large.csv',
          content: buffer.toString(),
        );

        final parser = const CsvImportParser();
        final sheet = await parser.parseSheet(source);

        expect(sheet.totalRows, equals(1000));
        expect(sheet.rows.last.toMap()['code'], equals('CODE-1000'));
      },
    );
  });
}
