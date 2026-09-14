import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/shared/data/services/account_mapping_resolver_impl.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_validation_service.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';

class MemoryAccountRepository implements AccountRepository {
  final Map<String, Account> _accounts = {};

  void addAccount(Account account) {
    _accounts[account.id] = account;
  }

  @override
  Future<List<Account>> getAll({
    bool includeInactive = false,
    bool includeDeleted = false,
  }) async {
    return _accounts.values.where((a) {
      if (!includeInactive && !a.isActive) return false;
      if (!includeDeleted && a.isDeleted) return false;
      return true;
    }).toList();
  }

  @override
  Future<Account?> getByUuid(String uuid) async => _accounts[uuid];

  @override
  Future<Account?> getByAccountCode(String code) async {
    for (final acc in _accounts.values) {
      if (acc.accountCode == code) return acc;
    }
    return null;
  }

  @override
  Future<Account?> getById(int id) async {
    for (final acc in _accounts.values) {
      if (acc.id == id) return acc;
    }
    return null;
  }

  @override
  Future<Account> save(Account account) async {
    _accounts[account.id] = account;
    return account;
  }

  @override
  Future<void> delete(String uuid) async {
    _accounts.remove(uuid);
  }

  @override
  Future<void> seedDefaultChart() async {}

  @override
  Future<void> ensureDefaultChartSeeded() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCompanyInitializationRepository
    implements CompanyInitializationRepository {
  FakeCompanyInitializationRepository(this._config);

  final CompanyAccountingConfig _config;

  @override
  Future<CompanyAccountingConfig> getAccountingConfig() async => _config;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAccountValidationService implements AccountValidationService {
  @override
  Future<AccountValidationResult> validateAccount(Account account) async {
    return const AccountValidationResult(isValid: true);
  }

  @override
  Future<AccountValidationResult> validateAccountUuid(
    String accountId,
  ) async {
    return const AccountValidationResult(isValid: true);
  }

  @override
  Future<AccountValidationResult> validateMapping({
    required AccountRole role,
    required Account account,
  }) async {
    return const AccountValidationResult(isValid: true);
  }

  @override
  Future<void> assertCanPost(String accountId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AR-C04.1 Multi-Company Tenant Isolation & Account Resolution', () {
    late MemoryAccountRepository repoCompA;
    late MemoryAccountRepository repoCompB;

    final now = DateTime.now();

    final compAAccount = Account(
      id: 'comp_a_rev_uuid',
      accountCode: '4101',
      name: 'إيرادات مبيعات شركة أ',
      companyId: 'company_A',
      accountType: AccountType.revenue,
      normalBalance: NormalBalance.credit,
      level: 4,
      isGroup: false,
      isActive: true,
      isSystemAccount: false,
      createdAt: now,
      updatedAt: now,
    );

    final compBAccount = Account(
      id: 'comp_b_rev_uuid',
      accountCode: '4101',
      name: 'إيرادات مبيعات شركة ب',
      companyId: 'company_B',
      accountType: AccountType.revenue,
      normalBalance: NormalBalance.credit,
      level: 4,
      isGroup: false,
      isActive: true,
      isSystemAccount: false,
      createdAt: now,
      updatedAt: now,
    );

    setUp(() {
      repoCompA = MemoryAccountRepository()..addAccount(compAAccount);
      repoCompB = MemoryAccountRepository()..addAccount(compBAccount);
    });

    test(
      'Company A resolves its own bound revenue account without fallback',
      () async {
        final configA = CompanyAccountingConfig(
          companyId: 'company_A',
          accountMappings: const {AccountRole.revenue: 'comp_a_rev_uuid'},
        );

        final resolverA = AccountMappingResolverImpl(
          accountRepository: repoCompA,
          validationService: FakeAccountValidationService(),
          initRepository: FakeCompanyInitializationRepository(configA),
        );

        final mapping = await resolverA.resolveForDocument(
          documentType: 'sale',
        );
        expect(
          mapping.getRole(AccountRole.revenue)?.accountId,
          equals('comp_a_rev_uuid'),
        );
        expect(
          mapping.getRole(AccountRole.revenue)?.accountName,
          equals('إيرادات مبيعات شركة أ'),
        );
      },
    );

    test('Company B resolves its distinct bound revenue account', () async {
      final configB = CompanyAccountingConfig(
        companyId: 'company_B',
        accountMappings: const {AccountRole.revenue: 'comp_b_rev_uuid'},
      );

      final resolverB = AccountMappingResolverImpl(
        accountRepository: repoCompB,
        validationService: FakeAccountValidationService(),
        initRepository: FakeCompanyInitializationRepository(configB),
      );

      final mapping = await resolverB.resolveForDocument(documentType: 'sale');
      expect(
        mapping.getRole(AccountRole.revenue)?.accountId,
        equals('comp_b_rev_uuid'),
      );
      expect(
        mapping.getRole(AccountRole.revenue)?.accountName,
        equals('إيرادات مبيعات شركة ب'),
      );
    });

    test(
      'Unconfigured account role returns null without silent fallback',
      () async {
        final emptyConfig = const CompanyAccountingConfig(
          companyId: 'company_A',
          accountMappings: {},
        );

        final resolverEmpty = AccountMappingResolverImpl(
          accountRepository: repoCompA,
          validationService: FakeAccountValidationService(),
          initRepository: FakeCompanyInitializationRepository(emptyConfig),
        );

        final mapping = await resolverEmpty.resolveForDocument(
          documentType: 'sale',
        );
        expect(mapping.getRole(AccountRole.revenue), isNull);
        expect(mapping.getRole(AccountRole.cash), isNull);
        expect(mapping.getRole(AccountRole.receivable), isNull);
      },
    );
  });
}
