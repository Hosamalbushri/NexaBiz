import 'package:flutter/foundation.dart';

/// Cursor token representing deterministic position in keyset-ordered sales queries (`saleDate DESC, id DESC`).
@immutable
class SaleCursor {
  const SaleCursor({
    required this.saleDateMs,
    required this.id,
  });

  final int saleDateMs;
  final int id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleCursor &&
          runtimeType == other.runtimeType &&
          saleDateMs == other.saleDateMs &&
          id == other.id;

  @override
  int get hashCode => saleDateMs.hashCode ^ id.hashCode;

  @override
  String toString() => 'SaleCursor(saleDateMs: $saleDateMs, id: $id)';
}

/// Generic container for keyset-paged query results.
@immutable
class SaleKeysetPagedResult<T> {
  const SaleKeysetPagedResult({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });

  final List<T> items;
  final SaleCursor? nextCursor;
  final bool hasMore;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleKeysetPagedResult<T> &&
          runtimeType == other.runtimeType &&
          listEquals(items, other.items) &&
          nextCursor == other.nextCursor &&
          hasMore == other.hasMore;

  @override
  int get hashCode => items.hashCode ^ nextCursor.hashCode ^ hasMore.hashCode;
}
