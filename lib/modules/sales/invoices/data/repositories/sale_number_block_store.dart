import 'package:hive_flutter/hive_flutter.dart';

import 'package:stock_count/core/database/hive_boxes.dart';

/// One reserved offline number range for a voucher book on this device.
class SaleNumberBlock {
  const SaleNumberBlock({
    required this.bookId,
    required this.start,
    required this.end,
    required this.next,
  });

  final String bookId;
  final int start;
  final int end;

  /// Next sequence to hand out (inclusive). Exhausted when [next] > [end].
  final int next;

  bool get hasRemaining => next <= end;

  SaleNumberBlock copyWith({int? next}) {
    return SaleNumberBlock(
      bookId: bookId,
      start: start,
      end: end,
      next: next ?? this.next,
    );
  }

  Map<String, dynamic> toMap() => {
    'bookId': bookId,
    'start': start,
    'end': end,
    'next': next,
  };

  static SaleNumberBlock? fromMap(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(raw);
    final bookId = map['bookId']?.toString();
    final start = (map['start'] as num?)?.toInt();
    final end = (map['end'] as num?)?.toInt();
    final next = (map['next'] as num?)?.toInt();
    if (bookId == null ||
        bookId.isEmpty ||
        start == null ||
        end == null ||
        next == null) {
      return null;
    }
    return SaleNumberBlock(
      bookId: bookId,
      start: start,
      end: end,
      next: next,
    );
  }
}

/// Persists per-book number blocks so each device consumes exclusive ranges.
class SaleNumberBlockStore {
  SaleNumberBlockStore({this._box});

  Box<dynamic>? _box;

  static const _keyPrefix = 'sale_number_block_';

  /// Default how many numbers to claim from a voucher book at once.
  static const defaultBlockSize = 50;

  Future<Box<dynamic>> get _settingsBox async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    _box = await Hive.openBox<dynamic>(HiveBoxes.settings);
    return _box!;
  }

  String _key(String bookId) => '$_keyPrefix$bookId';

  Future<SaleNumberBlock?> load(String bookId) async {
    final box = await _settingsBox;
    return SaleNumberBlock.fromMap(box.get(_key(bookId)));
  }

  Future<void> save(SaleNumberBlock block) async {
    final box = await _settingsBox;
    await box.put(_key(block.bookId), block.toMap());
  }

  /// Returns the next sequence from an existing block, or null if exhausted/missing.
  Future<int?> takeNext(String bookId) async {
    final current = await load(bookId);
    if (current == null || !current.hasRemaining) {
      return null;
    }
    final allocated = current.next;
    await save(current.copyWith(next: allocated + 1));
    return allocated;
  }

  /// Stores a freshly reserved range and returns its first number.
  Future<int> installBlock({
    required String bookId,
    required int start,
    required int end,
  }) async {
    if (end < start) {
      throw ArgumentError('Invalid number block $start..$end');
    }
    final block = SaleNumberBlock(
      bookId: bookId,
      start: start,
      end: end,
      next: start + 1,
    );
    await save(block);
    return start;
  }

  /// Next number that will be shown in UI previews (does not consume).
  Future<int?> peekNext(String bookId) async {
    final current = await load(bookId);
    if (current == null || !current.hasRemaining) {
      return null;
    }
    return current.next;
  }
}
