import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/modules/sync/engine/domain/entities/sync_operation.dart';
import 'package:stock_count/modules/sync/engine/presentation/providers/sync_providers.dart';
import 'sync_queue.dart';

/// Contract for module-specific initial cloud entity scanning.
abstract class InitialCloudEntityScanner {
  String get entityType;
  int get priorityOrder => 1;
  Future<List<SyncOperation>> scanInitialOperations({
    required Ref ref,
    required String companyId,
    required String deviceId,
  });
}

enum MigrationStatus {
  notStarted,
  scanning,
  uploading,
  verifying,
  completed,
  failedRetryable,
  failedPermanent,
}

class MigrationProgress {
  const MigrationProgress({
    required this.status,
    required this.processedCount,
    required this.totalCount,
    this.errorMessage,
  });

  final MigrationStatus status;
  final int processedCount;
  final int totalCount;
  final String? errorMessage;
}

class InitialCloudSyncScanner {
  InitialCloudSyncScanner(
    this._ref, {
    this._remoteProvider,
    this._scanners,
  });

  final Ref _ref;
  final RemoteSyncApi Function()? _remoteProvider;
  final List<InitialCloudEntityScanner>? _scanners;

  final _controller = StreamController<MigrationProgress>.broadcast();
  Stream<MigrationProgress> get progress => _controller.stream;

  RemoteSyncApi get _remote =>
      _remoteProvider?.call() ?? _ref.read(remoteSyncApiProvider);

  Future<void> runMigration({
    required String companyId,
    required String deviceId,
    required SyncQueue queue,
  }) async {
    _controller.add(const MigrationProgress(
      status: MigrationStatus.scanning,
      processedCount: 0,
      totalCount: 0,
    ));

    try {
      final List<InitialCloudEntityScanner> activeScanners =
          _scanners ?? _ref.read(initialCloudEntityScannersProvider);
      final sortedScanners =
          List<InitialCloudEntityScanner>.from(activeScanners)
            ..sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));

      final allOperations = <SyncOperation>[];
      for (final scanner in sortedScanners) {
        final ops = await scanner.scanInitialOperations(
          ref: _ref,
          companyId: companyId,
          deviceId: deviceId,
        );
        allOperations.addAll(ops);
      }

      final totalItems = allOperations.length;

      _controller.add(MigrationProgress(
        status: MigrationStatus.uploading,
        processedCount: 0,
        totalCount: totalItems,
      ));

      var processed = 0;

      for (final op in allOperations) {
        final meta = await _remote.getMeta(
          entityType: op.entityType,
          entityId: op.entityId,
        );
        if (meta == null) {
          await queue.enqueue(op);
        }
        processed++;
        _controller.add(MigrationProgress(
          status: MigrationStatus.uploading,
          processedCount: processed,
          totalCount: totalItems,
        ));
      }

      _controller.add(MigrationProgress(
        status: MigrationStatus.completed,
        processedCount: processed,
        totalCount: totalItems,
      ));
    } catch (e) {
      _controller.add(MigrationProgress(
        status: MigrationStatus.failedRetryable,
        processedCount: 0,
        totalCount: 0,
        errorMessage: e.toString(),
      ));
    }
  }

  void dispose() {
    _controller.close();
  }
}

final initialCloudEntityScannersProvider =
    StateProvider<List<InitialCloudEntityScanner>>((ref) => []);
