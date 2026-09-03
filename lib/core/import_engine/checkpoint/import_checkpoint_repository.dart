import 'import_checkpoint.dart';

/// Abstract port interface for persisting job checkpoints.
abstract class ImportCheckpointRepository {
  /// Saves or updates a checkpoint for a job.
  Future<void> save(ImportCheckpoint checkpoint);

  /// Retrieves the latest checkpoint for [jobId] scoped to [companyId].
  Future<ImportCheckpoint?> getLatestCheckpoint(String jobId, {required String companyId});

  /// Deletes checkpoint for [jobId] scoped to [companyId].
  Future<void> deleteCheckpoint(String jobId, {required String companyId});

  /// Clears all checkpoints.
  Future<void> clear();
}

/// In-memory implementation of [ImportCheckpointRepository].
class InMemoryImportCheckpointRepository implements ImportCheckpointRepository {
  final Map<String, ImportCheckpoint> _store = {};

  @override
  Future<void> save(ImportCheckpoint checkpoint) async {
    if (checkpoint.companyId.trim().isEmpty) {
      throw ArgumentError('Checkpoint must have a non-empty companyId');
    }
    _store[checkpoint.jobId] = checkpoint;
  }

  @override
  Future<ImportCheckpoint?> getLatestCheckpoint(String jobId, {required String companyId}) async {
    if (companyId.trim().isEmpty) return null;
    final cp = _store[jobId];
    if (cp == null || cp.companyId != companyId) return null;
    return cp;
  }

  @override
  Future<void> deleteCheckpoint(String jobId, {required String companyId}) async {
    final cp = _store[jobId];
    if (cp != null && cp.companyId == companyId) {
      _store.remove(jobId);
    }
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }
}
