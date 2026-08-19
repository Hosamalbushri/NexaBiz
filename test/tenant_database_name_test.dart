import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/database/tenant_database_name.dart';

void main() {
  const base = 'accounting_accounts';
  const otherCompany = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

  group('tenantDbName', () {
    test('keeps historical name when company is empty', () {
      expect(tenantDbName(base), base);
      expect(tenantDbName(base, companyId: ''), base);
      expect(tenantDbName(base, companyId: '  '), base);
    });

    test(
      'tenantScopedName keeps historical names for the bootstrap company',
      () {
        expect(tenantScopedName(base, null), base);
        expect(tenantScopedName(base, kLegacyLocalCompanyId), base);
      },
    );

    test(
      'tenantScopedName isolates a second company from the bootstrap files',
      () {
        expect(tenantScopedName(base, otherCompany), isNot(base));
        expect(
          tenantScopedName(base, otherCompany),
          isNot(tenantScopedName(base, kLegacyLocalCompanyId)),
        );
      },
    );

    test('suffixes a hex company id for other tenants', () {
      expect(
        tenantDbName(
          base,
          companyId: otherCompany,
          legacyCompanyId: kLegacyLocalCompanyId,
        ),
        '${base}_aaaaaaaaaaaa4aaa8aaaaaaaaaaaaaaa',
      );
    });

    test('normalizes mixed-case UUIDs and strips non-hex', () {
      expect(
        tenantDbName(
          'sales_master',
          companyId: 'BBBBBBBB-BBBB-4BBB-8BBB-BBBBBBBBBBBB',
          legacyCompanyId: kLegacyLocalCompanyId,
        ),
        'sales_master_bbbbbbbbbbbb4bbb8bbbbbbbbbbbbbbb',
      );
    });

    test('falls back to the base name when the id is too short', () {
      expect(
        tenantDbName(
          base,
          companyId: 'abc-12',
          legacyCompanyId: kLegacyLocalCompanyId,
        ),
        base,
      );
    });
  });
}
