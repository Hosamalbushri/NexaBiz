import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class TimeCheckpoint {
  const TimeCheckpoint({
    required this.serverTime,
    required this.localWallClock,
    required this.monotonicMs,
    required this.recordedAt,
  });

  final DateTime serverTime;
  final DateTime localWallClock;
  final int monotonicMs;
  final DateTime recordedAt;

  Map<String, dynamic> toJson() => {
        'serverTime': serverTime.toIso8601String(),
        'localWallClock': localWallClock.toIso8601String(),
        'monotonicMs': monotonicMs,
        'recordedAt': recordedAt.toIso8601String(),
      };

  factory TimeCheckpoint.fromJson(Map<String, dynamic> json) => TimeCheckpoint(
        serverTime: DateTime.parse(json['serverTime'] as String).toUtc(),
        localWallClock: DateTime.parse(json['localWallClock'] as String).toUtc(),
        monotonicMs: json['monotonicMs'] as int,
        recordedAt: DateTime.parse(json['recordedAt'] as String).toUtc(),
      );
}

class TrustedClock {
  TrustedClock({
    FlutterSecureStorage? storage,
    Stopwatch? stopwatch,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _stopwatch = stopwatch ?? (Stopwatch()..start());

  final FlutterSecureStorage _storage;
  final Stopwatch _stopwatch;
  TimeCheckpoint? _checkpoint;
  DateTime? _lastStoredWallClock;

  static const String _checkpointKey = 'trusted_time_checkpoint';
  static const String _lastWallClockKey = 'last_stored_wall_clock';

  Future<void> initialize() async {
    try {
      final cpJson = await _storage.read(key: _checkpointKey);
      if (cpJson != null) {
        _checkpoint = TimeCheckpoint.fromJson(jsonDecode(cpJson));
      }

      final wallStr = await _storage.read(key: _lastWallClockKey);
      if (wallStr != null) {
        _lastStoredWallClock = DateTime.parse(wallStr).toUtc();
      }
    } catch (_) {}
  }

  Future<void> setCheckpoint({required DateTime serverTime, required DateTime localWallClock}) async {
    _checkpoint = TimeCheckpoint(
      serverTime: serverTime.toUtc(),
      localWallClock: localWallClock.toUtc(),
      monotonicMs: _stopwatch.elapsedMilliseconds,
      recordedAt: DateTime.now().toUtc(),
    );
    _lastStoredWallClock = localWallClock.toUtc();

    await _storage.write(key: _checkpointKey, value: jsonEncode(_checkpoint!.toJson()));
    await _storage.write(key: _lastWallClockKey, value: _lastStoredWallClock!.toIso8601String());
  }

  DateTime now() => utcNow().toLocal();

  DateTime utcNow() {
    final cp = _checkpoint;
    if (cp == null) {
      return DateTime.now().toUtc();
    }
    final elapsed = _stopwatch.elapsedMilliseconds - cp.monotonicMs;
    return cp.serverTime.add(Duration(milliseconds: elapsed));
  }

  Future<void> updateWallClock(DateTime localWallClock) async {
    _lastStoredWallClock = localWallClock.toUtc();
    await _storage.write(key: _lastWallClockKey, value: _lastStoredWallClock!.toIso8601String());
  }

  DateTime? get lastStoredWallClock => _lastStoredWallClock;
  TimeCheckpoint? get checkpoint => _checkpoint;
  int get currentMonotonicMs => _stopwatch.elapsedMilliseconds;

  Future<void> clearSession() async {
    _checkpoint = null;
    await _storage.delete(key: _checkpointKey);
  }
}

final trustedClockProvider = Provider<TrustedClock>((ref) {
  return TrustedClock();
});
