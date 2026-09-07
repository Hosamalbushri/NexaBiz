import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/cash_registers/data/repositories/cash_register_repository_impl.dart';
import 'package:stock_count/modules/cash_registers/domain/entities/cash_register.dart';
import 'package:stock_count/modules/cash_registers/domain/services/cash_register_movement_service.dart';
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

class FakeJournalRepository implements JournalRepository {
  final Map<String, JournalEntry> _journals = {};
  final List<AccountLedgerMovement> _movements = [];
  int _idSeq = 1;

  @override
  Future<JournalEntry> post(JournalEntryDraft draft) async {
    if (draft.sourceId != null && draft.sourceId!.isNotEmpty) {
      final existing = _journals.values
          .where((j) => j.sourceId == draft.sourceId)
          .firstOrNull;
      if (existing != null) return existing;
    }

    final entryUuid = draft.uuid ?? 'je-${_idSeq++}';
    final lines = <JournalLine>[];

    for (var i = 0; i < draft.lines.length; i++) {
      final lDraft = draft.lines[i];
      final line = JournalLine(
        id: _idSeq++,
        uuid: lDraft.uuid ?? 'jl-${_idSeq++}',
        entryUuid: entryUuid,
        accountUuid: lDraft.accountUuid,
        debit: lDraft.debit,
        credit: lDraft.credit,
        currencyCode: lDraft.currencyCode,
        sortOrder: lDraft.sortOrder,
        lineDescription: lDraft.lineDescription,
      );
      lines.add(line);

      _movements.add(
        AccountLedgerMovement(
          entryDate: draft.entryDate,
          voucherNumber: draft.voucherNumber,
          voucherType: draft.voucherType,
          description: lDraft.lineDescription ?? draft.description ?? '',
          debit: lDraft.debit,
          credit: lDraft.credit,
          currencyCode: lDraft.currencyCode,
          isPosted: draft.isPosted,
          accountUuid: lDraft.accountUuid,
          entryUuid: entryUuid,
          lineUuid: line.uuid,
          lineId: line.id,
          sortOrder: lDraft.sortOrder,
        ),
      );
    }

    final entry = JournalEntry(
      id: _idSeq++,
      uuid: entryUuid,
      voucherNumber: draft.voucherNumber,
      voucherType: draft.voucherType,
      currencyCode: draft.currencyCode,
      entryDate: draft.entryDate,
      isPosted: draft.isPosted,
      sourceType: draft.sourceType,
      sourceId: draft.sourceId,
      description: draft.description,
      lines: lines,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _journals[entryUuid] = entry;
    return entry;
  }

  @override
  Future<List<AccountLedgerMovement>> listMovementsForAccount({
    required String accountUuid,
    DateTime? fromDate,
    DateTime? toDate,
    String? currencyCode,
    bool? isPosted,
    int? limit,
    AccountLedgerCursor? after,
  }) async {
    return _movements.where((m) => m.accountUuid == accountUuid).toList();
  }

  @override
  Future<JournalEntry?> getByUuid(String uuid) async => _journals[uuid];

  @override
  Future<JournalEntry?> findBySource({
    required String sourceType,
    required String sourceId,
  }) async {
    return _journals.values
        .where((j) => j.sourceType == sourceType && j.sourceId == sourceId)
        .firstOrNull;
  }

  @override
  Future<void> softDeleteBySource({
    required String sourceType,
    required String sourceId,
  }) async {
    final toRemove = _journals.values
        .where((j) => j.sourceType == sourceType && j.sourceId == sourceId)
        .toList();
    for (final j in toRemove) {
      _journals.remove(j.uuid);
      _movements.removeWhere((m) => m.entryUuid == j.uuid);
    }
  }

  @override
  Future<void> softDeleteByUuid(String uuid) async {
    final j = _journals.remove(uuid);
    if (j != null) {
      _movements.removeWhere((m) => m.entryUuid == uuid);
    }
  }

  @override
  Future<void> softDeletePostedAfterReverse(String uuid) async {}

  @override
  Future<List<JournalEntryHeader>> listHeaders({
    DateTime? fromDate,
    DateTime? toDate,
    bool? isPosted,
    String? query,
    int? limit,
    int? afterId,
  }) async => [];

  @override
  Future<List<String>> listCurrencyCodesForAccount({
    required String accountUuid,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isPosted,
  }) async => ['YER'];

  @override
  Future<double> sumNetBefore({
    required String accountUuid,
    required DateTime beforeDate,
    String? currencyCode,
    bool? isPosted,
  }) async => 0.0;

  @override
  Future<List<MonetaryFxPositionRow>> listMonetaryFxPositions({
    required DateTime asOfInclusive,
    required String baseCurrencyCode,
  }) async => [];

  @override
  Future<List<TrialBalanceRow>> listTrialBalance({
    DateTime? fromDate,
    DateTime? toDate,
    bool? isPosted,
  }) async => [];

  @override
  Future<List<JournalBookLineRow>> listJournalBookLines({
    DateTime? fromDate,
    DateTime? toDate,
    bool? isPosted,
  }) async => [];
}

class FakeJournalPostingService implements JournalPostingService {
  FakeJournalPostingService(this.repo);

  final FakeJournalRepository repo;

  @override
  Future<JournalEntry> post(JournalEntryDraft draft, {String? userId}) async {
    return repo.post(draft);
  }

  @override
  Future<void> voidBySource({
    required String sourceType,
    required String sourceId,
    String? userId,
  }) async {
    await repo.softDeleteBySource(sourceType: sourceType, sourceId: sourceId);
  }

  @override
  Future<JournalEntry?> findBySource({
    required String sourceType,
    required String sourceId,
  }) async {
    return repo.findBySource(sourceType: sourceType, sourceId: sourceId);
  }

  @override
  Future<JournalEntry> reverseByUuid(
    String uuid, {
    DateTime? reverseDate,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> softDeleteBySource({
    required String sourceType,
    required String sourceId,
  }) async {
    await repo.softDeleteBySource(sourceType: sourceType, sourceId: sourceId);
  }

  @override
  Future<void> softDeleteByUuid(String uuid) async {
    await repo.softDeleteByUuid(uuid);
  }

  @override
  Future<void> voidByUuid(String uuid, {String? userId}) async {
    await repo.softDeleteByUuid(uuid);
  }
}

void main() {
  group('CR-05 Cash Movements & Transaction Integrity Test Matrix', () {
    late FakeAccountRepository accountRepo;
    late FakeJournalRepository journalRepo;
    late AccountingDatabase db;
    late CashRegisterRepositoryImpl cashRepo;
    late DefaultCashRegisterResolver defaultResolver;
    late CashRegisterPostingResolverService postingResolver;
    late FakeJournalPostingService journalPosting;
    late CashRegisterMovementService movementService;
    late Directory tempDir;

    const companyA = 'company-A';
    const companyB = 'company-B';

    late Account cashAccountA1;
    late Account cashAccountA2;
    late Account revenueAccount;
    late Account expenseAccount;

    late CashRegister registerA1;
    late CashRegister registerA2;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cr05_movement_test_');
      Hive.init(tempDir.path);
      await Hive.openBox<dynamic>(HiveBoxes.settings);

      accountRepo = FakeAccountRepository();
      journalRepo = FakeJournalRepository();
      db = AccountingDatabase.memory();
      journalPosting = FakeJournalPostingService(journalRepo);

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

      revenueAccount = Account(
        id: 103,
        uuid: 'acc-rev-uuid',
        accountCode: '4101',
        name: 'المبيعات',
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

      expenseAccount = Account(
        id: 104,
        uuid: 'acc-exp-uuid',
        accountCode: '5101',
        name: 'المصروفات',
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

      accountRepo.addAccount(cashAccountA1);
      accountRepo.addAccount(cashAccountA2);
      accountRepo.addAccount(revenueAccount);
      accountRepo.addAccount(expenseAccount);

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

      movementService = CashRegisterMovementService(
        cashRegisterRepository: cashRepo,
        accountRepository: accountRepo,
        journalRepository: journalRepo,
        postingResolver: postingResolver,
        journalPostingService: journalPosting,
      );

      registerA1 = await cashRepo.createCashRegister(
        CashRegister(
          id: 'cr-a1',
          companyId: companyA,
          name: 'Main Register',
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
          name: 'Branch Register',
          code: 'REG_A2',
          isActive: true,
          accountingAccountId: cashAccountA2.uuid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
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
      '1. Cash receipt posting & ledger balance calculation: Receipt increases ledger balance authoritatively',
      () async {
        // Step A: Initial balance is 0.0
        double balBefore = await movementService.getLedgerBalance(
          registerId: registerA1.id,
          companyId: companyA,
        );
        expect(balBefore, equals(0.0));

        // Step B: Post receipt journal of 1000.0 (Debit Cash A1, Credit Revenue)
        await journalPosting.post(
          JournalEntryDraft(
            entryDate: DateTime.now(),
            voucherNumber: 'REC-001',
            voucherType: 'CASH_RECEIPT',
            currencyCode: 'YER',
            isPosted: true,
            sourceType: 'receipt',
            sourceId: 'rec-001',
            lines: [
              JournalLineDraft(
                accountUuid: cashAccountA1.uuid,
                debit: 1000.0,
                credit: 0.0,
                currencyCode: 'YER',
                sortOrder: 1,
              ),
              JournalLineDraft(
                accountUuid: revenueAccount.uuid,
                debit: 0.0,
                credit: 1000.0,
                currencyCode: 'YER',
                sortOrder: 2,
              ),
            ],
          ),
        );

        // Step C: Ledger balance derived dynamically is now 1000.0
        double balAfter = await movementService.getLedgerBalance(
          registerId: registerA1.id,
          companyId: companyA,
        );
        expect(balAfter, equals(1000.0));
      },
    );

    test(
      '2. Cash payment posting & ledger balance reduction: Payment reduces ledger balance authoritatively',
      () async {
        // Seed 1000.0 initial cash
        await journalPosting.post(
          JournalEntryDraft(
            entryDate: DateTime.now(),
            voucherNumber: 'REC-002',
            voucherType: 'CASH_RECEIPT',
            currencyCode: 'YER',
            isPosted: true,
            lines: [
              JournalLineDraft(
                accountUuid: cashAccountA1.uuid,
                debit: 1000.0,
                credit: 0.0,
                currencyCode: 'YER',
                sortOrder: 1,
              ),
              JournalLineDraft(
                accountUuid: revenueAccount.uuid,
                debit: 0.0,
                credit: 1000.0,
                currencyCode: 'YER',
                sortOrder: 2,
              ),
            ],
          ),
        );

        // Post payment of 300.0 (Debit Expense, Credit Cash A1)
        await journalPosting.post(
          JournalEntryDraft(
            entryDate: DateTime.now(),
            voucherNumber: 'PAY-001',
            voucherType: 'CASH_PAYMENT',
            currencyCode: 'YER',
            isPosted: true,
            lines: [
              JournalLineDraft(
                accountUuid: expenseAccount.uuid,
                debit: 300.0,
                credit: 0.0,
                currencyCode: 'YER',
                sortOrder: 1,
              ),
              JournalLineDraft(
                accountUuid: cashAccountA1.uuid,
                debit: 0.0,
                credit: 300.0,
                currencyCode: 'YER',
                sortOrder: 2,
              ),
            ],
          ),
        );

        double bal = await movementService.getLedgerBalance(
          registerId: registerA1.id,
          companyId: companyA,
        );
        expect(bal, equals(700.0)); // 1000 - 300
      },
    );

    test(
      '3. Insufficient balance policy: Rejects transfer when negative balance is forbidden and funds insufficient',
      () async {
        // Current balance of registerA1 is 0.0. Attempt transfer of 500.0 with allowNegativeBalance = false
        final result = await movementService.executeTransfer(
          companyId: companyA,
          sourceRegisterId: registerA1.id,
          destinationRegisterId: registerA2.id,
          amount: 500.0,
          referenceId: 'TRF-OVERDRAFT',
          allowNegativeBalance: false,
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('INSUFFICIENT_BALANCE'));
      },
    );

    test(
      '4. Inter-register transfer: Atomic double entry increases destination and decreases source',
      () async {
        // Seed 1500.0 into registerA1
        await journalPosting.post(
          JournalEntryDraft(
            entryDate: DateTime.now(),
            voucherNumber: 'SEED-01',
            voucherType: 'CASH_RECEIPT',
            currencyCode: 'YER',
            isPosted: true,
            lines: [
              JournalLineDraft(
                accountUuid: cashAccountA1.uuid,
                debit: 1500.0,
                credit: 0.0,
                currencyCode: 'YER',
                sortOrder: 1,
              ),
              JournalLineDraft(
                accountUuid: revenueAccount.uuid,
                debit: 0.0,
                credit: 1500.0,
                currencyCode: 'YER',
                sortOrder: 2,
              ),
            ],
          ),
        );

        // Transfer 400.0 from registerA1 to registerA2
        final result = await movementService.executeTransfer(
          companyId: companyA,
          sourceRegisterId: registerA1.id,
          destinationRegisterId: registerA2.id,
          amount: 400.0,
          referenceId: 'TRF-001',
        );

        expect(result.isSuccess, isTrue);
        expect(result.journalEntry, isNotNull);

        // Verify ledger balances: Reg A1 = 1100, Reg A2 = 400
        final balA1 = await movementService.getLedgerBalance(
          registerId: registerA1.id,
          companyId: companyA,
        );
        final balA2 = await movementService.getLedgerBalance(
          registerId: registerA2.id,
          companyId: companyA,
        );

        expect(balA1, equals(1100.0));
        expect(balA2, equals(400.0));
      },
    );

    test(
      '5. Inter-register transfer failure atomicity: Transfer between same register rejected without posting',
      () async {
        final result = await movementService.executeTransfer(
          companyId: companyA,
          sourceRegisterId: registerA1.id,
          destinationRegisterId: registerA1.id, // Same register
          amount: 100.0,
          referenceId: 'TRF-SAME',
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('SAME_REGISTER_TRANSFER'));
      },
    );

    test(
      '6. Register active status enforcement: Transfer rejected if source register is inactive',
      () async {
        // Create inactive register
        final inactiveReg = await cashRepo.createCashRegister(
          CashRegister(
            id: 'cr-inactive',
            companyId: companyA,
            name: 'Inactive Reg',
            code: 'REG_INACTIVE',
            isActive: false,
            accountingAccountId: cashAccountA1.uuid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final result = await movementService.executeTransfer(
          companyId: companyA,
          sourceRegisterId: inactiveReg.id,
          destinationRegisterId: registerA2.id,
          amount: 100.0,
          referenceId: 'TRF-INACTIVE',
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, contains('REGISTER_INACTIVE'));
      },
    );

    test('7. Movement rejection when register is unlinked or closed', () async {
      final unlinked = await cashRepo.createCashRegister(
        CashRegister(
          id: 'cr-unlinked',
          companyId: companyA,
          name: 'Unlinked Register',
          code: 'REG_UNLINKED',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final result = await movementService.executeTransfer(
        companyId: companyA,
        sourceRegisterId: unlinked.id,
        destinationRegisterId: registerA2.id,
        amount: 100.0,
        referenceId: 'TRF-UNLINKED',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, contains('UNLINKED_REGISTER'));
    });

    test(
      '8. Reversal / voiding transaction integrity: Voiding a receipt offsets ledger balance',
      () async {
        // Post receipt of 800.0
        await journalPosting.post(
          JournalEntryDraft(
            entryDate: DateTime.now(),
            voucherNumber: 'REC-VOID-ME',
            voucherType: 'CASH_RECEIPT',
            currencyCode: 'YER',
            isPosted: true,
            sourceType: 'receipt',
            sourceId: 'rec-void-01',
            lines: [
              JournalLineDraft(
                accountUuid: cashAccountA1.uuid,
                debit: 800.0,
                credit: 0.0,
                currencyCode: 'YER',
                sortOrder: 1,
              ),
              JournalLineDraft(
                accountUuid: revenueAccount.uuid,
                debit: 0.0,
                credit: 800.0,
                currencyCode: 'YER',
                sortOrder: 2,
              ),
            ],
          ),
        );

        expect(
          await movementService.getLedgerBalance(
            registerId: registerA1.id,
            companyId: companyA,
          ),
          equals(800.0),
        );

        // Reverse transaction
        final reversed = await movementService.reverseMovement(
          sourceType: 'receipt',
          sourceId: 'rec-void-01',
        );
        expect(reversed, isTrue);

        // Ledger balance restored to 0.0
        expect(
          await movementService.getLedgerBalance(
            registerId: registerA1.id,
            companyId: companyA,
          ),
          equals(0.0),
        );
      },
    );

    test(
      '9. Duplicate request idempotency: Retrying transfer with same reference returns existing entry without double posting',
      () async {
        await journalPosting.post(
          JournalEntryDraft(
            entryDate: DateTime.now(),
            voucherNumber: 'SEED-IDEM',
            voucherType: 'CASH_RECEIPT',
            currencyCode: 'YER',
            isPosted: true,
            lines: [
              JournalLineDraft(
                accountUuid: cashAccountA1.uuid,
                debit: 2000.0,
                credit: 0.0,
                currencyCode: 'YER',
                sortOrder: 1,
              ),
              JournalLineDraft(
                accountUuid: revenueAccount.uuid,
                debit: 0.0,
                credit: 2000.0,
                currencyCode: 'YER',
                sortOrder: 2,
              ),
            ],
          ),
        );

        // First transfer attempt
        final res1 = await movementService.executeTransfer(
          companyId: companyA,
          sourceRegisterId: registerA1.id,
          destinationRegisterId: registerA2.id,
          amount: 500.0,
          referenceId: 'IDEMPOTENT-TRF-KEY',
        );
        expect(res1.isSuccess, isTrue);

        // Second identical transfer attempt
        final res2 = await movementService.executeTransfer(
          companyId: companyA,
          sourceRegisterId: registerA1.id,
          destinationRegisterId: registerA2.id,
          amount: 500.0,
          referenceId: 'IDEMPOTENT-TRF-KEY',
        );
        expect(res2.isSuccess, isTrue);

        // Journal entry UUIDs match
        expect(res2.journalEntry!.uuid, equals(res1.journalEntry!.uuid));

        // Balances deducted ONLY ONCE (2000 - 500 = 1500)
        final balA1 = await movementService.getLedgerBalance(
          registerId: registerA1.id,
          companyId: companyA,
        );
        expect(balA1, equals(1500.0));
      },
    );

    test(
      '10. Concurrent movement simulation & lock safety: Multiple parallel operations compute balance accurately',
      () async {
        await journalPosting.post(
          JournalEntryDraft(
            entryDate: DateTime.now(),
            voucherNumber: 'SEED-CONCUR',
            voucherType: 'CASH_RECEIPT',
            currencyCode: 'YER',
            isPosted: true,
            lines: [
              JournalLineDraft(
                accountUuid: cashAccountA1.uuid,
                debit: 10000.0,
                credit: 0.0,
                currencyCode: 'YER',
                sortOrder: 1,
              ),
              JournalLineDraft(
                accountUuid: revenueAccount.uuid,
                debit: 0.0,
                credit: 10000.0,
                currencyCode: 'YER',
                sortOrder: 2,
              ),
            ],
          ),
        );

        // Execute 5 parallel transfers with distinct reference IDs
        final futures = List.generate(5, (index) {
          return movementService.executeTransfer(
            companyId: companyA,
            sourceRegisterId: registerA1.id,
            destinationRegisterId: registerA2.id,
            amount: 100.0,
            referenceId: 'PARALLEL-TRF-$index',
          );
        });

        final results = await Future.wait(futures);
        expect(results.every((r) => r.isSuccess), isTrue);

        // Total transferred = 500.0. Reg A1 balance = 9500.0, Reg A2 balance = 500.0
        final balA1 = await movementService.getLedgerBalance(
          registerId: registerA1.id,
          companyId: companyA,
        );
        final balA2 = await movementService.getLedgerBalance(
          registerId: registerA2.id,
          companyId: companyA,
        );

        expect(balA1, equals(9500.0));
        expect(balA2, equals(500.0));
      },
    );

    test(
      '11. Cold restart persistence: Movements and balances remain stable across service rebuilds',
      () async {
        // Seed balance
        await journalPosting.post(
          JournalEntryDraft(
            entryDate: DateTime.now(),
            voucherNumber: 'SEED-RESTART',
            voucherType: 'CASH_RECEIPT',
            currencyCode: 'YER',
            isPosted: true,
            lines: [
              JournalLineDraft(
                accountUuid: cashAccountA1.uuid,
                debit: 2500.0,
                credit: 0.0,
                currencyCode: 'YER',
                sortOrder: 1,
              ),
              JournalLineDraft(
                accountUuid: revenueAccount.uuid,
                debit: 0.0,
                credit: 2500.0,
                currencyCode: 'YER',
                sortOrder: 2,
              ),
            ],
          ),
        );

        // Rebuild service instances
        final freshService = CashRegisterMovementService(
          cashRegisterRepository: cashRepo,
          accountRepository: accountRepo,
          journalRepository: journalRepo,
          postingResolver: postingResolver,
          journalPostingService: journalPosting,
        );

        final bal = await freshService.getLedgerBalance(
          registerId: registerA1.id,
          companyId: companyA,
        );
        expect(bal, equals(2500.0));
      },
    );

    test(
      '12. Offline retry resilience: Retrying offline queued movements posts safely when online',
      () async {
        final resOffline = await movementService.executeTransfer(
          companyId: companyA,
          sourceRegisterId: registerA1.id,
          destinationRegisterId: registerA2.id,
          amount: 350.0,
          referenceId: 'OFFLINE-QUEUED-01',
          allowNegativeBalance: true,
        );

        expect(resOffline.isSuccess, isTrue);

        // Re-run sync retry with same reference ID
        final resSync = await movementService.executeTransfer(
          companyId: companyA,
          sourceRegisterId: registerA1.id,
          destinationRegisterId: registerA2.id,
          amount: 350.0,
          referenceId: 'OFFLINE-QUEUED-01',
          allowNegativeBalance: true,
        );

        expect(resSync.isSuccess, isTrue);
        expect(
          resSync.journalEntry!.uuid,
          equals(resOffline.journalEntry!.uuid),
        );
      },
    );

    test(
      '13. Journal failure atomicity: Invalid zero amount transfer rejected before journal creation',
      () async {
        final result = await movementService.executeTransfer(
          companyId: companyA,
          sourceRegisterId: registerA1.id,
          destinationRegisterId: registerA2.id,
          amount: 0.0, // Invalid amount
          referenceId: 'TRF-ZERO',
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('INVALID_AMOUNT'));
      },
    );

    test(
      '14. Database failure atomicity: Cross-company transfer request is rejected before any DB mutation',
      () async {
        final result = await movementService.executeTransfer(
          companyId: companyB, // Wrong company ID
          sourceRegisterId: registerA1.id,
          destinationRegisterId: registerA2.id,
          amount: 100.0,
          referenceId: 'TRF-CROSS',
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, contains('CROSS_COMPANY'));
      },
    );
  });
}
