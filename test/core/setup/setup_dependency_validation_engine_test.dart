import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/core/domain/ports/setup_account_lookup_port.dart';
import 'package:stock_count/core/setup/setup.dart';

class MockAccountLookupPort implements SetupAccountLookupPort {
  final Map<String, SetupAccountData> accounts = {};

  @override
  Future<SetupAccountData?> findAccount(String accountUuid) async {
    return accounts[accountUuid];
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

class InMemoryAccountBindingRepository implements AccountBindingRepository {
  final Map<String, AccountBinding> bindings = {};

  String _key(String companyId, String packageId, String requirementKey) =>
      '$companyId:$packageId:$requirementKey';

  @override
  Future<AccountBinding?> getBinding({
    required String companyId,
    required String packageId,
    required String requirementKey,
  }) async {
    return bindings[_key(companyId, packageId, requirementKey)];
  }

  @override
  Future<List<AccountBinding>> getBindingsForCompany(String companyId) async {
    return bindings.values.where((b) => b.companyId == companyId).toList();
  }

  @override
  Future<List<AccountBinding>> getBindingsForPackage({
    required String companyId,
    required String packageId,
  }) async {
    return bindings.values
        .where((b) => b.companyId == companyId && b.packageId == packageId)
        .toList();
  }

  @override
  Future<void> saveBinding(AccountBinding binding) async {
    bindings[_key(binding.companyId, binding.packageId, binding.requirementKey)] = binding;
  }

  @override
  Future<void> removeBinding({
    required String companyId,
    required String packageId,
    required String requirementKey,
  }) async {
    bindings.remove(_key(companyId, packageId, requirementKey));
  }

  @override
  Future<void> clear() async {
    bindings.clear();
  }
}

void main() {
  group('Phase 8 — Setup Dependencies & Validation Engine Tests', () {
    late CentralSetupRegistry registry;
    late SetupDependencyEngine dependencyEngine;
    late MockAccountLookupPort mockAccountLookup;
    late InMemoryAccountBindingRepository bindingRepository;
    late CentralSetupValidationEngine validationEngine;
    late TransactionSetupValidator transactionValidator;

    const companyId = 'company_tenant_1';

    setUp(() {
      registry = CentralSetupRegistry();
      dependencyEngine = const SetupDependencyEngine();
      mockAccountLookup = MockAccountLookupPort();
      bindingRepository = InMemoryAccountBindingRepository();
      validationEngine = CentralSetupValidationEngine(
        accountLookupPort: mockAccountLookup,
        bindingRepository: bindingRepository,
        dependencyEngine: dependencyEngine,
      );
      transactionValidator = TransactionSetupValidator(
        accountLookupPort: mockAccountLookup,
        bindingRepository: bindingRepository,
      );
    });

    test('1. Dependency ordering — Topological sorting places prerequisites before dependents', () {
      const accountingDef = PackageSetupDefinition(
        packageId: 'accounting',
        displayNameAr: 'المحاسبة',
        displayNameEn: 'Accounting',
        sortOrder: 10,
      );

      const coaDef = PackageSetupDefinition(
        packageId: 'chart_of_accounts',
        displayNameAr: 'دليل الحسابات',
        displayNameEn: 'Chart of Accounts',
        sortOrder: 15,
        dependencies: [
          SetupDependency(targetPackageId: 'accounting', dependencyType: SetupDependencyType.required),
        ],
      );

      const inventoryDef = PackageSetupDefinition(
        packageId: 'inventory',
        displayNameAr: 'المخزون',
        displayNameEn: 'Inventory',
        sortOrder: 20,
        dependencies: [
          SetupDependency(targetPackageId: 'chart_of_accounts', dependencyType: SetupDependencyType.required),
        ],
      );

      const salesDef = PackageSetupDefinition(
        packageId: 'sales',
        displayNameAr: 'المبيعات',
        displayNameEn: 'Sales',
        sortOrder: 30,
        dependencies: [
          SetupDependency(targetPackageId: 'inventory', dependencyType: SetupDependencyType.required),
        ],
      );

      // Register out of topological order
      registry.register(salesDef);
      registry.register(inventoryDef);
      registry.register(accountingDef);
      registry.register(coaDef);

      final ordered = dependencyEngine.getExecutionOrder(registry.getAll());
      final orderedIds = ordered.map((d) => d.packageId).toList();

      expect(orderedIds, equals(['accounting', 'chart_of_accounts', 'inventory', 'sales']));
    });

    test('2. Missing dependency — Unregistered required dependency throws MissingSetupDependencyException', () {
      const salesDef = PackageSetupDefinition(
        packageId: 'sales',
        displayNameAr: 'المبيعات',
        displayNameEn: 'Sales',
        dependencies: [
          SetupDependency(targetPackageId: 'unregistered_inventory', dependencyType: SetupDependencyType.required),
        ],
      );

      registry.register(salesDef);

      expect(
        () => dependencyEngine.validateDependencies(registry),
        throwsA(isA<MissingSetupDependencyException>().having(
          (e) => e.targetPackageId,
          'targetPackageId',
          equals('unregistered_inventory'),
        )),
      );
    });

    test('3. Circular dependency — Cycle A -> B -> C -> A throws CircularSetupDependencyException', () {
      const pkgA = PackageSetupDefinition(
        packageId: 'pkg_a',
        displayNameAr: 'حزمة أ',
        displayNameEn: 'Package A',
        dependencies: [
          SetupDependency(targetPackageId: 'pkg_b', dependencyType: SetupDependencyType.required),
        ],
      );

      const pkgB = PackageSetupDefinition(
        packageId: 'pkg_b',
        displayNameAr: 'حزمة ب',
        displayNameEn: 'Package B',
        dependencies: [
          SetupDependency(targetPackageId: 'pkg_c', dependencyType: SetupDependencyType.required),
        ],
      );

      const pkgC = PackageSetupDefinition(
        packageId: 'pkg_c',
        displayNameAr: 'حزمة ج',
        displayNameEn: 'Package C',
        dependencies: [
          SetupDependency(targetPackageId: 'pkg_a', dependencyType: SetupDependencyType.required),
        ],
      );

      final list = [pkgA, pkgB, pkgC];

      expect(
        () => dependencyEngine.detectCycles(list),
        throwsA(isA<CircularSetupDependencyException>().having(
          (e) => e.cyclePath,
          'cyclePath',
          contains('pkg_a'),
        )),
      );
    });

    test('4. Incomplete setup — Unfilled required field evaluates to notConfigured / partiallyConfigured', () async {
      const salesDef = PackageSetupDefinition(
        packageId: 'sales',
        displayNameAr: 'المبيعات',
        displayNameEn: 'Sales',
        sections: [
          SetupSection(
            id: 'policies',
            packageId: 'sales',
            titleAr: 'السياسات',
            titleEn: 'Policies',
            descriptionAr: 'الوصف',
            descriptionEn: 'Description',
            fields: [
              SetupField(
                id: 'taxRate',
                sectionId: 'policies',
                key: 'taxRate',
                labelAr: 'الضريبة',
                labelEn: 'Tax Rate',
                fieldType: SetupFieldType.number,
                isRequired: true,
              ),
            ],
          ),
        ],
      );

      registry.register(salesDef);

      final status = await validationEngine.evaluatePackageStatus(
        companyId: companyId,
        packageDef: salesDef,
        fieldValues: {}, // Empty field values
        registry: registry,
        allPackageStatuses: {},
      );

      expect(status, equals(SetupStatus.notConfigured));
    });

    test('5. Valid setup — All required fields and bindings satisfied evaluates to configured', () async {
      const salesDef = PackageSetupDefinition(
        packageId: 'sales',
        displayNameAr: 'المبيعات',
        displayNameEn: 'Sales',
        sections: [
          SetupSection(
            id: 'policies',
            packageId: 'sales',
            titleAr: 'السياسات',
            titleEn: 'Policies',
            descriptionAr: 'الوصف',
            descriptionEn: 'Description',
            fields: [
              SetupField(
                id: 'taxRate',
                sectionId: 'policies',
                key: 'taxRate',
                labelAr: 'الضريبة',
                labelEn: 'Tax Rate',
                fieldType: SetupFieldType.number,
                isRequired: true,
                defaultValue: 15,
              ),
            ],
          ),
        ],
      );

      const salesAccountReq = AccountRequirement(
        packageId: 'sales',
        requirementKey: 'sales_account',
        role: AccountRole.revenue,
        labelAr: 'حساب المبيعات',
        labelEn: 'Sales Account',
        isRequired: true,
      );

      registry.register(salesDef);

      // Populate mock COA account
      mockAccountLookup.accounts['acc_uuid_100'] = const SetupAccountData(
        uuid: 'acc_uuid_100',
        accountCode: '4101',
        accountType: SetupAccountType.revenue,
        companyId: companyId,
        isActive: true,
        isDeleted: false,
        isGroup: false,
        canPost: true,
      );

      // Bind account
      final resolver = AccountBindingResolver(
        accountLookupPort: mockAccountLookup,
        bindingRepository: bindingRepository,
      );

      await resolver.bindAccount(
        companyId: companyId,
        requirement: salesAccountReq,
        accountUuid: 'acc_uuid_100',
      );

      final status = await validationEngine.evaluatePackageStatus(
        companyId: companyId,
        packageDef: salesDef,
        fieldValues: {'taxRate': 15},
        registry: registry,
        allPackageStatuses: {},
        accountRequirements: [salesAccountReq],
      );

      expect(status, equals(SetupStatus.configured));
    });

    test('6. Stale account binding — Deleted / deactivated account evaluates as invalid status', () async {
      const salesAccountReq = AccountRequirement(
        packageId: 'sales',
        requirementKey: 'sales_account',
        role: AccountRole.revenue,
        labelAr: 'حساب المبيعات',
        labelEn: 'Sales Account',
        isRequired: true,
      );

      // Account initially active
      mockAccountLookup.accounts['acc_uuid_stale'] = const SetupAccountData(
        uuid: 'acc_uuid_stale',
        accountCode: '4101',
        accountType: SetupAccountType.revenue,
        companyId: companyId,
        isActive: false, // DEACTIVATED
        isDeleted: true, // DELETED
        isGroup: false,
        canPost: false,
      );

      // Save stale binding manually into repository
      await bindingRepository.saveBinding(const AccountBinding(
        companyId: companyId,
        packageId: 'sales',
        requirementKey: 'sales_account',
        accountUuid: 'acc_uuid_stale',
        status: AccountBindingStatus.bound,
      ));

      const salesDef = PackageSetupDefinition(
        packageId: 'sales',
        displayNameAr: 'المبيعات',
        displayNameEn: 'Sales',
      );
      registry.register(salesDef);

      final status = await validationEngine.evaluatePackageStatus(
        companyId: companyId,
        packageDef: salesDef,
        fieldValues: {},
        registry: registry,
        allPackageStatuses: {},
        accountRequirements: [salesAccountReq],
      );

      expect(status, equals(SetupStatus.invalid));
    });

    test('7. Cross-company account rejection — Account from different tenant company is rejected', () async {
      const salesAccountReq = AccountRequirement(
        packageId: 'sales',
        requirementKey: 'sales_account',
        role: AccountRole.revenue,
        labelAr: 'حساب المبيعات',
        labelEn: 'Sales Account',
        isRequired: true,
      );

      // Account belongs to company_OTHER
      mockAccountLookup.accounts['acc_uuid_other_company'] = const SetupAccountData(
        uuid: 'acc_uuid_other_company',
        accountCode: '4101',
        accountType: SetupAccountType.revenue,
        companyId: 'company_OTHER_tenant',
        isActive: true,
        isDeleted: false,
        isGroup: false,
        canPost: true,
      );

      final resolver = AccountBindingResolver(
        accountLookupPort: mockAccountLookup,
        bindingRepository: bindingRepository,
      );

      expect(
        () => resolver.bindAccount(
          companyId: companyId,
          requirement: salesAccountReq,
          accountUuid: 'acc_uuid_other_company',
        ),
        throwsA(isA<CrossCompanyAccountBindingException>()),
      );
    });

    test('8. Transaction-level missing configuration — Posting without account binding throws exception', () async {
      const salesAccountReq = AccountRequirement(
        packageId: 'sales',
        requirementKey: 'sales_account',
        role: AccountRole.revenue,
        labelAr: 'حساب المبيعات',
        labelEn: 'Sales Account',
        isRequired: true,
      );

      // Requirement is unbound in bindingRepository

      expect(
        () => transactionValidator.validateAndResolveAccount(
          companyId: companyId,
          requirement: salesAccountReq,
        ),
        throwsA(isA<TransactionSetupConfigurationException>().having(
          (e) => e.requirementKey,
          'requirementKey',
          equals('sales_account'),
        )),
      );
    });
  });
}
