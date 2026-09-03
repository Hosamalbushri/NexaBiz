import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/repositories/account_repository.dart';

import 'package:stock_count/modules/accounting/chart_of_accounts/import/accounts_import.dart';
import 'package:stock_count/core/import_engine/import_engine.dart';

/// In-memory test repository implementation for Chart of Accounts.
class TestAccountRepository implements AccountRepository {
  String? activeCompanyId;
  final Map<int, Account> _accountsById = {};
  final Map<String, Account> _accountsByUuid = {};
  final Map<String, Account> _accountsByCode = {};

  @override
  Future<List<Account>> getAll({bool includeInactive = false}) async {
    return _accountsById.values
        .where((a) => includeInactive || (a.isActive && !a.isDeleted))
        .where((a) => activeCompanyId == null || a.companyId == null || a.companyId == activeCompanyId)
        .toList();
  }

  @override
  Stream<List<Account>> watchAll({bool includeInactive = false}) {
    return Stream.value(_accountsById.values.toList());
  }

  @override
  Future<Account?> getById(int id) async => _accountsById[id];

  @override
  Future<Account?> getByUuid(String uuid) async => _accountsByUuid[uuid];

  @override
  Future<List<Account>> getByUuids(Iterable<String> uuids) async {
    return uuids.map((u) => _accountsByUuid[u]).whereType<Account>().toList();
  }

  @override
  Future<Account?> getByAccountCode(String accountCode) async {
    final acc = _accountsByCode[accountCode];
    if (acc != null && activeCompanyId != null && acc.companyId != null && acc.companyId != activeCompanyId) {
      return null;
    }
    return acc;
  }

  @override
  Future<List<Account>> search(String query, {bool includeInactive = false}) async {
    final clean = query.toLowerCase().trim();
    return _accountsById.values
        .where((a) => activeCompanyId == null || a.companyId == null || a.companyId == activeCompanyId)
        .where((a) => a.accountCode.toLowerCase().contains(clean) || a.name.toLowerCase().contains(clean))
        .toList();
  }

  @override
  Future<List<Account>> getChildren(String parentUuid) async {
    return _accountsById.values.where((a) => a.parentId == parentUuid).toList();
  }

  @override
  Future<bool> hasChildren(String uuid) async {
    return _accountsById.values.any((a) => a.parentId == uuid);
  }

  @override
  Future<bool> isUsedInTransactions(String uuid) async => false;

  @override
  Future<Account> insert(AccountDraft draft) async {
    final now = DateTime.now().toUtc();
    final newId = _accountsById.length + 1;
    final uuid = 'ACC-UUID-$newId';

    int level = 0;
    if (draft.parentId != null) {
      final parent = _accountsByUuid[draft.parentId];
      if (parent != null) {
        level = parent.level + 1;
      }
    }

    final account = Account(
      id: newId,
      uuid: uuid,
      accountCode: draft.accountCode,
      name: draft.name,
      accountType: draft.accountType,
      normalBalance: draft.normalBalance,
      level: level,
      isGroup: draft.isGroup,
      isActive: draft.isActive,
      isSystemAccount: draft.isSystemAccount,
      createdAt: now,
      updatedAt: now,
      parentId: draft.parentId,
      companyId: activeCompanyId,
      description: draft.description,
    );

    _accountsById[newId] = account;
    _accountsByUuid[uuid] = account;
    _accountsByCode[account.accountCode] = account;
    return account;
  }


  @override
  Future<Account> update(int id, AccountDraft draft) async {
    final existing = _accountsById[id];
    if (existing == null) throw StateError('Account $id not found');

    int level = existing.level;
    if (draft.parentId != null) {
      final parent = _accountsByUuid[draft.parentId];
      if (parent != null) {
        level = parent.level + 1;
      }
    }

    final updated = existing.copyWith(
      accountCode: draft.accountCode,
      name: draft.name,
      accountType: draft.accountType,
      normalBalance: draft.normalBalance,
      isGroup: draft.isGroup,
      parentId: draft.parentId,
      description: draft.description,
      isActive: draft.isActive,
      level: level,
      updatedAt: DateTime.now().toUtc(),
    );

    _accountsById[id] = updated;
    _accountsByUuid[updated.uuid] = updated;
    _accountsByCode[updated.accountCode] = updated;
    return updated;
  }

  @override
  Future<void> deactivate(int id) async {
    final acc = _accountsById[id];
    if (acc != null) {
      final updated = acc.copyWith(isActive: false);
      _accountsById[id] = updated;
      _accountsByUuid[acc.uuid] = updated;
      _accountsByCode[acc.accountCode] = updated;
    }
  }

  @override
  Future<void> softDelete(int id) async {
    final acc = _accountsById[id];
    if (acc != null) {
      final updated = acc.copyWith(deletedAt: DateTime.now().toUtc());
      _accountsById[id] = updated;
      _accountsByUuid[acc.uuid] = updated;
      _accountsByCode[acc.accountCode] = updated;
    }
  }

  @override
  Future<void> ensureDefaultChartSeeded() async {}

  @override
  Future<void> seedDefaultChart() async {}

  @override
  Future<List<Account>> getByType(AccountType type, {bool includeInactive = false}) async {
    return _accountsById.values.where((a) => a.accountType == type).toList();
  }
}

void main() {
  group('Phase 19 — Universal Import Engine Accounting Import Integration Tests', () {
    late TestAccountRepository accountRepo;
    late AccountImportExecutor executor;

    setUp(() {
      accountRepo = TestAccountRepository();
      executor = AccountImportExecutor(accountRepository: accountRepo);
    });

    test('1. Hierarchy: Processes and inserts parent accounts before dependent child accounts', () async {
      // Child rows presented in reverse order in file
      final rawRows = [
        {
          'accountCode': '1110',
          'name': 'Cash on Hand',
          'parentAccount': '1100',
          'accountType': 'Asset',
          'isGroup': false,
        },
        {
          'accountCode': '1100',
          'name': 'Current Assets',
          'parentAccount': '1000',
          'accountType': 'Asset',
          'isGroup': true,
        },
        {
          'accountCode': '1000',
          'name': 'Assets',
          'accountType': 'Asset',
          'isGroup': true,
        },
      ];

      final results = await executor.executeAccountBatch(
        rows: rawRows,
        companyId: 'COMP-100',
      );

      expect(results, hasLength(3));
      final root = await accountRepo.getByAccountCode('1000');
      final current = await accountRepo.getByAccountCode('1100');
      final cash = await accountRepo.getByAccountCode('1110');

      expect(root, isNotNull);
      expect(root!.level, equals(0));
      expect(root.isGroup, isTrue);

      expect(current, isNotNull);
      expect(current!.parentId, equals(root.uuid));
      expect(current.level, equals(1));

      expect(cash, isNotNull);
      expect(cash!.parentId, equals(current.uuid));
      expect(cash.level, equals(2));
    });

    test('2. Duplicate Codes: Rejects duplicate account codes when policy is ERROR', () async {
      final initialRow = {
        'accountCode': '1000',
        'name': 'Assets',
        'accountType': 'Asset',
        'isGroup': true,
      };
      await executor.executeAccountRow(rowData: initialRow, companyId: 'COMP-100');

      final duplicateRow = {
        'accountCode': '1000',
        'name': 'Assets Duplicate',
        'accountType': 'Asset',
        'isGroup': true,
      };

      const errorPolicy = ImportPolicy(duplicateResolution: DuplicateResolutionStrategy.error);

      expect(
        () async => executor.executeAccountRow(
          rowData: duplicateRow,
          companyId: 'COMP-100',
          policy: errorPolicy,
        ),
        throwsA(isA<AccountImportException>()),
      );
    });

    test('3. Duplicate Names: Rejects ambiguous account names across different codes', () async {
      final initialRow = {
        'accountCode': '1000',
        'name': 'Assets Header',
        'accountType': 'Asset',
        'isGroup': true,
      };
      await executor.executeAccountRow(rowData: initialRow, companyId: 'COMP-100');

      final ambiguousRow = {
        'accountCode': '1001',
        'name': 'Assets Header',
        'accountType': 'Asset',
        'isGroup': true,
      };

      const errorPolicy = ImportPolicy(duplicateResolution: DuplicateResolutionStrategy.error);

      expect(
        () async => executor.executeAccountRow(
          rowData: ambiguousRow,
          companyId: 'COMP-100',
          policy: errorPolicy,
        ),
        throwsA(
          isA<AccountImportException>().having((e) => e.code, 'code', equals('AMBIGUOUS_NAME')),
        ),
      );
    });

    test('4. Parent Resolution: Rejects when parent account is missing and auto-creation is disabled', () async {
      final childRowMissingParent = {
        'accountCode': '1110',
        'name': 'Cash in Bank',
        'parentAccount': '9999', // Non-existent parent
        'accountType': 'Asset',
        'isGroup': false,
      };

      const strictPolicy = ImportPolicy(createMissingRelations: false);

      expect(
        () async => executor.executeAccountRow(
          rowData: childRowMissingParent,
          companyId: 'COMP-100',
          policy: strictPolicy,
        ),
        throwsA(
          isA<AccountImportException>().having((e) => e.code, 'code', equals('PARENT_NOT_FOUND')),
        ),
      );
    });

    test('5. Opening Balances: Accepts valid single-sided balances and rejects dual-sided or group opening balances', () async {
      final validRow = {
        'accountCode': '1110',
        'name': 'Petty Cash',
        'accountType': 'Asset',
        'isGroup': false,
        'debitOpening': 1500.0,
        'creditOpening': 0.0,
      };

      final validRes = await executor.executeAccountRow(
        rowData: validRow,
        companyId: 'COMP-100',
      );
      expect(validRes, isNotNull);
      expect(validRes!.debitOpening, equals(1500.0));

      final dualSidedRow = {
        'accountCode': '1120',
        'name': 'Bank Account Dual',
        'accountType': 'Asset',
        'isGroup': false,
        'debitOpening': 500.0,
        'creditOpening': 200.0,
      };

      expect(
        () async => executor.executeAccountRow(
          rowData: dualSidedRow,
          companyId: 'COMP-100',
        ),
        throwsA(
          isA<AccountImportException>().having((e) => e.code, 'code', equals('BOTH_OPENING_SIDES')),
        ),
      );

      final groupOpeningRow = {
        'accountCode': '1100',
        'name': 'Current Assets Header',
        'accountType': 'Asset',
        'isGroup': true,
        'debitOpening': 1000.0,
      };

      expect(
        () async => executor.executeAccountRow(
          rowData: groupOpeningRow,
          companyId: 'COMP-100',
        ),
        throwsA(
          isA<AccountImportException>().having((e) => e.code, 'code', equals('GROUP_OPENING_BALANCE')),
        ),
      );
    });

    test('6. Invalid Account Types: Rejects unparseable/invalid account types', () async {
      final invalidTypeRow = {
        'accountCode': '9000',
        'name': 'Mystery Account',
        'accountType': 'UnrecognizedType',
      };

      expect(
        () async => executor.executeAccountRow(
          rowData: invalidTypeRow,
          companyId: 'COMP-100',
        ),
        throwsA(
          isA<AccountImportException>().having((e) => e.code, 'code', equals('INVALID_ACCOUNT_TYPE')),
        ),
      );
    });

    test('7. Company Isolation: Ensures accounts and parent lookups respect tenant isolation', () async {
      // Create Parent in Company A
      accountRepo.activeCompanyId = 'COMPANY-A';
      final parentA = {
        'accountCode': '1000',
        'name': 'Assets Company A',
        'accountType': 'Asset',
        'isGroup': true,
      };
      await executor.executeAccountRow(rowData: parentA, companyId: 'COMPANY-A');

      // Attempting to resolve parent in Company B should fail because parent belongs to Company A
      accountRepo.activeCompanyId = 'COMPANY-B';
      final childB = {
        'accountCode': '1100',
        'name': 'Current Assets Company B',
        'parentAccount': '1000',
        'accountType': 'Asset',
        'isGroup': false,
      };

      const policy = ImportPolicy(createMissingRelations: false);

      expect(
        () async => executor.executeAccountRow(
          rowData: childB,
          companyId: 'COMPANY-B',
          policy: policy,
        ),
        throwsA(
          isA<AccountImportException>().having((e) => e.code, 'code', equals('PARENT_NOT_FOUND')),
        ),
      );
    });


    test('8. Rollback Simulation: Batch import aborts cleanly when non-recoverable error occurs', () async {
      final batchWithFailure = [
        {
          'accountCode': '2000',
          'name': 'Liabilities',
          'accountType': 'Liability',
          'isGroup': true,
        },
        {
          'accountCode': '2100',
          'name': 'Current Liabilities',
          'parentAccount': '2000',
          'accountType': 'INVALID_TYPE_TRIGGER',
          'isGroup': true,
        },
      ];

      expect(
        () async => executor.executeAccountBatch(
          rows: batchWithFailure,
          companyId: 'COMP-100',
        ),
        throwsA(isA<AccountImportException>()),
      );
    });
  });
}
