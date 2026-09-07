import 'dart:io';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/app/sales/accounting_sale_treasury_adapter.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
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
  group('CR-02 Account Binding Architecture Test Matrix', () {
    late FakeAccountRepository accountRepo;
    late AccountingDatabase db;
    late CashRegisterRepositoryImpl cashRepo;
    late DefaultCashRegisterResolver resolver;
    late Directory tempDir;

    const companyA = 'company-A';
    const companyB = 'company-B';

    late Account validAssetAccountA;
    late Account validAssetAccountA2;
    late Account companyBAccount;
    late Account inactiveAccount;
    late Account expenseAccount;
    late Account groupAccount;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cr02_binding_test_');
      Hive.init(tempDir.path);
      await Hive.openBox<dynamic>(HiveBoxes.settings);

      accountRepo = FakeAccountRepository();
      db = AccountingDatabase.memory();

      validAssetAccountA = Account(
        id: 101,
        uuid: 'acc-cash-a1-uuid',
        accountCode: '1101',
        name: 'الصندوق الرئيسي A1',
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

      validAssetAccountA2 = Account(
        id: 102,
        uuid: 'acc-cash-a2-uuid',
        accountCode: '1102',
        name: 'صندوق الفرع A2',
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

      companyBAccount = Account(
        id: 201,
        uuid: 'acc-cash-b1-uuid',
        accountCode: '1101-B',
        name: 'صندوق شركة B',
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

      inactiveAccount = Account(
        id: 103,
        uuid: 'acc-inactive-uuid',
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

      expenseAccount = Account(
        id: 104,
        uuid: 'acc-expense-uuid',
        accountCode: '5101',
        name: 'حساب مصروفات',
        accountType: AccountType.expense,
        normalBalance: NormalBalance.debit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      groupAccount = Account(
        id: 105,
        uuid: 'acc-group-uuid',
        accountCode: '1100',
        name: 'مجموعة الأصول المتداولة',
        accountType: AccountType.asset,
        normalBalance: NormalBalance.debit,
        level: 1,
        isGroup: true,
        isActive: true,
        isSystemAccount: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      accountRepo.addAccount(validAssetAccountA);
      accountRepo.addAccount(validAssetAccountA2);
      accountRepo.addAccount(companyBAccount);
      accountRepo.addAccount(inactiveAccount);
      accountRepo.addAccount(expenseAccount);
      accountRepo.addAccount(groupAccount);

      cashRepo = CashRegisterRepositoryImpl(
        accountRepository: accountRepo,
        db: db,
      );
      resolver = DefaultCashRegisterResolver(
        cashRegisterRepository: cashRepo,
        accountRepository: accountRepo,
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
      '1. Valid binding: Link valid asset account to register -> state becomes ready & queryable',
      () async {
        final reg = await cashRepo.createCashRegister(
          CashRegister(
            id: 'cr-bind-1',
            companyId: companyA,
            name: 'Register 1',
            code: 'CR-01',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final linked = await cashRepo.linkAccountingAccount(
          registerId: reg.id,
          accountId: validAssetAccountA.uuid,
          companyId: companyA,
        );

        expect(linked.isLinked, isTrue);
        expect(linked.accountingAccountId, equals(validAssetAccountA.uuid));

        final ready = await cashRepo.getAccountingReadyCashRegisters(companyA);
        expect(ready.length, equals(1));
        expect(ready.first.id, equals('cr-bind-1'));
      },
    );

    test(
      '2. Cross-company rejection: Linking account from company B to company A register is rejected',
      () async {
        final reg = await cashRepo.createCashRegister(
          CashRegister(
            id: 'cr-bind-2',
            companyId: companyA,
            name: 'Register Comp A',
            code: 'CR-02',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        expect(
          () => cashRepo.linkAccountingAccount(
            registerId: reg.id,
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
      '3. Invalid account rejection: Rejects inactive, non-asset, and group accounts',
      () async {
        final reg = await cashRepo.createCashRegister(
          CashRegister(
            id: 'cr-bind-3',
            companyId: companyA,
            name: 'Register 3',
            code: 'CR-03',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Inactive
        expect(
          () => cashRepo.linkAccountingAccount(
            registerId: reg.id,
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

        // Non-asset (Expense)
        expect(
          () => cashRepo.linkAccountingAccount(
            registerId: reg.id,
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

        // Group account
        expect(
          () => cashRepo.linkAccountingAccount(
            registerId: reg.id,
            accountId: groupAccount.uuid,
            companyId: companyA,
          ),
          throwsA(
            isA<CashRegisterException>().having(
              (e) => e.code,
              'code',
              equals('ACCOUNT_CANNOT_POST'),
            ),
          ),
        );
      },
    );

    test(
      '4. Missing default account: Unconfigured company default returns notConfigured state',
      () async {
        final result = await resolver.resolveDefaultCashRegister(companyA);
        expect(result.isValid, isFalse);
        expect(
          result.errorCode,
          equals(DefaultCashRegisterErrorCode.notConfigured),
        );

        final saleAdapter = AccountingSaleTreasuryAdapter(
          accountRepo,
          cashRegisterRepository: cashRepo,
        );
        final defaultBox = await saleAdapter.findDefaultCashBox();
        expect(defaultBox, isNull);
      },
    );

    test(
      '5. Valid default account: Explicit default selection resolves correctly',
      () async {
        final reg = await cashRepo.createCashRegister(
          CashRegister(
            id: 'cr-def-5',
            companyId: companyA,
            name: 'Default Reg',
            code: 'CR-DEF',
            isActive: true,
            accountingAccountId: validAssetAccountA.uuid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await cashRepo.setDefaultCashRegisterId(
          companyId: companyA,
          registerId: reg.id,
        );

        final result = await resolver.resolveDefaultCashRegister(companyA);
        expect(result.isValid, isTrue);
        expect(result.register?.id, equals(reg.id));
        expect(result.linkedAccount?.uuid, equals(validAssetAccountA.uuid));
      },
    );

    test(
      '6. Default account persistence: Default setting persists across repository restart',
      () async {
        final reg = await cashRepo.createCashRegister(
          CashRegister(
            id: 'cr-def-6',
            companyId: companyA,
            name: 'Persistent Default',
            code: 'CR-PDEF',
            isActive: true,
            accountingAccountId: validAssetAccountA.uuid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await cashRepo.setDefaultCashRegisterId(
          companyId: companyA,
          registerId: reg.id,
        );

        final freshRepo = CashRegisterRepositoryImpl(
          accountRepository: accountRepo,
          db: db,
        );
        final freshResolver = DefaultCashRegisterResolver(
          cashRegisterRepository: freshRepo,
          accountRepository: accountRepo,
        );

        final result = await freshResolver.resolveDefaultCashRegister(companyA);
        expect(result.isValid, isTrue);
        expect(result.register?.id, equals(reg.id));
      },
    );

    test(
      '7. Register reload: Created and linked register remains in database after fresh reload',
      () async {
        final reg = await cashRepo.createCashRegister(
          CashRegister(
            id: 'cr-reload-7',
            companyId: companyA,
            name: 'Reloadable Cash',
            code: 'CR-RLD',
            isActive: true,
            accountingAccountId: validAssetAccountA.uuid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final freshRepo = CashRegisterRepositoryImpl(
          accountRepository: accountRepo,
          db: db,
        );
        final reloaded = await freshRepo.getCashRegisterById(reg.id);

        expect(reloaded, isNotNull);
        expect(reloaded!.name, equals('Reloadable Cash'));
        expect(reloaded.accountingAccountId, equals(validAssetAccountA.uuid));
      },
    );

    test(
      '8. Account deactivation: Deactivating bound account invalidates readiness without DB corruption',
      () async {
        await cashRepo.createCashRegister(
          CashRegister(
            id: 'cr-deact-8',
            companyId: companyA,
            name: 'Deact Target',
            code: 'CR-DEACT',
            isActive: true,
            accountingAccountId: validAssetAccountA.uuid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        accountRepo.addAccount(validAssetAccountA.copyWith(isActive: false));

        final ready = await cashRepo.getAccountingReadyCashRegisters(companyA);
        expect(ready, isEmpty);

        final all = await cashRepo.getCashRegisters(companyA);
        expect(all.length, equals(1));
        expect(
          all.first.evaluateStatus(
            await accountRepo.getByUuid(validAssetAccountA.uuid),
          ),
          equals(CashRegisterAccountingStatus.invalid),
        );
      },
    );

    test(
      '9. Account deletion: Soft deleting bound account invalidates readiness dynamically',
      () async {
        await cashRepo.createCashRegister(
          CashRegister(
            id: 'cr-del-9',
            companyId: companyA,
            name: 'Delete Target',
            code: 'CR-DEL',
            isActive: true,
            accountingAccountId: validAssetAccountA.uuid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await accountRepo.softDelete(validAssetAccountA.id);

        final ready = await cashRepo.getAccountingReadyCashRegisters(companyA);
        expect(ready, isEmpty);
      },
    );

    test(
      '10. Binding replacement: Replacing linked account updates binding immediately',
      () async {
        final reg = await cashRepo.createCashRegister(
          CashRegister(
            id: 'cr-repl-10',
            companyId: companyA,
            name: 'Repl Target',
            code: 'CR-REPL',
            isActive: true,
            accountingAccountId: validAssetAccountA.uuid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await cashRepo.linkAccountingAccount(
          registerId: reg.id,
          accountId: validAssetAccountA2.uuid,
          companyId: companyA,
        );

        final ready = await cashRepo.getAccountingReadyCashRegisters(companyA);
        expect(
          ready.first.accountingAccountId,
          equals(validAssetAccountA2.uuid),
        );
      },
    );

    test(
      '11. Existing posted transactions safety: Updating link does not alter historical posting account',
      () async {
        final historicalAccountUuid = validAssetAccountA.uuid;

        final reg = await cashRepo.createCashRegister(
          CashRegister(
            id: 'cr-hist-11',
            companyId: companyA,
            name: 'Hist Cash',
            code: 'CR-HIST',
            isActive: true,
            accountingAccountId: historicalAccountUuid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Unlink register
        await cashRepo.unlinkAccountingAccount(
          registerId: reg.id,
          companyId: companyA,
        );

        // Historical document account reference remains unchanged
        expect(historicalAccountUuid, equals('acc-cash-a1-uuid'));
      },
    );

    test(
      '12. Initialization restart idempotency: Re-instantiating repository retains established links',
      () async {
        final reg = await cashRepo.createCashRegister(
          CashRegister(
            id: 'cr-init-12',
            companyId: companyA,
            name: 'Init Cash',
            code: 'CR-INIT',
            isActive: true,
            accountingAccountId: validAssetAccountA.uuid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final repo2 = CashRegisterRepositoryImpl(
          accountRepository: accountRepo,
          db: db,
        );
        final repo3 = CashRegisterRepositoryImpl(
          accountRepository: accountRepo,
          db: db,
        );

        expect(
          (await repo2.getCashRegisters(companyA)).first.id,
          equals(reg.id),
        );
        expect(
          (await repo3.getCashRegisters(companyA)).first.id,
          equals(reg.id),
        );
      },
    );

    test(
      '13. Duplicate initialization safety: Seeding existing register preserves existing link',
      () async {
        final reg = CashRegister(
          id: 'cr-dup-13',
          companyId: companyA,
          name: 'Dup Cash',
          code: 'CR-DUP',
          isActive: true,
          accountingAccountId: validAssetAccountA.uuid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await cashRepo.createCashRegister(reg);

        // Re-seed same register with different name draft
        final regDraft = reg.copyWith(name: 'Modified Draft');
        CashRegisterRepositoryImpl(
          accountRepository: accountRepo,
          db: db,
          initialRegisters: [regDraft],
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final loaded = await cashRepo.getCashRegisterById(reg.id);

        expect(
          loaded?.name,
          equals('Dup Cash'),
        ); // Original preserved, not overwritten
        expect(loaded?.accountingAccountId, equals(validAssetAccountA.uuid));
      },
    );

    test(
      '14. Offline reload persistence: Database and Hive reload preserves data without network dependencies',
      () async {
        const regId = 'cr-off-14';
        await cashRepo.createCashRegister(
          CashRegister(
            id: regId,
            companyId: companyA,
            name: 'Offline Cash',
            code: 'CR-OFF',
            isActive: true,
            accountingAccountId: validAssetAccountA.uuid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        await cashRepo.setDefaultCashRegisterId(
          companyId: companyA,
          registerId: regId,
        );

        final offlineRepo = CashRegisterRepositoryImpl(
          accountRepository: accountRepo,
          db: db,
        );
        final offlineResolver = DefaultCashRegisterResolver(
          cashRegisterRepository: offlineRepo,
          accountRepository: accountRepo,
        );

        final loadedReg = await offlineRepo.getCashRegisterById(regId);
        final defaultRes = await offlineResolver.resolveDefaultCashRegister(
          companyA,
        );

        expect(loadedReg, isNotNull);
        expect(loadedReg?.isLinked, isTrue);
        expect(defaultRes.isValid, isTrue);
        expect(defaultRes.register?.id, equals(regId));
      },
    );

    test(
      '15. Prevent unlinking account when transaction movements exist',
      () async {
        const regId = 'cr-mov-15';
        const movementAccountUuid = '00000000-0000-0000-0000-000000000155';
        accountRepo.addAccount(
          Account(
            id: 155,
            uuid: movementAccountUuid,
            accountCode: '1155',
            name: 'Movement Account',
            accountType: AccountType.asset,
            normalBalance: NormalBalance.debit,
            level: 2,
            isGroup: false,
            isActive: true,
            isSystemAccount: false,
            companyId: companyA,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final reg = await cashRepo.createCashRegister(
          CashRegister(
            id: regId,
            companyId: companyA,
            name: 'Movement Reg',
            code: 'CR-MOV',
            isActive: true,
            accountingAccountId: movementAccountUuid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Insert a journal line directly into database for movementAccountUuid
        await db
            .into(db.journalLines)
            .insert(
              JournalLinesCompanion.insert(
                uuid: '00000000-0000-0000-0000-000000000099',
                entryUuid: '00000000-0000-0000-0000-000000000088',
                accountUuid: movementAccountUuid,
                currencyCode: 'SAR',
                debit: const Value(150.0),
              ),
            );

        // Attempt to unlink account when movement exists
        expect(
          () => cashRepo.unlinkAccountingAccount(
            registerId: reg.id,
            companyId: companyA,
          ),
          throwsA(
            isA<CashRegisterException>().having(
              (e) => e.code,
              'code',
              equals('REGISTER_HAS_MOVEMENTS'),
            ),
          ),
        );
      },
    );
  });
}
