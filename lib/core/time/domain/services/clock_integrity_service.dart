import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../trusted_clock.dart';

enum ClockIntegrityState {
  trusted,
  unverified,
  suspicious,
  tampered,
}

class ClockIntegrityService {
  ClockIntegrityService({required this._clock});
  final TrustedClock _clock;

  ClockIntegrityState checkIntegrity() {
    final checkpoint = _clock.checkpoint;
    final lastWallClock = _clock.lastStoredWallClock;
    final currentWallClock = DateTime.now().toUtc();

    // 1. If no checkpoint exists, it is unverified
    if (checkpoint == null) {
      return ClockIntegrityState.unverified;
    }

    // 2. Check if wall clock moved backwards compared to last stored wall clock
    if (lastWallClock != null && currentWallClock.isBefore(lastWallClock)) {
      return ClockIntegrityState.tampered;
    }

    // 3. Monitor drift: compare wall-clock elapsed time vs monotonic elapsed time
    final wallDelta = currentWallClock.difference(checkpoint.localWallClock).inMilliseconds;
    final monoDelta = _clock.currentMonotonicMs - checkpoint.monotonicMs;

    // A drift is suspicious if wall clock changed significantly compared to monotonic clock
    // (e.g. wall clock delta differs from monotonic delta by more than 5 minutes, except if wall clock delta is positive
    // which can happen during system sleep/suspend).
    // So we only flag a difference as suspicious if monotonic delta is larger than wall delta (meaning wall clock moved backward or stopped)
    // OR if there is an enormous discrepancy that indicates active tempering.
    const maxDriftMs = 300000; // 5 minutes
    final discrepancy = wallDelta - monoDelta;
    if (discrepancy < -maxDriftMs) {
      // Wall clock is lagging behind monotonic time progression
      return ClockIntegrityState.tampered;
    }

    return ClockIntegrityState.trusted;
  }
}

final clockIntegrityServiceProvider = Provider<ClockIntegrityService>((ref) {
  final clock = ref.watch(trustedClockProvider);
  return ClockIntegrityService(clock: clock);
});
