import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_count/modules/inventory/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/data/datasources/product_excel_import_datasource.dart';
import 'package:stock_count/modules/inventory/data/repositories/product_repository_impl.dart';
import 'package:stock_count/modules/inventory/domain/entities/product.dart';
import 'package:stock_count/modules/inventory/domain/models/product_barcode_generator.dart';
import 'package:stock_count/modules/inventory/domain/models/product_exception.dart';
import 'package:stock_count/modules/inventory/domain/models/product_item_code_generator.dart';

Uint8List _encodeSheet(List<List<String>> rows) {
  final excel = Excel.createExcel();
  final sheet = excel['Sheet1'];
  for (final row in rows) {
    sheet.appendRow([for (final cell in row) TextCellValue(cell)]);
  }
  return Uint8List.fromList(excel.encode()!);
}

void _ensureSqlite() {
  if (!Platform.isLinux) {
    return;
  }
}

void main() {
  _ensureSqlite();

  group('ProductRepositoryImpl', () {
    late InventoryDatabase db;
    late ProductRepositoryImpl repository;

    setUp(() {
      db = InventoryDatabase.memory();
      repository = ProductRepositoryImpl(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('insert search update delete and uniqueness', () async {
      final created = await repository.insert(
        const ProductDraft(
          itemCode: 'P1',
          name: 'Milk',
          packSize: 12,
          price: 3.5,
          barcode: '111',
        ),
      );
      expect(created.id, greaterThan(0));

      final found = await repository.search('mil');
      expect(found, hasLength(1));
      expect(found.first.itemCode, 'P1');

      await expectLater(
        repository.insert(
          const ProductDraft(
            itemCode: 'P1',
            name: 'Other',
            packSize: 1,
            price: 1,
          ),
        ),
        throwsA(
          isA<ProductException>().having(
            (e) => e.code,
            'code',
            ProductException.duplicateItemCode,
          ),
        ),
      );

      final updated = await repository.update(
        created.id,
        const ProductDraft(
          itemCode: 'P1',
          name: 'Milk Lite',
          packSize: 24,
          price: 4.0,
          barcode: '111',
        ),
      );
      expect(updated.name, 'Milk Lite');
      expect(updated.packSize, 24);

      await repository.delete(created.id);
      expect(await repository.getById(created.id), isNull);
    });

    test('search limit and barcode exact rank first', () async {
      await repository.insert(
        const ProductDraft(
          itemCode: 'MILK-BOX',
          name: 'Other milk',
          packSize: 1,
          price: 1,
        ),
      );
      await repository.insert(
        const ProductDraft(
          itemCode: 'X1',
          name: 'Milk powder',
          packSize: 1,
          price: 2,
        ),
      );
      await repository.insert(
        const ProductDraft(
          itemCode: 'X2',
          name: 'Fresh milk',
          packSize: 1,
          price: 3,
          barcode: 'MILK',
        ),
      );

      final limited = await repository.search('milk', limit: 2);
      expect(limited, hasLength(2));
      expect(limited.first.barcode, 'MILK');

      final byUuid = await repository.getByUuid(limited.first.uuid);
      expect(byUuid?.itemCode, limited.first.itemCode);
    });

    test('upsertAll inserts then updates by item code', () async {
      final first = await repository.upsertAll([
        const ProductDraft(
          itemCode: 'A',
          name: 'Alpha',
          packSize: 6,
          price: 1.0,
        ),
      ]);
      expect(first.insertedCount, 1);
      expect(first.updatedCount, 0);

      final second = await repository.upsertAll([
        const ProductDraft(
          itemCode: 'A',
          name: 'Alpha 2',
          packSize: 8,
          price: 2.0,
        ),
        const ProductDraft(
          itemCode: 'B',
          name: 'Beta',
          packSize: 4,
          price: 5.0,
        ),
      ]);
      expect(second.insertedCount, 1);
      expect(second.updatedCount, 1);

      final all = await repository.getAll();
      expect(all, hasLength(2));
      expect(all.firstWhere((p) => p.itemCode == 'A').name, 'Alpha 2');
    });

    test('getPaged returns limit/offset pages and filters by query', () async {
      for (var i = 1; i <= 5; i++) {
        await repository.insert(
          ProductDraft(
            itemCode: 'C$i',
            name: 'Item $i',
            packSize: i,
            price: i.toDouble(),
          ),
        );
      }

      final page0 = await repository.getPaged(page: 0, pageSize: 2);
      expect(page0.totalCount, 5);
      expect(page0.items, hasLength(2));
      expect(page0.items.map((p) => p.itemCode), ['C1', 'C2']);
      expect(page0.totalPages, 3);

      final page1 = await repository.getPaged(page: 1, pageSize: 2);
      expect(page1.items.map((p) => p.itemCode), ['C3', 'C4']);

      final filtered = await repository.getPaged(
        page: 0,
        pageSize: 10,
        query: 'item 5',
      );
      expect(filtered.totalCount, 1);
      expect(filtered.items.single.itemCode, 'C5');
    });

    test('getByBarcode returns exact match after trim', () async {
      await repository.insert(
        const ProductDraft(
          itemCode: 'BC1',
          name: 'Barcoded',
          packSize: 1,
          price: 1,
          barcode: ' 998877 ',
        ),
      );

      final found = await repository.getByBarcode('998877');
      expect(found, isNotNull);
      expect(found!.itemCode, 'BC1');
      expect(await repository.getByBarcode(''), isNull);
      expect(await repository.getByBarcode('missing'), isNull);
    });
  });

  group('ProductBarcodeGenerator', () {
    late InventoryDatabase db;
    late ProductRepositoryImpl repository;
    late ProductBarcodeGenerator generator;

    setUp(() {
      db = InventoryDatabase.memory();
      repository = ProductRepositoryImpl(db);
      generator = ProductBarcodeGenerator(repository);
    });

    tearDown(() async {
      await db.close();
    });

    test('uses item code when free and suffixes on collision', () async {
      await repository.insert(
        const ProductDraft(
          itemCode: 'SKU1',
          name: 'Taken',
          packSize: 1,
          price: 1,
          barcode: 'SKU1',
        ),
      );

      final free = await generator.generate(itemCode: 'SKU2');
      expect(free, 'SKU2');

      final collided = await generator.generate(itemCode: 'SKU1');
      expect(collided, 'SKU1-2');
    });

    test('allows own barcode when excluding product id', () async {
      final created = await repository.insert(
        const ProductDraft(
          itemCode: 'OWN',
          name: 'Own',
          packSize: 1,
          price: 1,
          barcode: 'OWN',
        ),
      );

      final value = await generator.generate(
        itemCode: 'OWN',
        excludingProductId: created.id,
      );
      expect(value, 'OWN');
    });

    test('falls back to timestamp prefix when item code empty', () async {
      final value = await generator.generate(
        itemCode: '  ',
        now: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
      expect(value, 'P1700000000000');
    });
  });

  group('ProductItemCodeGenerator', () {
    late InventoryDatabase db;
    late ProductRepositoryImpl repository;
    late ProductItemCodeGenerator generator;

    setUp(() {
      db = InventoryDatabase.memory();
      repository = ProductRepositoryImpl(db);
      generator = ProductItemCodeGenerator(repository);
    });

    tearDown(() async {
      await db.close();
    });

    test('starts at P0001 and skips taken codes', () async {
      expect(await generator.generate(), 'P0001');

      await repository.insert(
        const ProductDraft(itemCode: 'P0001', name: 'A', packSize: 1, price: 1),
      );
      expect(await generator.generate(), 'P0002');
    });
  });

  group('ProductExcelImportDatasource', () {
    const datasource = ProductExcelImportDatasource();

    test('parses required catalog columns and ignores invalid rows', () {
      final bytes = _encodeSheet(const [
        ['Item Code', 'Item Name', 'Pack Size', 'Price'],
        ['1001', 'Milk', '12', '3.5'],
        ['', 'Bad', '12', '1'],
        ['1002', 'Bread', '0', '2'],
        ['1003', 'Juice', '6', '4.25'],
        ['1001', 'Milk Dup', '12', '3.9'],
      ]);

      final result = datasource.importBytes(bytes);
      expect(result.importedCount, 2);
      expect(result.ignoredCount, 2);
      expect(result.duplicateCount, 1);
      expect(
        result.drafts.map((d) => d.itemCode),
        containsAll(['1001', '1003']),
      );
      final milk = result.drafts.firstWhere((d) => d.itemCode == '1001');
      expect(milk.price, 3.9);
      expect(milk.packSize, 12);
    });

    test('falls back to positional columns when headers are unknown', () {
      final bytes = _encodeSheet(const [
        ['col_a', 'col_b', 'col_c', 'col_d'],
        ['2001', 'Tea', '24', '1.5'],
      ]);

      final result = datasource.importBytes(bytes);
      expect(result.importedCount, 1);
      expect(result.drafts.single.itemCode, '2001');
      expect(result.drafts.single.name, 'Tea');
      expect(result.drafts.single.packSize, 24);
      expect(result.drafts.single.price, 1.5);
      expect(result.warnings, contains('headers_fallback'));
    });
  });
}
