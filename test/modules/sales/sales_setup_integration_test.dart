import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/ports/setup_account_lookup_port.dart';
import 'package:stock_count/core/setup/setup.dart';
import 'package:stock_count/modules/sales/sales_module.dart';
import 'package:stock_count/modules/sales/sales_module_setup.dart';

class FakeSetupAccountLookupPort implements SetupAccountLookupPort {
  FakeSetupAccountLookupPort(this.accounts);

  final Map<String, SetupAccountData> accounts;

  @override
  Future<SetupAccountData?> findAccount(String codeOrUuidOrId) async {
    return accounts[codeOrUuidOrId.trim()];
  }
}

void main() {
  group('Phase 6 — Sales Setup Integration Tests', () {
    late CentralSetupRegistry registry;
    late InMemoryAccountBindingRepository bindingRepository;
    late FakeSetupAccountLookupPort lookupPort;
    late AccountBindingResolver resolver;

    const companyA = 'company_A';
    const companyB = 'company_B';

    const validSalesAccount = SetupAccountData(
      uuid: 'uuid_sales_400',
      accountCode: '4100',
      accountType: SetupAccountType.revenue,
      companyId: companyA,
      isActive: true,
      isDeleted: false,
      isGroup: false,
      canPost: true,
    );

    const crossCompanyAccount = SetupAccountData(
      uuid: 'uuid_sales_cross_999',
      accountCode: '4100',
      accountType: SetupAccountType.revenue,
      companyId: companyB,
      isActive: true,
      isDeleted: false,
      isGroup: false,
      canPost: true,
    );

    setUp(() {
      registry = CentralSetupRegistry();
      bindingRepository = InMemoryAccountBindingRepository();
      lookupPort = FakeSetupAccountLookupPort({
        validSalesAccount.uuid: validSalesAccount,
        crossCompanyAccount.uuid: crossCompanyAccount,
      });
      resolver = AccountBindingResolver(
        accountLookupPort: lookupPort,
        bindingRepository: bindingRepository,
      );
    });

    test('1. CentralSetupRegistry discovers Sales setup via module registration', () {
      SalesModule.register(setupRegistry: registry);

      expect(registry.isRegistered('sales'), isTrue);

      final setup = registry.get('sales');
      expect(setup, isNotNull);
      expect(setup!.packageId, equals('sales'));
      expect(setup.displayName('ar'), equals('إعدادات المبيعات'));
      expect(setup.displayName('en'), equals('Sales Setup'));
      expect(setup.sortOrder, equals(30));
    });

    test('2. Sales setup definition exposes policies and account_requirements sections', () {
      registerSalesSetup(registry);

      final setup = registry.get('sales')!;
      final sectionIds = setup.sections.map((s) => s.id).toList();

      expect(sectionIds, containsAll(['policies', 'account_requirements']));

      final policiesSection = setup.sections.firstWhere((s) => s.id == 'policies');
      expect(
        policiesSection.fields.map((f) => f.key),
        containsAll(['defaultTaxRate', 'allowPriceOverride', 'allowInvoiceDiscount']),
      );
    });

    test('3. Binds Sales account requirement successfully with UUID reference', () async {
      final binding = await resolver.bindAccount(
        companyId: companyA,
        requirement: salesAccountRequirement,
        accountUuid: validSalesAccount.uuid,
      );

      expect(binding.status, equals(AccountBindingStatus.bound));
      expect(binding.accountUuid, equals('uuid_sales_400'));
    });

    test('4. Missing account invariant — safe init; controlled exception on transaction attempt', () async {
      final result = await resolver.resolveRequirement(
        companyId: companyA,
        requirement: salesAccountRequirement,
      );

      expect(result.isUnbound, isTrue);

      expect(
        () async => resolver.resolveAccountForTransaction(
          companyId: companyA,
          requirement: salesAccountRequirement,
        ),
        throwsA(isA<AccountBindingException>()),
      );
    });

    test('5. Multi-tenant company isolation rejects cross-company account assignment', () async {
      expect(
        () async => resolver.bindAccount(
          companyId: companyA,
          requirement: salesAccountRequirement,
          accountUuid: crossCompanyAccount.uuid,
        ),
        throwsA(isA<CrossCompanyAccountBindingException>()),
      );
    });
  });
}
