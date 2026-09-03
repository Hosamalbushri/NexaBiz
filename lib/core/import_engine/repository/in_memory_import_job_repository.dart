import '../domain/entities/import_job.dart';
import '../domain/entities/import_job_status.dart';
import '../domain/exceptions/tenant_isolation_exception.dart';
import '../domain/ports/import_job_repository.dart';

/// Persistent in-memory implementation of [ImportJobRepository].
/// Enforces strict multi-company tenant isolation on all operations.
class InMemoryImportJobRepository implements ImportJobRepository {
  InMemoryImportJobRepository();

  final Map<String, ImportJob> _store = {};

  @override
  Future<void> save(ImportJob job) async {
    if (job.companyId.trim().isEmpty) {
      throw ArgumentError('Cannot save ImportJob without a valid companyId');
    }

    final existing = _store[job.jobId];
    if (existing != null && existing.companyId != job.companyId) {
      throw TenantIsolationException(
        'Cross-company job overwrite violation: Job "${job.jobId}" belongs to company "${existing.companyId}", but attempt was made to overwrite with company "${job.companyId}"',
        expectedCompanyId: existing.companyId,
        attemptedCompanyId: job.companyId,
      );
    }

    _store[job.jobId] = job;
  }

  @override
  Future<ImportJob?> getById(String jobId, {required String companyId}) async {
    if (companyId.trim().isEmpty) return null;
    final job = _store[jobId];
    if (job == null) return null;

    // Reject cross-company access (return null to hide existence across tenants)
    if (job.companyId != companyId) {
      return null;
    }
    return job;
  }

  @override
  Future<List<ImportJob>> getJobsForCompany(
    String companyId, {
    ImportJobStatus? statusFilter,
  }) async {
    if (companyId.trim().isEmpty) return [];

    return _store.values.where((job) {
      if (job.companyId != companyId) return false;
      if (statusFilter != null && job.status != statusFilter) return false;
      return true;
    }).toList();
  }

  @override
  Future<void> delete(String jobId, {required String companyId}) async {
    if (companyId.trim().isEmpty) return;
    final job = _store[jobId];
    if (job != null) {
      if (job.companyId != companyId) {
        throw TenantIsolationException(
          'Cross-company job deletion violation: Job "$jobId" belongs to company "${job.companyId}", but deletion was attempted by company "$companyId"',
          expectedCompanyId: companyId,
          attemptedCompanyId: job.companyId,
        );
      }
      _store.remove(jobId);
    }
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }
}
