import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/atomic_bootstrap_installer.dart';
import '../../core/entitlements/domain/entities/entitlement.dart';
import '../../core/entitlements/presentation/providers/entitlement_providers.dart';
import '../../core/errors/app_error_domain.dart';
import '../../core/logging/app_error_log.dart';
import '../../core/network/server_bootstrap_service.dart';
import 'package:stock_count/modules/sync/sync.dart';
import '../settings/settings_repository.dart';
import '../sync/sync_enabled_provider.dart';
import 'app_bootstrap.dart';
import 'app_initialization_state.dart';

/// Minimum splash duration for smooth visual rendering.
const Duration kMinSplashDuration = Duration(milliseconds: 1000);

/// Maximum timeout duration for standard local initialization.
const Duration kMaxBootstrapTimeout = Duration(seconds: 8);

/// Master orchestrator for application initialization lifecycle.
class AppInitializationCoordinator extends StateNotifier<InitializationState> {
  AppInitializationCoordinator(this._ref)
    : super(const InitializationState.notStarted());

  final Ref _ref;

  /// Main entry point called at application launch.
  Future<void> initialize() async {
    if (state.isInitializing || state.isReady) {
      return;
    }

    final startTime = DateTime.now();
    state = InitializationState(
      status: InitializationStatus.initializing,
      stage: InitializationStage.coreBootstrap,
      startedAt: startTime,
      stageDetails: 'Starting core application bootstrap',
    );

    Timer? timeoutTimer;
    try {
      timeoutTimer = Timer(kMaxBootstrapTimeout, () {
        if (mounted && state.isInitializing) {
          state = state.copyWith(
            status: InitializationStatus.degraded,
            stage: InitializationStage.applicationReady,
            error: const AppError(
              category: AppErrorCategory.initialization,
              message:
                  'Local initialization timed out. Running in degraded mode.',
              severity: FailureSeverity.recoverable,
            ),
          );
        }
      });

      // 1. Storage & Hive
      state = state.copyWith(
        stage: InitializationStage.localStorage,
        stageDetails: 'Initializing local storage',
      );
      await AppBootstrap.bootstrapStorage();

      // 2. Database & Sync Queue
      state = state.copyWith(
        stage: InitializationStage.database,
        stageDetails: 'Opening database engine',
      );
      await AppBootstrap.bootstrapDatabase();

      // 3. System Configuration
      state = state.copyWith(
        stage: InitializationStage.configuration,
        stageDetails: 'Loading platform configuration',
      );
      await AppBootstrap.bootstrapConfig(_ref);

      // 4. Auth & Identity Hydration
      state = state.copyWith(
        stage: InitializationStage.authenticating,
        stageDetails: 'Hydrating authentication state',
      );
      await AppBootstrap.bootstrapAuth(_ref);

      final settings = SettingsRepository();
      final isConfigured = await settings.appearsPreviouslyConfigured();
      final isFirstLaunch = !isConfigured;

      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < kMinSplashDuration) {
        await Future<void>.delayed(kMinSplashDuration - elapsed);
      }

      timeoutTimer.cancel();

      if (isFirstLaunch) {
        await completeLocalSetup();
      } else {
        state = state.copyWith(
          status: InitializationStatus.ready,
          stage: InitializationStage.applicationReady,
          isFirstLaunch: false,
          completedAt: DateTime.now(),
          stageDetails: 'Application ready',
        );
        unawaited(_startBackgroundServices());
      }
    } catch (e, stack) {
      timeoutTimer?.cancel();
      AppErrorLog.record(e, stack, source: 'AppInitializationCoordinator');
      final appError = classifyAppError(e, stackTrace: stack);

      if (appError.isFatal) {
        state = state.copyWith(
          status: InitializationStatus.failed,
          error: appError,
          completedAt: DateTime.now(),
          stageDetails: 'Fatal initialization failure',
        );
      } else {
        state = state.copyWith(
          status: InitializationStatus.degraded,
          stage: InitializationStage.applicationReady,
          error: appError,
          completedAt: DateTime.now(),
          stageDetails: 'Operating in degraded offline mode',
        );
        unawaited(_startBackgroundServices());
      }
    }
  }

  /// Marks local setup as completed and transitions application to ready state.
  Future<void> completeLocalSetup() async {
    state = state.copyWith(
      status: InitializationStatus.initializingLocalDatabase,
      stage: InitializationStage.localInitialization,
      stageDetails: 'Finalizing local setup',
    );

    try {
      final settings = SettingsRepository();
      await settings.saveOnboardingCompleted(true);
      await settings.saveDeviceInitialization(
        mode: DeviceInitializationMode.local,
        initialized: true,
        initializedAt: DateTime.now(),
      );

      state = state.copyWith(
        status: InitializationStatus.ready,
        stage: InitializationStage.applicationReady,
        operatingMode: ApplicationOperatingMode.local,
        isFirstLaunch: false,
        completedAt: DateTime.now(),
        stageDetails: 'Local setup completed',
      );

      unawaited(_startBackgroundServices());
    } catch (e, stack) {
      state = state.copyWith(
        status: InitializationStatus.failed,
        error: classifyAppError(e, stackTrace: stack),
      );
    }
  }

  /// Executes full server initialization pipeline (URL health -> login -> bootstrap status -> data download -> atomic DB -> initial sync -> ready).
  Future<void> runServerInitialization({
    required String baseUrl,
    required String token,
    ServerBootstrapService? bootstrapService,
    AtomicBootstrapInstaller? dbInstaller,
  }) async {
    final service = bootstrapService ?? const ServerBootstrapService();
    final installer = dbInstaller ?? const AtomicBootstrapInstaller();

    try {
      // Step 1: Server URL & Health Check
      state = state.copyWith(
        status: InitializationStatus.validatingServer,
        stage: InitializationStage.validatingServer,
        operatingMode: ApplicationOperatingMode.server,
        currentStep: 1,
        totalSteps: 6,
        progressPercentage: 0.1,
        stageDetails: 'Connecting to server health probe...',
      );

      final healthy = await service.checkHealth(baseUrl);
      if (!healthy) {
        throw classifyAppError(
          'Server at $baseUrl is unreachable or unhealthy.',
          category: AppErrorCategory.network,
          severity: FailureSeverity.recoverable,
        );
      }

      // Step 2: Authentication
      state = state.copyWith(
        status: InitializationStatus.authenticating,
        stage: InitializationStage.authenticating,
        currentStep: 2,
        progressPercentage: 0.25,
        stageDetails: 'Server connection & session authenticated',
      );

      // Step 3: Check Remote Bootstrap Status
      state = state.copyWith(
        status: InitializationStatus.checkingRemoteInitialization,
        stage: InitializationStage.checkingRemoteInitialization,
        currentStep: 3,
        progressPercentage: 0.35,
        stageDetails: 'Checking remote initialization state...',
      );

      final status = await service.fetchStatus(baseUrl: baseUrl, token: token);

      if (!status.initialized) {
        state = state.copyWith(
          status: InitializationStatus.serverNoData,
          stage: InitializationStage.checkingRemoteInitialization,
          progressPercentage: 0.4,
          stageDetails: 'No initialization data was found on the server.',
        );
        return;
      }

      // Step 4: Download Master Initialization Data Pages
      state = state.copyWith(
        status: InitializationStatus.downloadingInitialization,
        stage: InitializationStage.downloadingInitialization,
        currentStep: 4,
        progressPercentage: 0.5,
        stageDetails: 'Downloading master configuration data...',
      );

      final entitiesByType = <String, List<Map<String, dynamic>>>{};
      final totalToDownload = status.totalMasterEntities;
      var totalDownloaded = 0;

      for (final type in status.entityCounts.keys) {
        final typeCount = status.entityCounts[type] ?? 0;
        if (typeCount == 0) continue;

        state = state.copyWith(
          currentEntityType: type,
          stageDetails:
              'Downloading $type ($totalDownloaded / $totalToDownload)',
        );

        String? cursor;
        var hasMore = true;
        final list = <Map<String, dynamic>>[];

        while (hasMore) {
          final page = await service.fetchEntityPage(
            baseUrl: baseUrl,
            token: token,
            entityType: type,
            takenAt: status.takenAt,
            cursor: cursor,
            limit: 250,
          );

          list.addAll(page.items);
          totalDownloaded += page.items.length;
          cursor = page.nextCursor;
          hasMore = page.hasMore;

          final frac = totalToDownload > 0
              ? (totalDownloaded / totalToDownload)
              : 1.0;
          state = state.copyWith(
            downloadedCount: totalDownloaded,
            totalToDownload: totalToDownload,
            progressPercentage: 0.5 + (frac * 0.25),
          );
        }
        entitiesByType[type] = list;
      }

      // Step 5: Atomic Local DB Write
      state = state.copyWith(
        status: InitializationStatus.initializingLocalDatabase,
        stage: InitializationStage.initializingLocalDatabase,
        currentStep: 5,
        progressPercentage: 0.8,
        stageDetails: 'Finalizing local database snapshot...',
      );

      // Ensure all feature sync handlers are registered in SyncManager
      await AppBootstrap.bootstrapSync(_ref);
      final syncManager = _ref.read(syncManagerProvider);

      for (final entry in entitiesByType.entries) {
        final entityType = entry.key;
        final items = entry.value;
        final handler = syncManager.getHandler(entityType);

        if (handler != null) {
          for (final item in items) {
            final payload = (item['payload'] as Map<String, dynamic>?) ?? item;
            final entityId =
                (item['entity_id'] as String?) ??
                (payload['id'] as String?) ??
                (payload['uuid'] as String?) ??
                (item['uuid'] as String?) ??
                '';
            if (entityId.isEmpty && entityType != 'company_profile') continue;
            final version = (item['version'] as num?)?.toInt() ?? 1;
            final updatedAtRaw = item['updated_at'] ?? item['updatedAt'];
            final updatedAt = updatedAtRaw is String
                ? (DateTime.tryParse(updatedAtRaw) ?? status.takenAt)
                : (updatedAtRaw is int
                      ? DateTime.fromMillisecondsSinceEpoch(updatedAtRaw)
                      : status.takenAt);
            final deleted = (item['deleted'] as bool?) ?? false;

            final change = SyncRemoteChange(
              entityType: entityType,
              entityId: entityId,
              version: version,
              updatedAt: updatedAt,
              deleted: deleted,
              payload: payload,
            );

            await handler.applyRemoteChange(change);
          }
          await handler.confirmPull();
        }
      }

      await installer.installSnapshot(
        companyId: status.companyId,
        companyName: status.companyName,
        snapshotSequence: status.snapshotSequence,
        takenAt: status.takenAt,
        entitiesByType: entitiesByType,
      );

      // Step 6: Initial Sync Pass (Non-blocking background pass)
      state = state.copyWith(
        status: InitializationStatus.synchronizing,
        stage: InitializationStage.synchronization,
        currentStep: 6,
        progressPercentage: 0.9,
        stageDetails: 'Running initial synchronization...',
      );

      final entitlementService = _ref.read(entitlementServiceProvider);
      if (entitlementService.hasCapability(EntitlementCapability.sync)) {
        unawaited(syncManager.syncNow(trigger: SyncPassTrigger.manual));
      }

      // Save sync & configuration credentials
      await _ref
          .read(syncEnabledProvider.notifier)
          .saveServer(baseUrl: baseUrl, apiToken: token);

      final settings = SettingsRepository();
      await settings.saveOnboardingCompleted(true);
      await settings.saveDeviceInitialization(
        mode: DeviceInitializationMode.server,
        initialized: true,
        companyId: status.companyId,
        initializedAt: DateTime.now(),
      );

      state = state.copyWith(
        status: InitializationStatus.bootstrapCompleted,
        stage: InitializationStage.applicationReady,
        operatingMode: ApplicationOperatingMode.server,
        isFirstLaunch: false,
        completedAt: DateTime.now(),
        progressPercentage: 1.0,
        stageDetails: 'Server initialization completed successfully',
      );
    } catch (e, stack) {
      AppErrorLog.record(e, stack, source: 'runServerInitialization');
      final appError = classifyAppError(e, stackTrace: stack);

      state = state.copyWith(
        status: InitializationStatus.failed,
        error: appError,
        stageDetails: appError.message,
      );
    }
  }

  /// Finalizes initialization completion and transitions app state to [InitializationStatus.ready].
  void completeBootstrapAndProceedToDashboard() {
    state = state.copyWith(
      status: InitializationStatus.ready,
      stage: InitializationStage.applicationReady,
      operatingMode: ApplicationOperatingMode.server,
      isFirstLaunch: false,
      completedAt: DateTime.now(),
      progressPercentage: 1.0,
      stageDetails: 'Ready',
    );
    unawaited(_startBackgroundServices());
  }

  /// Restores degraded state to operate offline.
  void continueOffline() {
    state = state.copyWith(
      status: InitializationStatus.ready,
      stage: InitializationStage.applicationReady,
      operatingMode: ApplicationOperatingMode.local,
      stageDetails: 'Continuing in local offline mode',
    );
  }

  /// When server returns initialized = false, allows user to fall back to local setup cleanly.
  Future<void> fallbackToLocalSetupFromEmptyServer() async {
    await completeLocalSetup();
  }

  /// Retries initialization process.
  Future<void> retry() async {
    state = const InitializationState.notStarted();
    await initialize();
  }

  Future<void> _startBackgroundServices() async {
    try {
      await AppBootstrap.bootstrapAuth(_ref);
      await AppBootstrap.bootstrapSync(_ref);
    } catch (e, stack) {
      AppErrorLog.record(e, stack, source: 'backgroundServices');
    }
  }
}

/// Provider for watching/reading initialization state and coordinator.
final appInitializationControllerProvider =
    StateNotifierProvider<AppInitializationCoordinator, InitializationState>((
      ref,
    ) {
      final coordinator = AppInitializationCoordinator(ref);
      coordinator.initialize();
      return coordinator;
    });

/// Backwards-compatible FutureProvider for legacy listeners.
final appInitializationProvider = FutureProvider<void>((ref) async {
  final state = ref.watch(appInitializationControllerProvider);
  if (state.isFailed) {
    throw state.error ?? Exception('Initialization failed');
  }
  if (!state.canOperate) {
    await ref
        .watch(appInitializationControllerProvider.notifier)
        .stream
        .firstWhere((s) => s.canOperate || s.isFailed);
  }
});
