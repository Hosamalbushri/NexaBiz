import 'package:stock_count/modules/sync/sync.dart';
import '../../presentation/providers/dashboard_services_provider.dart';
import 'company_profile_sync_handler.dart';

class CompanyProfileSyncRegistrar implements SyncModuleRegistrar {
  const CompanyProfileSyncRegistrar();

  @override
  String get moduleId => 'company_profile';

  @override
  SyncScope get scope => SyncScope.any;

  @override
  List<SyncEntityHandler> buildHandlers(dynamic ref) {
    return [
      CompanyProfileSyncHandler(
        repository: ref.read(settingsRepositoryProvider),
        remoteProvider: () => ref.read(remoteSyncApiProvider),
      ),
    ];
  }
}
