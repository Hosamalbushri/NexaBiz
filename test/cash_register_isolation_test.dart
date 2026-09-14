import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stock_count/core/database/hive_boxes.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/normal_balance.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/repositories/journal_repository.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_posting_service.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/cash_registers/data/repositories/cash_register_repository_impl.dart';
import 'package:stock_count/modules/cash_registers/domain/entities/cash_register.dart';
import 'package:stock_count/modules/cash_registers/domain/repositories/cash_register_repository.dart';
import 'package:stock_count/modules/cash_registers/domain/services/cash_register_initializer_service.dart';
import 'package:stock_count/modules/cash_registers/domain/services/cash_register_movement_service.dart';
import 'package:stock_count/modules/cash_registers/domain/services/cash_register_posting_resolver_service.dart';
import 'package:stock_count/modules/cash_registers/domain/services/default_cash_register_resolver.dart';
import 'package:stock_count/modules/cash_registers/permissions/cash_register_permissions.dart';
import 'package:stock_count/modules/cash_registers/presentation/providers/cash_register_providers.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_accounting_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_initialization_state.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_inventory_config.dart';
import 'package:stock_count/modules/system_setup/domain/entities/company_warehouse_config.dart';
import 'package:stock_count/modules/system_setup/domain/repositories/company_initialization_repository.dart';
import 'package:stock_count/modules/system_setup/presentation/providers/system_setup_providers.dart';

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
  Future<bool> hasChildren(String uuid) async => false;

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
      sourceType: draft.sourceType,
      sourceId: draft.sourceId,
      description: draft.description,
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

  Future<void> voidBySource({
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
  Future<void> softDeleteBySource({
    required String sourceType,
    required String sourceId,
  }) async {
    await voidBySource(sourceType: sourceType, sourceId: sourceId);
  }

  @override
  Future<void> softDeleteByUuid(String uuid) async {
    final j = _journals.remove(uuid);
    if (j != null) {
      _movements.removeWhere((m) => m.entryId == uuid);
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
    required String accountId,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isPosted,
  }) async => ['YER'];

  @override
  Future<double> sumNetBefore({
    required String accountId,
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
    await repo.voidBySource(sourceType: sourceType, sourceId: sourceId);
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
  }) async => throw UnimplementedError();

  @override
  Future<void> softDeleteBySource({
    required String sourceType,
    required String sourceId,
    String? userId,
  }) async {}

  @override
  Future<void> softDeleteByUuid(String uuid, {String? userId}) async {}

  @override
  Future<void> voidByUuid(String uuid, {String? userId}) async {}
}

class FakeCompanyInitRepository implements CompanyInitializationRepository {
  FakeCompanyInitRepository(this._companyId);
  String _companyId;

  void setCompanyId(String id) {
    _companyId = id;
  }

  @override
  Future<CompanyInitializationState> getState() async {
    return CompanyInitializationState(
      companyId: _companyId,
      initializationCompleted: true,
    );
  }

  @override
  Future<void> saveState(CompanyInitializationState state) async {
    _companyId = state.companyId;
  }

  @override
  Future<CompanyAccountingConfig?> getAccountingConfig() async => null;

  @override
  Future<CompanyInventoryConfig?> getInventoryConfig() async => null;

  @override
  Future<CompanyWarehouseConfig?> getWarehouseConfig() async => null;

  @override
  Future<void> saveAccountingConfig(CompanyAccountingConfig config) async {}

  @override
  Future<void> saveInventoryConfig(CompanyInventoryConfig config) async {}

  @override
  Future<void> saveWarehouseConfig(CompanyWarehouseConfig config) async {}

  @override
  Future<CompanyInitializationState> finalizeInitialization() async {
    return CompanyInitializationState(
      companyId: _companyId,
      initializationCompleted: true,
    );
  }
}

void main() {
  late CashRegisterRepositoryImpl cashRepo;
  late FakeAccountRepository accountRepo;
  late DefaultCashRegisterResolver defaultResolver;
  late CashRegisterPostingResolverService postingResolver;
  late CashRegisterInitializerService initializerService;
  late CashRegisterMovementService movementService;
  late NexabizDatabase db;
  late Directory tempDir;

  final now = DateTime.now().toUtc();

  final accountCompanyA = Account(
    id: 'acc_asset_comp_a',
    companyId: 'company_a',
    accountCode: '110101',
    name: 'Cash Account Company A',
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    level: 2,
    isGroup: false,
    isActive: true,
    isSystemAccount: false,
    createdAt: now,
    updatedAt: now,
  );

  final accountCompanyB = Account(
    id: 'acc_asset_comp_b',
    companyId: 'company_b',
    accountCode: '110102',
    name: 'Cash Account Company B',
    accountType: AccountType.asset,
    normalBalance: NormalBalance.debit,
    level: 2,
    isGroup: false,
    isActive: true,
    isSystemAccount: false,
    createdAt: now,
    updatedAt: now,
  );

  final regCompanyA = CashRegister(
    id: 'reg_comp_a',
    companyId: 'company_a',
    name: 'Main Register Company A',
    code: 'REG_A',
    isActive: true,
    accountingAccountId: 'acc_asset_comp_a',
    createdAt: now,
    updatedAt: now,
  );

  final regCompanyB = CashRegister(
    id: 'reg_comp_b',
    companyId: 'company_b',
    name: 'Main Register Company B',
    code: 'REG_B',
    isActive: true,
    accountingAccountId: 'acc_asset_comp_b',
    createdAt: now,
    updatedAt: now,
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cr07_isolation_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(HiveBoxes.settings);

    accountRepo = FakeAccountRepository();
    accountRepo.addAccount(accountCompanyA);
    accountRepo.addAccount(accountCompanyB);

    db = NexabizDatabase.memory();
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
    initializerService = CashRegisterInitializerService(
      cashRegisterRepository: cashRepo,
      accountRepository: accountRepo,
      defaultCashRegisterResolver: defaultResolver,
    );

    final journalRepo = FakeJournalRepository();
    final journalPostingService = FakeJournalPostingService(journalRepo);

    movementService = CashRegisterMovementService(
      cashRegisterRepository: cashRepo,
      accountRepository: accountRepo,
      journalRepository: journalRepo,
      postingResolver: postingResolver,
      journalPostingService: journalPostingService,
    );

    await cashRepo.createCashRegister(regCompanyA);
    await cashRepo.createCashRegister(regCompanyB);
    await cashRepo.setDefaultCashRegisterId(
      companyId: 'company_a',
      registerId: 'reg_comp_a',
    );
    await cashRepo.setDefaultCashRegisterId(
      companyId: 'company_b',
      registerId: 'reg_comp_b',
    );
  });

  tearDown(() async {
    await db.close();
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CR-07 Multi-Company / Authorization / Isolation Test Matrix', () {
    test(
      '1. Read Isolation: Company A cannot query or read Company B registers',
      () async {
        final listCompA = await cashRepo.getCashRegisters('company_a');
        expect(listCompA.any((r) => r.id == regCompanyB.id), isFalse);
        expect(listCompA.any((r) => r.companyId == 'company_b'), isFalse);

        final readyCompA = await cashRepo.getAccountingReadyCashRegisters(
          'company_a',
        );
        expect(readyCompA.any((r) => r.id == regCompanyB.id), isFalse);

        final scopedRead = await cashRepo.getCashRegisterById(
          'reg_comp_b',
          companyId: 'company_a',
        );
        expect(scopedRead, isNull);
      },
    );

    test(
      '2. Write Isolation: Company A cannot update or overwrite Company B register',
      () async {
        final maliciousUpdate = regCompanyB.copyWith(
          name: 'Hacked Register Name',
          companyId: 'company_a',
        );

        expect(
          () async => await cashRepo.updateCashRegister(maliciousUpdate),
          throwsA(
            isA<CashRegisterException>().having(
              (e) => e.code,
              'code',
              'CROSS_COMPANY_UPDATE',
            ),
          ),
        );

        final originalB = await cashRepo.getCashRegisterById('reg_comp_b');
        expect(originalB?.name, equals('Main Register Company B'));
      },
    );

    test(
      '3. Cross-Company Link Isolation: Cannot link Company A register to Company B account',
      () async {
        expect(
          () async => await cashRepo.linkAccountingAccount(
            registerId: 'reg_comp_a',
            accountId: 'acc_asset_comp_b',
            companyId: 'company_a',
          ),
          throwsA(
            isA<CashRegisterException>().having(
              (e) => e.code,
              'code',
              'CROSS_COMPANY_ACCOUNT',
            ),
          ),
        );
      },
    );

    test(
      '4. Cross-Company Register Linking Attempt: Cannot link Company B register using Company A context',
      () async {
        expect(
          () async => await cashRepo.linkAccountingAccount(
            registerId: 'reg_comp_b',
            accountId: 'acc_asset_comp_a',
            companyId: 'company_a',
          ),
          throwsA(isA<CashRegisterException>()),
        );
      },
    );

    test(
      '5. Default Register Isolation: Cannot set Company B register as default for Company A',
      () async {
        expect(
          () async => await cashRepo.setDefaultCashRegisterId(
            companyId: 'company_a',
            registerId: 'reg_comp_b',
          ),
          throwsA(
            isA<CashRegisterException>().having(
              (e) => e.code,
              'code',
              'CROSS_COMPANY_DEFAULT',
            ),
          ),
        );
      },
    );

    test(
      '6. Inter-Register Transfer Isolation: Cross-company transfer between Company A & B is rejected',
      () async {
        final result = await movementService.executeTransfer(
          companyId: 'company_a',
          sourceRegisterId: 'reg_comp_a',
          destinationRegisterId: 'reg_comp_b',
          amount: 100.0,
          referenceId: 'REF_CROSS_01',
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('DEST_CROSS_COMPANY_REGISTER'));
      },
    );

    test(
      '7. Creation Scoping Isolation: Register with empty company ID is rejected',
      () async {
        final invalidReg = CashRegister(
          id: 'reg_no_company',
          companyId: '   ',
          name: 'No Company Register',
          code: 'REG_NO_COMP',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(
          () async => await cashRepo.createCashRegister(invalidReg),
          throwsA(
            isA<CashRegisterException>().having(
              (e) => e.code,
              'code',
              'INVALID_COMPANY',
            ),
          ),
        );
      },
    );

    test(
      '8. Initialization Isolation: Initialization rejected when linking cross-company account',
      () async {
        final res = await initializerService
            .initializeDefaultRegisterForCompany(
              companyId: 'company_uninit',
              registerId: 'reg_new_uninit',
              accountId: 'acc_asset_comp_b',
            );

        expect(res.isSuccess, isFalse);
        expect(res.errorCode, equals('CROSS_COMPANY_ACCOUNT'));
      },
    );

    test(
      '9. Provider State & Cache Isolation: Switching active company clears stale register state',
      () async {
        final fakeCompanyRepo = FakeCompanyInitRepository('company_a');

        final container = ProviderContainer(
          overrides: [
            cashRegisterRepositoryProvider.overrideWithValue(cashRepo),
            accountRepositoryProvider.overrideWithValue(accountRepo),
            companyInitializationRepositoryProvider.overrideWithValue(
              fakeCompanyRepo,
            ),
          ],
        );
        addTearDown(container.dispose);

        final registersA = await container.read(cashRegistersProvider.future);
        expect(registersA.length, equals(1));
        expect(registersA.first.id, equals('reg_comp_a'));

        final defaultA = await container.read(
          defaultCashRegisterResultProvider.future,
        );
        expect(defaultA.register?.id, equals('reg_comp_a'));

        fakeCompanyRepo.setCompanyId('company_b');
        container.invalidate(cashRegistersProvider);
        container.invalidate(defaultCashRegisterResultProvider);

        final registersB = await container.read(cashRegistersProvider.future);
        expect(registersB.length, equals(1));
        expect(registersB.first.id, equals('reg_comp_b'));

        final defaultB = await container.read(
          defaultCashRegisterResultProvider.future,
        );
        expect(defaultB.register?.id, equals('reg_comp_b'));
      },
    );

    test(
      '10. Permission Definitions Audit: Verify CashRegisterPermissions packageDef codes',
      () {
        expect(CashRegisterPermissions.view, contains('cash_registers.view'));
        expect(
          CashRegisterPermissions.create,
          contains('cash_registers.create'),
        );
        expect(
          CashRegisterPermissions.update,
          contains('cash_registers.update'),
        );
        expect(
          CashRegisterPermissions.delete,
          contains('cash_registers.delete'),
        );
        expect(CashRegisterPermissions.link, contains('cash_registers.link'));
        expect(
          CashRegisterPermissions.transfer,
          contains('cash_registers.transfer'),
        );
        expect(
          CashRegisterPermissions.configure,
          contains('cash_registers.configure'),
        );

        expect(CashRegisterPermissions.packageDef.id, equals('cash_registers'));
        expect(
          CashRegisterPermissions.packageDef.services.first.allCodes.length,
          equals(7),
        );
      },
    );
  });
}
