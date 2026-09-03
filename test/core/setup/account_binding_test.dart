import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/domain/ports/setup_account_lookup_port.dart';
import 'package:stock_count/core/setup/setup.dart';

class FakeLookupPort implements SetupAccountLookupPort {
  FakeLookupPort(this.accounts);

  final Map<String, SetupAccountData> accounts;

  @override
  Future<SetupAccountData?> findAccount(String codeOrUuidOrId) async {
    return accounts[codeOrUuidOrId.trim()];
  }

  @override
  Future<List<SetupAccountData>> getChildren(String parentUuid, {String? companyId}) async {
    return [];
  }

  @override
  Future<List<SetupAccountData>> getDescendants(String parentUuid, {String? companyId}) async {
    return [];
  }
}

void main() {
  group('Phase 4 — Default Account Requirements & Account Binding Tests', () {
    late InMemoryAccountBindingRepository repository;
    late FakeLookupPort lookupPort;
    late AccountBindingResolver resolver;

    const companyA = 'company_A';
    const companyB = 'company_B';

    const validAccountA = SetupAccountData(
      uuid: 'uuid_acc_100',
      accountCode: '1230',
      accountType: SetupAccountType.asset,
      companyId: companyA,
      isActive: true,
      isDeleted: false,
      isGroup: false,
      canPost: true,
    );

    const validAccountB = SetupAccountData(
      uuid: 'uuid_acc_200',
      accountCode: '1230',
      accountType: SetupAccountType.asset,
      companyId: companyB,
      isActive: true,
      isDeleted: false,
      isGroup: false,
      canPost: true,
    );

    const deletedAccountA = SetupAccountData(
      uuid: 'uuid_acc_300',
      accountCode: '1235',
      accountType: SetupAccountType.asset,
      companyId: companyA,
      isActive: true,
      isDeleted: true,
      isGroup: false,
      canPost: true,
    );

    const inventoryRequirement = AccountRequirement(
      packageId: 'inventory',
      requirementKey: 'inventory_asset_account',
      role: AccountRole.inventory,
      labelAr: 'حساب المخزون',
      labelEn: 'Inventory Account',
      isRequired: true,
      expectedAccountType: SetupAccountType.asset,
    );

    setUp(() {
      repository = InMemoryAccountBindingRepository();
      lookupPort = FakeLookupPort({
        validAccountA.uuid: validAccountA,
        validAccountB.uuid: validAccountB,
        deletedAccountA.uuid: deletedAccountA,
      });
      resolver = AccountBindingResolver(
        accountLookupPort: lookupPort,
        bindingRepository: repository,
      );
    });

    test('1. Account exists -> binding succeeds', () async {
      final binding = await resolver.bindAccount(
        companyId: companyA,
        requirement: inventoryRequirement,
        accountUuid: validAccountA.uuid,
      );

      expect(binding.status, equals(AccountBindingStatus.bound));
      expect(binding.accountUuid, equals('uuid_acc_100'));

      final result = await resolver.resolveRequirement(
        companyId: companyA,
        requirement: inventoryRequirement,
      );

      expect(result.status, equals(AccountBindingStatus.bound));
      expect(result.isBound, isTrue);
      expect(result.account?.uuid, equals('uuid_acc_100'));
    });

    test('2. Account missing -> no package initialization failure', () async {
      final result = await resolver.resolveRequirement(
        companyId: companyA,
        requirement: inventoryRequirement,
      );

      expect(result.status, equals(AccountBindingStatus.unbound));
      expect(result.isUnbound, isTrue);
      expect(result.account, isNull);
    });

    test('3. Missing required account -> setup status evaluated as needsAttention/notConfigured', () async {
      final result = await resolver.resolveRequirement(
        companyId: companyA,
        requirement: inventoryRequirement,
      );

      final status = result.isBound
          ? SetupStatus.configured
          : (inventoryRequirement.isRequired
              ? SetupStatus.partiallyConfigured
              : SetupStatus.notConfigured);

      expect(status, equals(SetupStatus.partiallyConfigured));
    });

    test('4. Missing required account during transaction -> controlled AccountBindingException thrown', () async {
      expect(
        () async => resolver.resolveAccountForTransaction(
          companyId: companyA,
          requirement: inventoryRequirement,
        ),
        throwsA(isA<AccountBindingException>()),
      );
    });

    test('5. Account from another company -> rejected with CrossCompanyAccountBindingException', () async {
      expect(
        () async => resolver.bindAccount(
          companyId: companyA,
          requirement: inventoryRequirement,
          accountUuid: validAccountB.uuid, // belongs to companyB
        ),
        throwsA(isA<CrossCompanyAccountBindingException>()),
      );
    });

    test('6. Stale/Deleted account -> detected as invalidStale', () async {
      await repository.saveBinding(
        const AccountBinding(
          companyId: companyA,
          packageId: 'inventory',
          requirementKey: 'inventory_asset_account',
          accountUuid: 'uuid_acc_300', // deleted account
          status: AccountBindingStatus.bound,
        ),
      );

      final result = await resolver.resolveRequirement(
        companyId: companyA,
        requirement: inventoryRequirement,
      );

      expect(result.status, equals(AccountBindingStatus.invalidStale));
      expect(result.isInvalidStale, isTrue);
      expect(result.account, isNull);
    });

    test('7. Bound account UUID persists across repository operations', () async {
      await resolver.bindAccount(
        companyId: companyA,
        requirement: inventoryRequirement,
        accountUuid: validAccountA.uuid,
      );

      final bindings = await repository.getBindingsForPackage(
        companyId: companyA,
        packageId: 'inventory',
      );

      expect(bindings.length, equals(1));
      expect(bindings.first.accountUuid, equals('uuid_acc_100'));
      expect(bindings.first.companyId, equals(companyA));
    });

    test('8. Permanent reference uses UUID (no hardcoded account code)', () async {
      final binding = await resolver.bindAccount(
        companyId: companyA,
        requirement: inventoryRequirement,
        accountUuid: validAccountA.uuid,
      );

      expect(binding.accountUuid, equals(validAccountA.uuid));
      expect(binding.accountUuid, isNot(equals(validAccountA.accountCode)));
    });
  });
}
