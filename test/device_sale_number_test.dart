import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/sales/data/sale_number_block_store.dart';
import 'package:stock_count/modules/sales/domain/services/device_sale_number.dart';
import 'package:stock_count/modules/sales/domain/services/sale_number_allocator_port.dart';

void main() {
  test('device lanes differ without embedding a device label', () {
    final a = absoluteSaleNumber(
      deviceId: '00000000-0000-4000-8000-0000000000a1',
      sequence: 41,
    );
    final b = absoluteSaleNumber(
      deviceId: '00000000-0000-4000-8000-0000000000b2',
      sequence: 41,
    );
    expect(a, isNot(b));
    expect(formatSaleNumber(a), isNot(contains('-')));
    expect(formatSaleNumber(b), isNot(contains('-')));
    expect(formatSaleNumber(a), '161000041');
  });

  test('parseSaleNumberSequence supports plain and legacy formats', () {
    expect(parseSaleNumberSequence('42'), 42);
    expect(parseSaleNumberSequence('INV-7'), 7);
    expect(parseSaleNumberSequence('00A1-12'), 12);
  });

  test('LocalSaleNumberAllocator returns plain integers', () async {
    final allocator = LocalSaleNumberAllocator(
      nextSequence: () async => 5,
    );
    expect(await allocator.allocateNext(), '5');
  });

  group('SaleNumberBlockStore', () {
    late Box<dynamic> box;
    late SaleNumberBlockStore store;

    setUp(() async {
      Hive.init('test_sale_number_blocks');
      box = await Hive.openBox<dynamic>(
        '${HiveBoxes.settings}_${DateTime.now().microsecondsSinceEpoch}',
      );
      store = SaleNumberBlockStore(box: box);
    });

    tearDown(() async {
      await box.clear();
      await box.close();
    });

    test('installs block and consumes exclusive sequences', () async {
      final first = await store.installBlock(
        bookId: 'book-1',
        start: 100,
        end: 102,
      );
      expect(first, 100);
      expect(await store.takeNext('book-1'), 101);
      expect(await store.takeNext('book-1'), 102);
      expect(await store.takeNext('book-1'), isNull);
    });
  });
}
