import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/utils/id_generator.dart';

void main() {
  group('UUID v7 Generator Tests', () {
    test('generateUuidV7 produces valid RFC 9562 version-7 UUID string', () {
      final uuid = generateUuidV7();
      final regex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(regex.hasMatch(uuid), isTrue, reason: 'UUID $uuid must match UUID v7 format');
    });

    test('generateUuidV7 incorporates version 7 and RFC 4122/9562 variant', () {
      final uuid = generateUuidV7();
      final parts = uuid.split('-');
      expect(parts[2].startsWith('7'), isTrue, reason: '3rd group must start with version 7');
      final variantChar = parts[3][0];
      expect(['8', '9', 'a', 'b'].contains(variantChar), isTrue, reason: '4th group must start with variant 8, 9, a, or b');
    });

    test('generateUuidV7 produces unique time-sortable IDs', () async {
      final ids = <String>[];
      for (var i = 0; i < 100; i++) {
        ids.add(generateUuidV7());
      }
      expect(ids.toSet().length, equals(100), reason: 'All 100 generated UUIDs must be unique');

      // Time-sortability test with increasing custom timestamps
      final t1 = DateTime(2026, 1, 1).millisecondsSinceEpoch;
      final t2 = DateTime(2026, 1, 2).millisecondsSinceEpoch;
      final id1 = generateUuidV7(t1);
      final id2 = generateUuidV7(t2);
      expect(id1.compareTo(id2), lessThan(0), reason: 'Earlier timestamp UUID must sort before later timestamp UUID');
    });

    test('generateUuidV5 system account namespace produces stable UUIDs', () {
      final id1 = systemAccountUuid('cash_box');
      final id2 = systemAccountUuid('cash_box');
      final id3 = systemAccountUuid('bank');

      expect(id1, equals(id2), reason: 'V5 deterministic UUIDs must match for identical keys');
      expect(id1, isNot(equals(id3)), reason: 'V5 deterministic UUIDs must differ for different keys');
      expect(id1.split('-')[2].startsWith('5'), isTrue, reason: 'V5 UUID must have version 5');
    });
  });
}
