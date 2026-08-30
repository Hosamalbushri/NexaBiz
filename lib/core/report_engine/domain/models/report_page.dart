import 'package:flutter/foundation.dart';
import 'report_cursor.dart';

/// Generic paged container holding a chunk of items and cursor metadata.
@immutable
class ReportPage<T> {
  const ReportPage({
    required this.items,
    this.nextCursor,
    required this.hasNextPage,
  });

  final List<T> items;
  final ReportCursor? nextCursor;
  final bool hasNextPage;

  static ReportPage<T> empty<T>() => ReportPage<T>(
        items: const [],
        nextCursor: null,
        hasNextPage: false,
      );
}
