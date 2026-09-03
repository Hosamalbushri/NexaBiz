import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/import_engine/import_engine.dart';

void main() {
  group('Phase 15 — Universal Import Engine Reporting & Audit Tests', () {
    late InMemoryImportReportRepository reportRepository;
    late DateTime now;

    setUp(() {
      reportRepository = InMemoryImportReportRepository();
      now = DateTime.parse('2026-09-03T21:00:00.000Z');
    });

    ImportReport createSampleReport({
      required String jobId,
      required String companyId,
      required String userId,
    }) {
      final auditRecord = ImportAuditRecord(
        auditId: 'AUDIT-$jobId',
        jobId: jobId,
        companyId: companyId,
        userId: userId,
        source: 'products_import_2026.xlsx',
        entityType: 'Product',
        configuration: const {'chunkSize': 500, 'mode': 'perChunk'},
        mappingProfileId: 'PROF-123',
        mappingSummary: const {
          'Code': 'code',
          'Name': 'name',
          'Price': 'price',
        },
        startedAt: now,
        completedAt: now.add(const Duration(seconds: 45)),
        totalRows: 100,
        createdRows: 80,
        updatedRows: 10,
        skippedRows: 5,
        failedRows: 5,
        warningCount: 2,
        errorCount: 5,
      );

      final rowResults = [
        const ImportRowResult(
          rowIndex: 1,
          outcome: ImportRowOutcome.created,
          entityId: 'PROD-001',
          metadata: {'executionTimeMs': 12},
        ),
        const ImportRowResult(
          rowIndex: 2,
          outcome: ImportRowOutcome.updated,
          entityId: 'PROD-002',
          metadata: {'executionTimeMs': 15},
        ),
        const ImportRowResult(
          rowIndex: 3,
          outcome: ImportRowOutcome.skipped,
          warnings: ['Duplicate entry skipped by policy'],
        ),
        const ImportRowResult(
          rowIndex: 4,
          outcome: ImportRowOutcome.failed,
          errors: ['Required field missing: code'],
        ),
      ];

      final errorReports = [
        ImportErrorReport(
          jobId: jobId,
          rowIndex: 4,
          fieldKey: 'code',
          errorCode: 'REQUIRED_FIELD_MISSING',
          message: 'Required field missing: code',
          severity: 'ERROR',
          rawValue: null,
          timestamp: now.add(const Duration(seconds: 10)),
        ),
      ];

      return ImportReport(
        auditRecord: auditRecord,
        rowResults: rowResults,
        errorReports: errorReports,
      );
    }

    test('1. Audit trail tracking verifies all required metadata & counts', () {
      final report = createSampleReport(
        jobId: 'JOB-9001',
        companyId: 'COMP-ALPHA',
        userId: 'USER-101',
      );

      final audit = report.auditRecord;

      expect(audit.jobId, equals('JOB-9001'));
      expect(audit.companyId, equals('COMP-ALPHA'));
      expect(audit.userId, equals('USER-101'));
      expect(audit.source, equals('products_import_2026.xlsx'));
      expect(audit.entityType, equals('Product'));
      expect(audit.configuration['chunkSize'], equals(500));
      expect(audit.mappingSummary['Code'], equals('code'));
      expect(audit.startedAt, equals(now));
      expect(audit.completedAt, equals(now.add(const Duration(seconds: 45))));
      expect(audit.isCompleted, isTrue);

      expect(audit.totalRows, equals(100));
      expect(audit.createdRows, equals(80));
      expect(audit.updatedRows, equals(10));
      expect(audit.skippedRows, equals(5));
      expect(audit.failedRows, equals(5));
      expect(audit.warningCount, equals(2));
      expect(audit.errorCount, equals(5));
    });

    test('2. Full JSON serialization roundtrip guarantees exact rehydration', () {
      final originalReport = createSampleReport(
        jobId: 'JOB-9002',
        companyId: 'COMP-ALPHA',
        userId: 'USER-102',
      );

      final json = originalReport.toJson();
      final restoredReport = ImportReport.fromJson(json);

      expect(restoredReport.jobId, equals(originalReport.jobId));
      expect(restoredReport.companyId, equals(originalReport.companyId));
      expect(restoredReport.auditRecord.auditId, equals(originalReport.auditRecord.auditId));
      expect(restoredReport.rowResults.length, equals(originalReport.rowResults.length));
      expect(restoredReport.errorReports.length, equals(originalReport.errorReports.length));

      expect(restoredReport.rowResults[0].outcome, equals(ImportRowOutcome.created));
      expect(restoredReport.rowResults[0].entityId, equals('PROD-001'));
      expect(restoredReport.errorReports[0].errorCode, equals('REQUIRED_FIELD_MISSING'));
    });

    test('3. Report reproducibility after application restart simulation', () async {
      final report1 = createSampleReport(
        jobId: 'JOB-RESTART-01',
        companyId: 'COMP-BETA',
        userId: 'USER-201',
      );

      await reportRepository.saveReport(report1);

      // Simulate application restart by exporting raw storage and initializing a fresh repository
      final exportedStorage = reportRepository.exportStorage();
      final freshRepositoryAfterRestart = InMemoryImportReportRepository(exportedStorage);

      final retrievedAudit = await freshRepositoryAfterRestart.getAuditRecord('JOB-RESTART-01', companyId: 'COMP-BETA');

      expect(retrievedAudit, isNotNull);
      expect(retrievedAudit!.jobId, equals('JOB-RESTART-01'));
      expect(retrievedAudit.companyId, equals('COMP-BETA'));
      expect(retrievedAudit.totalRows, equals(100));
      expect(retrievedAudit.createdRows, equals(80));
    });

    test('4. Multi-company tenant isolation for audit records', () async {
      final reportAlpha = createSampleReport(
        jobId: 'JOB-A1',
        companyId: 'COMPANY-A',
        userId: 'USER-1',
      );

      final reportBeta = createSampleReport(
        jobId: 'JOB-B1',
        companyId: 'COMPANY-B',
        userId: 'USER-2',
      );

      await reportRepository.saveReport(reportAlpha);
      await reportRepository.saveReport(reportBeta);

      final companyAAudits = await reportRepository.listAuditRecordsForCompany('COMPANY-A');
      final companyBAudits = await reportRepository.listAuditRecordsForCompany('COMPANY-B');

      expect(companyAAudits.length, equals(1));
      expect(companyAAudits.first.jobId, equals('JOB-A1'));

      expect(companyBAudits.length, equals(1));
      expect(companyBAudits.first.jobId, equals('JOB-B1'));
    });
  });
}
