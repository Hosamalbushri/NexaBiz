import 'package:drift/drift.dart';

import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/sync/sync_core.dart';
import 'package:stock_count/core/tenancy/company_context_resolver.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_data_source.dart';
import '../../domain/models/customer_exception.dart';
import '../../domain/models/import_session.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/services/customer_validator.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  CustomerRepositoryImpl(
    this._db, {
    this._syncQueue,
    this._validator = const CustomerValidator(),
    this._readCompanyId,
  });

  final NexabizDatabase _db;
  final SyncQueue? _syncQueue;
  final CustomerValidator _validator;
  final String Function()? _readCompanyId;

  static const entityType = 'customer';

  String get _currentCompanyId {
    final id = _readCompanyId?.call().trim();
    if (id == null || id.isEmpty) {
      throw MissingCompanyContextException(
        'CustomerRepository operation failed: missing company context.',
      );
    }
    return id;
  }

  Expression<bool> _tenantScoped($CustomersTable t) =>
      t.companyId.equals(_currentCompanyId);

  Expression<bool> _scoped($CustomersTable t, {bool includeInactive = false}) {
    if (includeInactive) {
      return t.status.isNotValue('deleted') & _tenantScoped(t);
    }
    return t.status.equals('active') & _tenantScoped(t);
  }

  Customer _map(CustomerData row) {
    return Customer(
      id: row.id,
      uuid: row.uuid,
      companyId: row.companyId,
      customerCode: row.customerCode,
      name: row.name,
      status: CustomerStatus.fromStorage(row.status),
      phone: row.phone,
      email: row.email,
      address: row.address,
      notes: null,
      accountId: row.accountUuid,
      externalId: null,
      creditLimit: row.creditLimit,
      currencyCode: row.currencyCode,
      taxNumber: null,
      dataSource: CustomerDataSource.local,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      syncStatus: SyncStatus.synced,
      lastSyncedAt: null,
      version: 1,
      deletedAt: row.status == 'deleted' ? row.updatedAt : null,
    );
  }

  String _normalizeCode(String value) => value.trim().toUpperCase();

  Future<void> _assertUniqueCode({
    required String customerCode,
    int? excludingId,
  }) async {
    final query = _db.select(_db.customers)
      ..where((t) => t.customerCode.equals(customerCode) & _scoped(t, includeInactive: true));
    if (excludingId != null) {
      query.where((t) => t.id.isNotValue(excludingId));
    }
    final existing = await query.getSingleOrNull();
    if (existing != null) {
      throw const CustomerException(CustomerException.duplicateCustomerCode);
    }
  }

  Future<void> _enqueue(Customer customer, SyncOperationType type) async {
    final queue = _syncQueue;
    if (queue == null) return;

    await queue.enqueue(
      SyncOperation.create(
        entityType: entityType,
        entityId: customer.uuid,
        type: type,
        baseVersion: customer.version,
        payload: {
          'uuid': customer.uuid,
          'companyId': customer.companyId,
          'customerCode': customer.customerCode,
          'name': customer.name,
          'status': customer.status.name,
          'phone': customer.phone,
          'email': customer.email,
          'address': customer.address,
          'accountId': customer.accountId,
          'creditLimit': customer.creditLimit,
          'currencyCode': customer.currencyCode,
          'version': customer.version,
          'updatedAt': customer.updatedAt.toUtc().millisecondsSinceEpoch,
          'deletedAt': customer.deletedAt?.toUtc().millisecondsSinceEpoch,
        },
      ),
    );
  }

  @override
  Future<List<Customer>> getAll({bool includeInactive = false}) async {
    final rows =
        await (_db.select(_db.customers)
              ..where((t) => _scoped(t, includeInactive: includeInactive))
              ..orderBy([(t) => OrderingTerm.asc(t.customerCode)]))
            .get();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Stream<List<Customer>> watchAll({bool includeInactive = false}) {
    final query = _db.select(_db.customers)
      ..where((t) => _scoped(t, includeInactive: includeInactive))
      ..orderBy([(t) => OrderingTerm.asc(t.customerCode)]);
    return query.watch().map((rows) => rows.map(_map).toList(growable: false));
  }

  @override
  Future<Customer?> getById(int id) async {
    final row = await (_db.select(
      _db.customers,
    )..where((t) => t.id.equals(id) & _scoped(t, includeInactive: true))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<Customer?> getByUuid(String uuid) async {
    final row = await (_db.select(
      _db.customers,
    )..where((t) => t.uuid.equals(uuid) & _scoped(t, includeInactive: true))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<Customer?> getByCustomerCode(String customerCode) async {
    final code = _normalizeCode(customerCode);
    if (code.isEmpty) return null;
    final row = await (_db.select(
      _db.customers,
    )..where((t) => t.customerCode.equals(code) & _scoped(t, includeInactive: true))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<Customer?> getByExternalId(String externalId) async {
    return null;
  }

  @override
  Future<List<Customer>> search(
    String query, {
    bool includeInactive = false,
    int? limit,
  }) async {
    final trimmed = query.trim().toLowerCase();
    final select = _db.select(_db.customers)
      ..where((t) => _scoped(t, includeInactive: includeInactive));
    if (trimmed.isNotEmpty) {
      final contains = '%$trimmed%';
      select.where(
        (t) =>
            t.customerCode.collate(Collate.noCase).like(contains) |
            t.name.collate(Collate.noCase).like(contains) |
            t.phone.collate(Collate.noCase).like(contains) |
            t.email.collate(Collate.noCase).like(contains),
      );
      select.orderBy([(t) => OrderingTerm.asc(t.customerCode)]);
    } else {
      select.orderBy([(t) => OrderingTerm.asc(t.customerCode)]);
    }

    if (limit != null && limit > 0) {
      select.limit(limit);
    }
    final rows = await select.get();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Future<Customer> insert(CustomerDraft draft) async {
    await _assertUniqueCode(customerCode: draft.customerCode);

    final now = DateTime.now().toUtc();
    final uuid = generateUuidV4();
    final id = await _db
        .into(_db.customers)
        .insert(
          CustomersCompanion.insert(
            uuid: Value(uuid),
            customerCode: draft.customerCode,
            name: draft.name,
            phone: Value(draft.phone),
            email: Value(draft.email),
            address: Value(draft.address),
            creditLimit: Value(draft.creditLimit),
            currencyCode: Value(draft.currencyCode),
            accountUuid: Value(draft.accountId),
            status: Value(draft.status.name),
            createdAt: Value(now),
            updatedAt: Value(now),
            companyId: _currentCompanyId,
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
    final existing = await getById(id);
    if (existing == null) {
      throw const CustomerException(CustomerException.notFound);
    }

    await _assertUniqueCode(
      customerCode: draft.customerCode,
      excludingId: id,
    );

    final now = DateTime.now().toUtc();
    await (_db.update(
      _db.customers,
    )..where((t) => t.id.equals(id) & _scoped(t, includeInactive: true))).write(
      CustomersCompanion(
        customerCode: Value(draft.customerCode),
        name: Value(draft.name),
        phone: Value(draft.phone),
        email: Value(draft.email),
        address: Value(draft.address),
        creditLimit: Value(draft.creditLimit),
        currencyCode: Value(draft.currencyCode),
        accountUuid: Value(draft.accountId),
        status: Value(draft.status.name),
        updatedAt: Value(now),
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
    await (_db.update(
      _db.customers,
    )..where((t) => t.id.equals(id) & _scoped(t, includeInactive: true))).write(
      CustomersCompanion(
        status: const Value('deleted'),
        updatedAt: Value(now),
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
  Future<Customer> restore(int id) async {
    final existing = await getById(id);
    if (existing == null) {
      throw const CustomerException(CustomerException.notFound);
    }

    final now = DateTime.now().toUtc();
    await (_db.update(
      _db.customers,
    )..where((t) => t.id.equals(id))).write(
      CustomersCompanion(
        status: const Value('active'),
        updatedAt: Value(now),
      ),
    );

    final restored = await getById(id);
    if (restored == null) {
      throw const CustomerException(CustomerException.notFound);
    }
    await _enqueue(restored, SyncOperationType.update);
    return restored;
  }

  @override
  Future<Customer> upsertFromExternal(CustomerDraft draft) async {
    final existing = await getByCustomerCode(draft.customerCode);
    if (existing != null) {
      return update(existing.id, draft);
    }
    return insert(draft);
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
    final total = drafts.length;

    for (var i = 0; i < drafts.length; i++) {
      final draft = drafts[i];
      final existing = await getByCustomerCode(draft.customerCode);
      if (existing == null) {
        await insert(draft);
        inserted++;
      } else {
        await update(existing.id, draft);
        updated++;
      }
      onProgress?.call(i + 1, total);
    }

    return CustomerUpsertResult(insertedCount: inserted, updatedCount: updated);
  }

  Future<void> updateAccountLink({
    required String customerUuid,
    required String accountId,
  }) async {
    final uuid = customerUuid.trim();
    final account = accountId.trim();
    if (uuid.isEmpty || account.isEmpty) return;

    final now = DateTime.now().toUtc();
    await (_db.update(
      _db.customers,
    )..where((t) => t.uuid.equals(uuid) & _tenantScoped(t))).write(
      CustomersCompanion(
        accountUuid: Value(account),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> remapAccountId({
    required String customerUuid,
    required String accountId,
  }) async {
    await updateAccountLink(customerUuid: customerUuid, accountId: accountId);
  }

  /// Marks a customer synced after server confirmation.
  Future<void> markSynced({
    required String uuid,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {
    final now = syncedAt ?? DateTime.now().toUtc();
    await (_db.update(
      _db.customers,
    )..where((t) => t.uuid.equals(uuid) & _tenantScoped(t))).write(
      CustomersCompanion(
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markConflict(String uuid) async {}

  Future<void> applyRemotePayload(Map<String, dynamic> payload) async {
    final uuid = payload['uuid']?.toString();
    if (uuid == null || uuid.isEmpty) return;

    final deletedAtMs = (payload['deletedAt'] as num?)?.toInt();
    final existing = await getByUuid(uuid);
    final now = DateTime.now().toUtc();

    if (existing == null) {
      if (deletedAtMs != null) return;
      await _db
          .into(_db.customers)
          .insert(
            CustomersCompanion.insert(
              uuid: Value(uuid),
              customerCode: payload['customerCode']?.toString() ?? uuid,
              name: payload['name']?.toString() ?? '',
              phone: Value(payload['phone']?.toString()),
              email: Value(payload['email']?.toString()),
              address: Value(payload['address']?.toString()),
              creditLimit: Value((payload['creditLimit'] as num?)?.toDouble()),
              currencyCode: Value(payload['currencyCode']?.toString()),
              accountUuid: Value(payload['accountId']?.toString()),
              status: Value(payload['status']?.toString() ?? 'active'),
              createdAt: Value(now),
              updatedAt: Value(now),
              companyId: payload['companyId']?.toString() ?? _currentCompanyId,
            ),
          );
      return;
    }

    await (_db.update(
      _db.customers,
    )..where((t) => t.uuid.equals(uuid) & _tenantScoped(t))).write(
      CustomersCompanion(
        customerCode: Value(
          payload['customerCode']?.toString() ?? existing.customerCode,
        ),
        name: Value(payload['name']?.toString() ?? existing.name),
        phone: Value(payload['phone']?.toString()),
        email: Value(payload['email']?.toString()),
        address: Value(payload['address']?.toString()),
        creditLimit: Value((payload['creditLimit'] as num?)?.toDouble()),
        currencyCode: Value(payload['currencyCode']?.toString()),
        accountUuid: Value(payload['accountId']?.toString()),
        status: Value(
          deletedAtMs != null
              ? 'deleted'
              : (payload['status']?.toString() ?? existing.status.name),
        ),
        updatedAt: Value(now),
      ),
    );
  }
}
