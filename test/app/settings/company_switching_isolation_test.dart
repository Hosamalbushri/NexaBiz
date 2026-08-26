import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/settings/company/company_cloud_state.dart';

void main() {
  group('Company Switching Isolation Tests', () {
    test('Company A cloud status does not leak to Company B', () {
      final companyA = CompanyCloudState(
        localCompanyId: 'company-a',
        serverCompanyId: 'server-a-999',
        cloudStatus: CompanyCloudStatus.cloudReady,
        subscriptionId: 'sub-a-1',
        planId: 'plan_starter',
      );

      final companyB = CompanyCloudState.localDefault('company-b');

      expect(companyA.isCloudReady, isTrue);
      expect(companyA.isCloudLinked, isTrue);
      expect(companyA.serverCompanyId, equals('server-a-999'));

      expect(companyB.isLocalOnly, isTrue);
      expect(companyB.isCloudReady, isFalse);
      expect(companyB.isCloudLinked, isFalse);
      expect(companyB.serverCompanyId, isNull);
    });
  });
}
