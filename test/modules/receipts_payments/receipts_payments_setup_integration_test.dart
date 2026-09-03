import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/ports/setup_account_lookup_port.dart';
import 'package:stock_count/core/setup/setup.dart';
import 'package:stock_count/modules/receipts_payments/receipts_payments_module.dart';
import 'package:stock_count/modules/receipts_payments/receipts_payments_module_setup.dart';

class FakeSetupAccountLookupPort implements SetupAccountLookupPort {
  FakeSetupAccountLookupPort(this.accounts);

  final Map<String, SetupAccountData> accounts;

  @override
  Future<SetupAccountData?> findAccount(String codeOrUuidOrId) async {
    return accounts[codeOrUuidOrId.trim()];
  }
}

void main() {
  group('Phase 6 — Receipts & Payments Setup Integration Tests', () {
    late CentralSetupRegistry registry;
    late InMemoryAccountBindingRepository bindingRepository;
    late FakeSetupAccountLookupPort lookupPort;
    late AccountBindingResolver resolver;

    const companyA = 'company_A';
    const companyB = 'company_B';

    const validCashAccount = SetupAccountData(
      uuid: 'uuid_cash_1010',
      accountCode: '1010',
      accountType: SetupAccountType.asset,
      companyId: companyA,
      isActive: true,
      isDeleted: false,
      isGroup: false,
      canPost: true,
    );

    const crossCompanyAccount = SetupAccountData(
      uuid: 'uuid_cash_cross_999',
      accountCode: '1010',
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
        validCashAccount.uuid: validCashAccount,
        crossCompanyAccount.uuid: crossCompanyAccount,
      });
      resolver = AccountBindingResolver(
        accountLookupPort: lookupPort,
        bindingRepository: bindingRepository,
      );
    });

    test('1. CentralSetupRegistry discovers Receipts & Payments setup via module registration', () {
      ReceiptsPaymentsModule.register(setupRegistry: registry);

      expect(registry.isRegistered('receipts_payments'), isTrue);

      final setup = registry.get('receipts_payments');
      expect(setup, isNotNull);
      expect(setup!.packageId, equals('receipts_payments'));
      expect(setup.displayName('ar'), equals('إعدادات السندات والخزينة'));
      expect(setup.displayName('en'), equals('Receipts & Payments Setup'));
      expect(setup.sortOrder, equals(50));
    });

    test('2. Setup definition exposes treasury_defaults and account_requirements sections', () {
      registerReceiptsPaymentsSetup(registry);

      final setup = registry.get('receipts_payments')!;
      final sectionIds = setup.sections.map((s) => s.id).toList();

      expect(sectionIds, containsAll(['treasury_defaults', 'account_requirements']));

      final treasurySection = setup.sections.firstWhere((s) => s.id == 'treasury_defaults');
      expect(
        treasurySection.fields.map((f) => f.key),
        containsAll(['requireCheckNumber', 'allowNegativeTreasuryBalance']),
      );
    });

    test('3. Binds Cash account requirement successfully with UUID reference', () async {
      final binding = await resolver.bindAccount(
        companyId: companyA,
        requirement: rpCashAccountRequirement,
        accountUuid: validCashAccount.uuid,
      );

      expect(binding.status, equals(AccountBindingStatus.bound));
      expect(binding.accountUuid, equals('uuid_cash_1010'));
    });

    test('4. Missing account invariant — safe init; controlled exception on transaction attempt', () async {
      final result = await resolver.resolveRequirement(
        companyId: companyA,
        requirement: rpCashAccountRequirement,
      );

      expect(result.isUnbound, isTrue);

      expect(
        () async => resolver.resolveAccountForTransaction(
          companyId: companyA,
          requirement: rpCashAccountRequirement,
        ),
        throwsA(isA<AccountBindingException>()),
      );
    });

    test('5. Multi-tenant company isolation rejects cross-company account assignment', () async {
      expect(
        () async => resolver.bindAccount(
          companyId: companyA,
          requirement: rpCashAccountRequirement,
          accountUuid: crossCompanyAccount.uuid,
        ),
        throwsA(isA<CrossCompanyAccountBindingException>()),
      );
    });
  });
}
