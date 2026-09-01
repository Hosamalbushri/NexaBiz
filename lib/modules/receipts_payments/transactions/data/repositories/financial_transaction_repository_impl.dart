import 'package:drift/drift.dart';

import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/core/utils/business_date.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import '../../domain/entities/financial_transaction.dart';
import '../../domain/entities/financial_transaction_line.dart';
import '../../domain/entities/rp_payment_method.dart';
import '../../domain/entities/transaction_dashboard_summary.dart';
import '../../domain/entities/transaction_list_item.dart';
import '../../domain/entities/transaction_source.dart';
import '../../domain/entities/transaction_status.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/models/financial_transaction_exception.dart';
import '../../domain/models/transaction_list_filter.dart';
import '../../domain/models/transaction_paged_result.dart';
import '../../domain/repositories/financial_transaction_repository.dart';
import 'package:stock_count/modules/receipts_payments/shared/data/database/receipts_payments_database.dart';

import 'package:stock_count/core/domain/ports/period_validator_port.dart';
import 'package:stock_count/core/errors/journal_exception.dart';

import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/receipts_payments/permissions/receipts_payments_permission_package.dart';

class FinancialTransactionRepositoryImpl
    implements FinancialTransactionRepository {
  FinancialTransactionRepositoryImpl(
    this._db, {
    PeriodValidatorPort? periodValidator,
    PermissionGuard permissionGuard = const AllowAllPermissionGuard(),
    SyncQueue? syncQueue,
    String Function()? readCompanyId,
  }) : _periodValidator = periodValidator,
       _permissionGuard = permissionGuard,
       _syncQueue = syncQueue,
       _readCompanyId = readCompanyId;

  final ReceiptsPaymentsDatabase _db;
  final PeriodValidatorPort? _periodValidator;
  final PermissionGuard _permissionGuard;
  final SyncQueue? _syncQueue;
  final String Function()? _readCompanyId;


  static const entityType = 'financial_transaction';

  String get _currentCompanyId =>
      _readCompanyId?.call() ?? 'default_company';

  Expression<bool> _tenantScoped($FinancialTransactionsTable t) =>
      t.companyId.equals(_currentCompanyId);

  Expression<bool> _scoped($FinancialTransactionsTable t) =>
      t.deletedAt.isNull() & _tenantScoped(t);

  Expression<bool> _notCancelled($FinancialTransactionsTable t) =>
      t.cancelledAt.isNull();

  DateTime _fromEpoch(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

  int? _toEpoch(DateTime? value) => value?.toUtc().millisecondsSinceEpoch;

  Expression<bool> _matchesFilter(
    $FinancialTransactionsTable t,
    TransactionListFilter filter,
  ) {
    var expr = _scoped(t) & _notCancelled(t);
    if (filter.transactionType != null) {
      expr = expr &
          t.transactionType.equals(filter.transactionType!.storageValue);
    }
    if (filter.documentStatus != null) {
      expr =
          expr & t.documentStatus.equals(filter.documentStatus!.storageValue);
    }
    if (filter.paymentMethod != null) {
      expr = expr & t.paymentMethod.equals(filter.paymentMethod!.storageValue);
    }
    if (filter.syncStatus != null) {
      expr = expr & t.syncStatus.equals(filter.syncStatus!.storageValue);
    }
    if (filter.source != null) {
      expr = expr & t.source.equals(filter.source!.storageValue);
    }
    if (filter.customerId != null && filter.customerId!.trim().isNotEmpty) {
      expr = expr & t.customerId.equals(filter.customerId!.trim());
    }
    if (filter.cashAccountId != null &&
        filter.cashAccountId!.trim().isNotEmpty) {
      expr = expr & t.cashAccountId.equals(filter.cashAccountId!.trim());
    }
    if (filter.cashAccountCodePrefix != null &&
        filter.cashAccountCodePrefix!.trim().isNotEmpty) {
      final prefix = filter.cashAccountCodePrefix!.trim();
      expr = expr & t.cashAccountCode.like('$prefix%');
    }
    if (filter.counterAccountId != null &&
        filter.counterAccountId!.trim().isNotEmpty) {
      expr =
          expr & t.counterAccountId.equals(filter.counterAccountId!.trim());
    }
    if (filter.fromDate != null) {
      expr = expr &
          t.transactionDate
              .isBiggerOrEqualValue(BusinessDate.utcDayMs(filter.fromDate!));
    }
    if (filter.toDate != null) {
      expr = expr &
          t.transactionDate
              .isSmallerOrEqualValue(BusinessDate.utcDayMs(filter.toDate!));
    }
    if (filter.numberFrom != null || filter.numberTo != null) {
      final from = filter.numberFrom ?? filter.numberTo!;
      final to = filter.numberTo ?? filter.numberFrom!;
      final lo = from <= to ? from : to;
      final hi = from <= to ? to : from;
      // Match absolute stored number or the short local sequence users see.
      const stride = 1000000;
      final absolute = CustomExpression<int>(
        'CAST(transaction_number AS INTEGER)',
      );
      final local = CustomExpression<int>(
        'CASE '
        'WHEN CAST(transaction_number AS INTEGER) < $stride '
        'THEN CAST(transaction_number AS INTEGER) '
        'WHEN CAST(transaction_number AS INTEGER) % $stride = 0 '
        'THEN $stride '
        'ELSE CAST(transaction_number AS INTEGER) % $stride '
        'END',
      );
      expr = expr &
          ((absolute.isBiggerOrEqualValue(lo) &
                  absolute.isSmallerOrEqualValue(hi)) |
              (local.isBiggerOrEqualValue(lo) & local.isSmallerOrEqualValue(hi)));
    }
    final q = filter.query.trim().toLowerCase();
    if (q.isNotEmpty) {
      final like = '%$q%';
      expr = expr &
          (t.transactionNumber.lower().like(like) |
              t.reference.lower().like(like) |
              t.description.lower().like(like) |
              t.customerName.lower().like(like) |
              t.partyName.lower().like(like) |
              t.cashAccountName.lower().like(like) |
              t.counterAccountName.lower().like(like));
    }
    return expr;
  }

  FinancialTransaction _mapRow(FinancialTransactionRow row) {
    return FinancialTransaction(
      id: row.id,
      uuid: row.uuid,
      transactionNumber: row.transactionNumber,
      transactionType: TransactionTypeX.fromStorage(row.transactionType),
      source: TransactionSourceX.fromStorage(row.source),
      transactionDate: _fromEpoch(row.transactionDate),
      amount: row.amount,
      currencyCode: row.currencyCode,
      baseCurrencyCode: row.baseCurrencyCode,
      exchangeRate: row.exchangeRate,
      counterAmount: row.counterAmount > 0 ? row.counterAmount : row.amount,
      counterCurrencyCode: row.counterCurrencyCode.trim().isEmpty
          ? row.currencyCode
          : row.counterCurrencyCode,
      counterExchangeRate: row.counterExchangeRate <= 0
          ? row.exchangeRate
          : row.counterExchangeRate,
      voucherBookId: row.voucherBookId,
      cashAccountId: row.cashAccountId,
      cashAccountCode: row.cashAccountCode,
      cashAccountName: row.cashAccountName,
      counterAccountId: row.counterAccountId,
      counterAccountCode: row.counterAccountCode,
      counterAccountName: row.counterAccountName,
      customerId: row.customerId,
      customerCode: row.customerCode,
      customerName: row.customerName,
      partyName: row.partyName,
      reference: row.reference,
      description: row.description,
      paymentMethod: RpPaymentMethodX.fromStorage(row.paymentMethod),
      documentStatus: TransactionStatusX.fromStorage(row.documentStatus),
      relatedDocumentId: row.relatedDocumentId,
      relatedDocumentType: row.relatedDocumentType,
      createdAt: _fromEpoch(row.createdAt),
      updatedAt: _fromEpoch(row.updatedAt),
      cancelledAt:
          row.cancelledAt == null ? null : _fromEpoch(row.cancelledAt!),
      externalId: row.externalId,
      syncStatus: SyncStatusX.fromStorage(row.syncStatus),
      lastSyncedAt:
          row.lastSyncedAt == null ? null : _fromEpoch(row.lastSyncedAt!),
      version: row.version,
      deletedAt: row.deletedAt == null ? null : _fromEpoch(row.deletedAt!),
      lines: FinancialTransactionLinesCodec.decode(row.linesJson),
    );
  }

  TransactionListItem _mapListItem(FinancialTransactionRow row) {
    final customer = row.customerName?.trim();
    final party = row.partyName?.trim();
    final display = (customer != null && customer.isNotEmpty)
        ? customer
        : (party != null && party.isNotEmpty ? party : null);
    return TransactionListItem(
      id: row.id,
      uuid: row.uuid,
      transactionNumber: row.transactionNumber,
      transactionType: TransactionTypeX.fromStorage(row.transactionType),
      transactionDate: _fromEpoch(row.transactionDate),
      amount: row.amount,
      currencyCode: row.currencyCode,
      cashAccountName: row.cashAccountName,
      counterAccountName: row.counterAccountName,
      partyDisplayName: display,
      reference: row.reference,
      description: row.description,
      documentStatus: TransactionStatusX.fromStorage(row.documentStatus),
      syncStatus: SyncStatusX.fromStorage(row.syncStatus),
    );
  }

  Map<String, dynamic> _toPayload(FinancialTransaction txn) {
    return {
      'uuid': txn.uuid,
      'transactionNumber': txn.transactionNumber,
      'transactionType': txn.transactionType.storageValue,
      'source': txn.source.storageValue,
      'transactionDate': txn.transactionDate.toUtc().millisecondsSinceEpoch,
      'amount': txn.amount,
      'currencyCode': txn.currencyCode,
      'baseCurrencyCode': txn.baseCurrencyCode,
      'exchangeRate': txn.exchangeRate,
      'counterAmount': txn.counterAmount,
      'counterCurrencyCode': txn.counterCurrencyCode,
      'counterExchangeRate': txn.counterExchangeRate,
      'voucherBookId': txn.voucherBookId,
      'cashAccountId': txn.cashAccountId,
      'cashAccountCode': txn.cashAccountCode,
      'cashAccountName': txn.cashAccountName,
      'counterAccountId': txn.counterAccountId,
      'counterAccountCode': txn.counterAccountCode,
      'counterAccountName': txn.counterAccountName,
      'customerId': txn.customerId,
      'customerCode': txn.customerCode,
      'customerName': txn.customerName,
      'partyName': txn.partyName,
      'reference': txn.reference,
      'description': txn.description,
      'paymentMethod': txn.paymentMethod.storageValue,
      'documentStatus': txn.documentStatus.storageValue,
      'relatedDocumentId': txn.relatedDocumentId,
      'relatedDocumentType': txn.relatedDocumentType,
      'cancelledAt': _toEpoch(txn.cancelledAt),
      'externalId': txn.externalId,
      'version': txn.version,
      'updatedAt': txn.updatedAt.toUtc().millisecondsSinceEpoch,
      'deletedAt': _toEpoch(txn.deletedAt),
      'lines': [for (final line in txn.resolvedLines) line.toJson()],
    };
  }

  Future<void> _enqueue(
    FinancialTransaction txn,
    SyncOperationType type,
  ) async {
    final queue = _syncQueue;
    if (queue == null) return;
    await queue.enqueue(
      SyncOperation.create(
        entityType: entityType,
        entityId: txn.uuid,
        type: type,
        baseVersion: txn.version,
        payload: _toPayload(txn),
      ),
    );
  }

  @override
  Future<FinancialTransaction?> getById(int id) async {
    final row = await (_db.select(_db.financialTransactions)
          ..where((t) => t.id.equals(id) & _scoped(t)))
        .getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<FinancialTransaction?> getByUuid(String uuid) async {
    final row = await (_db.select(_db.financialTransactions)
          ..where((t) => t.uuid.equals(uuid) & _scoped(t)))
        .getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<FinancialTransaction> insert(
    FinancialTransactionDraft draft, {
    required String transactionNumber,
  }) async {
    if (draft.documentStatus == TransactionStatus.posted) {
      _permissionGuard.requireAny(ReceiptsPaymentsPermissions.postFor(draft.transactionType));
    } else {
      _permissionGuard.requireAny(ReceiptsPaymentsPermissions.createFor(draft.transactionType));
    }
    await _periodValidator?.assertEntryAllowed(draft.transactionDate);
    final now = DateTime.now().toUtc();

    final uuid = generateUuidV4();
    final id = await _db.into(_db.financialTransactions).insert(
          FinancialTransactionsCompanion.insert(
            uuid: uuid,
            transactionNumber: transactionNumber,
            transactionType: draft.transactionType.storageValue,
            source: draft.source.storageValue,
            transactionDate: BusinessDate.utcDayMs(draft.transactionDate),
            amount: draft.amount,
            currencyCode: Value(draft.currencyCode),
            baseCurrencyCode: Value(draft.baseCurrencyCode),
            exchangeRate: Value(draft.exchangeRate),
            counterAmount: Value(draft.counterAmount),
            counterCurrencyCode: Value(draft.counterCurrencyCode),
            counterExchangeRate: Value(draft.counterExchangeRate),
            voucherBookId: Value(draft.voucherBookId),
            cashAccountId: draft.cashAccountId,
            cashAccountCode: Value(draft.cashAccountCode),
            cashAccountName: Value(draft.cashAccountName),
            counterAccountId: draft.counterAccountId,
            counterAccountCode: Value(draft.counterAccountCode),
            counterAccountName: Value(draft.counterAccountName),
            customerId: Value(draft.customerId),
            customerCode: Value(draft.customerCode),
            customerName: Value(draft.customerName),
            partyName: Value(draft.partyName),
            reference: Value(draft.reference),
            description: Value(draft.description),
            paymentMethod: Value(draft.paymentMethod.storageValue),
            documentStatus: Value(draft.documentStatus.storageValue),
            relatedDocumentId: Value(draft.relatedDocumentId),
            relatedDocumentType: Value(draft.relatedDocumentType),
            createdAt: now.millisecondsSinceEpoch,
            updatedAt: now.millisecondsSinceEpoch,
            externalId: Value(draft.externalId),
            syncStatus: const Value('pending'),
            linesJson: Value(FinancialTransactionLinesCodec.encode(draft.lines)),
            companyId: Value(_currentCompanyId),
          ),
        );
    final created = await getById(id);
    if (created == null) {
      throw const FinancialTransactionException(
        FinancialTransactionException.notFound,
      );
    }
    await _enqueue(created, SyncOperationType.create);
    return created;
  }

  @override
  Future<FinancialTransaction> update(
    int id,
    FinancialTransactionDraft draft,
  ) async {
    final existing = await getById(id);
    if (existing == null) {
      throw const FinancialTransactionException(
        FinancialTransactionException.notFound,
      );
    }
    if (existing.documentStatus == TransactionStatus.posted) {
      throw const JournalException(JournalException.postedImmutable);
    }
    await _periodValidator?.assertMutationAllowed(
      entryDate: draft.transactionDate,
      originalDate: existing.transactionDate,
    );
    final now = DateTime.now().toUtc();
    await (_db.update(_db.financialTransactions)..where((t) => t.id.equals(id) & _scoped(t)))
        .write(
      FinancialTransactionsCompanion(
        source: Value(draft.source.storageValue),
        transactionDate: Value(BusinessDate.utcDayMs(draft.transactionDate)),
        amount: Value(draft.amount),
        currencyCode: Value(draft.currencyCode),
        baseCurrencyCode: Value(draft.baseCurrencyCode),
        exchangeRate: Value(draft.exchangeRate),
        counterAmount: Value(draft.counterAmount),
        counterCurrencyCode: Value(draft.counterCurrencyCode),
        counterExchangeRate: Value(draft.counterExchangeRate),
        cashAccountId: Value(draft.cashAccountId),
        cashAccountCode: Value(draft.cashAccountCode),
        cashAccountName: Value(draft.cashAccountName),
        counterAccountId: Value(draft.counterAccountId),
        counterAccountCode: Value(draft.counterAccountCode),
        counterAccountName: Value(draft.counterAccountName),
        customerId: Value(draft.customerId),
        customerCode: Value(draft.customerCode),
        customerName: Value(draft.customerName),
        partyName: Value(draft.partyName),
        reference: Value(draft.reference),
        description: Value(draft.description),
        paymentMethod: Value(draft.paymentMethod.storageValue),
        documentStatus: Value(draft.documentStatus.storageValue),
        relatedDocumentId: Value(draft.relatedDocumentId),
        relatedDocumentType: Value(draft.relatedDocumentType),
        externalId: Value(draft.externalId),
        updatedAt: Value(now.millisecondsSinceEpoch),
        syncStatus: const Value('pending'),
        version: Value(existing.version + 1),
        linesJson: Value(FinancialTransactionLinesCodec.encode(draft.lines)),
        companyId: Value(_currentCompanyId),
      ),
    );
    final updated = await getById(id);
    if (updated == null) {
      throw const FinancialTransactionException(
        FinancialTransactionException.notFound,
      );
    }
    await _enqueue(updated, SyncOperationType.update);
    return updated;
  }

  @override
  Future<FinancialTransaction> markPosted(int id) async {
    final existing = await getById(id);
    if (existing == null) {
      throw const FinancialTransactionException(
        FinancialTransactionException.notFound,
      );
    }
    await _periodValidator?.assertEntryAllowed(existing.transactionDate);
    final now = DateTime.now().toUtc();
    await (_db.update(_db.financialTransactions)..where((t) => t.id.equals(id) & _scoped(t)))
        .write(
      FinancialTransactionsCompanion(
        documentStatus: Value(TransactionStatus.posted.storageValue),
        updatedAt: Value(now.millisecondsSinceEpoch),
        syncStatus: const Value('pending'),
        version: Value(existing.version + 1),
        companyId: Value(_currentCompanyId),
      ),
    );
    final posted = await getById(id);
    if (posted == null) {
      throw const FinancialTransactionException(
        FinancialTransactionException.notFound,
      );
    }
    await _enqueue(posted, SyncOperationType.update);
    return posted;
  }

  @override
  Future<FinancialTransaction> markUnposted(int id) async {
    final existing = await getById(id);
    if (existing == null) {
      throw const FinancialTransactionException(
        FinancialTransactionException.notFound,
      );
    }
    await _periodValidator?.assertEntryAllowed(existing.transactionDate);
    final now = DateTime.now().toUtc();
    await (_db.update(_db.financialTransactions)..where((t) => t.id.equals(id) & _scoped(t)))
        .write(
      FinancialTransactionsCompanion(
        documentStatus: Value(TransactionStatus.unposted.storageValue),
        updatedAt: Value(now.millisecondsSinceEpoch),
        syncStatus: const Value('pending'),
        version: Value(existing.version + 1),
        companyId: Value(_currentCompanyId),
      ),
    );
    final unposted = await getById(id);
    if (unposted == null) {
      throw const FinancialTransactionException(
        FinancialTransactionException.notFound,
      );
    }
    await _enqueue(unposted, SyncOperationType.update);
    return unposted;
  }

  @override
  Future<FinancialTransaction> markCancelled(int id) async {
    final existing = await getById(id);
    if (existing == null) {
      throw const FinancialTransactionException(
        FinancialTransactionException.notFound,
      );
    }
    await _periodValidator?.assertEntryAllowed(existing.transactionDate);
    final now = DateTime.now().toUtc();
    await (_db.update(_db.financialTransactions)..where((t) => t.id.equals(id) & _scoped(t)))
        .write(
      FinancialTransactionsCompanion(
        cancelledAt: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
        syncStatus: const Value('pending'),
        version: Value(existing.version + 1),
        companyId: Value(_currentCompanyId),
      ),
    );
    final cancelled = await getById(id);
    if (cancelled == null) {
      throw const FinancialTransactionException(
        FinancialTransactionException.notFound,
      );
    }
    await _enqueue(cancelled, SyncOperationType.update);
    return cancelled;
  }

  @override
  Future<void> softDelete(int id) async {
    final existing = await getById(id);
    if (existing == null) return;
    _permissionGuard.requireAny(ReceiptsPaymentsPermissions.cancelFor(existing.transactionType));
    if (existing.documentStatus == TransactionStatus.posted) {
      throw const JournalException(JournalException.postedImmutable);
    }

    await _periodValidator?.assertEntryAllowed(existing.transactionDate);
    final now = DateTime.now().toUtc();
    await (_db.update(_db.financialTransactions)..where((t) => t.id.equals(id) & _scoped(t)))
        .write(
      FinancialTransactionsCompanion(
        deletedAt: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
        syncStatus: const Value('pending'),
        version: Value(existing.version + 1),
        companyId: Value(_currentCompanyId),
      ),
    );
    final deleted = await getByUuid(existing.uuid);
    if (deleted != null) {
      await _enqueue(deleted, SyncOperationType.delete);
    } else {
      await _enqueue(
        existing.copyWithDeleted(now),
        SyncOperationType.delete,
      );
    }
  }

  @override
  Future<TransactionPagedResult<TransactionListItem>> searchListPaged({
    TransactionListFilter filter = const TransactionListFilter(),
    int page = 0,
    int pageSize = 30,
  }) async {
    final safePage = page < 0 ? 0 : page;
    final safeSize = pageSize <= 0 ? 30 : pageSize;

    final countQuery = _db.selectOnly(_db.financialTransactions)
      ..addColumns([_db.financialTransactions.id.count()])
      ..where(_matchesFilter(_db.financialTransactions, filter));
    final countRow = await countQuery.getSingle();
    final totalCount =
        countRow.read(_db.financialTransactions.id.count()) ?? 0;

    final start = safePage * safeSize;
    if (totalCount == 0 || start >= totalCount) {
      return TransactionPagedResult(
        items: const [],
        totalCount: totalCount,
        page: safePage,
        pageSize: safeSize,
      );
    }

    final select = _db.select(_db.financialTransactions)
      ..where((t) => _matchesFilter(t, filter))
      ..orderBy([
        (t) => OrderingTerm.desc(t.transactionDate),
        (t) => OrderingTerm.desc(t.id),
      ])
      ..limit(safeSize, offset: start);
    final rows = await select.get();
    return TransactionPagedResult(
      items: rows.map(_mapListItem).toList(growable: false),
      totalCount: totalCount,
      page: safePage,
      pageSize: safeSize,
    );
  }

  @override
  Future<TransactionDashboardSummary> dashboardSummary({
    required DateTime periodFrom,
    required DateTime periodTo,
    required DateTime todayStart,
    required DateTime todayEnd,
  }) async {
    final periodStartMs = BusinessDate.utcDayMs(periodFrom);
    final periodEndMs = BusinessDate.utcDayMs(periodTo);
    final todayStartMs = BusinessDate.utcDayMs(todayStart);
    final todayEndMs = BusinessDate.utcDayMs(todayEnd);

    // One round-trip via custom SQL aggregates.
    final rows = await _db.customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN transaction_type = 'receipt'
          AND transaction_date >= ? AND transaction_date <= ?
          THEN amount ELSE 0 END), 0) AS today_receipts_total,
        COALESCE(SUM(CASE WHEN transaction_type = 'receipt'
          AND transaction_date >= ? AND transaction_date <= ?
          THEN 1 ELSE 0 END), 0) AS today_receipts_count,
        COALESCE(SUM(CASE WHEN transaction_type = 'payment'
          AND transaction_date >= ? AND transaction_date <= ?
          THEN amount ELSE 0 END), 0) AS today_payments_total,
        COALESCE(SUM(CASE WHEN transaction_type = 'payment'
          AND transaction_date >= ? AND transaction_date <= ?
          THEN 1 ELSE 0 END), 0) AS today_payments_count,
        COALESCE(SUM(CASE WHEN transaction_type = 'receipt'
          AND transaction_date >= ? AND transaction_date <= ?
          THEN amount ELSE 0 END), 0) AS period_receipts_total,
        COALESCE(SUM(CASE WHEN transaction_type = 'receipt'
          AND transaction_date >= ? AND transaction_date <= ?
          THEN 1 ELSE 0 END), 0) AS period_receipts_count,
        COALESCE(SUM(CASE WHEN transaction_type = 'payment'
          AND transaction_date >= ? AND transaction_date <= ?
          THEN amount ELSE 0 END), 0) AS period_payments_total,
        COALESCE(SUM(CASE WHEN transaction_type = 'payment'
          AND transaction_date >= ? AND transaction_date <= ?
          THEN 1 ELSE 0 END), 0) AS period_payments_count,
        COALESCE(SUM(CASE WHEN LOWER(IFNULL(cash_account_code, '')) LIKE '1211%'
          AND transaction_date >= ? AND transaction_date <= ?
          THEN CASE WHEN transaction_type = 'receipt' THEN amount ELSE -amount END
          ELSE 0 END), 0) AS cash_movement_net,
        COALESCE(SUM(CASE WHEN LOWER(IFNULL(cash_account_code, '')) LIKE '1212%'
          AND transaction_date >= ? AND transaction_date <= ?
          THEN CASE WHEN transaction_type = 'receipt' THEN amount ELSE -amount END
          ELSE 0 END), 0) AS bank_movement_net,
        COALESCE(SUM(CASE WHEN sync_status IN ('pending', 'failed')
          THEN 1 ELSE 0 END), 0) AS pending_sync_count,
        COALESCE(SUM(CASE WHEN sync_status = 'failed'
          THEN 1 ELSE 0 END), 0) AS failed_sync_count
      FROM financial_transactions
      WHERE deleted_at IS NULL AND cancelled_at IS NULL
      ''',
      variables: [
        Variable.withInt(todayStartMs),
        Variable.withInt(todayEndMs),
        Variable.withInt(todayStartMs),
        Variable.withInt(todayEndMs),
        Variable.withInt(todayStartMs),
        Variable.withInt(todayEndMs),
        Variable.withInt(todayStartMs),
        Variable.withInt(todayEndMs),
        Variable.withInt(periodStartMs),
        Variable.withInt(periodEndMs),
        Variable.withInt(periodStartMs),
        Variable.withInt(periodEndMs),
        Variable.withInt(periodStartMs),
        Variable.withInt(periodEndMs),
        Variable.withInt(periodStartMs),
        Variable.withInt(periodEndMs),
        Variable.withInt(periodStartMs),
        Variable.withInt(periodEndMs),
        Variable.withInt(periodStartMs),
        Variable.withInt(periodEndMs),
      ],
      readsFrom: {_db.financialTransactions},
    ).get();

    final row = rows.first;
    return TransactionDashboardSummary(
      todayReceiptsTotal: (row.read<double>('today_receipts_total')),
      todayReceiptsCount: row.read<int>('today_receipts_count'),
      todayPaymentsTotal: row.read<double>('today_payments_total'),
      todayPaymentsCount: row.read<int>('today_payments_count'),
      periodReceiptsTotal: row.read<double>('period_receipts_total'),
      periodReceiptsCount: row.read<int>('period_receipts_count'),
      periodPaymentsTotal: row.read<double>('period_payments_total'),
      periodPaymentsCount: row.read<int>('period_payments_count'),
      cashMovementNet: row.read<double>('cash_movement_net'),
      bankMovementNet: row.read<double>('bank_movement_net'),
      pendingSyncCount: row.read<int>('pending_sync_count'),
      failedSyncCount: row.read<int>('failed_sync_count'),
    );
  }

  @override
  Future<List<TransactionListItem>> listForReport({
    required TransactionListFilter filter,
    int limit = 5000,
  }) async {
    final safeLimit = limit <= 0 ? 5000 : limit;
    final select = _db.select(_db.financialTransactions)
      ..where((t) => _matchesFilter(t, filter))
      ..orderBy([
        (t) => OrderingTerm.asc(t.transactionDate),
        (t) => OrderingTerm.asc(t.id),
      ])
      ..limit(safeLimit);
    final rows = await select.get();
    return rows.map(_mapListItem).toList(growable: false);
  }

  @override
  Future<({double total, int count})> aggregateTotals(
    TransactionListFilter filter,
  ) async {
    final query = _db.selectOnly(_db.financialTransactions)
      ..addColumns([
        _db.financialTransactions.id.count(),
        _db.financialTransactions.amount.sum(),
      ])
      ..where(_matchesFilter(_db.financialTransactions, filter));
    final row = await query.getSingle();
    return (
      total: row.read(_db.financialTransactions.amount.sum()) ?? 0.0,
      count: row.read(_db.financialTransactions.id.count()) ?? 0,
    );
  }

  @override
  Stream<void> watchListChanges() {
    return (_db.select(_db.financialTransactions)..where(_scoped))
        .watch()
        .map((_) {});
  }

  Future<void> markSynced({
    required String uuid,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {
    final at = syncedAt ?? DateTime.now().toUtc();
    await (_db.update(_db.financialTransactions)
          ..where((t) => t.uuid.equals(uuid) & _tenantScoped(t)))
        .write(
      FinancialTransactionsCompanion(
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(at.millisecondsSinceEpoch),
        version: Value(remoteVersion),
      ),
    );
  }

  Future<void> markConflict(String uuid) async {
    await (_db.update(_db.financialTransactions)
          ..where((t) => t.uuid.equals(uuid) & _tenantScoped(t)))
        .write(
      const FinancialTransactionsCompanion(syncStatus: Value('conflict')),
    );
  }

  Future<void> applyRemotePayload(Map<String, dynamic> payload) async {
    final uuid = (payload['uuid'] as String?)?.trim();
    if (uuid == null || uuid.isEmpty) return;
    final existing = await (_db.select(_db.financialTransactions)
          ..where((t) => t.uuid.equals(uuid)))
        .getSingleOrNull();
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final remoteVersion = (payload['version'] as int?) ?? 1;

    // Dirty local: pending/conflict/syncing → mark conflict if remote is newer.
    final localStatus = SyncStatusX.fromStorage(existing?.syncStatus ?? 'synced');
    if (existing != null &&
        (localStatus.needsUpload ||
            localStatus == SyncStatus.conflict ||
            localStatus == SyncStatus.syncing)) {
      if (remoteVersion > existing.version) {
        await (_db.update(_db.financialTransactions)
              ..where((t) => t.uuid.equals(uuid)))
            .write(const FinancialTransactionsCompanion(
                syncStatus: Value('conflict')));
      }
      return;
    }

    // Stale remote: incoming version <= local → skip (idempotent pull).
    if (existing != null && remoteVersion <= existing.version) {
      return;
    }
    final companion = FinancialTransactionsCompanion(
      uuid: Value(uuid),
      transactionNumber: Value(
        (payload['transactionNumber'] as String?)?.trim() ?? uuid,
      ),
      transactionType: Value(
        (payload['transactionType'] as String?) ?? 'receipt',
      ),
      source: Value((payload['source'] as String?) ?? 'manualReceipt'),
      transactionDate: Value(
        (payload['transactionDate'] as int?) ?? now,
      ),
      amount: Value((payload['amount'] as num?)?.toDouble() ?? 0),
      currencyCode: Value((payload['currencyCode'] as String?) ?? 'SAR'),
      baseCurrencyCode: Value((payload['baseCurrencyCode'] as String?) ?? 'SAR'),
      exchangeRate: Value((payload['exchangeRate'] as num?)?.toDouble() ?? 1),
      counterAmount: Value(
        (payload['counterAmount'] as num?)?.toDouble() ??
            (payload['amount'] as num?)?.toDouble() ??
            0,
      ),
      counterCurrencyCode: Value(
        (payload['counterCurrencyCode'] as String?) ??
            (payload['currencyCode'] as String?) ??
            'SAR',
      ),
      counterExchangeRate: Value(
        (payload['counterExchangeRate'] as num?)?.toDouble() ??
            (payload['exchangeRate'] as num?)?.toDouble() ??
            1,
      ),
      voucherBookId: Value(payload['voucherBookId'] as String?),
      cashAccountId: Value((payload['cashAccountId'] as String?) ?? ''),
      cashAccountCode: Value(payload['cashAccountCode'] as String?),
      cashAccountName: Value(payload['cashAccountName'] as String?),
      counterAccountId: Value((payload['counterAccountId'] as String?) ?? ''),
      counterAccountCode: Value(payload['counterAccountCode'] as String?),
      counterAccountName: Value(payload['counterAccountName'] as String?),
      customerId: Value(payload['customerId'] as String?),
      customerCode: Value(payload['customerCode'] as String?),
      customerName: Value(payload['customerName'] as String?),
      partyName: Value(payload['partyName'] as String?),
      reference: Value(payload['reference'] as String?),
      description: Value(payload['description'] as String?),
      paymentMethod: Value((payload['paymentMethod'] as String?) ?? 'cash'),
      documentStatus: Value((payload['documentStatus'] as String?) ?? 'unposted'),
      relatedDocumentId: Value(payload['relatedDocumentId'] as String?),
      relatedDocumentType: Value(payload['relatedDocumentType'] as String?),
      cancelledAt: Value(payload['cancelledAt'] as int?),
      externalId: Value(payload['externalId'] as String?),
      syncStatus: const Value('synced'),
      lastSyncedAt: Value(now),
      version: Value((payload['version'] as int?) ?? 1),
      deletedAt: Value(payload['deletedAt'] as int?),
      updatedAt: Value((payload['updatedAt'] as int?) ?? now),
      createdAt: existing == null
          ? Value(now)
          : const Value.absent(),
      linesJson: Value(
        FinancialTransactionLinesCodec.encode(_linesFromPayload(payload)),
      ),
      companyId: Value(payload['companyId']?.toString() ?? _currentCompanyId),
    );
    if (existing == null) {
      await _db.into(_db.financialTransactions).insert(companion);
    } else {
      await (_db.update(_db.financialTransactions)
            ..where((t) => t.uuid.equals(uuid) & _scoped(t)))
          .write(companion);
    }
  }
}

extension on FinancialTransaction {
  FinancialTransaction copyWithDeleted(DateTime deletedAt) {
    return FinancialTransaction(
      id: id,
      uuid: uuid,
      transactionNumber: transactionNumber,
      transactionType: transactionType,
      source: source,
      transactionDate: transactionDate,
      amount: amount,
      currencyCode: currencyCode,
      baseCurrencyCode: baseCurrencyCode,
      exchangeRate: exchangeRate,
      counterAmount: counterAmount,
      counterCurrencyCode: counterCurrencyCode,
      counterExchangeRate: counterExchangeRate,
      voucherBookId: voucherBookId,
      cashAccountId: cashAccountId,
      cashAccountCode: cashAccountCode,
      cashAccountName: cashAccountName,
      counterAccountId: counterAccountId,
      counterAccountCode: counterAccountCode,
      counterAccountName: counterAccountName,
      customerId: customerId,
      customerCode: customerCode,
      customerName: customerName,
      partyName: partyName,
      reference: reference,
      description: description,
      paymentMethod: paymentMethod,
      documentStatus: documentStatus,
      relatedDocumentId: relatedDocumentId,
      relatedDocumentType: relatedDocumentType,
      createdAt: createdAt,
      updatedAt: updatedAt,
      cancelledAt: cancelledAt,
      externalId: externalId,
      syncStatus: syncStatus,
      lastSyncedAt: lastSyncedAt,
      version: version,
      deletedAt: deletedAt,
      lines: lines,
    );
  }
}

List<FinancialTransactionLine> _linesFromPayload(Map<String, dynamic> payload) {
  final raw = payload['lines'];
  if (raw is List) {
    final lines = <FinancialTransactionLine>[];
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is! Map) continue;
      final line = FinancialTransactionLine.fromJson(
        Map<String, dynamic>.from(item),
      );
      if (line.accountId.trim().isEmpty) continue;
      lines.add(
        FinancialTransactionLine(
          accountId: line.accountId,
          accountCode: line.accountCode,
          accountName: line.accountName,
          amount: line.amount,
          currencyCode: line.currencyCode,
          exchangeRate: line.exchangeRate,
          description: line.description,
          lineOrder: line.lineOrder > 0 ? line.lineOrder : i,
        ),
      );
    }
    if (lines.isNotEmpty) return lines;
  }
  return FinancialTransactionLinesCodec.fromHeader(
    accountId: (payload['counterAccountId'] as String?) ?? '',
    accountCode: payload['counterAccountCode'] as String?,
    accountName: payload['counterAccountName'] as String?,
    amount: (payload['counterAmount'] as num?)?.toDouble() ??
        (payload['amount'] as num?)?.toDouble() ??
        0,
    currencyCode: (payload['counterCurrencyCode'] as String?) ??
        (payload['currencyCode'] as String?) ??
        'SAR',
    exchangeRate: (payload['counterExchangeRate'] as num?)?.toDouble() ??
        (payload['exchangeRate'] as num?)?.toDouble() ??
        1,
    description: payload['description'] as String?,
  );
}
