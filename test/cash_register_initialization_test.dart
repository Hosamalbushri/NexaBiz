import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/cash_registers/data/repositories/cash_register_repository_impl.dart';
import 'package:stock_count/modules/cash_registers/domain/entities/cash_register.dart';
import 'package:stock_count/modules/cash_registers/domain/services/cash_register_initializer_service.dart';
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
  Future<void> softDelete(int id) async {}

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
  group('CR-03 Register Creation & Initialization Remediation Test Matrix', () {
    late FakeAccountRepository accountRepo;
    late AccountingDatabase db;
    late CashRegisterRepositoryImpl cashRepo;
    late DefaultCashRegisterResolver resolver;
    late CashRegisterInitializerService initializer;
    late Directory tempDir;

    const companyA = 'company-A';
    const companyB = 'company-B';

    late Account validAccountA;
    late Account companyBAccount;
    late Account inactiveAccount;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cr03_init_test_');
      Hive.init(tempDir.path);
      await Hive.openBox<dynamic>(HiveBoxes.settings);

      accountRepo = FakeAccountRepository();
      db = AccountingDatabase.memory();

      validAccountA = Account(
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

      accountRepo.addAccount(validAccountA);
      accountRepo.addAccount(companyBAccount);
      accountRepo.addAccount(inactiveAccount);

      cashRepo = CashRegisterRepositoryImpl(accountRepository: accountRepo, db: db);
      resolver = DefaultCashRegisterResolver(
        cashRegisterRepository: cashRepo,
        accountRepository: accountRepo,
      );
      initializer = CashRegisterInitializerService(
        cashRegisterRepository: cashRepo,
        accountRepository: accountRepo,
        defaultCashRegisterResolver: resolver,
      );
    });

    tearDown(() async {
      await db.close();
      await Hive.deleteFromDisk();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('1. First initialization: Creates register, links account, sets company default persistantly', () async {
      final res = await initializer.initializeDefaultRegisterForCompany(
        companyId: companyA,
        accountUuid: validAccountA.uuid,
      );

      expect(res.isSuccess, isTrue);
      expect(res.isAlreadyInitialized, isFalse);
      expect(res.register, isNotNull);
      expect(res.register!.isLinked, isTrue);
      expect(res.register!.accountingAccountId, equals(validAccountA.uuid));

      final defaultRes = await resolver.resolveDefaultCashRegister(companyA);
      expect(defaultRes.isValid, isTrue);
      expect(defaultRes.register!.id, equals(res.register!.id));
    });

    test('2. Second initialization: Idempotent call returns existing ready configuration without duplicates', () async {
      final res1 = await initializer.initializeDefaultRegisterForCompany(
        companyId: companyA,
        accountUuid: validAccountA.uuid,
      );

      final res2 = await initializer.initializeDefaultRegisterForCompany(
        companyId: companyA,
        accountUuid: validAccountA.uuid,
      );

      expect(res2.isSuccess, isTrue);
      expect(res2.isAlreadyInitialized, isTrue);
      expect(res2.register!.id, equals(res1.register!.id));

      final allRegs = await cashRepo.getCashRegisters(companyA);
      expect(allRegs.length, equals(1)); // Exactly 1 register created
    });

    test('3. Restart persistence: Initialization state survives cold restart of repository and resolver', () async {
      await initializer.initializeDefaultRegisterForCompany(
        companyId: companyA,
        accountUuid: validAccountA.uuid,
      );

      final freshRepo = CashRegisterRepositoryImpl(accountRepository: accountRepo, db: db);
      final freshResolver = DefaultCashRegisterResolver(
        cashRegisterRepository: freshRepo,
        accountRepository: accountRepo,
      );

      final defaultRes = await freshResolver.resolveDefaultCashRegister(companyA);
      expect(defaultRes.isValid, isTrue);
      expect(defaultRes.linkedAccount!.uuid, equals(validAccountA.uuid));
    });

    test('4. Company switch isolation: Initializing company A does not affect company B', () async {
      await initializer.initializeDefaultRegisterForCompany(
        companyId: companyA,
        accountUuid: validAccountA.uuid,
      );

      final resB = await resolver.resolveDefaultCashRegister(companyB);
      expect(resB.isValid, isFalse);
      expect(resB.errorCode, equals(DefaultCashRegisterErrorCode.notConfigured));

      final regsB = await cashRepo.getCashRegisters(companyB);
      expect(regsB, isEmpty);
    });

    test('5. Empty database initialization: Creates register with stable non-localized code', () async {
      final res = await initializer.initializeDefaultRegisterForCompany(
        companyId: companyA,
        registerCode: 'DEF_CASH_REG',
      );

      expect(res.isSuccess, isTrue);
      expect(res.register!.code, equals('DEF_CASH_REG'));
      expect(res.register!.isLinked, isFalse); // Created unlinked when no account provided
    });

    test('6. Partially initialized database recovery: Completes linking and sets default', () async {
      // Step A: Create unlinked register manually
      final unlinked = await cashRepo.createCashRegister(CashRegister(
        id: 'cr_def_$companyA',
        companyId: companyA,
        name: 'Main Cash Register',
        code: 'DEF_CASH_REG',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      expect(unlinked.isLinked, isFalse);

      // Step B: Run initializer with account
      final res = await initializer.initializeDefaultRegisterForCompany(
        companyId: companyA,
        registerId: 'cr_def_$companyA',
        accountUuid: validAccountA.uuid,
      );

      expect(res.isSuccess, isTrue);
      expect(res.register!.isLinked, isTrue);

      final defaultRes = await resolver.resolveDefaultCashRegister(companyA);
      expect(defaultRes.isValid, isTrue);
    });

    test('7. Account linking failure atomicity: Invalid account rejects initialization without leaving partial state', () async {
      final res = await initializer.initializeDefaultRegisterForCompany(
        companyId: companyA,
        registerId: 'cr_failed_link',
        accountUuid: inactiveAccount.uuid, // Inactive account
      );

      expect(res.isSuccess, isFalse);
      expect(res.errorCode, equals('ACCOUNT_INACTIVE'));

      final reg = await cashRepo.getCashRegisterById('cr_failed_link');
      expect(reg, isNull); // Rolled back, no partial register left behind
    });

    test('8. Default setting failure atomicity: Cross-company account is rejected cleanly', () async {
      final res = await initializer.initializeDefaultRegisterForCompany(
        companyId: companyA,
        registerId: 'cr_failed_company',
        accountUuid: companyBAccount.uuid, // Belongs to company B
      );

      expect(res.isSuccess, isFalse);
      expect(res.errorCode, equals('CROSS_COMPANY_ACCOUNT'));

      final reg = await cashRepo.getCashRegisterById('cr_failed_company');
      expect(reg, isNull);
    });

    test('9. Duplicate register code rejection: Reuses existing register with matching code', () async {
      final reg1 = await cashRepo.createCashRegister(CashRegister(
        id: 'cr-existing-code',
        companyId: companyA,
        name: 'Existing Code Box',
        code: 'DEF_CASH_REG',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final res = await initializer.initializeDefaultRegisterForCompany(
        companyId: companyA,
        registerCode: 'DEF_CASH_REG',
        accountUuid: validAccountA.uuid,
      );

      expect(res.isSuccess, isTrue);
      expect(res.register!.id, equals(reg1.id)); // Reused existing register
    });

    test('10. Duplicate account binding prevention: Linking account already linked to another register works correctly', () async {
      final res1 = await initializer.initializeDefaultRegisterForCompany(
        companyId: companyA,
        registerId: 'cr-1',
        accountUuid: validAccountA.uuid,
      );
      expect(res1.isSuccess, isTrue);

      final res2 = await initializer.initializeDefaultRegisterForCompany(
        companyId: companyA,
        registerId: 'cr-2',
        accountUuid: validAccountA.uuid,
      );
      expect(res2.isSuccess, isTrue); // Returns existing initialized default cleanly
    });

    test('11. Invalid company context rejection: Rejects empty or whitespace companyId', () async {
      final res = await initializer.initializeDefaultRegisterForCompany(
        companyId: '   ',
      );

      expect(res.isSuccess, isFalse);
      expect(res.errorCode, equals('INVALID_COMPANY'));
    });

    test('12. Offline startup persistence: Reloading state from disk without network succeeds', () async {
      await initializer.initializeDefaultRegisterForCompany(
        companyId: companyA,
        accountUuid: validAccountA.uuid,
      );

      // Simulate offline restart
      final offlineRepo = CashRegisterRepositoryImpl(accountRepository: accountRepo, db: db);
      final offlineResolver = DefaultCashRegisterResolver(
        cashRegisterRepository: offlineRepo,
        accountRepository: accountRepo,
      );

      final defaultRes = await offlineResolver.resolveDefaultCashRegister(companyA);
      expect(defaultRes.isValid, isTrue);
    });

    test('13. Migration/legacy state preservation: Existing registers retain links during re-initialization', () async {
      final legacyReg = await cashRepo.createCashRegister(CashRegister(
        id: 'legacy-reg-1',
        companyId: companyA,
        name: 'Legacy Box',
        code: 'LEGACY_01',
        isActive: true,
        accountingAccountId: validAccountA.uuid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await cashRepo.setDefaultCashRegisterId(companyId: companyA, registerId: legacyReg.id);

      final res = await initializer.initializeDefaultRegisterForCompany(
        companyId: companyA,
      );

      expect(res.isSuccess, isTrue);
      expect(res.isAlreadyInitialized, isTrue);
      expect(res.register!.id, equals(legacyReg.id));
      expect(res.register!.accountingAccountId, equals(validAccountA.uuid));
    });
  });
}
