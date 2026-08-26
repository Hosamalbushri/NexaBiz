import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/sync/app_bar_sync_actions.dart';
import 'package:stock_count/modules/sync/sync.dart';

void main() {
  group('AppBarSyncActions.hasActiveSync', () {
    test('false when idle online with empty queues', () {
      expect(
        AppBarSyncActions.hasActiveSync(
          const SyncOverview(
            phase: SyncPhase.idleSynced,
            isOnline: true,
            pendingCount: 0,
            failedCount: 0,
            conflictCount: 0,
          ),
        ),
        isFalse,
      );
    });

    test('true while syncing or with pending/failed/conflict', () {
      expect(
        AppBarSyncActions.hasActiveSync(
          const SyncOverview(
            phase: SyncPhase.syncing,
            isOnline: true,
            pendingCount: 0,
            failedCount: 0,
            conflictCount: 0,
            isSyncing: true,
          ),
        ),
        isTrue,
      );
      expect(
        AppBarSyncActions.hasActiveSync(
          const SyncOverview(
            phase: SyncPhase.pending,
            isOnline: true,
            pendingCount: 2,
            failedCount: 0,
            conflictCount: 0,
          ),
        ),
        isTrue,
      );
      expect(
        AppBarSyncActions.hasActiveSync(
          const SyncOverview(
            phase: SyncPhase.failed,
            isOnline: true,
            pendingCount: 0,
            failedCount: 1,
            conflictCount: 0,
          ),
        ),
        isTrue,
      );
      expect(
        AppBarSyncActions.hasActiveSync(
          const SyncOverview(
            phase: SyncPhase.conflict,
            isOnline: true,
            pendingCount: 0,
            failedCount: 0,
            conflictCount: 1,
          ),
        ),
        isTrue,
      );
    });
  });
}
