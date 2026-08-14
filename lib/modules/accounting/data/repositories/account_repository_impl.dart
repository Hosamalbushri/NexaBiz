import 'package:drift/drift.dart';

import '../../../../core/sync/sync_operation.dart';
import '../../../../core/sync/sync_queue.dart';
import '../../../../core/sync/sync_status.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/normal_balance.dart';
import '../../domain/models/account_exception.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/services/account_validator.dart';
import '../../domain/services/default_chart_of_accounts.dart';
import '../database/accounting_database.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(
    this._db, {
    SyncQueue? syncQueue,
    AccountValidator validator = const AccountValidator(),
  }) : _syncQueue = syncQueue,
       _validator = validator;

  final AccountingDatabase _db;
  final SyncQueue? _syncQueue;
  final AccountValidator _validator;

  static const entityType = 'account';

  Account _map(AccountRow row) {
    return Account(
      id: row.id,
      uuid: row.uuid,
      parentId: row.parentId,
      accountCode: row.accountCode,
      name: row.name,
      description: row.description,
      accountType: AccountType.fromStorage(row.accountType),
      normalBalance: NormalBalance.fromStorage(row.normalBalance),
      level: row.level,
      isGroup: row.isGroup,
      isActive: row.isActive,
      isSystemAccount: row.isSystemAccount,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAt,
        isUtc: true,
      ),
      syncStatus: SyncStatusX.fromStorage(row.syncStatus),
      lastSyncedAt: row.lastSyncedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.lastSyncedAt!, isUtc: true),
      version: row.version,
      deletedAt: row.deletedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true),
    );
  }

  Expression<bool> _notDeleted($AccountsTable t) => t.deletedAt.isNull();

  Expression<bool> _activeFilter($AccountsTable t, bool includeInactive) {
    if (includeInactive) {
      return _notDeleted(t);
    }
    return _notDeleted(t) & t.isActive.equals(true);
  }

  String _normalizeCode(String value) => value.trim();

  String _normalizeName(String value) => value.trim();

  String? _normalizeDescription(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Future<void> _assertUniqueCode(String accountCode, {int? excludingId}) async {
    final query = _db.select(_db.accounts)
      ..where((t) => t.accountCode.equals(accountCode) & _notDeleted(t));
    if (excludingId != null) {
      query.where((t) => t.id.isNotValue(excludingId));
    }
    final hit = await query.getSingleOrNull();
    if (hit != null) {
      throw const AccountException(AccountException.duplicateAccountCode);
    }
  }

  Future<int> _resolveLevel(String? parentId) async {
    if (parentId == null) {
      return 0;
    }
    final parent = await getByUuid(parentId);
    if (parent == null || parent.isDeleted) {
      throw const AccountException(AccountException.invalidParent);
    }
    return parent.level + 1;
  }

  Future<void> _enqueue(Account account, SyncOperationType type) async {
    final queue = _syncQueue;
    if (queue == null) {
      return;
    }
    await queue.enqueue(
      SyncOperation.create(
        entityType: entityType,
        entityId: account.uuid,
        type: type,
        baseVersion: account.version,
        payload: {
          'uuid': account.uuid,
          'parentId': account.parentId,
          'accountCode': account.accountCode,
          'name': account.name,
          'description': account.description,
          'accountType': account.accountType.storageValue,
          'normalBalance': account.normalBalance.storageValue,
          'level': account.level,
          'isGroup': account.isGroup,
          'isActive': account.isActive,
          'isSystemAccount': account.isSystemAccount,
          'version': account.version,
          'updatedAt': account.updatedAt.toUtc().millisecondsSinceEpoch,
          'deletedAt': account.deletedAt?.toUtc().millisecondsSinceEpoch,
        },
      ),
    );
  }

  @override
  Future<List<Account>> getAll({bool includeInactive = false}) async {
    final rows =
        await (_db.select(_db.accounts)
              ..where((t) => _activeFilter(t, includeInactive))
              ..orderBy([(t) => OrderingTerm.asc(t.accountCode)]))
            .get();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Stream<List<Account>> watchAll({bool includeInactive = false}) {
    final query = _db.select(_db.accounts)
      ..where((t) => _activeFilter(t, includeInactive))
      ..orderBy([(t) => OrderingTerm.asc(t.accountCode)]);
    return query.watch().map((rows) => rows.map(_map).toList(growable: false));
  }

  @override
  Future<Account?> getById(int id) async {
    final row = await (_db.select(
      _db.accounts,
    )..where((t) => t.id.equals(id) & _notDeleted(t))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<Account?> getByUuid(String uuid) async {
    final row = await (_db.select(
      _db.accounts,
    )..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<List<Account>> getByUuids(Iterable<String> uuids) async {
    final ids = [
      for (final uuid in {...uuids})
        if (uuid.trim().isNotEmpty) uuid.trim(),
    ];
    if (ids.isEmpty) {
      return const [];
    }
    final rows = await (_db.select(
      _db.accounts,
    )..where((t) => t.uuid.isIn(ids))).get();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Future<Account?> getByAccountCode(String accountCode) async {
    final code = _normalizeCode(accountCode);
    if (code.isEmpty) {
      return null;
    }
    final row =
        await (_db.select(_db.accounts)
              ..where((t) => t.accountCode.equals(code) & _notDeleted(t)))
            .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<List<Account>> search(
    String query, {
    bool includeInactive = false,
  }) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return getAll(includeInactive: includeInactive);
    }
    final rows =
        await (_db.select(_db.accounts)
              ..where((t) => _activeFilter(t, includeInactive))
              ..orderBy([(t) => OrderingTerm.asc(t.accountCode)]))
            .get();
    return rows
        .map(_map)
        .where(
          (a) =>
              a.accountCode.toLowerCase().contains(normalized) ||
              a.name.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }

  @override
  Future<List<Account>> getChildren(String parentUuid) async {
    final rows =
        await (_db.select(_db.accounts)
              ..where((t) => t.parentId.equals(parentUuid) & _notDeleted(t))
              ..orderBy([(t) => OrderingTerm.asc(t.accountCode)]))
            .get();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Future<bool> hasChildren(String uuid) async {
    final row =
        await (_db.select(_db.accounts)
              ..where((t) => t.parentId.equals(uuid) & _notDeleted(t))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  @override
  Future<bool> isUsedInTransactions(String uuid) async {
    // Any journal line counts — including lines whose entry is soft-deleted —
    // so soft-deleting an account cannot orphan ledger history.
    final row =
        await (_db.select(_db.journalLines)
              ..where((t) => t.accountUuid.equals(uuid))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  @override
  Future<Account> insert(AccountDraft draft) async {
    final parent = draft.parentId == null
        ? null
        : await getByUuid(draft.parentId!);
    final all = await getAll(includeInactive: true);
    _validator.validateHierarchy(
      draft: draft,
      parent: parent,
      existing: null,
      allAccounts: all,
    );

    final code = _normalizeCode(draft.accountCode);
    final name = _normalizeName(draft.name);
    final description = _normalizeDescription(draft.description);
    await _assertUniqueCode(code);

    final level = await _resolveLevel(draft.parentId);
    final now = DateTime.now().toUtc();
    final nowMs = now.millisecondsSinceEpoch;
    final uuid = generateUuidV4();

    final id = await _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
            uuid: uuid,
            parentId: Value(draft.parentId),
            accountCode: code,
            name: name,
            description: Value(description),
            accountType: draft.accountType.storageValue,
            normalBalance: draft.normalBalance.storageValue,
            level: Value(level),
            isGroup: Value(draft.isGroup),
            isActive: Value(draft.isActive),
            isSystemAccount: Value(draft.isSystemAccount),
            createdAt: nowMs,
            updatedAt: nowMs,
            syncStatus: const Value('pending'),
            version: const Value(1),
          ),
        );

    final created = await getById(id);
    if (created == null) {
      throw const AccountException(AccountException.notFound);
    }
    await _enqueue(created, SyncOperationType.create);
    return created;
  }

  @override
  Future<Account> update(int id, AccountDraft draft) async {
    final existing = await getById(id);
    if (existing == null) {
      throw const AccountException(AccountException.notFound);
    }

    final parent = draft.parentId == null
        ? null
        : await getByUuid(draft.parentId!);
    final all = await getAll(includeInactive: true);
    _validator.validateHierarchy(
      draft: draft,
      parent: parent,
      existing: existing,
      allAccounts: all,
    );
    _validator.assertSystemAccountEditable(
      existing: existing,
      draft: draft,
      isDeactivating: existing.isActive && !draft.isActive,
    );

    if (existing.isSystemAccount && draft.isGroup != existing.isGroup) {
      throw const AccountException(AccountException.systemAccountProtected);
    }

    final code = _normalizeCode(draft.accountCode);
    final name = _normalizeName(draft.name);
    final description = _normalizeDescription(draft.description);
    await _assertUniqueCode(code, excludingId: id);

    final level = await _resolveLevel(draft.parentId);
    final now = DateTime.now().toUtc();
    final nextVersion = existing.version + 1;

    await (_db.update(_db.accounts)..where((t) => t.id.equals(id))).write(
      AccountsCompanion(
        parentId: Value(draft.parentId),
        accountCode: Value(code),
        name: Value(name),
        description: Value(description),
        accountType: Value(draft.accountType.storageValue),
        normalBalance: Value(draft.normalBalance.storageValue),
        level: Value(level),
        isGroup: Value(draft.isGroup),
        isActive: Value(draft.isActive),
        updatedAt: Value(now.millisecondsSinceEpoch),
        syncStatus: const Value('pending'),
        version: Value(nextVersion),
      ),
    );

    final updated = await getById(id);
    if (updated == null) {
      throw const AccountException(AccountException.notFound);
    }
    await _enqueue(updated, SyncOperationType.update);
    return updated;
  }

  @override
  Future<void> deactivate(int id) async {
    final existing = await getById(id);
    if (existing == null) {
      throw const AccountException(AccountException.notFound);
    }
    if (existing.isSystemAccount) {
      throw const AccountException(AccountException.systemAccountProtected);
    }

    final draft = AccountDraft(
      parentId: existing.parentId,
      accountCode: existing.accountCode,
      name: existing.name,
      description: existing.description,
      accountType: existing.accountType,
      isGroup: existing.isGroup,
      isActive: false,
      isSystemAccount: existing.isSystemAccount,
    );
    await update(id, draft);
  }

  @override
  Future<void> softDelete(int id) async {
    final existing = await getById(id);
    if (existing == null) {
      throw const AccountException(AccountException.notFound);
    }
    if (existing.isSystemAccount) {
      throw const AccountException(AccountException.systemAccountProtected);
    }
    if (await hasChildren(existing.uuid)) {
      throw const AccountException(AccountException.hasChildren);
    }
    if (await isUsedInTransactions(existing.uuid)) {
      throw const AccountException(AccountException.accountInUse);
    }

    final now = DateTime.now().toUtc();
    final nextVersion = existing.version + 1;
    await (_db.update(_db.accounts)..where((t) => t.id.equals(id))).write(
      AccountsCompanion(
        deletedAt: Value(now.millisecondsSinceEpoch),
        isActive: const Value(false),
        updatedAt: Value(now.millisecondsSinceEpoch),
        syncStatus: const Value('pending'),
        version: Value(nextVersion),
      ),
    );
    final tombstone = existing.copyWith(
      deletedAt: now,
      isActive: false,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
      version: nextVersion,
    );
    await _enqueue(tombstone, SyncOperationType.delete);
  }

  @override
  Future<void> ensureDefaultChartSeeded() async {
    final existing = await (_db.select(_db.accounts)..limit(1)).get();
    if (existing.isEmpty) {
      await _seedDefaultChart();
      return;
    }
    await _alignSystemAccountCodes();
    await _alignSystemAccountFlags();
    await _insertMissingSystemAccounts();
  }

  Future<void> _seedDefaultChart() async {
    final keyToUuid = <String, String>{};
    final keyToLevel = <String, int>{};
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    await _db.transaction(() async {
      for (final seed in DefaultChartOfAccounts.seeds()) {
        final parentUuid = seed.parentKey == null
            ? null
            : keyToUuid[seed.parentKey!];
        if (seed.parentKey != null && parentUuid == null) {
          throw StateError('Missing parent seed key: ${seed.parentKey}');
        }
        final level = seed.parentKey == null
            ? 0
            : (keyToLevel[seed.parentKey!] ?? 0) + 1;
        final uuid = generateUuidV4();
        await _db
            .into(_db.accounts)
            .insert(
              AccountsCompanion.insert(
                uuid: uuid,
                parentId: Value(parentUuid),
                accountCode: seed.accountCode,
                name: seed.name,
                description: Value('system:${seed.systemKey}'),
                accountType: seed.accountType.storageValue,
                normalBalance: seed.accountType.normalBalance.storageValue,
                level: Value(level),
                isGroup: Value(seed.isGroup),
                isActive: const Value(true),
                isSystemAccount: const Value(true),
                createdAt: nowMs,
                updatedAt: nowMs,
                syncStatus: const Value('synced'),
                version: const Value(1),
              ),
            );
        keyToUuid[seed.systemKey] = uuid;
        keyToLevel[seed.systemKey] = level;
      }
    });
  }

  /// Keeps system account codes in sync with [DefaultChartOfAccounts] seeds
  /// (e.g. Fixed Assets before Current Assets) without reseeding.
  Future<void> _alignSystemAccountCodes() async {
    final seeds = DefaultChartOfAccounts.seeds();
    final byKey = <String, AccountRow>{};
    final rows =
        await (_db.select(_db.accounts)..where(
              (t) => t.isSystemAccount.equals(true) & t.deletedAt.isNull(),
            ))
            .get();

    for (final row in rows) {
      final description = row.description;
      if (description == null || !description.startsWith('system:')) {
        continue;
      }
      byKey[description.substring('system:'.length)] = row;
    }

    final updates = <({AccountRow row, String code})>[];
    for (final seed in seeds) {
      final row = byKey[seed.systemKey];
      if (row == null || row.accountCode == seed.accountCode) {
        continue;
      }
      updates.add((row: row, code: seed.accountCode));
    }
    if (updates.isEmpty) {
      return;
    }

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    await _db.transaction(() async {
      // Stage 1: temporary codes to avoid UNIQUE collisions while swapping.
      for (final update in updates) {
        await (_db.update(
          _db.accounts,
        )..where((t) => t.id.equals(update.row.id))).write(
          AccountsCompanion(
            accountCode: Value('__tmp_${update.row.id}'),
            updatedAt: Value(nowMs),
          ),
        );
      }
      // Stage 2: final codes from the seed catalog.
      for (final update in updates) {
        await (_db.update(
          _db.accounts,
        )..where((t) => t.id.equals(update.row.id))).write(
          AccountsCompanion(
            accountCode: Value(update.code),
            updatedAt: Value(nowMs),
          ),
        );
      }
    });
  }

  /// Syncs system flags such as [isGroup] from seeds (e.g. Customers → group).
  Future<void> _alignSystemAccountFlags() async {
    final seeds = DefaultChartOfAccounts.seeds();
    final byKey = <String, AccountRow>{};
    final rows =
        await (_db.select(_db.accounts)..where(
              (t) => t.isSystemAccount.equals(true) & t.deletedAt.isNull(),
            ))
            .get();

    for (final row in rows) {
      final description = row.description;
      if (description == null || !description.startsWith('system:')) {
        continue;
      }
      byKey[description.substring('system:'.length)] = row;
    }

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    for (final seed in seeds) {
      final row = byKey[seed.systemKey];
      if (row == null || row.isGroup == seed.isGroup) {
        continue;
      }
      await (_db.update(_db.accounts)..where((t) => t.id.equals(row.id))).write(
        AccountsCompanion(
          isGroup: Value(seed.isGroup),
          updatedAt: Value(nowMs),
        ),
      );
    }
  }

  /// Inserts newly added system seeds that are missing from an existing chart.
  Future<void> _insertMissingSystemAccounts() async {
    final seeds = DefaultChartOfAccounts.seeds();
    final keyToUuid = <String, String>{};
    final keyToLevel = <String, int>{};
    final rows =
        await (_db.select(_db.accounts)..where(
              (t) => t.isSystemAccount.equals(true) & t.deletedAt.isNull(),
            ))
            .get();

    for (final row in rows) {
      final description = row.description;
      if (description == null || !description.startsWith('system:')) {
        continue;
      }
      final key = description.substring('system:'.length);
      keyToUuid[key] = row.uuid;
      keyToLevel[key] = row.level;
    }

    final missing = [
      for (final seed in seeds)
        if (!keyToUuid.containsKey(seed.systemKey)) seed,
    ];
    if (missing.isEmpty) {
      return;
    }

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    await _db.transaction(() async {
      for (final seed in missing) {
        String? parentUuid;
        var level = 0;
        if (seed.parentKey != null) {
          final parentId = keyToUuid[seed.parentKey!];
          if (parentId == null) {
            continue;
          }
          parentUuid = parentId;
          level = (keyToLevel[seed.parentKey!] ?? 0) + 1;
        }

        final codeHit =
            await (_db.select(_db.accounts)..where(
                  (t) =>
                      t.accountCode.equals(seed.accountCode) &
                      t.deletedAt.isNull(),
                ))
                .getSingleOrNull();
        if (codeHit != null) {
          continue;
        }

        final uuid = generateUuidV4();
        await _db
            .into(_db.accounts)
            .insert(
              AccountsCompanion.insert(
                uuid: uuid,
                parentId: Value(parentUuid),
                accountCode: seed.accountCode,
                name: seed.name,
                description: Value('system:${seed.systemKey}'),
                accountType: seed.accountType.storageValue,
                normalBalance: seed.accountType.normalBalance.storageValue,
                level: Value(level),
                isGroup: Value(seed.isGroup),
                isActive: const Value(true),
                isSystemAccount: const Value(true),
                createdAt: nowMs,
                updatedAt: nowMs,
                syncStatus: const Value('synced'),
                version: const Value(1),
              ),
            );
        keyToUuid[seed.systemKey] = uuid;
        keyToLevel[seed.systemKey] = level;
      }
    });
  }

  @override
  Future<List<Account>> getByType(
    AccountType type, {
    bool includeInactive = false,
  }) async {
    final rows =
        await (_db.select(_db.accounts)
              ..where(
                (t) =>
                    t.accountType.equals(type.storageValue) &
                    _activeFilter(t, includeInactive),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.accountCode)]))
            .get();
    return rows.map(_map).toList(growable: false);
  }

  Future<void> markSynced({
    required String uuid,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {
    final stamp = (syncedAt ?? DateTime.now().toUtc()).millisecondsSinceEpoch;
    await (_db.update(_db.accounts)..where((t) => t.uuid.equals(uuid))).write(
      AccountsCompanion(
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(stamp),
        version: Value(remoteVersion),
      ),
    );
  }

  Future<void> markConflict(String uuid) async {
    await (_db.update(_db.accounts)..where((t) => t.uuid.equals(uuid))).write(
      const AccountsCompanion(syncStatus: Value('conflict')),
    );
  }

  Future<void> applyRemotePayload(Map<String, dynamic> payload) async {
    final uuid = payload['uuid'] as String?;
    if (uuid == null || uuid.isEmpty) {
      return;
    }
    final deletedAtMs = payload['deletedAt'] as int?;
    final existing = await getByUuid(uuid);
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final updatedAt = payload['updatedAt'] as int? ?? nowMs;
    final version = payload['version'] as int? ?? 1;

    if (existing != null &&
        (existing.syncStatus.needsUpload ||
            existing.syncStatus == SyncStatus.conflict ||
            existing.syncStatus == SyncStatus.syncing)) {
      if (version > existing.version) {
        await markConflict(uuid);
      }
      return;
    }

    final accountType =
        (payload['accountType'] as String?) ?? AccountType.asset.storageValue;
    final normalBalance =
        (payload['normalBalance'] as String?) ??
        AccountType.fromStorage(accountType).normalBalance.storageValue;

    if (existing == null) {
      if (deletedAtMs != null) {
        return;
      }
      await _db
          .into(_db.accounts)
          .insert(
            AccountsCompanion.insert(
              uuid: uuid,
              parentId: Value(payload['parentId'] as String?),
              accountCode: (payload['accountCode'] as String?) ?? uuid,
              name: (payload['name'] as String?) ?? '',
              description: Value(payload['description'] as String?),
              accountType: accountType,
              normalBalance: normalBalance,
              level: Value((payload['level'] as int?) ?? 0),
              isGroup: Value((payload['isGroup'] as bool?) ?? false),
              isActive: Value((payload['isActive'] as bool?) ?? true),
              isSystemAccount: Value(
                (payload['isSystemAccount'] as bool?) ?? false,
              ),
              createdAt: payload['createdAt'] as int? ?? updatedAt,
              updatedAt: updatedAt,
              syncStatus: const Value('synced'),
              lastSyncedAt: Value(nowMs),
              version: Value(version),
            ),
          );
      return;
    }

    await (_db.update(_db.accounts)..where((t) => t.uuid.equals(uuid))).write(
      AccountsCompanion(
        parentId: Value(payload['parentId'] as String?),
        accountCode: Value(
          (payload['accountCode'] as String?) ?? existing.accountCode,
        ),
        name: Value((payload['name'] as String?) ?? existing.name),
        description: Value(payload['description'] as String?),
        accountType: Value(accountType),
        normalBalance: Value(normalBalance),
        level: Value((payload['level'] as int?) ?? existing.level),
        isGroup: Value((payload['isGroup'] as bool?) ?? existing.isGroup),
        isActive: Value((payload['isActive'] as bool?) ?? existing.isActive),
        isSystemAccount: Value(
          (payload['isSystemAccount'] as bool?) ?? existing.isSystemAccount,
        ),
        updatedAt: Value(updatedAt),
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(nowMs),
        version: Value(version),
        deletedAt: Value(deletedAtMs),
      ),
    );
  }
}
