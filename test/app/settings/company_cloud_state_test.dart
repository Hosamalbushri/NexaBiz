import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/settings/company/company_cloud_state.dart';

void main() {
  group('CompanyCloudState Tests', () {
    test('default CompanyCloudState is localOnly', () {
      final state = CompanyCloudState.localDefault('company-123');
      expect(state.localCompanyId, equals('company-123'));
      expect(state.cloudStatus, equals(CompanyCloudStatus.localOnly));
      expect(state.isLocalOnly, isTrue);
      expect(state.isCloudReady, isFalse);
      expect(state.serverCompanyId, isNull);
    });

    test('CompanyCloudStatus serialization and deserialization', () {
      expect(CompanyCloudStatus.fromString('LOCAL_ONLY'), equals(CompanyCloudStatus.localOnly));
      expect(CompanyCloudStatus.fromString('PROVISIONING'), equals(CompanyCloudStatus.provisioning));
      expect(CompanyCloudStatus.fromString('CLOUD_ADMIN_LINKED'), equals(CompanyCloudStatus.cloudAdminLinked));
      expect(CompanyCloudStatus.fromString('CLOUD_READY'), equals(CompanyCloudStatus.cloudReady));

      expect(CompanyCloudStatus.cloudReady.toDbString(), equals('CLOUD_READY'));
      expect(CompanyCloudStatus.localOnly.toDbString(), equals('LOCAL_ONLY'));
    });

    test('CompanyCloudState map serialization', () {
      final state = CompanyCloudState(
        localCompanyId: 'comp-abc',
        serverCompanyId: 'srv-comp-999',
        cloudStatus: CompanyCloudStatus.cloudReady,
        subscriptionId: 'sub-777',
        planId: 'plan_starter',
        cloudLinkedAt: DateTime.parse('2026-08-26T00:00:00.000Z'),
      );

      final map = state.toMap();
      expect(map['localCompanyId'], equals('comp-abc'));
      expect(map['serverCompanyId'], equals('srv-comp-999'));
      expect(map['cloudStatus'], equals('CLOUD_READY'));

      final restored = CompanyCloudState.fromMap(map, 'comp-abc');
      expect(restored.localCompanyId, equals('comp-abc'));
      expect(restored.serverCompanyId, equals('srv-comp-999'));
      expect(restored.cloudStatus, equals(CompanyCloudStatus.cloudReady));
      expect(restored.isCloudReady, isTrue);
      expect(restored.isCloudLinked, isTrue);
    });
  });
}
