import 'package:hive_flutter/hive_flutter.dart';

import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_overview.dart';
import 'package:stock_count/modules/sync/engine/domain/services/sync_request_context.dart';

/// One recorded sync pass for observability (Phase 6).
class SyncPassMetrics {
  const SyncPassMetrics({
    required this.correlationId,
    required this.outcome,
    required this.trigger,
    required this.uploaded,
    required this.downloaded,
    required this.failed,
    required this.conflicts,
    required this.durationMs,
    required this.finishedAt,
    this.downloadedByEntity = const {},
  });

  final String correlationId;
  final SyncPassOutcome outcome;
  final SyncPassTrigger trigger;
  final int uploaded;
  final int downloaded;
  final int failed;
  final int conflicts;
  final int durationMs;
  final DateTime finishedAt;
  final Map<String, int> downloadedByEntity;

  Map<String, dynamic> toMap() => {
    'correlationId': correlationId,
    'outcome': outcome.name,
    'trigger': trigger.storageValue,
    'uploaded': uploaded,
    'downloaded': downloaded,
    'failed': failed,
    'conflicts': conflicts,
    'durationMs': durationMs,
    'finishedAt': finishedAt.toUtc().millisecondsSinceEpoch,
    'downloadedByEntity': downloadedByEntity,
  };

  factory SyncPassMetrics.fromMap(Map<dynamic, dynamic> map) {
    final byEntityRaw = map['downloadedByEntity'];
    final byEntity = <String, int>{};
    if (byEntityRaw is Map) {
      for (final entry in byEntityRaw.entries) {
        final key = entry.key?.toString();
        final value = entry.value;
        if (key == null || key.isEmpty) continue;
        if (value is num) {
          byEntity[key] = value.toInt();
        }
      }
    }
    return SyncPassMetrics(
      correlationId: map['correlationId']?.toString() ?? '',
      outcome: SyncPassOutcome.values.firstWhere(
        (o) => o.name == map['outcome']?.toString(),
        orElse: () => SyncPassOutcome.idle,
      ),
      trigger: SyncPassTriggerX.fromStorage(map['trigger']?.toString()),
      uploaded: (map['uploaded'] as num?)?.toInt() ?? 0,
      downloaded: (map['downloaded'] as num?)?.toInt() ?? 0,
      failed: (map['failed'] as num?)?.toInt() ?? 0,
      conflicts: (map['conflicts'] as num?)?.toInt() ?? 0,
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      finishedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['finishedAt'] as num?)?.toInt() ?? 0,
        isUtc: true,
      ),
      downloadedByEntity: byEntity,
    );
  }

  factory SyncPassMetrics.fromResult(
    SyncPassResult result, {
    required DateTime finishedAt,
  }) {
    return SyncPassMetrics(
      correlationId: result.correlationId ?? '',
      outcome: result.outcome,
      trigger: result.trigger,
      uploaded: result.uploaded,
      downloaded: result.downloaded,
      failed: result.failed,
      conflicts: result.conflicts,
      durationMs: result.durationMs,
      finishedAt: finishedAt,
      downloadedByEntity: result.downloadedByEntity,
    );
  }
}

/// Durable ring buffer of recent sync pass metrics (Hive).
class SyncMetricsStore {
  SyncMetricsStore({Box? box, String? boxName, this.maxEntries = 40})
    : _boxOverride = box,
      _boxName = boxName ?? HiveBoxes.syncMetrics;

  static const historyKey = 'history';

  final Box? _boxOverride;
  final String _boxName;
  final int maxEntries;
  Box? _box;

  Future<Box> _ensureBox() async {
    final override = _boxOverride;
    if (override != null) {
      return override;
    }
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box(_boxName);
    } else {
      _box = await Hive.openBox(_boxName);
    }
    return _box!;
  }

  Future<void> record(SyncPassMetrics metrics) async {
    final box = await _ensureBox();
    final raw = box.get(historyKey);
    final list = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(Map<String, dynamic>.from(item));
        }
      }
    }
    list.insert(0, metrics.toMap());
    while (list.length > maxEntries) {
      list.removeLast();
    }
    await box.put(historyKey, list);
  }

  Future<List<SyncPassMetrics>> recent({int limit = 10}) async {
    final box = await _ensureBox();
    final raw = box.get(historyKey);
    if (raw is! List) {
      return const [];
    }
    final out = <SyncPassMetrics>[];
    for (final item in raw) {
      if (item is Map) {
        out.add(SyncPassMetrics.fromMap(item));
      }
      if (out.length >= limit) {
        break;
      }
    }
    return out;
  }

  Future<SyncPassMetrics?> latest() async {
    final rows = await recent(limit: 1);
    return rows.isEmpty ? null : rows.first;
  }
}

Future<void> openSyncMetricsBox() async {
  if (!Hive.isBoxOpen(HiveBoxes.syncMetrics)) {
    await Hive.openBox(HiveBoxes.syncMetrics);
  }
}
