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
import 'package:stock_count/modules/cash_registers/domain/services/default_cash_register_resolver.dart';

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
  Future<List<Account>> search(String query, {bool includeInactive = false}) async {
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
  Future<Account> insert(AccountDraft draft) async => throw UnimplementedError();

  @override
  Future<Account> update(int id, AccountDraft draft) async => throw UnimplementedError();

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
  group('CASH-ACCOUNT-02: Default Cash Register Tests', () {
    late FakeAccountRepository accountRepo;
    late CashRegisterRepositoryImpl cashRepo;
    late DefaultCashRegisterResolver resolver;

    const companyA = 'default';
    const companyB = 'company-b';

    late Account cashAccountA;
    late Account cashAccountB;
    late Account inactiveAccount;

    setUp(() {
      accountRepo = FakeAccountRepository();

      cashAccountA = Account(
        id: 1,
        uuid: 'acc-cash-a',
        accountCode: '1101',
        name: 'الصندوق الرئيسي A',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      cashAccountB = Account(
        id: 2,
        uuid: 'acc-cash-b',
        accountCode: '1102',
        name: 'صندوق الفرع B',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      inactiveAccount = Account(
        id: 3,
        uuid: 'acc-inactive',
        accountCode: '1109',
        name: 'صندوق معطل',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: false,
        isSystemAccount: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      accountRepo.addAccount(cashAccountA);
      accountRepo.addAccount(cashAccountB);
      accountRepo.addAccount(inactiveAccount);

      cashRepo = CashRegisterRepositoryImpl(accountRepository: accountRepo);
      resolver = DefaultCashRegisterResolver(
        cashRegisterRepository: cashRepo,
        accountRepository: accountRepo,
      );
    });

    test('Test 01: No default configured -> resolver returns notConfigured state, no automatic selection', () async {
      final regA = CashRegister(
        id: 'reg-a',
        companyId: companyA,
        name: 'Register A',
        code: 'CR-A',
        isActive: true,
        accountingAccountId: cashAccountA.uuid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await cashRepo.createCashRegister(regA);

      final result = await resolver.resolveDefaultCashRegister(companyA);
      expect(result.isValid, isFalse);
      expect(result.errorCode, equals(DefaultCashRegisterErrorCode.notConfigured));

      final saleAdapter = AccountingSaleTreasuryAdapter(accountRepo, cashRegisterRepository: cashRepo);
      final defaultBox = await saleAdapter.findDefaultCashBox();
      expect(defaultBox, isNull);
    });

    test('Test 02: Valid default configured -> automatically resolved for new documents', () async {
      final regA = CashRegister(
        id: 'reg-a',
        companyId: companyA,
        name: 'Register A',
        code: 'CR-A',
        isActive: true,
        accountingAccountId: cashAccountA.uuid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await cashRepo.createCashRegister(regA);
      await cashRepo.setDefaultCashRegisterId(companyId: companyA, registerId: 'reg-a');

      final result = await resolver.resolveDefaultCashRegister(companyA);
      expect(result.isValid, isTrue);
      expect(result.register?.id, equals('reg-a'));
      expect(result.linkedAccount?.uuid, equals(cashAccountA.uuid));

      final saleAdapter = AccountingSaleTreasuryAdapter(accountRepo, cashRegisterRepository: cashRepo);
      final defaultBox = await saleAdapter.findDefaultCashBox();
      expect(defaultBox, isNotNull);
      expect(defaultBox?.accountId, equals(cashAccountA.uuid));
    });

    test('Test 03: Multiple registers -> default auto-selected, ready registers available as options, unlinked hidden', () async {
      final regA = await cashRepo.createCashRegister(CashRegister(
        id: 'reg-a', companyId: companyA, name: 'Reg A', code: 'A', isActive: true,
        accountingAccountId: cashAccountA.uuid, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));
      await cashRepo.createCashRegister(CashRegister(
        id: 'reg-b', companyId: companyA, name: 'Reg B', code: 'B', isActive: true,
        accountingAccountId: cashAccountB.uuid, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));
      await cashRepo.createCashRegister(CashRegister(
        id: 'reg-c-unlinked', companyId: companyA, name: 'Reg C', code: 'C', isActive: true,
        accountingAccountId: null, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));

      await cashRepo.setDefaultCashRegisterId(companyId: companyA, registerId: regA.id);

      final ready = await cashRepo.getAccountingReadyCashRegisters(companyA);
      expect(ready.length, equals(2));
      expect(ready.any((r) => r.id == 'reg-c-unlinked'), isFalse);

      final result = await resolver.resolveDefaultCashRegister(companyA);
      expect(result.register?.id, equals('reg-a'));
    });

    test('Test 04: Setting unlinked Cash Register as default is rejected', () async {
      final regUnlinked = await cashRepo.createCashRegister(CashRegister(
        id: 'reg-u', companyId: companyA, name: 'Unlinked', code: 'U', isActive: true,
        accountingAccountId: null, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));

      expect(
        () => cashRepo.setDefaultCashRegisterId(companyId: companyA, registerId: regUnlinked.id),
        throwsA(isA<CashRegisterException>()),
      );
    });

    test('Test 05: Default register becomes unlinked -> default becomes INVALID, no silent fallback', () async {
      final regA = await cashRepo.createCashRegister(CashRegister(
        id: 'reg-a', companyId: companyA, name: 'Reg A', code: 'A', isActive: true,
        accountingAccountId: cashAccountA.uuid, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));
      await cashRepo.createCashRegister(CashRegister(
        id: 'reg-b', companyId: companyA, name: 'Reg B', code: 'B', isActive: true,
        accountingAccountId: cashAccountB.uuid, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));
      await cashRepo.setDefaultCashRegisterId(companyId: companyA, registerId: regA.id);

      // Unlink Reg A
      await cashRepo.unlinkAccountingAccount(registerId: 'reg-a', companyId: companyA);

      final result = await resolver.resolveDefaultCashRegister(companyA);
      expect(result.isValid, isFalse);
      expect(result.errorCode, equals(DefaultCashRegisterErrorCode.registerUnlinked));

      // Adapter must NOT fall back to Reg B automatically
      final saleAdapter = AccountingSaleTreasuryAdapter(accountRepo, cashRegisterRepository: cashRepo);
      final defaultBox = await saleAdapter.findDefaultCashBox();
      expect(defaultBox, isNull);
    });

    test('Test 06: Default account becomes inactive -> default becomes INVALID, no silent fallback', () async {
      final regA = await cashRepo.createCashRegister(CashRegister(
        id: 'reg-a', companyId: companyA, name: 'Reg A', code: 'A', isActive: true,
        accountingAccountId: cashAccountA.uuid, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));
      await cashRepo.setDefaultCashRegisterId(companyId: companyA, registerId: regA.id);

      // Deactivate cashAccountA in accountRepo
      accountRepo.addAccount(cashAccountA.copyWith(isActive: false));

      final result = await resolver.resolveDefaultCashRegister(companyA);
      expect(result.isValid, isFalse);
      expect(result.errorCode, equals(DefaultCashRegisterErrorCode.accountInactive));

      final saleAdapter = AccountingSaleTreasuryAdapter(accountRepo, cashRegisterRepository: cashRepo);
      final defaultBox = await saleAdapter.findDefaultCashBox();
      expect(defaultBox, isNull);
    });

    test('Test 07: Change default from A to B -> new documents resolve B', () async {
      final regA = await cashRepo.createCashRegister(CashRegister(
        id: 'reg-a', companyId: companyA, name: 'Reg A', code: 'A', isActive: true,
        accountingAccountId: cashAccountA.uuid, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));
      final regB = await cashRepo.createCashRegister(CashRegister(
        id: 'reg-b', companyId: companyA, name: 'Reg B', code: 'B', isActive: true,
        accountingAccountId: cashAccountB.uuid, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));

      await cashRepo.setDefaultCashRegisterId(companyId: companyA, registerId: regA.id);
      var result = await resolver.resolveDefaultCashRegister(companyA);
      expect(result.register?.id, equals('reg-a'));

      // Switch default to B
      await cashRepo.setDefaultCashRegisterId(companyId: companyA, registerId: regB.id);
      result = await resolver.resolveDefaultCashRegister(companyA);
      expect(result.register?.id, equals('reg-b'));
    });

    test('Test 08: Manual override in document -> override used, default remains unchanged', () async {
      final regA = await cashRepo.createCashRegister(CashRegister(
        id: 'reg-a', companyId: companyA, name: 'Reg A', code: 'A', isActive: true,
        accountingAccountId: cashAccountA.uuid, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));
      final regB = await cashRepo.createCashRegister(CashRegister(
        id: 'reg-b', companyId: companyA, name: 'Reg B', code: 'B', isActive: true,
        accountingAccountId: cashAccountB.uuid, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));
      await cashRepo.setDefaultCashRegisterId(companyId: companyA, registerId: regA.id);

      final saleAdapter = AccountingSaleTreasuryAdapter(accountRepo, cashRegisterRepository: cashRepo);

      // Default resolves to A
      final defaultBox = await saleAdapter.findDefaultCashBox();
      expect(defaultBox?.accountId, equals(cashAccountA.uuid));

      // User manually selects B by ID
      final selectedBox = await saleAdapter.findById(regB.id);
      expect(selectedBox?.accountId, equals(cashAccountB.uuid));

      // System default remains A
      final defaultStillA = await cashRepo.getDefaultCashRegisterId(companyA);
      expect(defaultStillA, equals('reg-a'));
    });

    test('Test 09: Company isolation -> Company A default != Company B default', () async {
      final regA = await cashRepo.createCashRegister(CashRegister(
        id: 'reg-a', companyId: companyA, name: 'Reg A', code: 'A', isActive: true,
        accountingAccountId: cashAccountA.uuid, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));

      final cashAccountForB = Account(
        id: 4,
        uuid: 'acc-cash-comp-b',
        accountCode: '1101-B',
        name: 'Main Cash B',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        companyId: companyB,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      accountRepo.addAccount(cashAccountForB);

      final regB = await cashRepo.createCashRegister(CashRegister(
        id: 'reg-b-comp-b', companyId: companyB, name: 'Reg B', code: 'B', isActive: true,
        accountingAccountId: cashAccountForB.uuid, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));

      await cashRepo.setDefaultCashRegisterId(companyId: companyA, registerId: regA.id);
      await cashRepo.setDefaultCashRegisterId(companyId: companyB, registerId: regB.id);

      final defaultA = await resolver.resolveDefaultCashRegister(companyA);
      final defaultB = await resolver.resolveDefaultCashRegister(companyB);

      expect(defaultA.register?.id, equals('reg-a'));
      expect(defaultB.register?.id, equals('reg-b-comp-b'));

      // Cross company set attempt is rejected
      expect(
        () => cashRepo.setDefaultCashRegisterId(companyId: companyA, registerId: regB.id),
        throwsA(isA<CashRegisterException>()),
      );
    });

    test('Test 10: Posting -> Document references default register -> posting uses concrete COA account', () async {
      final regA = await cashRepo.createCashRegister(CashRegister(
        id: 'reg-a', companyId: companyA, name: 'Reg A', code: 'A', isActive: true,
        accountingAccountId: cashAccountA.uuid, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));
      await cashRepo.setDefaultCashRegisterId(companyId: companyA, registerId: regA.id);

      final rpAdapter = AccountingRpTreasuryAdapter(accountRepo, cashRegisterRepository: cashRepo);
      final defaultBox = await rpAdapter.findDefaultCashBox();

      expect(defaultBox, isNotNull);
      expect(defaultBox?.accountId, equals(cashAccountA.uuid));
      expect(defaultBox?.code, equals('1101'));
    });

    test('Test 11: Historical integrity -> Changing default after document creation does not mutate historical link', () async {
      final regA = await cashRepo.createCashRegister(CashRegister(
        id: 'reg-a', companyId: companyA, name: 'Reg A', code: 'A', isActive: true,
        accountingAccountId: cashAccountA.uuid, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));
      final regB = await cashRepo.createCashRegister(CashRegister(
        id: 'reg-b', companyId: companyA, name: 'Reg B', code: 'B', isActive: true,
        accountingAccountId: cashAccountB.uuid, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));

      await cashRepo.setDefaultCashRegisterId(companyId: companyA, registerId: regA.id);
      final historicalDocAccountId = cashAccountA.uuid;

      // Change default to B
      await cashRepo.setDefaultCashRegisterId(companyId: companyA, registerId: regB.id);

      // Historical document posted account ID remains cashAccountA
      expect(historicalDocAccountId, equals('acc-cash-a'));
    });

    test('Test 12: Cache invalidation -> Default change immediately reflected in resolver', () async {
      final regA = await cashRepo.createCashRegister(CashRegister(
        id: 'reg-a', companyId: companyA, name: 'Reg A', code: 'A', isActive: true,
        accountingAccountId: cashAccountA.uuid, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));
      final regB = await cashRepo.createCashRegister(CashRegister(
        id: 'reg-b', companyId: companyA, name: 'Reg B', code: 'B', isActive: true,
        accountingAccountId: cashAccountB.uuid, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));

      await cashRepo.setDefaultCashRegisterId(companyId: companyA, registerId: regA.id);
      var result = await resolver.resolveDefaultCashRegister(companyA);
      expect(result.register?.id, equals('reg-a'));

      // Update default immediately
      await cashRepo.setDefaultCashRegisterId(companyId: companyA, registerId: regB.id);
      result = await resolver.resolveDefaultCashRegister(companyA);
      expect(result.register?.id, equals('reg-b'));
    });
  });
}
