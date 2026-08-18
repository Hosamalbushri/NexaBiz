import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/tenant_database_name.dart';
import 'package:stock_count/modules/authentication/domain/local_permissions.dart';

void main() {
  const base = 'accounting_accounts';
  const otherCompany = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

  group('tenantDbName', () {
    test('keeps historical name when company is empty', () {
      expect(tenantDbName(base), base);
      expect(tenantDbName(base, companyId: ''), base);
      expect(tenantDbName(base, companyId: '  '), base);
    });

    test('keeps historical name for the bootstrap local company', () {
      expect(
        tenantDbName(
          base,
          companyId: LocalAuthDefaults.companyId,
          legacyCompanyId: LocalAuthDefaults.companyId,
        ),
        base,
      );
    });

    test('suffixes a hex company id for other tenants', () {
      expect(
        tenantDbName(
          base,
          companyId: otherCompany,
          legacyCompanyId: LocalAuthDefaults.companyId,
        ),
        '${base}_aaaaaaaaaaaa4aaa8aaaaaaaaaaaaaaa',
      );
    });

    test('normalizes mixed-case UUIDs and strips non-hex', () {
      expect(
        tenantDbName(
          'sales_master',
          companyId: 'BBBBBBBB-BBBB-4BBB-8BBB-BBBBBBBBBBBB',
          legacyCompanyId: LocalAuthDefaults.companyId,
        ),
        'sales_master_bbbbbbbbbbbb4bbb8bbbbbbbbbbbbbbb',
      );
    });

    test('falls back to the base name when the id is too short', () {
      expect(
        tenantDbName(
          base,
          companyId: 'abc-12',
          legacyCompanyId: LocalAuthDefaults.companyId,
        ),
        base,
      );
    });
  });
}
