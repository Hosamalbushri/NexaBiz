import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/audit/domain/ports/audit_repository_port.dart';
import 'package:stock_count/core/audit/domain/services/audit_trail_service.dart';
import 'package:stock_count/core/auth/ports/session_context_port.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/data/repositories/inventory_audit_repository.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';

class _FakeSessionContext implements SessionContextPort {
  _FakeSessionContext({
    this.currentCompanyId = 'company_alpha',
    this.userId = 'user_001',
  });

  @override
  final String? currentCompanyId;
  @override
  final String? activeCompanyId = null;
  @override
  final List<CompanyInfo> companies = const [];
  @override
  final bool isAuthenticated = true;
  @override
  final String? userId;
  @override
  final String? deviceId = 'dev_001';
  @override
  final bool isStandalone = false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InventoryDatabase db;
  late InventoryAuditRepository repository;
  late AuditTrailService service;
  const companyAlpha = 'company_alpha';
  const companyBeta = 'company_beta';

  setUp(() {
    db = InventoryDatabase.memory();
    repository = InventoryAuditRepository(db);
    service = AuditTrailService(
      repository: repository,
      sessionContext: _FakeSessionContext(currentCompanyId: companyAlpha),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('InventoryAuditRepository & Decoupled AuditTrailService Unit Tests', () {
    test('1. Record audit entry and retrieve by company ID', () async {
      final id1 = generateUuidV4();
      final entry = AuditEntry(
        id: id1,
        companyId: companyAlpha,
        userId: 'usr_1',
        action: 'create',
        entityType: 'stock_receipt',
        entityId: 'rec_100',
        metadata: const {'notes': 'Created stock receipt 100'},
        timestamp: DateTime.now().toUtc(),
      );

      await repository.record(entry);

      final fetched = await repository.getForCompany(companyAlpha);
      expect(fetched.length, equals(1));
      expect(fetched.first.id, equals(id1));
      expect(fetched.first.companyId, equals(companyAlpha));
      expect(fetched.first.entityId, equals('rec_100'));
      expect(fetched.first.action, equals('create'));
    });

    test('2. System audits with NULL companyId survive and can be queried', () async {
      final sysId = generateUuidV4();
      final systemEntry = AuditEntry(
        id: sysId,
        companyId: null,
        userId: 'system_admin',
        action: 'system_bootstrap',
        entityType: 'system',
        entityId: 'sys_001',
        metadata: const {'notes': 'System initialized'},
        timestamp: DateTime.now().toUtc(),
      );

      await repository.record(systemEntry);

      final systemAudits = await repository.getSystemAudits();
      expect(systemAudits.length, equals(1));
      expect(systemAudits.first.id, equals(sysId));
      expect(systemAudits.first.companyId, isNull);

      final companyAudits = await repository.getForCompany(companyAlpha);
      expect(companyAudits, isEmpty);
    });

    test('3. Query audit entries for a specific entity', () async {
      final id2 = generateUuidV4();
      final id3 = generateUuidV4();
      await repository.record(
        AuditEntry(
          id: id2,
          companyId: companyAlpha,
          userId: 'usr_1',
          action: 'post',
          entityType: 'stock_issue',
          entityId: 'issue_500',
          metadata: const {'notes': 'Posted issue'},
          timestamp: DateTime.now().toUtc(),
        ),
      );

      await repository.record(
        AuditEntry(
          id: id3,
          companyId: companyBeta,
          userId: 'usr_2',
          action: 'post',
          entityType: 'stock_issue',
          entityId: 'issue_500',
          metadata: const {'notes': 'Other company issue'},
          timestamp: DateTime.now().toUtc(),
        ),
      );

      final entityAudits = await repository.getForEntity(
        'stock_issue',
        'issue_500',
        companyId: companyAlpha,
      );

      expect(entityAudits.length, equals(1));
      expect(entityAudits.first.id, equals(id2));
    });

    test('4. AuditTrailService records and retrieves audit logs seamlessly', () async {
      final event = await service.recordEvent(
        documentId: 'doc_123',
        documentType: 'journal_entry',
        eventType: 'post',
        notes: 'Posted via service',
        metadata: const {'amount': 1500},
      );

      expect(event.uuid, isNotEmpty);

      final trail = await service.getAuditTrail(documentId: 'doc_123');
      expect(trail.length, equals(1));
      expect(trail.first.documentId, equals('doc_123'));
      expect(trail.first.documentType, equals('journal_entry'));
      expect(trail.first.eventType, equals('post'));
      expect(trail.first.companyId, equals(companyAlpha));
    });
  });
}
