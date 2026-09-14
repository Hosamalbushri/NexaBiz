import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/receipts_payments/accounting_rp_treasury_adapter.dart';
import 'package:stock_count/app/sales/accounting_sale_treasury_adapter.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/cash_registers/data/repositories/cash_register_repository_impl.dart';
import 'package:stock_count/modules/cash_registers/domain/entities/cash_register.dart';
import 'package:stock_count/modules/cash_registers/domain/repositories/cash_register_repository.dart';

class FakeAccountRepository implements AccountRepository {
  final Map<String, Account> _accounts = {};

  void addAccount(Account acc) {
    _accounts[acc.uuid] = acc;
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
  Future<List<Account>> getAll({bool includeInactive = false}) async {
    if (includeInactive) return _accounts.values.toList();
    return _accounts.values.where((a) => a.isActive && !a.isDeleted).toList();
  }

  @override
  Stream<List<Account>> watchAll({bool includeInactive = false}) {
    return Stream.value(_accounts.values.toList());
  }

  @override
  Future<List<Account>> getByUuids(Iterable<String> uuids) async {
    return uuids.map((u) => _accounts[u]).whereType<Account>().toList();
  }

  @override
  Future<List<Account>> search(
    String query, {
    bool includeInactive = false,
  }) async {
    return _accounts.values.where((a) => a.name.contains(query)).toList();
  }

  @override
  Future<List<Account>> getChildren(String parentUuid) async {
    return _accounts.values.where((a) => a.parentId == parentUuid).toList();
  }

  @override
  Future<bool> hasChildren(String uuid) async {
    return _accounts.values.any((a) => a.parentId == uuid);
  }

  @override
  Future<bool> isUsedInTransactions(String uuid) async => false;

  @override
  Future<Account> insert(AccountDraft draft) async =>
      throw UnimplementedError();

  @override
  Future<Account> update(int id, AccountDraft draft) async =>
      throw UnimplementedError();

  @override
  Future<void> deactivate(int id) async {}

  @override
  Future<void> softDelete(int id) async {
    final acc = _accounts.values.firstWhere((a) => a.id == id);
    _accounts[acc.uuid] = acc.copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> ensureDefaultChartSeeded() async {}

  @override
  Future<void> seedDefaultChart() async {}

  @override
  Future<List<Account>> getByType(
    AccountType type, {
    bool includeInactive = false,
  }) async {
    return _accounts.values.where((a) => a.accountType == type).toList();
  }
}

void main() {
  late FakeAccountRepository accountRepo;
  late CashRegisterRepositoryImpl cashRegRepo;
  const companyA = 'company-A';
  const companyB = 'company-B';

  final validCashAccountA = Account(
    id: 'acc-cash-1',
    accountCode: '1111',
    name: 'صندوق النقدية 1',
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    level: 2,
    isGroup: false,
    isActive: true,
    isSystemAccount: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    companyId: companyA,
  );

  final validCashAccountA2 = Account(
    id: 'acc-cash-2',
    accountCode: '1112',
    name: 'صندوق الفرع 2',
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    level: 2,
    isGroup: false,
    isActive: true,
    isSystemAccount: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    companyId: companyA,
  );

  final inactiveAccount = Account(
    id: 'acc-cash-inactive',
    accountCode: '1113',
    name: 'حساب معطل',
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    level: 2,
    isGroup: false,
    isActive: false,
    isSystemAccount: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    companyId: companyA,
  );

  final expenseAccount = Account(
    id: 'acc-expense',
    accountCode: '5111',
    name: 'مصروف إداري',
    accountType: AccountType.expense,
    normalBalance: NormalBalance.debit,
    level: 2,
    isGroup: false,
    isActive: true,
    isSystemAccount: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    companyId: companyA,
  );

  final companyBAccount = Account(
    id: 'acc-cash-companyB',
    accountCode: '1119',
    name: 'صندوق شركة أخرى',
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    level: 2,
    isGroup: false,
    isActive: true,
    isSystemAccount: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    companyId: companyB,
  );

  setUp(() {
    accountRepo = FakeAccountRepository();
    accountRepo.addAccount(validCashAccountA);
    accountRepo.addAccount(validCashAccountA2);
    accountRepo.addAccount(inactiveAccount);
    accountRepo.addAccount(expenseAccount);
    accountRepo.addAccount(companyBAccount);

    cashRegRepo = CashRegisterRepositoryImpl(accountRepository: accountRepo);
  });

  group('CASH-ACCOUNT-01: Cash Register Accounting Configuration Tests', () {
    test(
      'Test 01: Create Cash Register without accounting link -> ACCOUNTING_NOT_LINKED & hidden from selectors',
      () async {
        final reg = CashRegister(
          id: 'cr-1',
          companyId: companyA,
          name: 'كاشير الفرع الرئيسي',
          code: 'CR-01',
          isActive: true,
          accountingAccountId: null, // Initially unlinked
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final created = await cashRegRepo.createCashRegister(reg);
        expect(created.isLinked, isFalse);
        expect(
          created.evaluateStatus(null),
          equals(CashRegisterAccountingStatus.notLinked),
        );

        final readyRegisters = await cashRegRepo
            .getAccountingReadyCashRegisters(companyA);
        expect(readyRegisters, isEmpty);

        final salesAdapter = AccountingSaleTreasuryAdapter(
          accountRepo,
          cashRegisterRepository: cashRegRepo,
        );
        final salesBoxes = await salesAdapter.listCashBoxAccounts();
        expect(salesBoxes, isEmpty);

        final rpAdapter = AccountingRpTreasuryAdapter(
          accountRepo,
          cashRegisterRepository: cashRegRepo,
        );
        final rpBoxes = await rpAdapter.listCashBoxAccounts();
        expect(rpBoxes, isEmpty);
      },
    );

    test(
      'Test 02: Link valid cash account -> status becomes ACCOUNTING_READY and appears in selectors',
      () async {
        final reg = CashRegister(
          id: 'cr-1',
          companyId: companyA,
          name: 'كاشير الفرع الرئيسي',
          code: 'CR-01',
          isActive: true,
          accountingAccountId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await cashRegRepo.createCashRegister(reg);

        final linked = await cashRegRepo.linkAccountingAccount(
          registerId: 'cr-1',
          accountId: validCashAccountA.uuid,
          companyId: companyA,
        );

        expect(linked.isLinked, isTrue);
        expect(linked.accountingAccountId, equals(validCashAccountA.uuid));

        final readyRegisters = await cashRegRepo
            .getAccountingReadyCashRegisters(companyA);
        expect(readyRegisters.length, equals(1));
        expect(readyRegisters.first.id, equals('cr-1'));

        final salesAdapter = AccountingSaleTreasuryAdapter(
          accountRepo,
          cashRegisterRepository: cashRegRepo,
        );
        final salesBoxes = await salesAdapter.listCashBoxAccounts();
        expect(salesBoxes.length, equals(1));
        expect(salesBoxes.first.accountId, equals(validCashAccountA.uuid));

        final rpAdapter = AccountingRpTreasuryAdapter(
          accountRepo,
          cashRegisterRepository: cashRegRepo,
        );
        final rpBoxes = await rpAdapter.listCashBoxAccounts();
        expect(rpBoxes.length, equals(1));
        expect(rpBoxes.first.accountId, equals(validCashAccountA.uuid));
      },
    );

    test(
      'Test 03: Create two Cash Registers, link only one -> only linked register appears',
      () async {
        await cashRegRepo.createCashRegister(
          CashRegister(
            id: 'cr-1',
            companyId: companyA,
            name: 'صندوق 1 (مربوط)',
            code: 'CR-01',
            isActive: true,
            accountingAccountId: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await cashRegRepo.createCashRegister(
          CashRegister(
            id: 'cr-2',
            companyId: companyA,
            name: 'صندوق 2 (غير مربوط)',
            code: 'CR-02',
            isActive: true,
            accountingAccountId: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await cashRegRepo.linkAccountingAccount(
          registerId: 'cr-1',
          accountId: validCashAccountA.uuid,
          companyId: companyA,
        );

        final readyRegisters = await cashRegRepo
            .getAccountingReadyCashRegisters(companyA);
        expect(readyRegisters.length, equals(1));
        expect(readyRegisters.first.id, equals('cr-1'));
      },
    );

    test(
      'Test 04: Unlink Cash Register -> immediately disappears from selectors',
      () async {
        await cashRegRepo.createCashRegister(
          CashRegister(
            id: 'cr-1',
            companyId: companyA,
            name: 'صندوق 1',
            code: 'CR-01',
            isActive: true,
            accountingAccountId: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await cashRegRepo.linkAccountingAccount(
          registerId: 'cr-1',
          accountId: validCashAccountA.uuid,
          companyId: companyA,
        );

        expect(
          (await cashRegRepo.getAccountingReadyCashRegisters(companyA)).length,
          equals(1),
        );

        await cashRegRepo.unlinkAccountingAccount(
          registerId: 'cr-1',
          companyId: companyA,
        );

        expect(
          (await cashRegRepo.getAccountingReadyCashRegisters(companyA)),
          isEmpty,
        );
      },
    );

    test(
      'Test 05: Link inactive account -> rejected with ACCOUNT_INACTIVE exception',
      () async {
        await cashRegRepo.createCashRegister(
          CashRegister(
            id: 'cr-1',
            companyId: companyA,
            name: 'صندوق 1',
            code: 'CR-01',
            isActive: true,
            accountingAccountId: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        expect(
          () async => await cashRegRepo.linkAccountingAccount(
            registerId: 'cr-1',
            accountId: inactiveAccount.uuid,
            companyId: companyA,
          ),
          throwsA(
            isA<CashRegisterException>().having(
              (e) => e.code,
              'code',
              equals('ACCOUNT_INACTIVE'),
            ),
          ),
        );
      },
    );

    test(
      'Test 06: Link incompatible account type (e.g. expense) -> rejected with ACCOUNT_TYPE_MISMATCH exception',
      () async {
        await cashRegRepo.createCashRegister(
          CashRegister(
            id: 'cr-1',
            companyId: companyA,
            name: 'صندوق 1',
            code: 'CR-01',
            isActive: true,
            accountingAccountId: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        expect(
          () async => await cashRegRepo.linkAccountingAccount(
            registerId: 'cr-1',
            accountId: expenseAccount.uuid,
            companyId: companyA,
          ),
          throwsA(
            isA<CashRegisterException>().having(
              (e) => e.code,
              'code',
              equals('ACCOUNT_TYPE_MISMATCH'),
            ),
          ),
        );
      },
    );

    test(
      'Test 07: Cross-company account assignment -> rejected with CROSS_COMPANY_ACCOUNT exception',
      () async {
        await cashRegRepo.createCashRegister(
          CashRegister(
            id: 'cr-1',
            companyId: companyA,
            name: 'صندوق 1',
            code: 'CR-01',
            isActive: true,
            accountingAccountId: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        expect(
          () async => await cashRegRepo.linkAccountingAccount(
            registerId: 'cr-1',
            accountId: companyBAccount.uuid,
            companyId: companyA,
          ),
          throwsA(
            isA<CashRegisterException>().having(
              (e) => e.code,
              'code',
              equals('CROSS_COMPANY_ACCOUNT'),
            ),
          ),
        );
      },
    );

    test(
      'Test 08: Change linked account -> future queries reflect new account',
      () async {
        await cashRegRepo.createCashRegister(
          CashRegister(
            id: 'cr-1',
            companyId: companyA,
            name: 'صندوق 1',
            code: 'CR-01',
            isActive: true,
            accountingAccountId: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await cashRegRepo.linkAccountingAccount(
          registerId: 'cr-1',
          accountId: validCashAccountA.uuid,
          companyId: companyA,
        );

        var ready = await cashRegRepo.getAccountingReadyCashRegisters(companyA);
        expect(ready.first.accountingAccountId, equals(validCashAccountA.uuid));

        await cashRegRepo.linkAccountingAccount(
          registerId: 'cr-1',
          accountId: validCashAccountA2.uuid,
          companyId: companyA,
        );

        ready = await cashRegRepo.getAccountingReadyCashRegisters(companyA);
        expect(
          ready.first.accountingAccountId,
          equals(validCashAccountA2.uuid),
        );
      },
    );

    test(
      'Test 09: Search / autocomplete -> unlinked cash registers never returned',
      () async {
        await cashRegRepo.createCashRegister(
          CashRegister(
            id: 'cr-unlinked',
            companyId: companyA,
            name: 'صندوق غير مربوط',
            code: 'CR-99',
            isActive: true,
            accountingAccountId: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final rpAdapter = AccountingRpTreasuryAdapter(
          accountRepo,
          cashRegisterRepository: cashRegRepo,
        );
        final searchResults = await rpAdapter.searchPostingAccounts(
          'غير مربوط',
        );
        expect(searchResults, isEmpty);
      },
    );

    test(
      'Test 10: Cached data -> unlinked register status evaluated at query time',
      () async {
        final reg = CashRegister(
          id: 'cr-1',
          companyId: companyA,
          name: 'صندوق 1',
          code: 'CR-01',
          isActive: true,
          accountingAccountId: validCashAccountA.uuid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await cashRegRepo.createCashRegister(reg);

        // Now soft delete account in COA
        await accountRepo.softDelete(validCashAccountA.id);

        final readyRegisters = await cashRegRepo
            .getAccountingReadyCashRegisters(companyA);
        expect(readyRegisters, isEmpty);
      },
    );

    test(
      'Test 11: Default COA unavailable -> linked valid accounts continue working independently',
      () async {
        // Create independent cash register linked explicitly
        await cashRegRepo.createCashRegister(
          CashRegister(
            id: 'cr-custom',
            companyId: companyA,
            name: 'صندوق خاص',
            code: 'CR-88',
            isActive: true,
            accountingAccountId: validCashAccountA2.uuid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final readyRegisters = await cashRegRepo
            .getAccountingReadyCashRegisters(companyA);
        expect(readyRegisters.length, equals(1));
        expect(readyRegisters.first.id, equals('cr-custom'));
        expect(
          readyRegisters.first.accountingAccountId,
          equals(validCashAccountA2.uuid),
        );
      },
    );

    test(
      'Test 12: CashRegister evaluateStatus handles all invalid edge cases',
      () {
        final reg = CashRegister(
          id: 'cr-test',
          companyId: companyA,
          name: 'صندوق اختبار',
          code: 'CR-T',
          isActive: true,
          accountingAccountId: 'acc-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Null account -> invalid
        expect(
          reg.evaluateStatus(null),
          equals(CashRegisterAccountingStatus.invalid),
        );

        // Wrong company -> invalid
        expect(
          reg.evaluateStatus(companyBAccount, targetCompanyId: companyA),
          equals(CashRegisterAccountingStatus.invalid),
        );

        // Inactive account -> invalid
        expect(
          reg.evaluateStatus(inactiveAccount, targetCompanyId: companyA),
          equals(CashRegisterAccountingStatus.invalid),
        );

        // Expense account -> invalid
        expect(
          reg.evaluateStatus(expenseAccount, targetCompanyId: companyA),
          equals(CashRegisterAccountingStatus.invalid),
        );

        // Valid account -> ready
        expect(
          reg.evaluateStatus(validCashAccountA, targetCompanyId: companyA),
          equals(CashRegisterAccountingStatus.ready),
        );
      },
    );
  });
}
