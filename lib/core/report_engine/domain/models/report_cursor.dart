import 'package:flutter/foundation.dart';

/// Immutable cursor for deterministic keyset pagination.
/// Contains the primary sort key (e.g. date epoch ms) and unique tie-breaker (e.g. id).
@immutable
class ReportCursor {
  const ReportCursor({
    required this.primarySortValue,
    required this.uniqueId,
    this.secondarySortValue,
  });

  /// Primary sort value (e.g. DateTime in epoch ms or String code)
  final dynamic primarySortValue;

  /// Secondary sort value (e.g. sortOrder integer or string)
  final dynamic secondarySortValue;

  /// Unique primary key or UUID tie-breaker
  final String uniqueId;

  Map<String, dynamic> toJson() => {
        'primarySortValue': primarySortValue,
        'secondarySortValue': secondarySortValue,
        'uniqueId': uniqueId,
      };

  factory ReportCursor.fromJson(Map<String, dynamic> json) => ReportCursor(
        primarySortValue: json['primarySortValue'],
        secondarySortValue: json['secondarySortValue'],
        uniqueId: json['uniqueId'] as String,
      );
}
