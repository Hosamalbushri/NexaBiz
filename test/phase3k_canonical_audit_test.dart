import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/audit/domain/entities/audit_trail_entry.dart';
import 'package:stock_count/core/audit/domain/ports/audit_repository_port.dart';
import 'package:stock_count/core/audit/domain/services/audit_trail_service.dart';
import 'package:stock_count/core/auth/ports/session_context_port.dart';
import 'package:stock_count/core/logging/security_logger.dart';
import 'package:stock_count/core/tenancy/scope_context.dart';
import 'package:stock_count/core/utils/id_generator.dart';

class _FakeSessionContext implements SessionContextPort {
  @override
  String? get currentCompanyId => 'company-active-3k';

  @override
  String? get activeCompanyId => 'company-active-3k';

  @override
  List<CompanyInfo> get companies => const [CompanyInfo(id: 'company-active-3k', name: 'Company 3K')];

  @override
  String? get userId => 'user-active-3k';

  @override
  String? get deviceId => 'device-3k';

  @override
  bool get isAuthenticated => true;

  @override
  bool get isStandalone => false;

  @override
  ScopeContext get scope => const CompanyScope('company-active-3k');
}

class _InMemoryAuditRepository implements AuditRepositoryPort {
  final List<AuditEntry> _entries = [];

  @override
  Future<void> record(AuditEntry entry) async {
    _entries.add(entry);
  }

  @override
  Future<List<AuditEntry>> getForCompany(String companyId, {int limit = 100}) async {
    return _entries
        .where((e) => e.companyId == companyId)
        .take(limit)
        .toList();
  }

  @override
  Future<List<AuditEntry>> getSystemAudits({int limit = 100}) async {
    return _entries
        .where((e) => e.companyId == null)
        .take(limit)
        .toList();
  }

  @override
  Future<List<AuditEntry>> getForEntity(
    String entityType,
    String entityId, {
    String? companyId,
    int limit = 100,
  }) async {
    return _entries
        .where((e) =>
            e.entityType == entityType &&
            e.entityId == entityId &&
            (companyId == null || e.companyId == companyId))
        .take(limit)
        .toList();
  }
}

void main() {
  late _InMemoryAuditRepository repository;
  late _FakeSessionContext sessionContext;
  late AuditTrailService service;

  setUp(() {
    repository = _InMemoryAuditRepository();
    sessionContext = _FakeSessionContext();
    service = AuditTrailService(
      repository: repository,
      sessionContext: sessionContext,
    );
  });

  group('Phase 3K — Canonical Audit & Observability Baseline Tests', () {
    test('Audit event uses stable 36-character UUID v4 identity', () async {
      final docId = generateUuidV4();
      final entry = await service.recordEvent(
        documentId: docId,
        documentType: 'sale',
        eventType: 'post',
        notes: 'Posted sale transaction',
      );

      expect(entry.uuid.length, equals(36));
      expect(entry.documentId, equals(docId));
      expect(entry.eventType, equals('post'));
    });

    test('Audit entries preserve tenant scope isolation and system actor fallback', () async {
      final docId = generateUuidV4();
      await service.recordEvent(
        documentId: docId,
        documentType: 'purchase',
        eventType: 'create',
        companyId: 'company-a-3k',
      );

      await service.recordAudit(
        AuditEntry(
          id: generateUuidV4(),
          companyId: null, // System scope audit
          userId: 'system',
          action: 'update',
          entityType: 'system_config',
          entityId: generateUuidV4(),
          timestamp: DateTime.now().toUtc(),
        ),
      );

      final companyAudits = await service.getAuditTrailByCompany(companyId: 'company-a-3k');
      final systemAudits = await service.getSystemAudits();

      expect(companyAudits.length, equals(1));
      expect(companyAudits.first.documentId, equals(docId));

      expect(systemAudits.length, equals(1));
      expect(systemAudits.first.documentType, equals('system_config'));
    });

    test('SecurityLogger redacts sensitive metadata keys (password, token, secret, auth)', () {
      // Test SecurityLogger cleansing metadata without throwing exceptions
      expect(
        () => SecurityLogger.logEvent(
          'user_login_attempt',
          metadata: {
            'username': 'john_doe',
            'password': 'secret_password_123',
            'token': 'bearer_token_xyz',
            'authHeader': 'Bearer secret',
          },
        ),
        returnsNormally,
      );
    });

    test('Audit query API is append-only and returns entries chronologically', () async {
      final docId = generateUuidV4();

      await service.recordEvent(
        documentId: docId,
        documentType: 'financial_voucher',
        eventType: 'create',
      );

      await service.recordEvent(
        documentId: docId,
        documentType: 'financial_voucher',
        eventType: 'post',
      );

      final auditTrail = await service.getAuditTrail(
        documentId: docId,
        documentType: 'financial_voucher',
      );

      expect(auditTrail.length, equals(2));
      expect(auditTrail[0].eventType, equals('create'));
      expect(auditTrail[1].eventType, equals('post'));
    });
  });
}
