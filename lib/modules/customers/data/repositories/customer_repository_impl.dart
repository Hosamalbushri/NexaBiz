import 'package:drift/drift.dart';

import '../../../../core/sync/sync_operation.dart';
import '../../../../core/sync/sync_queue.dart';
import '../../../../core/sync/sync_status.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_data_source.dart';
import '../../domain/models/customer_exception.dart';
import '../../domain/models/import_session.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/services/customer_validator.dart';
import '../database/customers_database.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  CustomerRepositoryImpl(
    this._db, {
    SyncQueue? syncQueue,
    CustomerValidator validator = const CustomerValidator(),
  }) : _syncQueue = syncQueue,
       _validator = validator;

  final CustomersDatabase _db;
  final SyncQueue? _syncQueue;
  final CustomerValidator _validator;

  static const entityType = 'customer';

  Customer _map(CustomerRow row) {
    return Customer(
      id: row.id,
      uuid: row.uuid,
      customerCode: row.customerCode,
      name: row.name,
      phone: row.phone,
      email: row.email,
      address: row.address,
      notes: row.notes,
      isActive: row.isActive,
      accountId: row.accountId,
      externalId: row.externalId,
      dataSource: CustomerDataSourceX.fromStorage(row.dataSource),
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

  Expression<bool> _notDeleted($CustomersTable t) => t.deletedAt.isNull();

  String _normalizeCode(String value) => value.trim().toUpperCase();

  String _normalizeName(String value) => value.trim();

  String? _normalizeOptional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Future<void> _assertUniqueCode({
    required String customerCode,
    int? excludingId,
  }) async {
    final query = _db.select(_db.customers)
      ..where((t) => t.customerCode.equals(customerCode) & _notDeleted(t));
    if (excludingId != null) {
      query.where((t) => t.id.isNotValue(excludingId));
    }
    final hit = await query.getSingleOrNull();
    if (hit != null) {
      throw const CustomerException(CustomerException.duplicateCustomerCode);
    }
  }

  Future<void> _assertUniqueExternalId({
    required String? externalId,
    int? excludingId,
  }) async {
    if (externalId == null) {
      return;
    }
    final query = _db.select(_db.customers)
      ..where((t) => t.externalId.equals(externalId) & _notDeleted(t));
    if (excludingId != null) {
      query.where((t) => t.id.isNotValue(excludingId));
    }
    final hit = await query.getSingleOrNull();
    if (hit != null) {
      throw const CustomerException(CustomerException.duplicateExternalId);
    }
  }

  Future<void> _enqueue(Customer customer, SyncOperationType type) async {
    final queue = _syncQueue;
    if (queue == null) {
      return;
    }
    await queue.enqueue(
      SyncOperation.create(
        entityType: entityType,
        entityId: customer.uuid,
        type: type,
        baseVersion: customer.version,
        payload: {
          'uuid': customer.uuid,
          'customerCode': customer.customerCode,
          'name': customer.name,
          'phone': customer.phone,
          'email': customer.email,
          'address': customer.address,
          'notes': customer.notes,
          'isActive': customer.isActive,
          'accountId': customer.accountId,
          'externalId': customer.externalId,
          'dataSource': customer.dataSource.storageValue,
          'version': customer.version,
          'updatedAt': customer.updatedAt.toUtc().millisecondsSinceEpoch,
          'deletedAt': customer.deletedAt?.toUtc().millisecondsSinceEpoch,
        },
      ),
    );
  }

  @override
  Future<List<Customer>> getAll({bool includeInactive = false}) async {
    final query = _db.select(_db.customers)
      ..where(_notDeleted)
      ..orderBy([(t) => OrderingTerm.asc(t.customerCode)]);
    if (!includeInactive) {
      query.where((t) => t.isActive.equals(true));
    }
    final rows = await query.get();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Stream<List<Customer>> watchAll({bool includeInactive = false}) {
    final query = _db.select(_db.customers)
      ..where(_notDeleted)
      ..orderBy([(t) => OrderingTerm.asc(t.customerCode)]);
    if (!includeInactive) {
      query.where((t) => t.isActive.equals(true));
    }
    return query.watch().map((rows) => rows.map(_map).toList(growable: false));
  }

  @override
  Future<Customer?> getById(int id) async {
    final row = await (_db.select(
      _db.customers,
    )..where((t) => t.id.equals(id) & _notDeleted(t))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<Customer?> getByUuid(String uuid) async {
    final row = await (_db.select(
      _db.customers,
    )..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<Customer?> getByCustomerCode(String customerCode) async {
    final code = _normalizeCode(customerCode);
    if (code.isEmpty) {
      return null;
    }
    final row =
        await (_db.select(_db.customers)
              ..where((t) => t.customerCode.equals(code) & _notDeleted(t)))
            .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<Customer?> getByExternalId(String externalId) async {
    final id = _normalizeOptional(externalId);
    if (id == null) {
      return null;
    }
    final row =
        await (_db.select(_db.customers)
              ..where((t) => t.externalId.equals(id) & _notDeleted(t)))
            .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  Expression<bool> _matchesQuery($CustomersTable t, String normalized) {
    final contains = '%$normalized%';
    // COLLATE NOCASE avoids wrapping columns in lower(), which blocks indexes.
    return t.customerCode.collate(Collate.noCase).like(contains) |
        t.name.collate(Collate.noCase).like(contains) |
        t.phone.collate(Collate.noCase).like(contains) |
        t.email.collate(Collate.noCase).like(contains) |
        t.externalId.collate(Collate.noCase).like(contains);
  }

  Expression<int> _relevance($CustomersTable t, String normalized) {
    final prefix = '$normalized%';
    return CaseWhenExpression<int>(
      cases: [
        CaseWhen(
          t.customerCode.collate(Collate.noCase).equals(normalized),
          then: const Constant(0),
        ),
        CaseWhen(
          t.externalId.collate(Collate.noCase).equals(normalized),
          then: const Constant(1),
        ),
        CaseWhen(
          t.phone.collate(Collate.noCase).equals(normalized),
          then: const Constant(2),
        ),
        CaseWhen(
          t.customerCode.collate(Collate.noCase).like(prefix),
          then: const Constant(3),
        ),
        CaseWhen(
          t.name.collate(Collate.noCase).equals(normalized),
          then: const Constant(4),
        ),
        CaseWhen(
          t.name.collate(Collate.noCase).like(prefix),
          then: const Constant(5),
        ),
      ],
      orElse: const Constant(6),
    );
  }

  @override
  Future<List<Customer>> search(
    String query, {
    bool includeInactive = false,
    int? limit,
  }) async {
    final normalized = query.trim().toLowerCase();
    final select = _db.select(_db.customers)..where(_notDeleted);
    if (!includeInactive) {
      select.where((t) => t.isActive.equals(true));
    }
    if (normalized.isNotEmpty) {
      select.where((t) => _matchesQuery(t, normalized));
      select.orderBy([
        (t) => OrderingTerm.asc(_relevance(t, normalized)),
        (t) => OrderingTerm.asc(t.customerCode),
      ]);
    } else {
      select.orderBy([(t) => OrderingTerm.asc(t.customerCode)]);
    }
    if (limit != null && limit > 0) {
      select.limit(limit);
    }
    final rows = await select.get();
    return rows.map(_map).toList(growable: false);
  }

  CustomerDraft _normalizedDraft(CustomerDraft draft) {
    final externalId = _normalizeOptional(draft.externalId);
    final dataSource = draft.dataSource;
    return CustomerDraft(
      customerCode: _normalizeCode(draft.customerCode),
      name: _normalizeName(draft.name),
      phone: _normalizeOptional(draft.phone),
      email: _normalizeOptional(draft.email)?.toLowerCase(),
      address: _normalizeOptional(draft.address),
      notes: _normalizeOptional(draft.notes),
      isActive: draft.isActive,
      accountId: _normalizeOptional(draft.accountId),
      externalId: dataSource == CustomerDataSource.local ? null : externalId,
      dataSource: dataSource,
    );
  }

  @override
  Future<Customer> insert(CustomerDraft draft) async {
    _validator.validate(draft);
    final normalized = _normalizedDraft(draft);
    await _assertUniqueCode(customerCode: normalized.customerCode);
    await _assertUniqueExternalId(externalId: normalized.externalId);

    final now = DateTime.now().toUtc();
    final nowMs = now.millisecondsSinceEpoch;
    final uuid = generateUuidV4();
    final id = await _db
        .into(_db.customers)
        .insert(
          CustomersCompanion.insert(
            uuid: uuid,
            customerCode: normalized.customerCode,
            name: normalized.name,
            phone: Value(normalized.phone),
            email: Value(normalized.email),
            address: Value(normalized.address),
            notes: Value(normalized.notes),
            isActive: Value(normalized.isActive),
            accountId: Value(normalized.accountId),
            externalId: Value(normalized.externalId),
            dataSource: Value(normalized.dataSource.storageValue),
            createdAt: nowMs,
            updatedAt: nowMs,
            syncStatus: const Value('pending'),
            version: const Value(1),
          ),
        );
    final created = await getById(id);
    if (created == null) {
      throw const CustomerException(CustomerException.notFound);
    }
    await _enqueue(created, SyncOperationType.create);
    return created;
  }

  @override
  Future<Customer> update(int id, CustomerDraft draft) async {
    _validator.validate(draft);
    final existing = await getById(id);
    if (existing == null) {
      throw const CustomerException(CustomerException.notFound);
    }

    final normalized = _normalizedDraft(draft);
    await _assertUniqueCode(
      customerCode: normalized.customerCode,
      excludingId: id,
    );
    await _assertUniqueExternalId(
      externalId: normalized.externalId,
      excludingId: id,
    );

    final now = DateTime.now().toUtc();
    final nextVersion = existing.version + 1;
    await (_db.update(_db.customers)..where((t) => t.id.equals(id))).write(
      CustomersCompanion(
        customerCode: Value(normalized.customerCode),
        name: Value(normalized.name),
        phone: Value(normalized.phone),
        email: Value(normalized.email),
        address: Value(normalized.address),
        notes: Value(normalized.notes),
        isActive: Value(normalized.isActive),
        accountId: Value(normalized.accountId),
        externalId: Value(normalized.externalId),
        dataSource: Value(normalized.dataSource.storageValue),
        updatedAt: Value(now.millisecondsSinceEpoch),
        syncStatus: const Value('pending'),
        version: Value(nextVersion),
      ),
    );

    final updated = await getById(id);
    if (updated == null) {
      throw const CustomerException(CustomerException.notFound);
    }
    await _enqueue(updated, SyncOperationType.update);
    return updated;
  }

  @override
  Future<void> softDelete(int id) async {
    final existing = await getById(id);
    if (existing == null) {
      throw const CustomerException(CustomerException.notFound);
    }
    final now = DateTime.now().toUtc();
    final nextVersion = existing.version + 1;
    await (_db.update(_db.customers)..where((t) => t.id.equals(id))).write(
      CustomersCompanion(
        deletedAt: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
        syncStatus: const Value('pending'),
        version: Value(nextVersion),
      ),
    );
    final tombstone = existing.copyWith(
      deletedAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
      version: nextVersion,
    );
    await _enqueue(tombstone, SyncOperationType.delete);
  }

  @override
  Future<Customer> upsertFromExternal(CustomerDraft draft) async {
    final withExternal = CustomerDraft(
      customerCode: draft.customerCode,
      name: draft.name,
      phone: draft.phone,
      email: draft.email,
      address: draft.address,
      notes: draft.notes,
      isActive: draft.isActive,
      accountId: draft.accountId,
      externalId: draft.externalId,
      dataSource: CustomerDataSource.external,
    );
    _validator.validate(withExternal);
    final normalized = _normalizedDraft(withExternal);
    final existing = await getByExternalId(normalized.externalId!);
    if (existing != null) {
      return update(existing.id, normalized);
    }
    return insert(normalized);
  }

  @override
  Future<CustomerUpsertResult> upsertAll(
    List<CustomerDraft> drafts, {
    void Function(int processed, int total)? onProgress,
  }) async {
    if (drafts.isEmpty) {
      return const CustomerUpsertResult(insertedCount: 0, updatedCount: 0);
    }

    var inserted = 0;
    var updated = 0;
    final now = DateTime.now().toUtc();
    final nowMs = now.millisecondsSinceEpoch;
    final touched = <Customer>[];

    // One preload instead of N+1 lookups per row.
    final existingRows =
        await (_db.select(_db.customers)..where(_notDeleted)).get();
    final byCode = <String, Customer>{};
    final byExternalId = <String, Customer>{};
    for (final row in existingRows) {
      final customer = _map(row);
      byCode[customer.customerCode] = customer;
      final externalId = customer.externalId;
      if (externalId != null && externalId.isNotEmpty) {
        byExternalId[externalId] = customer;
      }
    }

    const chunkSize = 40;
    final total = drafts.length;
    for (var start = 0; start < drafts.length; start += chunkSize) {
      final end = (start + chunkSize < drafts.length)
          ? start + chunkSize
          : drafts.length;
      final chunk = drafts.sublist(start, end);

      await _db.transaction(() async {
        for (final draft in chunk) {
          _validator.validate(draft);
          final normalized = _normalizedDraft(draft);

          Customer? existing;
          if (normalized.externalId != null) {
            existing = byExternalId[normalized.externalId!];
          }
          existing ??= byCode[normalized.customerCode];

          if (existing == null) {
            final codeClash = byCode[normalized.customerCode];
            if (codeClash != null) {
              throw const CustomerException(
                CustomerException.duplicateCustomerCode,
              );
            }
            if (normalized.externalId != null &&
                byExternalId.containsKey(normalized.externalId!)) {
              throw const CustomerException(
                CustomerException.duplicateExternalId,
              );
            }

            final uuid = generateUuidV4();
            final id = await _db
                .into(_db.customers)
                .insert(
                  CustomersCompanion.insert(
                    uuid: uuid,
                    customerCode: normalized.customerCode,
                    name: normalized.name,
                    phone: Value(normalized.phone),
                    email: Value(normalized.email),
                    address: Value(normalized.address),
                    notes: Value(normalized.notes),
                    isActive: Value(normalized.isActive),
                    accountId: Value(normalized.accountId),
                    externalId: Value(normalized.externalId),
                    dataSource: Value(normalized.dataSource.storageValue),
                    createdAt: nowMs,
                    updatedAt: nowMs,
                    syncStatus: const Value('pending'),
                    version: const Value(1),
                  ),
                );
            final created = Customer(
              id: id,
              uuid: uuid,
              customerCode: normalized.customerCode,
              name: normalized.name,
              phone: normalized.phone,
              email: normalized.email,
              address: normalized.address,
              notes: normalized.notes,
              isActive: normalized.isActive,
              accountId: normalized.accountId,
              externalId: normalized.externalId,
              dataSource: normalized.dataSource,
              createdAt: now,
              updatedAt: now,
              syncStatus: SyncStatus.pending,
              version: 1,
            );
            touched.add(created);
            byCode[created.customerCode] = created;
            if (created.externalId != null) {
              byExternalId[created.externalId!] = created;
            }
            inserted++;
          } else {
            final codeOwner = byCode[normalized.customerCode];
            if (codeOwner != null && codeOwner.id != existing.id) {
              throw const CustomerException(
                CustomerException.duplicateCustomerCode,
              );
            }
            if (normalized.externalId != null) {
              final extOwner = byExternalId[normalized.externalId!];
              if (extOwner != null && extOwner.id != existing.id) {
                throw const CustomerException(
                  CustomerException.duplicateExternalId,
                );
              }
            }

            final nextVersion = existing.version + 1;
            final nextAccountId = normalized.accountId ?? existing.accountId;
            final nextExternalId =
                normalized.externalId ?? existing.externalId;
            await (_db.update(
              _db.customers,
            )..where((t) => t.id.equals(existing!.id))).write(
              CustomersCompanion(
                customerCode: Value(normalized.customerCode),
                name: Value(normalized.name),
                phone: Value(normalized.phone),
                email: Value(normalized.email),
                address: Value(normalized.address),
                notes: Value(normalized.notes),
                isActive: Value(normalized.isActive),
                // Preserve linked CoA account unless the draft explicitly sets one.
                accountId: Value(nextAccountId),
                externalId: Value(nextExternalId),
                dataSource: Value(normalized.dataSource.storageValue),
                updatedAt: Value(nowMs),
                syncStatus: const Value('pending'),
                version: Value(nextVersion),
              ),
            );
            final updatedRow = existing.copyWith(
              customerCode: normalized.customerCode,
              name: normalized.name,
              phone: normalized.phone,
              clearPhone: normalized.phone == null,
              email: normalized.email,
              clearEmail: normalized.email == null,
              address: normalized.address,
              clearAddress: normalized.address == null,
              notes: normalized.notes,
              clearNotes: normalized.notes == null,
              isActive: normalized.isActive,
              accountId: nextAccountId,
              clearAccountId: nextAccountId == null,
              externalId: nextExternalId,
              clearExternalId: nextExternalId == null,
              dataSource: normalized.dataSource,
              updatedAt: now,
              syncStatus: SyncStatus.pending,
              version: nextVersion,
            );
            // Refresh maps if code/external id changed.
            if (existing.customerCode != updatedRow.customerCode) {
              byCode.remove(existing.customerCode);
            }
            final oldExternal = existing.externalId;
            if (oldExternal != null && oldExternal != updatedRow.externalId) {
              byExternalId.remove(oldExternal);
            }
            byCode[updatedRow.customerCode] = updatedRow;
            if (updatedRow.externalId != null) {
              byExternalId[updatedRow.externalId!] = updatedRow;
            }
            touched.add(updatedRow);
            updated++;
          }
        }
      });

      onProgress?.call(end, total);
      await Future<void>.delayed(Duration.zero);
    }

    for (final customer in touched) {
      await _enqueue(
        customer,
        customer.version <= 1
            ? SyncOperationType.create
            : SyncOperationType.update,
      );
    }

    return CustomerUpsertResult(insertedCount: inserted, updatedCount: updated);
  }

  Future<void> markSynced({
    required String uuid,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {
    final stamp = (syncedAt ?? DateTime.now().toUtc()).millisecondsSinceEpoch;
    await (_db.update(_db.customers)..where((t) => t.uuid.equals(uuid))).write(
      CustomersCompanion(
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(stamp),
        version: Value(remoteVersion),
      ),
    );
  }

  Future<void> markConflict(String uuid) async {
    await (_db.update(_db.customers)..where((t) => t.uuid.equals(uuid))).write(
      const CustomersCompanion(syncStatus: Value('conflict')),
    );
  }

  /// Point customer CoA links at a remapped account UUID after sync merge.
  Future<void> remapAccountId({
    required String fromUuid,
    required String toUuid,
  }) async {
    if (fromUuid == toUuid) {
      return;
    }
    await (_db.update(_db.customers)
          ..where((t) => t.accountId.equals(fromUuid)))
        .write(CustomersCompanion(accountId: Value(toUuid)));
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
    final code =
        (payload['customerCode']?.toString())?.toUpperCase() ?? uuid;
    final dataSource = CustomerDataSourceX.fromStorage(
      payload['dataSource']?.toString(),
    );

    // Same UUID, local still dirty → conflict marker (do not clobber local edit).
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
    // Prevents a re-delivered remote change from silently overwriting local edits
    // made between the first and second apply of the same remote change.
    if (existingByUuid != null && version <= existingByUuid.version) {
      return;
    }

    // Business-key merge: both devices imported the same customerCode with
    // different UUIDs. Prefer the remote UUID so pull can insert/update.
    if (existingByUuid == null && deletedAtMs == null) {
      final byCode = await getByCustomerCode(code);
      if (byCode != null && byCode.uuid != uuid) {
        final oldUuid = byCode.uuid;
        await (_db.update(_db.customers)..where((t) => t.id.equals(byCode.id)))
            .write(
              CustomersCompanion(
                uuid: Value(uuid),
                customerCode: Value(code),
                name: Value(payload['name']?.toString() ?? byCode.name),
                phone: Value(payload['phone']?.toString()),
                email: Value(payload['email']?.toString()),
                address: Value(payload['address']?.toString()),
                notes: Value(payload['notes']?.toString()),
                isActive: Value(payload['isActive'] as bool? ?? byCode.isActive),
                accountId: Value(
                  payload['accountId']?.toString() ?? byCode.accountId,
                ),
                externalId: Value(
                  payload['externalId']?.toString() ?? byCode.externalId,
                ),
                dataSource: Value(dataSource.storageValue),
                updatedAt: Value(updatedAt),
                syncStatus: const Value('synced'),
                lastSyncedAt: Value(nowMs),
                version: Value(version),
                deletedAt: const Value(null),
              ),
            );
        await _syncQueue?.removeForEntity(
          entityType: entityType,
          entityId: oldUuid,
        );
        await _syncQueue?.removeForEntity(
          entityType: entityType,
          entityId: uuid,
        );
        return;
      }
    }

    if (existingByUuid == null) {
      if (deletedAtMs != null) {
        return;
      }
      await _db
          .into(_db.customers)
          .insert(
            CustomersCompanion.insert(
              uuid: uuid,
              customerCode: code,
              name: payload['name']?.toString() ?? '',
              phone: Value(payload['phone']?.toString()),
              email: Value(payload['email']?.toString()),
              address: Value(payload['address']?.toString()),
              notes: Value(payload['notes']?.toString()),
              isActive: Value(payload['isActive'] as bool? ?? true),
              accountId: Value(payload['accountId']?.toString()),
              externalId: Value(payload['externalId']?.toString()),
              dataSource: Value(dataSource.storageValue),
              createdAt: (payload['createdAt'] as num?)?.toInt() ?? updatedAt,
              updatedAt: updatedAt,
              syncStatus: const Value('synced'),
              lastSyncedAt: Value(nowMs),
              version: Value(version),
            ),
          );
      return;
    }

    await (_db.update(_db.customers)..where((t) => t.uuid.equals(uuid))).write(
      CustomersCompanion(
        customerCode: Value(code),
        name: Value(payload['name']?.toString() ?? existingByUuid.name),
        phone: Value(payload['phone']?.toString()),
        email: Value(payload['email']?.toString()),
        address: Value(payload['address']?.toString()),
        notes: Value(payload['notes']?.toString()),
        isActive: Value(
          payload['isActive'] as bool? ?? existingByUuid.isActive,
        ),
        accountId: Value(payload['accountId']?.toString()),
        externalId: Value(payload['externalId']?.toString()),
        dataSource: Value(dataSource.storageValue),
        updatedAt: Value(updatedAt),
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(nowMs),
        version: Value(version),
        deletedAt: Value(deletedAtMs),
      ),
    );
  }
}
