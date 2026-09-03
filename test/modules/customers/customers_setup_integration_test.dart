import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/ports/setup_account_lookup_port.dart';
import 'package:stock_count/core/setup/setup.dart';
import 'package:stock_count/modules/customers/customers_module.dart';
import 'package:stock_count/modules/customers/customers_module_setup.dart';

class FakeSetupAccountLookupPort implements SetupAccountLookupPort {
  FakeSetupAccountLookupPort(this.accounts);

  final Map<String, SetupAccountData> accounts;

  @override
  Future<SetupAccountData?> findAccount(String codeOrUuidOrId) async {
    return accounts[codeOrUuidOrId.trim()];
  }
}

void main() {
  group('Phase 6 — Customers Setup Integration Tests', () {
    late CentralSetupRegistry registry;
    late InMemoryAccountBindingRepository bindingRepository;
    late FakeSetupAccountLookupPort lookupPort;
    late AccountBindingResolver resolver;

    const companyA = 'company_A';
    const companyB = 'company_B';

    const validArAccount = SetupAccountData(
      uuid: 'uuid_ar_1100',
      accountCode: '1100',
      accountType: SetupAccountType.asset,
      companyId: companyA,
      isActive: true,
      isDeleted: false,
      isGroup: false,
      canPost: true,
    );

    const crossCompanyAccount = SetupAccountData(
      uuid: 'uuid_ar_cross_999',
      accountCode: '1100',
      accountType: SetupAccountType.asset,
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
        validArAccount.uuid: validArAccount,
        crossCompanyAccount.uuid: crossCompanyAccount,
      });
      resolver = AccountBindingResolver(
        accountLookupPort: lookupPort,
        bindingRepository: bindingRepository,
      );
    });

    test('1. CentralSetupRegistry discovers Customers setup via module registration', () {
      CustomersModule.register(setupRegistry: registry);

      expect(registry.isRegistered('customers'), isTrue);

      final setup = registry.get('customers');
      expect(setup, isNotNull);
      expect(setup!.packageId, equals('customers'));
      expect(setup.displayName('ar'), equals('إعدادات العملاء'));
      expect(setup.displayName('en'), equals('Customers Setup'));
      expect(setup.sortOrder, equals(40));
    });

    test('2. Customers setup definition exposes policies and account_requirements sections', () {
      registerCustomersSetup(registry);

      final setup = registry.get('customers')!;
      final sectionIds = setup.sections.map((s) => s.id).toList();

      expect(sectionIds, containsAll(['policies', 'account_requirements']));

      final policiesSection = setup.sections.firstWhere((s) => s.id == 'policies');
      expect(
        policiesSection.fields.map((f) => f.key),
        containsAll(['defaultCreditLimit', 'autoLinkAccounts', 'requireTaxNumber']),
      );
    });

    test('3. Binds Customers AR account requirement successfully with UUID reference', () async {
      final binding = await resolver.bindAccount(
        companyId: companyA,
        requirement: arAccountRequirement,
        accountUuid: validArAccount.uuid,
      );

      expect(binding.status, equals(AccountBindingStatus.bound));
      expect(binding.accountUuid, equals('uuid_ar_1100'));
    });

    test('4. Missing account invariant — safe init; controlled exception on transaction attempt', () async {
      final result = await resolver.resolveRequirement(
        companyId: companyA,
        requirement: arAccountRequirement,
      );

      expect(result.isUnbound, isTrue);

      expect(
        () async => resolver.resolveAccountForTransaction(
          companyId: companyA,
          requirement: arAccountRequirement,
        ),
        throwsA(isA<AccountBindingException>()),
      );
    });

    test('5. Multi-tenant company isolation rejects cross-company account assignment', () async {
      expect(
        () async => resolver.bindAccount(
          companyId: companyA,
          requirement: arAccountRequirement,
          accountUuid: crossCompanyAccount.uuid,
        ),
        throwsA(isA<CrossCompanyAccountBindingException>()),
      );
    });
  });
}
