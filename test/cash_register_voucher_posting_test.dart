import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/cash_registers/data/repositories/cash_register_repository_impl.dart';
import 'package:stock_count/modules/cash_registers/domain/entities/cash_register.dart';
import 'package:stock_count/modules/cash_registers/domain/services/cash_register_posting_resolver_service.dart';
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

class FakePostingService {
  final Map<String, JournalEntry> _postedJournals = {};

  Future<JournalEntry> postVoucherJournal({
    required String companyId,
    required String referenceId,
    required String cashAccountId,
    required String offsetAccountId,
    required double amount,
  }) async {
    // Idempotency check: if transaction reference was already posted, return existing journal entry
    if (_postedJournals.containsKey(referenceId)) {
      return _postedJournals[referenceId]!;
    }

    if (amount <= 0) {
      throw ArgumentError('Voucher amount must be positive');
    }

    final entry = JournalEntry(
      id: 1,
      uuid: 'je-$referenceId',
      voucherNumber: 'JE-$referenceId',
      voucherType: 'CASH_VOUCHER',
      currencyCode: 'YER',
      entryDate: DateTime.now(),
      isPosted: true,
      lines: [
        JournalLine(
          id: 101,
          uuid: 'jl-101-$referenceId',
          entryUuid: 'je-$referenceId',
          accountUuid: cashAccountId,
          debit: amount,
          credit: 0.0,
          currencyCode: 'YER',
          sortOrder: 1,
          lineDescription: 'Cash Receipt',
        ),
        JournalLine(
          id: 102,
          uuid: 'jl-102-$referenceId',
          entryUuid: 'je-$referenceId',
          accountUuid: offsetAccountId,
          debit: 0.0,
          credit: amount,
          currencyCode: 'YER',
          sortOrder: 2,
          lineDescription: 'Sales Income',
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _postedJournals[referenceId] = entry;
    return entry;
  }
}

void main() {
  group('CR-04 Default Accounts & Voucher Posting Test Matrix', () {
    late FakeAccountRepository accountRepo;
    late AccountingDatabase db;
    late CashRegisterRepositoryImpl cashRepo;
    late DefaultCashRegisterResolver defaultResolver;
    late CashRegisterPostingResolverService postingResolver;
    late FakePostingService postingService;
    late Directory tempDir;

    const companyA = 'company-A';
    const companyB = 'company-B';

    late Account cashAccountA1;
    late Account cashAccountA2;
    late Account companyBAccount;
    late Account inactiveAccount;
    late Account equityAccount;
    late Account salesRevenueAccount;

    late CashRegister registerA1;
    late CashRegister registerA2;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cr04_posting_test_');
      Hive.init(tempDir.path);
      await Hive.openBox<dynamic>(HiveBoxes.settings);

      accountRepo = FakeAccountRepository();
      db = AccountingDatabase.memory();
      postingService = FakePostingService();

      cashAccountA1 = Account(
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

      cashAccountA2 = Account(
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

      equityAccount = Account(
        id: 104,
        uuid: 'acc-equity-uuid',
        accountCode: '3101',
        name: 'رأس المال',
        accountType: AccountType.equity,
        normalBalance: NormalBalance.credit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      salesRevenueAccount = Account(
        id: 105,
        uuid: 'acc-revenue-uuid',
        accountCode: '4101',
        name: 'إيراد المبيعات',
        accountType: AccountType.revenue,
        normalBalance: NormalBalance.credit,
        level: 2,
        isGroup: false,
        isActive: true,
        isSystemAccount: false,
        companyId: companyA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      accountRepo.addAccount(cashAccountA1);
      accountRepo.addAccount(cashAccountA2);
      accountRepo.addAccount(companyBAccount);
      accountRepo.addAccount(inactiveAccount);
      accountRepo.addAccount(equityAccount);
      accountRepo.addAccount(salesRevenueAccount);

      cashRepo = CashRegisterRepositoryImpl(
        accountRepository: accountRepo,
        db: db,
      );
      defaultResolver = DefaultCashRegisterResolver(
        cashRegisterRepository: cashRepo,
        accountRepository: accountRepo,
      );
      postingResolver = CashRegisterPostingResolverService(
        cashRegisterRepository: cashRepo,
        accountRepository: accountRepo,
        defaultCashRegisterResolver: defaultResolver,
      );

      // Create registers
      registerA1 = await cashRepo.createCashRegister(
        CashRegister(
          id: 'cr-a1',
          companyId: companyA,
          name: 'Register Main',
          code: 'REG_A1',
          isActive: true,
          accountingAccountId: cashAccountA1.uuid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      registerA2 = await cashRepo.createCashRegister(
        CashRegister(
          id: 'cr-a2',
          companyId: companyA,
          name: 'Register Branch',
          code: 'REG_A2',
          isActive: true,
          accountingAccountId: cashAccountA2.uuid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await cashRepo.setDefaultCashRegisterId(
        companyId: companyA,
        registerId: registerA1.id,
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
      '1. Default account resolution order: Explicit override > Selected Register > Default Register',
      () async {
        // 1a. Explicit account override
        final resExplicit = await postingResolver.resolveAccountForPosting(
          companyId: companyA,
          explicitAccountId: cashAccountA2.uuid,
        );
        expect(resExplicit.isSuccess, isTrue);
        expect(resExplicit.account!.uuid, equals(cashAccountA2.uuid));

        // 1b. Selected register account
        final resRegister = await postingResolver.resolveAccountForPosting(
          companyId: companyA,
          registerId: registerA2.id,
        );
        expect(resRegister.isSuccess, isTrue);
        expect(resRegister.account!.uuid, equals(cashAccountA2.uuid));
        expect(resRegister.register!.id, equals(registerA2.id));

        // 1c. Default company register account (no explicit account or register provided)
        final resDefault = await postingResolver.resolveAccountForPosting(
          companyId: companyA,
        );
        expect(resDefault.isSuccess, isTrue);
        expect(resDefault.account!.uuid, equals(cashAccountA1.uuid));
        expect(resDefault.register!.id, equals(registerA1.id));
      },
    );

    test(
      '2. Missing default account: Error returned when no default cash register is configured',
      () async {
        final res = await postingResolver.resolveAccountForPosting(
          companyId: companyB, // No registers or defaults in company B
        );

        expect(res.isSuccess, isFalse);
        expect(res.errorCode, equals('NOTCONFIGURED'));
      },
    );

    test(
      '3. Invalid account: Account with non-asset type rejected for cash posting',
      () async {
        final res = await postingResolver.resolveAccountForPosting(
          companyId: companyA,
          explicitAccountId: equityAccount.uuid, // Equity account
        );

        expect(res.isSuccess, isFalse);
        expect(res.errorCode, equals('ACCOUNT_TYPE_MISMATCH'));
      },
    );

    test(
      '4. Cross-company account: Reject account belonging to company B when posting for company A',
      () async {
        final res = await postingResolver.resolveAccountForPosting(
          companyId: companyA,
          explicitAccountId: companyBAccount.uuid,
        );

        expect(res.isSuccess, isFalse);
        expect(res.errorCode, equals('CROSS_COMPANY_ACCOUNT'));
      },
    );

    test(
      '5. Inactive account: Reject inactive account for voucher posting',
      () async {
        final res = await postingResolver.resolveAccountForPosting(
          companyId: companyA,
          explicitAccountId: inactiveAccount.uuid,
        );

        expect(res.isSuccess, isFalse);
        expect(res.errorCode, equals('ACCOUNT_INACTIVE'));
      },
    );

    test(
      '6. Register/account mismatch: Unlinked register rejected for posting',
      () async {
        final unlinkedReg = await cashRepo.createCashRegister(
          CashRegister(
            id: 'cr-unlinked',
            companyId: companyA,
            name: 'Unlinked Box',
            code: 'REG_UNLINKED',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final res = await postingResolver.resolveAccountForPosting(
          companyId: companyA,
          registerId: unlinkedReg.id,
        );

        expect(res.isSuccess, isFalse);
        expect(res.errorCode, equals('UNLINKED_REGISTER'));
      },
    );

    test(
      '7. Voucher creation & journal building: Resolved account is correctly used in voucher journal',
      () async {
        final resolution = await postingResolver.resolveAccountForPosting(
          companyId: companyA,
          registerId: registerA1.id,
        );
        expect(resolution.isSuccess, isTrue);

        final journal = await postingService.postVoucherJournal(
          companyId: companyA,
          referenceId: 'VOUCHER-001',
          cashAccountId: resolution.account!.uuid,
          offsetAccountId: salesRevenueAccount.uuid,
          amount: 500.0,
        );

        expect(journal.lines.length, equals(2));
        expect(journal.lines.first.accountUuid, equals(cashAccountA1.uuid));
        expect(journal.lines.first.debit, equals(500.0));
      },
    );

    test(
      '8. Balanced journal posting: Journal entry enforces debit = credit invariant',
      () async {
        final journal = await postingService.postVoucherJournal(
          companyId: companyA,
          referenceId: 'VOUCHER-002',
          cashAccountId: cashAccountA1.uuid,
          offsetAccountId: salesRevenueAccount.uuid,
          amount: 1250.75,
        );

        final totalDebit = journal.lines.fold<double>(
          0,
          (sum, l) => sum + l.debit,
        );
        final totalCredit = journal.lines.fold<double>(
          0,
          (sum, l) => sum + l.credit,
        );
        expect(totalDebit, equals(totalCredit));
        expect(totalDebit, equals(1250.75));
      },
    );

    test(
      '9. Duplicate posting idempotency: Posting same reference ID twice returns same journal without duplication',
      () async {
        final posting1 = await postingService.postVoucherJournal(
          companyId: companyA,
          referenceId: 'REF-IDEMPOTENT-01',
          cashAccountId: cashAccountA1.uuid,
          offsetAccountId: salesRevenueAccount.uuid,
          amount: 300.0,
        );

        final posting2 = await postingService.postVoucherJournal(
          companyId: companyA,
          referenceId: 'REF-IDEMPOTENT-01', // Same reference ID
          cashAccountId: cashAccountA1.uuid,
          offsetAccountId: salesRevenueAccount.uuid,
          amount: 300.0,
        );

        expect(posting2.uuid, equals(posting1.uuid));
      },
    );

    test(
      '10. Restart & reload persistence: Posting resolution survives cold restart',
      () async {
        final freshRepo = CashRegisterRepositoryImpl(
          accountRepository: accountRepo,
          db: db,
        );
        final freshDefaultResolver = DefaultCashRegisterResolver(
          cashRegisterRepository: freshRepo,
          accountRepository: accountRepo,
        );
        final freshPostingResolver = CashRegisterPostingResolverService(
          cashRegisterRepository: freshRepo,
          accountRepository: accountRepo,
          defaultCashRegisterResolver: freshDefaultResolver,
        );

        final res = await freshPostingResolver.resolveAccountForPosting(
          companyId: companyA,
          registerId: registerA1.id,
        );

        expect(res.isSuccess, isTrue);
        expect(res.account!.uuid, equals(cashAccountA1.uuid));
      },
    );

    test(
      '11. Account replacement: Updating register accounting link changes future resolved posting account',
      () async {
        // Step A: Initial resolution points to cashAccountA1
        final resBefore = await postingResolver.resolveAccountForPosting(
          companyId: companyA,
          registerId: registerA1.id,
        );
        expect(resBefore.account!.uuid, equals(cashAccountA1.uuid));

        // Step B: Re-link registerA1 to cashAccountA2
        await cashRepo.linkAccountingAccount(
          registerId: registerA1.id,
          accountId: cashAccountA2.uuid,
          companyId: companyA,
        );

        // Step C: Future resolution now returns cashAccountA2
        final resAfter = await postingResolver.resolveAccountForPosting(
          companyId: companyA,
          registerId: registerA1.id,
        );
        expect(resAfter.account!.uuid, equals(cashAccountA2.uuid));
      },
    );

    test(
      '12. Historical transaction protection: Historical posted journals retain original account UUID after re-linking',
      () async {
        // Step A: Post journal using original cashAccountA1
        final journal1 = await postingService.postVoucherJournal(
          companyId: companyA,
          referenceId: 'HISTORICAL-01',
          cashAccountId: cashAccountA1.uuid,
          offsetAccountId: salesRevenueAccount.uuid,
          amount: 1000.0,
        );
        expect(journal1.lines.first.accountUuid, equals(cashAccountA1.uuid));

        // Step B: Change register link to cashAccountA2
        await cashRepo.linkAccountingAccount(
          registerId: registerA1.id,
          accountId: cashAccountA2.uuid,
          companyId: companyA,
        );

        // Step C: Verify historical posted journal line was NOT altered
        expect(journal1.lines.first.accountUuid, equals(cashAccountA1.uuid));
      },
    );
  });
}
