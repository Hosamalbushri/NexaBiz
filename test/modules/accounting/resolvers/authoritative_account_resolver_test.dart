import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/domain/foundation/accounting_failure.dart';
import 'package:stock_count/modules/accounting/domain/resolvers/authoritative_account_resolver_impl.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';

class FakeAccountRepository implements AccountRepository {
  final Map<String, Account> _accountsByUuid = {};

  void addAccount(Account acc) {
    _accountsByUuid[acc.uuid] = acc;
  }

  @override
  Future<Account?> getByUuid(String uuid) async => _accountsByUuid[uuid];

  @override
  Future<Account?> getByAccountCode(String code) async => null;

  @override
  Future<Account?> getById(int id) async => null;

  @override
  Future<List<Account>> getAll({bool includeInactive = false}) async => _accountsByUuid.values.toList();

  @override
  Future<void> ensureDefaultChartSeeded() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeInitRepository implements CompanyInitializationRepository {
  CompanyAccountingConfig? config;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<CompanyAccountingConfig?> getAccountingConfig() async => config;

  @override
  Future<void> saveAccountingConfig(CompanyAccountingConfig config) async {}

  @override
  Future<bool> isCompanyInitialized() async => config != null;
}


void main() {
  late FakeAccountRepository fakeAccountRepo;
  late FakeInitRepository fakeInitRepo;
  late AuthoritativeAccountResolver resolver;

  final companyId = 'comp-uuid-100';
  final validAccUuid = 'acc-inv-uuid-001';
  final groupAccUuid = 'acc-group-uuid-002';
  final inactiveAccUuid = 'acc-inactive-uuid-003';
  final wrongCompanyAccUuid = 'acc-wrong-comp-uuid-004';

  final validInventoryAccount = Account(
    id: validAccUuid,
    accountCode: '1200',
    name: 'Inventory Assets',
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    level: 1,
    isGroup: false,
    isActive: true,
    isSystemAccount: false,
    companyId: companyId,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  final groupAccount = Account(
    id: groupAccUuid,
    accountCode: '1000',
    name: 'Current Assets Group',
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    level: 0,
    isGroup: true,
    isActive: true,
    isSystemAccount: true,
    companyId: companyId,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  final inactiveAccount = Account(
    id: inactiveAccUuid,
    accountCode: '1201',
    name: 'Inactive Inventory',
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    level: 1,
    isGroup: false,
    isActive: false,
    isSystemAccount: false,
    companyId: companyId,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  final wrongCompanyAccount = Account(
    id: wrongCompanyAccUuid,
    accountCode: '1202',
    name: 'Other Company Inventory',
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    level: 1,
    isGroup: false,
    isActive: true,
    isSystemAccount: false,
    companyId: 'comp-uuid-999',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    fakeAccountRepo = FakeAccountRepository();
    fakeInitRepo = FakeInitRepository();
    resolver = AuthoritativeAccountResolver(
      accountRepository: fakeAccountRepo,
      initRepository: fakeInitRepo,
    );

    fakeAccountRepo.addAccount(validInventoryAccount);
    fakeAccountRepo.addAccount(groupAccount);
    fakeAccountRepo.addAccount(inactiveAccount);
    fakeAccountRepo.addAccount(wrongCompanyAccount);

    fakeInitRepo.config = CompanyAccountingConfig(
      companyId: companyId,
      accountMappings: {
        AccountRole.inventory: validAccUuid,
      },
    );
  });

  group('AuthoritativeAccountResolver Tests', () {
    test('resolves configured role to valid posting account', () async {
      final account = await resolver.resolveAccount(
        companyId: companyId,
        role: AccountRole.inventory,
      );

      expect(account.id, validAccUuid);
      expect(account.name, 'Inventory Assets');
      expect(account.canPost, isTrue);
    });

    test('rejects missing role mapping when not configured', () async {
      expect(
        () => resolver.resolveAccount(
          companyId: companyId,
          role: AccountRole.cogs,
        ),
        throwsA(isA<InvalidAccountingEffectFailure>()),
      );
    });

    test('rejects account when UUID does not exist in Chart of Accounts', () async {
      expect(
        () => resolver.resolveAccount(
          companyId: companyId,
          role: AccountRole.inventory,
          overrideAccountUuid: 'non-existent-uuid',
        ),
        throwsA(isA<InvalidAccountingEffectFailure>()),
      );
    });

    test('rejects account belonging to another company (tenant isolation)', () async {
      expect(
        () => resolver.resolveAccount(
          companyId: companyId,
          role: AccountRole.inventory,
          overrideAccountUuid: wrongCompanyAccUuid,
        ),
        throwsA(isA<InvalidAccountingEffectFailure>()),
      );
    });

    test('rejects inactive account', () async {
      expect(
        () => resolver.resolveAccount(
          companyId: companyId,
          role: AccountRole.inventory,
          overrideAccountUuid: inactiveAccUuid,
        ),
        throwsA(isA<InvalidAccountingEffectFailure>()),
      );
    });

    test('rejects group account (non-postable)', () async {
      expect(
        () => resolver.resolveAccount(
          companyId: companyId,
          role: AccountRole.inventory,
          overrideAccountUuid: groupAccUuid,
        ),
        throwsA(isA<InvalidAccountingEffectFailure>()),
      );
    });

    test('rejects illegal fallback company ID scope', () async {
      expect(
        () => resolver.resolveAccount(
          companyId: 'legacy_company',
          role: AccountRole.inventory,
        ),
        throwsA(isA<MissingCompanyScopeFailure>()),
      );
    });

    test('rejects raw local integer ID as cross-domain account target', () async {
      expect(
        () => resolver.resolveAccount(
          companyId: companyId,
          role: AccountRole.inventory,
          overrideAccountUuid: '1110',
        ),
        throwsA(isA<InvalidSourceReferenceFailure>()),
      );
    });
  });
}
