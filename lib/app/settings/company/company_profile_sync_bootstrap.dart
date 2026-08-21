import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_providers.dart';
import '../../presentation/providers/dashboard_services_provider.dart';
import '../settings_repository.dart';
import 'company_profile_sync_handler.dart';

/// Registers Company Profile sync adapter with the shared [SyncManager].
void registerCompanyProfileSyncHandlers(Ref ref) {
  final manager = ref.read(syncManagerProvider);
  manager.registerHandler(
    CompanyProfileSyncHandler(
      repository: ref.read(settingsRepositoryProvider),
      remoteProvider: () => ref.read(remoteSyncApiProvider),
    ),
  );
}
