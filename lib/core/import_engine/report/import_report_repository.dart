import 'dart:convert';
import 'import_audit_record.dart';
import 'import_report.dart';

/// Repository port for storing, retrieving, and listing persistent post-import reports and audit trails.
abstract class ImportReportRepository {
  /// Persists an [ImportReport].
  Future<void> saveReport(ImportReport report);

  /// Retrieves an [ImportReport] by [jobId] strictly scoped to [companyId].
  Future<ImportReport?> getReport(String jobId, {required String companyId});

  /// Retrieves an [ImportAuditRecord] by [jobId] strictly scoped to [companyId].
  Future<ImportAuditRecord?> getAuditRecord(
    String jobId, {
    required String companyId,
  });

  /// Lists all audit records for a given [companyId] (tenant isolated).
  Future<List<ImportAuditRecord>> listAuditRecordsForCompany(String companyId);
}

/// In-memory & JSON-serializable persistent implementation of [ImportReportRepository].
/// Enforces strict multi-company tenant isolation on all operations.
class InMemoryImportReportRepository implements ImportReportRepository {
  InMemoryImportReportRepository([Map<String, String>? initialStorage]) {
    if (initialStorage != null) {
      _storage.addAll(initialStorage);
      for (final entry in _storage.entries) {
        try {
          final map = jsonDecode(entry.value) as Map<String, dynamic>;
          _reports[entry.key] = ImportReport.fromJson(map);
        } catch (_) {}
      }
    }
  }

  /// Internal raw JSON string storage mapping `jobId` -> serialized JSON string.
  final Map<String, String> _storage = {};
  final Map<String, ImportReport> _reports = {};

  /// Exports raw serialized storage (simulating disk/database backup across restarts).
  Map<String, String> exportStorage() =>
      Map<String, String>.unmodifiable(_storage);

  @override
  Future<void> saveReport(ImportReport report) async {
    if (report.companyId.trim().isEmpty) {
      throw ArgumentError('Cannot save ImportReport without a valid companyId');
    }
    final jsonStr = jsonEncode(report.toJson());
    _storage[report.jobId] = jsonStr;
    _reports[report.jobId] = report;
  }

  @override
  Future<ImportReport?> getReport(
    String jobId, {
    required String companyId,
  }) async {
    if (companyId.trim().isEmpty) return null;

    ImportReport? report = _reports[jobId];
    if (report == null) {
      final raw = _storage[jobId];
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        report = ImportReport.fromJson(map);
        _reports[jobId] = report;
      }
    }

    if (report == null) return null;

    // Strict Multi-Company Tenant Isolation Guard: return null on cross-tenant read
    if (report.companyId != companyId) {
      return null;
    }

    return report;
  }

  @override
  Future<ImportAuditRecord?> getAuditRecord(
    String jobId, {
    required String companyId,
  }) async {
    final report = await getReport(jobId, companyId: companyId);
    return report?.auditRecord;
  }

  @override
  Future<List<ImportAuditRecord>> listAuditRecordsForCompany(
    String companyId,
  ) async {
    if (companyId.trim().isEmpty) return [];

    // Ensure all stored reports are loaded
    for (final jobId in _storage.keys) {
      if (!_reports.containsKey(jobId)) {
        await getReport(jobId, companyId: companyId);
      }
    }
    return _reports.values
        .where((r) => r.companyId == companyId)
        .map((r) => r.auditRecord)
        .toList();
  }
}
