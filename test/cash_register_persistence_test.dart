import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/app/sales/accounting_sale_treasury_adapter.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/cash_registers/data/repositories/cash_register_repository_impl.dart';
import 'package:stock_count/modules/cash_registers/domain/entities/cash_register.dart';
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
  group('CASH-ACCOUNT-03: Persistent Cash Register Tests', () {
    late FakeAccountRepository accountRepo;
    late NexabizDatabase db;
    late CashRegisterRepositoryImpl cashRepo;
    late Directory tempDir;

    const companyA = 'company-A';
    const companyB = 'company-B';

    late Account cashAccountA;
    late Account cashAccountB;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_cash_reg_test_');
      Hive.init(tempDir.path);
      await Hive.openBox<dynamic>(HiveBoxes.settings);

      accountRepo = FakeAccountRepository();
      db = NexabizDatabase.memory();

      cashAccountA = Account(
        id: 'acc-cash-a-uuid-1111-2222-333344445555',
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
        id: 'acc-cash-b-uuid-1111-2222-333344445555',
        accountCode: '1102',
        name: 'صندوق الفرع B',
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

      accountRepo.addAccount(cashAccountA);
      accountRepo.addAccount(cashAccountB);

      cashRepo = CashRegisterRepositoryImpl(
        accountRepository: accountRepo,
        db: db,
      );
    });

    tearDown(() async {
      await db.close();
      await Hive.deleteFromDisk();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'A. Create: Create Cash Register -> verify database record exists & read-back succeeds',
      () async {
        const regId = 'cr-uuid-1111-2222-3333-444455556666';
        final reg = CashRegister(
          id: regId,
          companyId: companyA,
          name: 'Main Cash Register',
          code: 'CR-01',
          isActive: true,
          accountingAccountId: null,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );

        final created = await cashRepo.createCashRegister(reg);
        expect(created.id, equals(regId));

        final rows = await db.select(db.cashRegisters).get();
        expect(rows.length, equals(1));
        expect(rows.first.name, equals('Main Cash Register'));
      },
    );

    test(
      'B. Read: Destroy repository instance -> instantiate fresh repository -> read again -> record remains',
      () async {
        const regId = 'cr-uuid-2222-3333-4444-555566667777';
        final reg = CashRegister(
          id: regId,
          companyId: companyA,
          name: 'Branch Cash',
          code: 'CR-02',
          isActive: true,
          accountingAccountId: null,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );
        await cashRepo.createCashRegister(reg);

        final freshRepo = CashRegisterRepositoryImpl(
          accountRepository: accountRepo,
          db: db,
        );

        final loaded = await freshRepo.getCashRegisters(companyA);
        expect(loaded.length, equals(1));
        expect(loaded.first.id, equals(regId));
        expect(loaded.first.name, equals('Branch Cash'));
      },
    );

    test(
      'C. Restart & Stable UUID: UUID remains stable across restarts and multiple initializations',
      () async {
        const stableUuid = 'cr-uuid-3333-4444-5555-666677778888';
        final reg = CashRegister(
          id: stableUuid,
          companyId: companyA,
          name: 'Stable Cash',
          code: 'CR-STABLE',
          isActive: true,
          accountingAccountId: null,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );
        await cashRepo.createCashRegister(reg);

        final repo1 = CashRegisterRepositoryImpl(
          accountRepository: accountRepo,
          db: db,
        );
        final list1 = await repo1.getCashRegisters(companyA);

        final repo2 = CashRegisterRepositoryImpl(
          accountRepository: accountRepo,
          db: db,
        );
        final list2 = await repo2.getCashRegisters(companyA);

        expect(list1.first.id, equals(stableUuid));
        expect(list2.first.id, equals(stableUuid));
      },
    );

    test(
      'D. Accounting Link Persistence: Create -> link account -> restart repo -> relationship remains',
      () async {
        const regId = 'cr-uuid-4444-5555-6666-777788889999';
        await cashRepo.createCashRegister(
          CashRegister(
            id: regId,
            companyId: companyA,
            name: 'Linked Cash',
            code: 'CR-LINKED',
            isActive: true,
            accountingAccountId: null,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );

        await cashRepo.linkAccountingAccount(
          registerId: regId,
          accountId: cashAccountA.uuid,
          companyId: companyA,
        );

        final freshRepo = CashRegisterRepositoryImpl(
          accountRepository: accountRepo,
          db: db,
        );
        final loaded = await freshRepo.getCashRegisterById(regId);

        expect(loaded, isNotNull);
        expect(loaded!.isLinked, isTrue);
        expect(loaded.accountingAccountId, equals(cashAccountA.uuid));

        final ready = await freshRepo.getAccountingReadyCashRegisters(companyA);
        expect(ready.length, equals(1));
        expect(ready.first.id, equals(regId));
      },
    );

    test(
      'E. Multiple Registers: Create three registers -> verify all 3 persist independently',
      () async {
        await cashRepo.createCashRegister(
          CashRegister(
            id: 'cr-multi-1-uuid-1111-2222-3333444455',
            companyId: companyA,
            name: 'Cash 1',
            code: 'C1',
            isActive: true,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
        await cashRepo.createCashRegister(
          CashRegister(
            id: 'cr-multi-2-uuid-1111-2222-3333444455',
            companyId: companyA,
            name: 'Cash 2',
            code: 'C2',
            isActive: true,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
        await cashRepo.createCashRegister(
          CashRegister(
            id: 'cr-multi-3-uuid-1111-2222-3333444455',
            companyId: companyA,
            name: 'Cash 3',
            code: 'C3',
            isActive: true,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );

        final freshRepo = CashRegisterRepositoryImpl(
          accountRepository: accountRepo,
          db: db,
        );
        final list = await freshRepo.getCashRegisters(companyA);
        expect(list.length, equals(3));
      },
    );

    test(
      'F & G & H. Unlinked Register: Preserved in DB & initialization page, omitted from transaction selectors until linked',
      () async {
        const regId = 'cr-unlinked-1111-2222-3333-444455556';
        await cashRepo.createCashRegister(
          CashRegister(
            id: regId,
            companyId: companyA,
            name: 'Unlinked Cash',
            code: 'CR-UN',
            isActive: true,
            accountingAccountId: null,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );

        final all = await cashRepo.getCashRegisters(companyA);
        expect(all.length, equals(1));
        expect(all.first.id, equals(regId));

        final readyBefore = await cashRepo.getAccountingReadyCashRegisters(
          companyA,
        );
        expect(readyBefore, isEmpty);

        final salesAdapter = AccountingSaleTreasuryAdapter(
          accountRepo,
          cashRegisterRepository: cashRepo,
        );
        final boxesBefore = await salesAdapter.listCashBoxAccounts();
        expect(boxesBefore, isEmpty);

        await cashRepo.linkAccountingAccount(
          registerId: regId,
          accountId: cashAccountA.uuid,
          companyId: companyA,
        );

        final readyAfter = await cashRepo.getAccountingReadyCashRegisters(
          companyA,
        );
        expect(readyAfter.length, equals(1));
        expect(readyAfter.first.id, equals(regId));

        await cashRepo.unlinkAccountingAccount(
          registerId: regId,
          companyId: companyA,
        );

        final allAfterUnlink = await cashRepo.getCashRegisters(companyA);
        expect(allAfterUnlink.length, equals(1));
        expect(allAfterUnlink.first.id, equals(regId));
        expect(allAfterUnlink.first.isLinked, isFalse);

        final readyAfterUnlink = await cashRepo.getAccountingReadyCashRegisters(
          companyA,
        );
        expect(readyAfterUnlink, isEmpty);
      },
    );

    test(
      'I. Default Register Persistence: Set default -> restart repo -> default remains',
      () async {
        const regId = 'cr-def-uuid-1111-2222-3333-44445566';
        await cashRepo.createCashRegister(
          CashRegister(
            id: regId,
            companyId: companyA,
            name: 'Default Cash',
            code: 'CR-DEF',
            isActive: true,
            accountingAccountId: cashAccountA.uuid,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );

        await cashRepo.setDefaultCashRegisterId(
          companyId: companyA,
          registerId: regId,
        );

        final freshRepo = CashRegisterRepositoryImpl(
          accountRepository: accountRepo,
          db: db,
        );
        final freshResolver = DefaultCashRegisterResolver(
          cashRegisterRepository: freshRepo,
          accountRepository: accountRepo,
        );

        final defaultResult = await freshResolver.resolveDefaultCashRegister(
          companyA,
        );
        expect(defaultResult.isValid, isTrue);
        expect(defaultResult.register?.id, equals(regId));
        expect(defaultResult.linkedAccount?.uuid, equals(cashAccountA.uuid));
      },
    );

    test(
      'J. Account Deactivation: Cash Register remains in DB, link state becomes ACCOUNTING_INVALID',
      () async {
        const regId = 'cr-deact-1111-2222-3333-4444-5555666';
        await cashRepo.createCashRegister(
          CashRegister(
            id: regId,
            companyId: companyA,
            name: 'Deact Cash',
            code: 'CR-DEACT',
            isActive: true,
            accountingAccountId: cashAccountA.uuid,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );

        accountRepo.addAccount(cashAccountA.copyWith(isActive: false));

        final all = await cashRepo.getCashRegisters(companyA);
        expect(all.length, equals(1));
        expect(all.first.id, equals(regId));

        final acc = await accountRepo.getByUuid(cashAccountA.uuid);
        final status = all.first.evaluateStatus(acc, targetCompanyId: companyA);
        expect(status, equals(CashRegisterAccountingStatus.invalid));

        final ready = await cashRepo.getAccountingReadyCashRegisters(companyA);
        expect(ready, isEmpty);
      },
    );

    test(
      'K. Company Isolation: Company A registers are isolated from Company B',
      () async {
        const regIdA = 'cr-comp-a-1111-2222-3333-44445555666';
        const regIdB = 'cr-comp-b-1111-2222-3333-44445555666';

        await cashRepo.createCashRegister(
          CashRegister(
            id: regIdA,
            companyId: companyA,
            name: 'Comp A Cash',
            code: 'C-A',
            isActive: true,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
        await cashRepo.createCashRegister(
          CashRegister(
            id: regIdB,
            companyId: companyB,
            name: 'Comp B Cash',
            code: 'C-B',
            isActive: true,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );

        final listA = await cashRepo.getCashRegisters(companyA);
        final listB = await cashRepo.getCashRegisters(companyB);

        expect(listA.length, equals(1));
        expect(listA.first.id, equals(regIdA));

        expect(listB.length, equals(1));
        expect(listB.first.id, equals(regIdB));
      },
    );
  });
}
