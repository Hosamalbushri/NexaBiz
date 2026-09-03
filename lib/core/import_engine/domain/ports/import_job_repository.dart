import '../entities/import_job.dart';
import '../entities/import_job_status.dart';

/// Abstract port interface for persistent ImportJob storage.
/// Enforces mandatory company isolation on all operations.
abstract class ImportJobRepository {
  /// Saves or updates an [ImportJob].
  /// Throws [ArgumentError] if [job.companyId] is empty.
  Future<void> save(ImportJob job);

  /// Retrieves a job by [jobId], strictly scoped to [companyId].
  /// Returns null if job does not exist or belongs to a different company.
  Future<ImportJob?> getById(String jobId, {required String companyId});

  /// Lists all jobs belonging to [companyId], optionally filtered by [statusFilter].
  Future<List<ImportJob>> getJobsForCompany(
    String companyId, {
    ImportJobStatus? statusFilter,
  });

  /// Deletes a job by [jobId] strictly scoped to [companyId].
  Future<void> delete(String jobId, {required String companyId});

  /// Clears all jobs in repository (utility for testing).
  Future<void> clear();
}
