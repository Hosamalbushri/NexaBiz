import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/core/auth/domain/services/local_authorization_guard.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/core/network/remote_sync_api.dart';
import 'package:stock_count/core/tenancy/company_context_resolver.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/modules/cash_registers/data/repositories/cash_register_repository_impl.dart';
import 'package:stock_count/modules/cash_registers/domain/entities/cash_register.dart';
import 'package:stock_count/modules/cash_registers/domain/repositories/cash_register_repository.dart';
import 'package:stock_count/modules/cash_registers/domain/services/cash_register_movement_service.dart';
import 'package:stock_count/modules/cash_registers/domain/services/cash_register_posting_resolver_service.dart';
import 'package:stock_count/modules/cash_registers/domain/services/default_cash_register_resolver.dart';
import 'package:stock_count/modules/cash_registers/shared/data/sync/cash_registers_sync_handlers.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';

class FakeAccountRepository implements AccountRepository {
  final Map<String, Account> _accounts = {};

  void addAccount(Account acc) {
    _accounts[acc.uuid] = acc;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

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
  Future<List<Account>> getAll({bool includeInactive = false}) async =>
      _accounts.values.where((a) => includeInactive || a.isActive).toList();

  @override
  Stream<List<Account>> watchAll({bool includeInactive = false}) =>
      Stream.value(_accounts.values.toList());

  @override
  Future<List<Account>> getByUuids(Iterable<String> uuids) async =>
      uuids.map((u) => _accounts[u]).whereType<Account>().toList();

  @override
  Future<List<Account>> getByType(
    AccountType type, {
    bool includeInactive = false,
  }) async => _accounts.values
      .where((a) => a.accountType == type && (includeInactive || a.isActive))
      .toList();
}

class FakeJournalRepository implements JournalRepository {
  final Map<String, JournalEntry> _journals = {};
  final List<AccountLedgerMovement> _movements = [];
  int _idSeq = 1;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<JournalEntry> post(JournalEntryDraft draft) async {
    final entryId = draft.uuid ?? 'je-${_idSeq++}';
    final lines = <JournalLine>[];
    for (var i = 0; i < draft.lines.length; i++) {
      final lDraft = draft.lines[i];
      final line = JournalLine(
        id: _idSeq++,
        uuid: lDraft.uuid ?? 'jl-${_idSeq++}',
        entryId: entryId,
        accountId: lDraft.accountId,
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
          accountUuid: lDraft.accountId,
          entryUuid: entryId,
          lineUuid: line.uuid,
          lineId: line.id,
          sortOrder: lDraft.sortOrder,
        ),
      );
    }
    final entry = JournalEntry(
      id: _idSeq++,
      uuid: entryId,
      voucherNumber: draft.voucherNumber,
      voucherType: draft.voucherType,
      currencyCode: draft.currencyCode,
      entryDate: draft.entryDate,
      isPosted: draft.isPosted,
      description: draft.description,
      sourceType: draft.sourceType,
      sourceId: draft.sourceId,
      lines: lines,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _journals[entryId] = entry;
    return entry;
  }

  @override
  Future<List<AccountLedgerMovement>> listMovementsForAccount({
    required String accountId,
    DateTime? fromDate,
    DateTime? toDate,
    String? currencyCode,
    bool? isPosted,
    int? limit,
    AccountLedgerCursor? after,
  }) async {
    return _movements.where((m) => m.accountId == accountId).toList();
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
      _movements.removeWhere((m) => m.entryId == j.uuid);
    }
  }

  @override
  Future<void> softDeleteByUuid(String uuid) async {
    final j = _journals.remove(uuid);
    if (j != null) {
      _movements.removeWhere((m) => m.entryId == uuid);
    }
  }

  Future<List<JournalEntry>> getJournalEntries({
    bool includeLines = true,
    bool includeVoided = false,
  }) async => _journals.values.toList();
}

class FakeJournalPostingService implements JournalPostingService {
  FakeJournalPostingService(this.repo);
  final FakeJournalRepository repo;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<JournalEntry> post(JournalEntryDraft draft, {String? userId}) async =>
      repo.post(draft);

  @override
  Future<void> voidBySource({
    required String sourceType,
    required String sourceId,
    String? userId,
  }) async =>
      repo.softDeleteBySource(sourceType: sourceType, sourceId: sourceId);

  @override
  Future<JournalEntry?> findBySource({
    required String sourceType,
    required String sourceId,
  }) async => repo.findBySource(sourceType: sourceType, sourceId: sourceId);

  @override
  Future<JournalEntry> reverseByUuid(
    String uuid, {
    DateTime? reverseDate,
  }) async => throw UnimplementedError();

  @override
  Future<void> softDeleteBySource({
    required String sourceType,
    required String sourceId,
  }) async =>
      repo.softDeleteBySource(sourceType: sourceType, sourceId: sourceId);
}

void main() {
  late CashRegisterRepositoryImpl cashRepo;
  late FakeAccountRepository accountRepo;
  late FakeJournalRepository journalRepo;
  late NexabizDatabase db;
  late Directory tempDir;
  late CashRegisterMovementService movementService;

  final now = DateTime.now().toUtc();

  final companyAAccount = Account(
    id: 'acc_company_a_01',
    companyId: 'company_a',
    accountCode: '110101',
    name: 'Company A Cash Asset',
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    level: 2,
    isGroup: false,
    isActive: true,
    isSystemAccount: false,
    createdAt: now,
    updatedAt: now,
  );

  final companyAAccount2 = Account(
    id: 'acc_company_a_02',
    companyId: 'company_a',
    accountCode: '110104',
    name: 'Company A Cash Asset 2',
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    level: 2,
    isGroup: false,
    isActive: true,
    isSystemAccount: false,
    createdAt: now,
    updatedAt: now,
  );

  final companyAInactiveAccount = Account(
    id: 'acc_company_a_inactive',
    companyId: 'company_a',
    accountCode: '110102',
    name: 'Company A Inactive Cash',
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    level: 2,
    isGroup: false,
    isActive: false,
    isSystemAccount: false,
    createdAt: now,
    updatedAt: now,
  );

  final companyBAccount = Account(
    id: 'acc_company_b_01',
    companyId: 'company_b',
    accountCode: '110101',
    name: 'Company B Cash Asset',
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    level: 2,
    isGroup: false,
    isActive: true,
    isSystemAccount: false,
    createdAt: now,
    updatedAt: now,
  );

  final companyADeletedAccount = Account(
    id: 'acc_company_a_deleted',
    companyId: 'company_a',
    accountCode: '110103',
    name: 'Company A Deleted Cash',
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    level: 2,
    isGroup: false,
    isActive: true,
    isSystemAccount: false,
    createdAt: now,
    updatedAt: now,
    deletedAt: now,
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cr09_adv_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(HiveBoxes.settings);
    await SyncQueue.registerAdapter();

    accountRepo = FakeAccountRepository();
    accountRepo.addAccount(companyAAccount);
    accountRepo.addAccount(companyAAccount2);
    accountRepo.addAccount(companyAInactiveAccount);
    accountRepo.addAccount(companyBAccount);
    accountRepo.addAccount(companyADeletedAccount);

    journalRepo = FakeJournalRepository();
    db = NexabizDatabase.memory();
    cashRepo = CashRegisterRepositoryImpl(
      accountRepository: accountRepo,
      db: db,
    );
    final defaultResolver = DefaultCashRegisterResolver(
      cashRegisterRepository: cashRepo,
      accountRepository: accountRepo,
    );
    final resolver = CashRegisterPostingResolverService(
      cashRegisterRepository: cashRepo,
      accountRepository: accountRepo,
      defaultCashRegisterResolver: defaultResolver,
    );
    final postingService = FakeJournalPostingService(journalRepo);

    movementService = CashRegisterMovementService(
      cashRegisterRepository: cashRepo,
      accountRepository: accountRepo,
      journalRepository: journalRepo,
      postingResolver: resolver,
      journalPostingService: postingService,
    );
  });

  tearDown(() async {
    await db.close();
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CR-09 Adversarial Testing & Penetration Matrix', () {
    // ------------------------------------------------------------------------
    // 1. ACCOUNTING ATTACKS
    // ------------------------------------------------------------------------
    group('1. Accounting Attacks', () {
      test('1.1 Linking non-existent account fails explicitly', () async {
        final reg = CashRegister(
          id: 'adv_reg_01',
          companyId: 'company_a',
          name: 'Adv Register 1',
          code: 'ADV_01',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
        await cashRepo.createCashRegister(reg);

        expect(
          () async => await cashRepo.linkAccountingAccount(
            registerId: 'adv_reg_01',
            accountId: 'non_existent_account_uuid',
            companyId: 'company_a',
          ),
          throwsA(isA<CashRegisterException>()),
        );
      });

      test('1.2 Linking inactive account fails explicitly', () async {
        final reg = CashRegister(
          id: 'adv_reg_02',
          companyId: 'company_a',
          name: 'Adv Register 2',
          code: 'ADV_02',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
        await cashRepo.createCashRegister(reg);

        expect(
          () async => await cashRepo.linkAccountingAccount(
            registerId: 'adv_reg_02',
            accountId: 'acc_company_a_inactive',
            companyId: 'company_a',
          ),
          throwsA(isA<CashRegisterException>()),
        );
      });

      test('1.3 Linking soft-deleted account fails explicitly', () async {
        final reg = CashRegister(
          id: 'adv_reg_03',
          companyId: 'company_a',
          name: 'Adv Register 3',
          code: 'ADV_03',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
        await cashRepo.createCashRegister(reg);

        expect(
          () async => await cashRepo.linkAccountingAccount(
            registerId: 'adv_reg_03',
            accountId: 'acc_company_a_deleted',
            companyId: 'company_a',
          ),
          throwsA(isA<CashRegisterException>()),
        );
      });

      test('1.4 Movement transfer with negative amount fails', () async {
        final reg1 = CashRegister(
          id: 'adv_reg_04',
          companyId: 'company_a',
          name: 'Adv Register 4',
          code: 'ADV_04',
          isActive: true,
          accountingAccountId: 'acc_company_a_01',
          createdAt: now,
          updatedAt: now,
        );
        final reg2 = CashRegister(
          id: 'adv_reg_05',
          companyId: 'company_a',
          name: 'Adv Register 5',
          code: 'ADV_05',
          isActive: true,
          accountingAccountId: 'acc_company_a_02',
          createdAt: now,
          updatedAt: now,
        );
        await cashRepo.createCashRegister(reg1);
        await cashRepo.createCashRegister(reg2);

        final result = await movementService.executeTransfer(
          companyId: 'company_a',
          sourceRegisterId: 'adv_reg_04',
          destinationRegisterId: 'adv_reg_05',
          amount: -100.0,
          referenceId: 'REF-NEG',
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('INVALID_AMOUNT'));
      });

      test('1.5 Transfer between same registers fails', () async {
        final reg1 = CashRegister(
          id: 'adv_reg_same',
          companyId: 'company_a',
          name: 'Same Register',
          code: 'ADV_SAME',
          isActive: true,
          accountingAccountId: 'acc_company_a_01',
          createdAt: now,
          updatedAt: now,
        );
        await cashRepo.createCashRegister(reg1);

        final result = await movementService.executeTransfer(
          companyId: 'company_a',
          sourceRegisterId: 'adv_reg_same',
          destinationRegisterId: 'adv_reg_same',
          amount: 100.0,
          referenceId: 'REF-SAME',
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('SAME_REGISTER_TRANSFER'));
      });

      test('1.6 Transfer from unlinked register fails', () async {
        final reg1 = CashRegister(
          id: 'adv_reg_unlinked',
          companyId: 'company_a',
          name: 'Unlinked Register',
          code: 'UNLINKED',
          isActive: true,
          accountingAccountId: null,
          createdAt: now,
          updatedAt: now,
        );
        final reg2 = CashRegister(
          id: 'adv_reg_linked',
          companyId: 'company_a',
          name: 'Linked Register',
          code: 'LINKED',
          isActive: true,
          accountingAccountId: 'acc_company_a_01',
          createdAt: now,
          updatedAt: now,
        );
        await cashRepo.createCashRegister(reg1);
        await cashRepo.createCashRegister(reg2);

        final result = await movementService.executeTransfer(
          companyId: 'company_a',
          sourceRegisterId: 'adv_reg_unlinked',
          destinationRegisterId: 'adv_reg_linked',
          amount: 100.0,
          referenceId: 'REF-UNLINKED',
        );

        expect(result.isSuccess, isFalse);
      });
    });

    // ------------------------------------------------------------------------
    // 2. TENANCY & ISOLATION ATTACKS
    // ------------------------------------------------------------------------
    group('2. Tenancy & Isolation Attacks', () {
      test('2.1 Cross-company account binding attack fails', () async {
        final reg = CashRegister(
          id: 'adv_reg_cross_acc',
          companyId: 'company_a',
          name: 'Company A Register',
          code: 'COMP_A_REG',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
        await cashRepo.createCashRegister(reg);

        expect(
          () async => await cashRepo.linkAccountingAccount(
            registerId: 'adv_reg_cross_acc',
            accountId: 'acc_company_b_01',
            companyId: 'company_a',
          ),
          throwsA(isA<CashRegisterException>()),
        );
      });

      test('2.2 Cross-company register access returns null', () async {
        final regB = CashRegister(
          id: 'adv_reg_comp_b',
          companyId: 'company_b',
          name: 'Company B Register',
          code: 'COMP_B_REG',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
        await cashRepo.createCashRegister(regB);

        final result = await cashRepo.getCashRegisterById(
          'adv_reg_comp_b',
          companyId: 'company_a',
        );
        expect(result, isNull);
      });

      test(
        '2.3 Cross-company register list query returns only tenant data',
        () async {
          final regA = CashRegister(
            id: 'reg_iso_a',
            companyId: 'company_a',
            name: 'Register A',
            code: 'REG_A',
            isActive: true,
            createdAt: now,
            updatedAt: now,
          );
          final regB = CashRegister(
            id: 'reg_iso_b',
            companyId: 'company_b',
            name: 'Register B',
            code: 'REG_B',
            isActive: true,
            createdAt: now,
            updatedAt: now,
          );
          await cashRepo.createCashRegister(regA);
          await cashRepo.createCashRegister(regB);

          final listA = await cashRepo.getCashRegisters('company_a');
          expect(listA.length, equals(1));
          expect(listA.first.id, equals('reg_iso_a'));
        },
      );
    });

    // ------------------------------------------------------------------------
    // 3. INITIALIZATION & RECOVERY ATTACKS
    // ------------------------------------------------------------------------
    group('3. Initialization & Recovery Attacks', () {
      test(
        '3.1 Duplicate register creation explicitly throws CashRegisterException',
        () async {
          final reg1 = CashRegister(
            id: 'idem_reg_01',
            companyId: 'company_a',
            name: 'Idempotent Register',
            code: 'IDEM_01',
            isActive: true,
            createdAt: now,
            updatedAt: now,
          );
          await cashRepo.createCashRegister(reg1);

          expect(
            () async => await cashRepo.createCashRegister(reg1),
            throwsA(isA<CashRegisterException>()),
          );

          final list = await cashRepo.getCashRegisters('company_a');
          expect(list.where((r) => r.id == 'idem_reg_01').length, equals(1));
        },
      );

      test(
        '3.2 Operations with empty/missing companyId throw exception',
        () async {
          final regNoCompany = CashRegister(
            id: 'no_company_reg',
            companyId: '',
            name: 'No Company Register',
            code: 'NO_COMP',
            isActive: true,
            createdAt: now,
            updatedAt: now,
          );

          expect(
            () async => await cashRepo.createCashRegister(regNoCompany),
            throwsA(isA<CashRegisterException>()),
          );
        },
      );
    });

    // ------------------------------------------------------------------------
    // 4. PERSISTENCE SURVIVAL ATTACKS
    // ------------------------------------------------------------------------
    group('4. Persistence Survival Attacks', () {
      test(
        '4.1 Full Lifecycle: Create -> Link -> Save -> DB Reopen -> Verify',
        () async {
          final reg = CashRegister(
            id: 'persist_reg_01',
            companyId: 'company_a',
            name: 'Persisted Register',
            code: 'PERSIST_01',
            isActive: true,
            createdAt: now,
            updatedAt: now,
          );
          await cashRepo.createCashRegister(reg);
          await cashRepo.linkAccountingAccount(
            registerId: 'persist_reg_01',
            accountId: 'acc_company_a_01',
            companyId: 'company_a',
          );

          // Simulate application restart by creating a new repository wrapping the same DB
          final reloadedRepo = CashRegisterRepositoryImpl(
            accountRepository: accountRepo,
            db: db,
          );

          final loaded = await reloadedRepo.getCashRegisterById(
            'persist_reg_01',
            companyId: 'company_a',
          );

          expect(loaded, isNotNull);
          expect(loaded!.name, equals('Persisted Register'));
          expect(loaded.accountingAccountId, equals('acc_company_a_01'));
          expect(loaded.isLinked, isTrue);
        },
      );
    });

    // ------------------------------------------------------------------------
    // 5. SYNCHRONIZATION ATTACKS
    // ------------------------------------------------------------------------
    group('5. Synchronization Attacks', () {
      test('5.1 Cross-company sync payload injection is rejected', () async {
        final queueBox = await Hive.openBox<SyncOperation>(
          'test_sync_adv_${DateTime.now().millisecondsSinceEpoch}',
        );
        final queue = SyncQueue(box: queueBox, companyId: 'company_a');

        final opB = SyncOperation.create(
          entityType: CashRegisterRepositoryImpl.entityType,
          entityId: 'reg_b_sync_adv',
          type: SyncOperationType.create,
          payload: {'name': 'Injected Company B Payload'},
          companyId: 'company_b',
        );

        expect(
          () async => await queue.enqueue(opB),
          throwsA(isA<CompanyContextMismatchException>()),
        );
      });

      test(
        '5.2 Malformed remote payload does not corrupt database state',
        () async {
          final remoteApi = InMemoryRemoteSyncApi();
          final syncHandler = CashRegisterSyncHandler(
            repository: cashRepo,
            remoteProvider: () => remoteApi,
          );

          final malformedChange = SyncRemoteChange(
            entityId: 'malformed_uuid',
            version: 1,
            updatedAt: DateTime.now().toUtc(),
            payload: {'invalidKey': 'Corrupt data'},
          );

          await syncHandler.applyRemoteChange(malformedChange);

          final list = await cashRepo.getCashRegisters('company_a');
          expect(list.any((r) => r.id == 'malformed_uuid'), isFalse);
        },
      );
    });
  });
}
