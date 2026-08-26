import '../../../core/network/remote_sync_api.dart';
import 'package:stock_count/modules/sync/sync.dart';
import '../settings_repository.dart';
import 'company_profile.dart';

/// Company Profile sync adapter for [SyncManager].
class CompanyProfileSyncHandler implements SyncEntityHandler {
  CompanyProfileSyncHandler({
    required SettingsRepository repository,
    required RemoteSyncApi Function() remoteProvider,
    this.conflictResolver = const ConflictResolver(),
  }) : _repository = repository,
       _remoteProvider = remoteProvider;

  static const String entityTypeKey = 'company_profile';

  final SettingsRepository _repository;
  final RemoteSyncApi Function() _remoteProvider;
  final ConflictResolver conflictResolver;

  RemoteSyncApi get _remote => _remoteProvider();

  @override
  String get entityType => entityTypeKey;

  @override
  bool get preferServerWhenLocalSynced => true;

  @override
  Future<ConflictDecision?> evaluateConflict(SyncOperation operation) async {
    final meta = await _remote.getMeta(
      entityType: entityType,
      entityId: operation.entityId,
    );
    if (meta == null) {
      return ConflictDecision.uploadLocal;
    }
    return conflictResolver.resolve(
      localOperation: operation,
      remoteVersion: meta.version,
      remoteUpdatedAt: meta.updatedAt,
      preferServerWhenLocalSynced: preferServerWhenLocalSynced,
      remotePayload: meta.payload,
    );
  }

  @override
  Future<SyncUploadAck> upload(SyncOperation operation) {
    return _remote.push(entityType: entityType, operation: operation);
  }

  @override
  Future<List<SyncRemoteChange>> pull({DateTime? since}) {
    return _remote.pull(entityType: entityType, since: since);
  }

  @override
  Future<void> confirmPull() async => _remote.acknowledgePull(entityType);

  @override
  Future<void> abandonPull() async => _remote.abandonPull(entityType);

  @override
  Future<void> applyRemoteChange(SyncRemoteChange change) async {
    if (change.deleted) {
      return;
    }
    final payload = Map<String, dynamic>.from(change.payload);
    final profile = CompanyProfile.fromMap(payload);
    await _repository.saveCompanyProfile(profile);
  }

  @override
  Future<void> markLocalSynced({
    required String entityId,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {
    // Company profile is stored in settings; no entity table version flag required.
  }

  @override
  Future<void> markLocalConflict({required String entityId, String? message}) async {
    // No local conflict state stored for settings.
  }
}
