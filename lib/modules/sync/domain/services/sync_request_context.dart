import 'dart:async';

/// Per-sync-pass correlation id for client↔server log joins.
///
/// Set via [run] around a [SyncManager.syncNow] body; HTTP clients read
/// [correlationId] from the current zone.
class SyncRequestContext {
  SyncRequestContext._();

  static const _correlationKey = #syncCorrelationId;
  static const _triggerKey = #syncPassTrigger;

  static String? get correlationId =>
      Zone.current[_correlationKey] as String?;

  static SyncPassTrigger get trigger {
    final value = Zone.current[_triggerKey];
    if (value is SyncPassTrigger) {
      return value;
    }
    return SyncPassTrigger.manual;
  }

  static Future<T> run<T>({
    required String correlationId,
    SyncPassTrigger trigger = SyncPassTrigger.manual,
    required Future<T> Function() body,
  }) {
    return runZoned(
      body,
      zoneValues: {
        _correlationKey: correlationId,
        _triggerKey: trigger,
      },
    );
  }
}

/// Why a sync pass was started (metrics / logs).
enum SyncPassTrigger {
  manual,
  auto,
  connectivity,
  osBackground,
}

extension SyncPassTriggerX on SyncPassTrigger {
  String get storageValue => name;

  static SyncPassTrigger fromStorage(String? raw) {
    return SyncPassTrigger.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => SyncPassTrigger.manual,
    );
  }
}
