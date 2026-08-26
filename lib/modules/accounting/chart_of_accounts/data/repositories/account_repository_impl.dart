import 'package:drift/drift.dart';

import 'package:stock_count/app/settings/settings_repository.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/normal_balance.dart';
import '../../domain/models/account_exception.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/services/account_validator.dart';
import '../../domain/services/default_chart_of_accounts.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';

import 'package:stock_count/modules/authentication/data/local_auth_store.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(
    this._db, {
    SyncQueue? syncQueue,
    AccountValidator validator = const AccountValidator(),
    Future<void> Function(String oldUuid, String newUuid)? onUuidRemapped,
    Future<bool> Function()? shouldSuppressLocalChartSeed,
    String Function()? readCompanyId,
  }) : _syncQueue = syncQueue,
       _validator = validator,
       _onUuidRemapped = onUuidRemapped,
       _shouldSuppressLocalChartSeed = shouldSuppressLocalChartSeed,
       _readCompanyId = readCompanyId;

  final AccountingDatabase _db;
  final SyncQueue? _syncQueue;
  final AccountValidator _validator;
  final Future<void> Function(String oldUuid, String newUuid)? _onUuidRemapped;
  final Future<bool> Function()? _shouldSuppressLocalChartSeed;
  final String Function()? _readCompanyId;

  static const entityType = 'account';

  String get _currentCompanyId =>
      _readCompanyId?.call() ?? LocalAuthDefaults.companyId;

  Expression<bool> _tenantScoped($AccountsTable t) =>
      t.companyId.equals(_currentCompanyId);

  Expression<bool> _scoped($AccountsTable t) =>
      t.deletedAt.isNull() & _tenantScoped(t);

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

  Expression<bool> _activeFilter($AccountsTable t, bool includeInactive) {
    if (includeInactive) {
      return _scoped(t);
    }
    return _scoped(t) & t.isActive.equals(true);
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
      ..where((t) => t.accountCode.equals(accountCode) & _scoped(t));
    if (excludingId != null) {
      query.where((t) => t.id.isNotValue(excludingId));
    }
    final hit = await query.getSingleOrNull();
    if (hit != null) {
      throw const AccountException(AccountException.duplicateAccountCode);
    }
  }

  /// Soft-deleted row that still occupies [accountCode] (DB UNIQUE includes tombstones).
  Future<AccountRow?> _findDeletedByAccountCode(String accountCode) async {
    final code = _normalizeCode(accountCode);
    if (code.isEmpty) {
      return null;
    }
    return (_db.select(_db.accounts)..where(
          (t) =>
              t.accountCode.equals(code) & t.deletedAt.isNotNull(),
        ))
        .getSingleOrNull();
  }

  /// Reuses a soft-deleted row so the UNIQUE [account_code] can be reclaimed.
  Future<Account> _reviveDeletedAccount(
    AccountRow tombstone,
    AccountDraft draft,
  ) async {
    final parent = draft.parentId == null
        ? null
        : await getByUuid(draft.parentId!);
    final existing = _map(tombstone);
    final all = await getAll(includeInactive: true);
    _validator.validateHierarchy(
      draft: draft,
      parent: parent,
      existing: existing,
      allAccounts: all,
    );

    final code = _normalizeCode(draft.accountCode);
    final name = _normalizeName(draft.name);
    final description = _normalizeDescription(draft.description);
    await _assertUniqueCode(code, excludingId: tombstone.id);

    final level = await _resolveLevel(draft.parentId);
    final now = DateTime.now().toUtc();
    final nextVersion = tombstone.version + 1;

    await (_db.update(_db.accounts)..where((t) => t.id.equals(tombstone.id)))
        .write(
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
        isSystemAccount: Value(draft.isSystemAccount),
        deletedAt: const Value(null),
        updatedAt: Value(now.millisecondsSinceEpoch),
        syncStatus: const Value('pending'),
        version: Value(nextVersion),
      ),
    );

    final revived = await getById(tombstone.id);
    if (revived == null) {
      throw const AccountException(AccountException.notFound);
    }
    await _enqueue(revived, SyncOperationType.update);
    return revived;
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
    String? parentAccountCode;
    final parentId = account.parentId;
    if (parentId != null) {
      final parent = await getByUuid(parentId);
      parentAccountCode = parent?.accountCode;
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
          // Business key so other devices can remount under their local parent
          // UUID (system chart seeds use different UUIDs per install).
          'parentAccountCode': parentAccountCode,
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

  /// Maps a remote parent UUID onto this device's chart.
  ///
  /// System accounts are seeded locally (not synced), so [parentId] from
  /// another phone rarely exists here. Prefer [parentAccountCode] (e.g. 1221).
  Future<({String? parentId, int level})> _resolveRemoteParent({
    required String? parentId,
    required String? parentAccountCode,
    required String accountCode,
    required int? fallbackLevel,
  }) async {
    if (parentId != null && parentId.isNotEmpty) {
      final byUuid = await getByUuid(parentId);
      if (byUuid != null && !byUuid.isDeleted) {
        return (parentId: byUuid.uuid, level: byUuid.level + 1);
      }
    }
    final code = parentAccountCode?.trim();
    if (code != null && code.isNotEmpty) {
      final byCode = await getByAccountCode(code);
      if (byCode != null && !byCode.isDeleted) {
        return (parentId: byCode.uuid, level: byCode.level + 1);
      }
    }
    // Legacy payloads without parentAccountCode: nest under the longest local
    // group whose code is a prefix of this account (e.g. 12210001 → 1221).
    final byPrefix = await _findGroupParentByCodePrefix(accountCode);
    if (byPrefix != null) {
      return (parentId: byPrefix.uuid, level: byPrefix.level + 1);
    }
    return (parentId: parentId, level: fallbackLevel ?? 0);
  }

  Future<Account?> _findGroupParentByCodePrefix(String accountCode) async {
    final code = accountCode.trim();
    if (code.isEmpty) {
      return null;
    }
    final groups = (await getAll(includeInactive: true)).where(
      (a) => a.isGroup && !a.isDeleted && a.accountCode.isNotEmpty,
    );
    Account? best;
    for (final group in groups) {
      if (code == group.accountCode) {
        continue;
      }
      if (!code.startsWith(group.accountCode)) {
        continue;
      }
      if (best == null || group.accountCode.length > best.accountCode.length) {
        best = group;
      }
    }
    return best;
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
    )..where((t) => t.id.equals(id) & _scoped(t))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<Account?> getByUuid(String uuid) async {
    final row = await (_db.select(
      _db.accounts,
    )..where((t) => t.uuid.equals(uuid) & _tenantScoped(t))).getSingleOrNull();
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
    )..where((t) => t.uuid.isIn(ids) & _scoped(t))).get();
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
              ..where((t) => t.accountCode.equals(code) & _scoped(t)))
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
              ..where((t) => t.parentId.equals(parentUuid) & _scoped(t))
              ..orderBy([(t) => OrderingTerm.asc(t.accountCode)]))
            .get();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Future<bool> hasChildren(String uuid) async {
    final row =
        await (_db.select(_db.accounts)
              ..where((t) => t.parentId.equals(uuid) & _scoped(t))
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

    final tombstone = await _findDeletedByAccountCode(code);
    if (tombstone != null) {
      return _reviveDeletedAccount(tombstone, draft);
    }

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
            companyId: Value(_currentCompanyId),
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

    await (_db.update(_db.accounts)..where((t) => t.id.equals(id) & _scoped(t))).write(
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
        companyId: Value(_currentCompanyId),
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
    final settingsRepo = SettingsRepository();
    final isServerInit = await settingsRepo.isServerInitialized();
    final deviceInitRecord = await settingsRepo.loadDeviceInitialization();
    if (isServerInit || deviceInitRecord.mode == DeviceInitializationMode.server) {
      // Server-initialized device: master Chart of Accounts is controlled by the server.
      // Do NOT run local seed alignment or force-enqueue unpushed accounts!
      return;
    }

    final existing = await (_db.select(_db.accounts)..where(_scoped)..limit(1)).get();
    if (existing.isEmpty) {
      final preferRemote = await settingsRepo.loadChartBootstrapPreferRemote();
      final suppressFn = await _shouldSuppressLocalChartSeed?.call() ?? false;
      if (preferRemote || suppressFn || deviceInitRecord.mode == DeviceInitializationMode.server) {
        // Joining device: wait for background pull — do not create a local CoA.
        return;
      }
      await _seedDefaultChart();
    } else {
      await _alignSystemAccountCodes();
      await _alignSystemAccountFlags();
      await _insertMissingSystemAccounts();
      await _alignSystemAccountParents();
      await _enqueueUnpushedAccounts();
    }
  }

  Future<void> _seedDefaultChart() async {
    final keyToUuid = <String, String>{};
    final keyToLevel = <String, int>{};
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final createdUuids = <String>[];

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
        final uuid = systemAccountUuid(seed.systemKey);
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
                syncStatus: const Value('pending'),
                version: const Value(1),
                companyId: Value(_currentCompanyId),
              ),
            );
        keyToUuid[seed.systemKey] = uuid;
        keyToLevel[seed.systemKey] = level;
        createdUuids.add(uuid);
      }
    });

    for (final uuid in createdUuids) {
      final account = await getByUuid(uuid);
      if (account != null) {
        await _enqueue(account, SyncOperationType.create);
      }
    }
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
        final nextVersion = update.row.version + 1;
        await (_db.update(
          _db.accounts,
        )..where((t) => t.id.equals(update.row.id))).write(
          AccountsCompanion(
            accountCode: Value(update.code),
            updatedAt: Value(nowMs),
            syncStatus: const Value('pending'),
            version: Value(nextVersion),
          ),
        );
      }
    });

    for (final update in updates) {
      final account = await getById(update.row.id);
      if (account != null) {
        await _enqueue(account, SyncOperationType.update);
      }
    }
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
    final changedIds = <int>[];
    for (final seed in seeds) {
      final row = byKey[seed.systemKey];
      if (row == null || row.isGroup == seed.isGroup) {
        continue;
      }
      await (_db.update(_db.accounts)..where((t) => t.id.equals(row.id))).write(
        AccountsCompanion(
          isGroup: Value(seed.isGroup),
          updatedAt: Value(nowMs),
          syncStatus: const Value('pending'),
          version: Value(row.version + 1),
        ),
      );
      changedIds.add(row.id);
    }
    for (final id in changedIds) {
      final account = await getById(id);
      if (account != null) {
        await _enqueue(account, SyncOperationType.update);
      }
    }
  }

  /// Moves system accounts under the parent implied by [DefaultChartOfAccounts]
  /// (e.g. Cash/Bank under Cash Boxes) and refreshes tree levels.
  Future<void> _alignSystemAccountParents() async {
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
    final changedIds = <int>[];
    for (final seed in seeds) {
      final row = byKey[seed.systemKey];
      if (row == null) {
        continue;
      }
      final expectedParentUuid =
          seed.parentKey == null ? null : byKey[seed.parentKey!]?.uuid;
      if (seed.parentKey != null && expectedParentUuid == null) {
        continue;
      }
      final expectedLevel = seed.parentKey == null
          ? 0
          : (byKey[seed.parentKey!]?.level ?? 0) + 1;
      final parentChanged = row.parentId != expectedParentUuid;
      final levelChanged = row.level != expectedLevel;
      if (!parentChanged && !levelChanged) {
        continue;
      }
      await (_db.update(_db.accounts)..where((t) => t.id.equals(row.id))).write(
        AccountsCompanion(
          parentId: Value(expectedParentUuid),
          level: Value(expectedLevel),
          updatedAt: Value(nowMs),
          syncStatus: const Value('pending'),
          version: Value(row.version + 1),
        ),
      );
      changedIds.add(row.id);
      // Keep in-memory map fresh for children processed later in seed order.
      byKey[seed.systemKey] = row.copyWith(
        parentId: Value(expectedParentUuid),
        level: expectedLevel,
        version: row.version + 1,
      );
    }
    for (final id in changedIds) {
      final account = await getById(id);
      if (account != null) {
        await _enqueue(account, SyncOperationType.update);
      }
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
    final createdUuids = <String>[];
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

        final uuid = systemAccountUuid(seed.systemKey);
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
                syncStatus: const Value('pending'),
                version: const Value(1),
                companyId: Value(_currentCompanyId),
              ),
            );
        keyToUuid[seed.systemKey] = uuid;
        keyToLevel[seed.systemKey] = level;
        createdUuids.add(uuid);
      }
    });

    for (final uuid in createdUuids) {
      final account = await getByUuid(uuid);
      if (account != null) {
        await _enqueue(account, SyncOperationType.create);
      }
    }
  }

  /// Queues Chart of Accounts rows that were never acknowledged by the remote.
  Future<void> _enqueueUnpushedAccounts() async {
    if (_syncQueue == null) {
      return;
    }
    final rows =
        await (_db.select(_db.accounts)..where(
              (t) => t.deletedAt.isNull() & t.lastSyncedAt.isNull(),
            ))
            .get();
    for (final row in rows) {
      final account = _map(row);
      if (account.syncStatus == SyncStatus.syncing ||
          account.syncStatus == SyncStatus.conflict) {
        continue;
      }
      if (account.syncStatus != SyncStatus.pending) {
        await (_db.update(_db.accounts)..where((t) => t.id.equals(row.id)))
            .write(const AccountsCompanion(syncStatus: Value('pending')));
      }
      final refreshed = account.syncStatus == SyncStatus.pending
          ? account
          : account.copyWith(syncStatus: SyncStatus.pending);
      await _enqueue(
        refreshed,
        account.version <= 1
            ? SyncOperationType.create
            : SyncOperationType.update,
      );
    }
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
    final uuid = payload['uuid']?.toString();
    if (uuid == null || uuid.isEmpty) {
      return;
    }
    final deletedAtMs = (payload['deletedAt'] as num?)?.toInt();
    final existingByUuid = await getByUuid(uuid);
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final updatedAt = (payload['updatedAt'] as num?)?.toInt() ?? nowMs;
    final version = (payload['version'] as num?)?.toInt() ?? 1;
    final code = payload['accountCode']?.toString() ?? uuid;

    if (existingByUuid != null &&
        (existingByUuid.syncStatus.needsUpload ||
            existingByUuid.syncStatus == SyncStatus.conflict ||
            existingByUuid.syncStatus == SyncStatus.syncing)) {
      if (version > existingByUuid.version) {
        await markConflict(uuid);
      }
      return;
    }

    // Stale remote: incoming version <= local version → skip (idempotent pull).
    if (existingByUuid != null && version <= existingByUuid.version) {
      return;
    }

    final accountType =
        payload['accountType']?.toString() ?? AccountType.asset.storageValue;
    final normalBalance =
        payload['normalBalance']?.toString() ??
        AccountType.fromStorage(accountType).normalBalance.storageValue;

    final resolvedParent = await _resolveRemoteParent(
      parentId: payload['parentId']?.toString(),
      parentAccountCode: payload['parentAccountCode']?.toString(),
      accountCode: code,
      fallbackLevel: (payload['level'] as num?)?.toInt(),
    );

    // Same accountCode on two devices with different UUIDs → adopt remote UUID.
    if (existingByUuid == null && deletedAtMs == null) {
      final byCode = await getByAccountCode(code);
      if (byCode != null && byCode.uuid != uuid) {
        final oldUuid = byCode.uuid;
        await (_db.update(_db.accounts)..where((t) => t.id.equals(byCode.id)))
            .write(
              AccountsCompanion(
                uuid: Value(uuid),
                parentId: Value(resolvedParent.parentId),
                accountCode: Value(code),
                name: Value(payload['name']?.toString() ?? byCode.name),
                description: Value(payload['description']?.toString()),
                accountType: Value(accountType),
                normalBalance: Value(normalBalance),
                level: Value(resolvedParent.level),
                isGroup: Value(
                  payload['isGroup'] as bool? ?? byCode.isGroup,
                ),
                isActive: Value(
                  payload['isActive'] as bool? ?? byCode.isActive,
                ),
                isSystemAccount: Value(
                  payload['isSystemAccount'] as bool? ?? byCode.isSystemAccount,
                ),
                updatedAt: Value(updatedAt),
                syncStatus: const Value('synced'),
                lastSyncedAt: Value(nowMs),
                version: Value(version),
                deletedAt: const Value(null),
              ),
            );
        // Remap children that pointed at the old local UUID.
        await (_db.update(_db.accounts)
              ..where((t) => t.parentId.equals(oldUuid)))
            .write(AccountsCompanion(parentId: Value(uuid)));
        await _syncQueue?.removeForEntity(
          entityType: entityType,
          entityId: oldUuid,
        );
        await _syncQueue?.removeForEntity(
          entityType: entityType,
          entityId: uuid,
        );
        final remap = _onUuidRemapped;
        if (remap != null) {
          await remap(oldUuid, uuid);
        }
        return;
      }
    }

    if (existingByUuid == null) {
      if (deletedAtMs != null) {
        return;
      }
      await _db
          .into(_db.accounts)
          .insert(
            AccountsCompanion.insert(
              uuid: uuid,
              parentId: Value(resolvedParent.parentId),
              accountCode: code,
              name: payload['name']?.toString() ?? '',
              description: Value(payload['description']?.toString()),
              accountType: accountType,
              normalBalance: normalBalance,
              level: Value(resolvedParent.level),
              isGroup: Value(payload['isGroup'] as bool? ?? false),
              isActive: Value(payload['isActive'] as bool? ?? true),
              isSystemAccount: Value(
                payload['isSystemAccount'] as bool? ?? false,
              ),
              createdAt: (payload['createdAt'] as num?)?.toInt() ?? updatedAt,
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
        parentId: Value(resolvedParent.parentId),
        accountCode: Value(code),
        name: Value(payload['name']?.toString() ?? existingByUuid.name),
        description: Value(payload['description']?.toString()),
        accountType: Value(accountType),
        normalBalance: Value(normalBalance),
        level: Value(resolvedParent.level),
        isGroup: Value(
          payload['isGroup'] as bool? ?? existingByUuid.isGroup,
        ),
        isActive: Value(
          payload['isActive'] as bool? ?? existingByUuid.isActive,
        ),
        isSystemAccount: Value(
          payload['isSystemAccount'] as bool? ??
              existingByUuid.isSystemAccount,
        ),
        updatedAt: Value(updatedAt),
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(nowMs),
        version: Value(version),
        deletedAt: Value(deletedAtMs),
      ),
    );
  }

  /// Re-parents an account whose [parentId] is missing locally (sync orphan).
  Future<void> remountUnderParent({
    required String accountUuid,
    required String parentUuid,
  }) async {
    final account = await getByUuid(accountUuid);
    final parent = await getByUuid(parentUuid);
    if (account == null || account.isDeleted || parent == null) {
      return;
    }
    final currentParentId = account.parentId;
    if (currentParentId == parent.uuid) {
      return;
    }
    final parentMissing =
        currentParentId == null || await getByUuid(currentParentId) == null;
    if (!parentMissing) {
      return;
    }
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.accounts)..where((t) => t.uuid.equals(accountUuid)))
        .write(
          AccountsCompanion(
            parentId: Value(parent.uuid),
            level: Value(parent.level + 1),
            updatedAt: Value(nowMs),
          ),
        );
  }
}
