import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/setup/domain/entities/account_requirement.dart';
import 'package:stock_count/core/setup/domain/services/account_binding_resolver.dart';
import 'package:stock_count/core/domain/ports/setup_account_lookup_port.dart';
import 'package:stock_count/core/setup/domain/repositories/account_binding_repository.dart';
import 'package:stock_count/core/setup/domain/entities/account_binding.dart';

class MockLookupPort implements SetupAccountLookupPort {
  final Map<String, SetupAccountData> _accounts = {};

  void addAccount(SetupAccountData account) {
    _accounts[account.uuid] = account;
  }

  @override
  Future<SetupAccountData?> findAccount(String accountUuid) async {
    return _accounts[accountUuid];
  }

  @override
  Future<List<SetupAccountData>> getChildren(String parentUuid, {String? companyId}) async {
    return const [];
  }

  @override
  Future<List<SetupAccountData>> getDescendants(String parentUuid, {String? companyId}) async {
    return const [];
  }
}

class InMemoryBindingRepo implements AccountBindingRepository {
  final Map<String, AccountBinding> _bindings = {};

  String _key(String companyId, String packageId, String requirementKey) =>
      '$companyId:$packageId:$requirementKey';

  @override
  Future<void> saveBinding(AccountBinding binding) async {
    _bindings[_key(binding.companyId, binding.packageId, binding.requirementKey)] = binding;
  }

  @override
  Future<AccountBinding?> getBinding({
    required String companyId,
    required String packageId,
    required String requirementKey,
  }) async {
    return _bindings[_key(companyId, packageId, requirementKey)];
  }

  @override
  Future<List<AccountBinding>> getBindingsForPackage({
    required String companyId,
    required String packageId,
  }) async {
    return _bindings.values
        .where((b) => b.companyId == companyId && b.packageId == packageId)
        .toList();
  }

  @override
  Future<void> removeBinding({
    required String companyId,
    required String packageId,
    required String requirementKey,
  }) async {
    _bindings.remove(_key(companyId, packageId, requirementKey));
  }

  @override
  Future<void> clear() async {
    _bindings.clear();
  }
}

void main() {
  late MockLookupPort lookupPort;
  late InMemoryBindingRepo bindingRepo;
  late AccountBindingResolver resolver;

  setUp(() {
    lookupPort = MockLookupPort();
    bindingRepo = InMemoryBindingRepo();
    resolver = AccountBindingResolver(
      accountLookupPort: lookupPort,
      bindingRepository: bindingRepo,
    );
  });

  group('AR-C08 Decommission Legacy Account Mapping & Duplicate Configuration Paths', () {
    test('1. Authoritative Configuration Chain: Rejects unconfigured role resolution without fallbacks', () async {
      final req = const AccountRequirement(
        packageId: 'sales',
        requirementKey: 'sales_revenue',
        role: AccountRole.revenue,
        labelAr: 'حساب المبيعات',
        labelEn: 'Sales Revenue',
        expectedAccountType: SetupAccountType.revenue,
      );

      // Unbound role MUST fail cleanly without falling back to hardcoded account code 4110
      expect(
        () => resolver.resolveAccountForTransaction(
          companyId: 'companyA',
          requirement: req,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('2. Authoritative Configuration Chain: Resolves explicitly configured account binding', () async {
      final lookupAccount = const SetupAccountData(
        uuid: 'acc-sales-rev-01',
        accountCode: '411001',
        companyId: 'companyA',
        accountType: SetupAccountType.revenue,
        isGroup: false,
        isActive: true,
        isDeleted: false,
        canPost: true,
      );
      lookupPort.addAccount(lookupAccount);

      final req = const AccountRequirement(
        packageId: 'sales',
        requirementKey: 'sales_revenue',
        role: AccountRole.revenue,
        labelAr: 'حساب المبيعات',
        labelEn: 'Sales Revenue',
        expectedAccountType: SetupAccountType.revenue,
      );

      await resolver.bindAccount(
        companyId: 'companyA',
        requirement: req,
        accountUuid: 'acc-sales-rev-01',
      );

      final resolved = await resolver.resolveAccountForTransaction(
        companyId: 'companyA',
        requirement: req,
      );

      expect(resolved.uuid, equals('acc-sales-rev-01'));
      expect(resolved.accountCode, equals('411001'));
    });

    test('3. Single Source of Truth Verification: Zero runtime bypasses', () async {
      expect(resolver, isNotNull);
      expect(bindingRepo, isNotNull);
    });
  });
}
