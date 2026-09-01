import '../repositories/sync_repository.dart';

class ExecuteSyncUseCase {
  const ExecuteSyncUseCase(this._repository);

  final SyncRepository _repository;

  Future<void> call() => _repository.triggerSync();
}
