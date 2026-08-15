import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sync/sync_manager.dart';
import '../../core/sync/sync_providers.dart';
import '../presentation/providers/dashboard_services_provider.dart';
import '../settings/settings_repository.dart';

/// Whether the user opted into multi-device sync (persisted; default off).
final syncEnabledProvider =
    StateNotifierProvider<SyncEnabledController, bool>((ref) {
  return SyncEnabledController(
    repository: ref.watch(settingsRepositoryProvider),
    syncManager: ref.watch(syncManagerProvider),
  );
});

class SyncEnabledController extends StateNotifier<bool> {
  SyncEnabledController({
    required SettingsRepository repository,
    required SyncManager syncManager,
  })  : _repository = repository,
        _syncManager = syncManager,
        super(false);

  final SettingsRepository _repository;
  final SyncManager _syncManager;

  Future<void> hydrate(bool enabled) async {
    state = enabled;
    await _syncManager.setEnabled(enabled);
  }

  Future<void> setEnabled(bool enabled) async {
    await _repository.saveSyncEnabled(enabled);
    state = enabled;
    await _syncManager.setEnabled(enabled);
  }
}
