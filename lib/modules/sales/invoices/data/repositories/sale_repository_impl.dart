import 'package:drift/drift.dart';
import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';

import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/core/utils/business_date.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import '../../domain/entities/discount_type.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/payment_status.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_data_source.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/entities/sale_list_item.dart';
import '../../domain/entities/sale_payment.dart';
import '../../domain/entities/sale_settlement_type.dart';
import '../../domain/entities/sale_status.dart';
import '../../domain/models/sale_exception.dart';
import '../../domain/models/sale_list_filter.dart';
import '../../domain/models/sale_paged_result.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../domain/services/sale_calculation_service.dart';
import '../../domain/services/sale_quantity_math.dart';
import '../../domain/services/device_sale_number.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import '../../domain/services/sale_validator.dart';
import 'package:stock_count/modules/sales/shared/data/database/sales_database.dart';

import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/sales/permissions/sales_permission_package.dart';

class SaleRepositoryImpl implements SaleRepository {
  SaleRepositoryImpl(
    this._db, {
    SyncQueue? syncQueue,
    SaleValidator validator = const SaleValidator(),
    SaleCalculationService calculator = const SaleCalculationService(),
    PermissionGuard permissionGuard = const AllowAllPermissionGuard(),
    String Function()? readCompanyId,
  }) : _syncQueue = syncQueue,
       _validator = validator,
       _calculator = calculator,
       _permissionGuard = permissionGuard,
       _readCompanyId = readCompanyId;

  final SalesDatabase _db;
  final SyncQueue? _syncQueue;
  final SaleValidator _validator;
  final SaleCalculationService _calculator;
  final PermissionGuard _permissionGuard;
  final String Function()? _readCompanyId;


  static const entityType = 'sale';

  String get _currentCompanyId =>
      _readCompanyId?.call() ?? LocalAuthDefaults.companyId;

  Expression<bool> _tenantScoped($SalesTable t) =>
      t.companyId.equals(_currentCompanyId);

  Expression<bool> _scoped($SalesTable t) =>
      t.deletedAt.isNull() & _tenantScoped(t);

  DateTime _fromEpoch(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

  int? _toEpoch(DateTime? value) => value?.toUtc().millisecondsSinceEpoch;

  Future<List<SaleItem>> _loadItems(String saleUuid) async {
    final rows =
        await (_db.select(_db.saleItems)
              ..where((t) => t.saleUuid.equals(saleUuid))
              ..orderBy([(t) => OrderingTerm.asc(t.lineOrder)]))
            .get();
    return rows.map(_mapItem).toList(growable: false);
  }

  Future<List<SalePayment>> _loadPayments(String saleUuid) async {
    final rows =
        await (_db.select(_db.salePayments)
              ..where((t) => t.saleUuid.equals(saleUuid))
              ..orderBy([(t) => OrderingTerm.asc(t.paidAt)]))
            .get();
    return rows.map(_mapPayment).toList(growable: false);
  }

  SaleItem _mapItem(SaleItemRow row) {
    final resolved = SaleQuantityMath.resolveStored(
      quantity: row.quantity,
      mainQuantity: row.mainQuantity,
      subQuantity: row.subQuantity,
    );
    final packSize = row.packSize <= 0 ? 1 : row.packSize;
    return SaleItem(
      id: row.id,
      uuid: row.uuid,
      saleUuid: row.saleUuid,
      productId: row.productId,
      productName: row.productName,
      productCode: row.productCode,
      barcode: row.barcode,
      quantity: row.quantity,
      mainQuantity: resolved.mainQuantity,
      subQuantity: resolved.subQuantity,
      packSize: packSize,
      unitPrice: row.unitPrice,
      baseUnitPrice: row.baseUnitPrice,
      discountType: DiscountTypeX.fromStorage(row.discountType),
      discountValue: row.discountValue,
      discountAmount: row.discountAmount,
      taxAmount: row.taxAmount,
      subtotal: row.subtotal,
      total: row.total,
      lineOrder: row.lineOrder,
    );
  }

  SalePayment _mapPayment(SalePaymentRow row) {
    return SalePayment(
      id: row.id,
      uuid: row.uuid,
      saleUuid: row.saleUuid,
      amount: row.amount,
      method: PaymentMethodX.fromStorage(row.method),
      paidAt: _fromEpoch(row.paidAt),
      createdAt: _fromEpoch(row.createdAt),
      notes: row.notes,
      externalId: row.externalId,
    );
  }

  Future<Sale> _mapSale(SaleRow row) async {
    final items = await _loadItems(row.uuid);
    final payments = await _loadPayments(row.uuid);
    final createdAt = _fromEpoch(row.createdAt);
    final saleDateMs = row.saleDate;
    final saleDate = saleDateMs <= 0 ? createdAt : _fromEpoch(saleDateMs);
    return Sale(
      id: row.id,
      uuid: row.uuid,
      saleNumber: row.saleNumber,
      saleDate: saleDate,
      settlementType: SaleSettlementTypeX.fromStorage(row.settlementType),
      voucherBookId: row.voucherBookId,
      customerId: row.customerId,
      customerCode: row.customerCode,
      customerName: row.customerName,
      customerAccountId: row.customerAccountId,
      cashAccountId: row.cashAccountId,
      currencyCode: row.currencyCode,
      baseCurrencyCode: row.baseCurrencyCode,
      exchangeRate: row.exchangeRate,
      items: items,
      payments: payments,
      subtotal: row.subtotal,
      itemDiscountTotal: row.itemDiscountTotal,
      discountType: DiscountTypeX.fromStorage(row.discountType),
      discountValue: row.discountValue,
      discountAmount: row.discountAmount,
      taxRate: row.taxRate,
      taxAmount: row.taxAmount,
      total: row.total,
      paidAmount: row.paidAmount,
      remainingAmount: row.remainingAmount,
      paymentStatus: PaymentStatusX.fromStorage(row.paymentStatus),
      paymentMethod: PaymentMethodX.fromStorage(row.paymentMethod),
      saleStatus: SaleStatusX.fromStorage(row.saleStatus),
      notes: row.notes,
      createdAt: createdAt,
      updatedAt: _fromEpoch(row.updatedAt),
      submittedAt: row.submittedAt == null
          ? null
          : _fromEpoch(row.submittedAt!),
      confirmedAt: row.confirmedAt == null
          ? null
          : _fromEpoch(row.confirmedAt!),
      completedAt: row.completedAt == null
          ? null
          : _fromEpoch(row.completedAt!),
      cancelledAt: row.cancelledAt == null
          ? null
          : _fromEpoch(row.cancelledAt!),
      externalId: row.externalId,
      externalDocumentNumber: row.externalDocumentNumber,
      externalStatus: row.externalStatus,
      dataSource: SaleDataSourceX.fromStorage(row.dataSource),
      syncStatus: SyncStatusX.fromStorage(row.syncStatus),
      lastSyncedAt: row.lastSyncedAt == null
          ? null
          : _fromEpoch(row.lastSyncedAt!),
      version: row.version,
      deletedAt: row.deletedAt == null ? null : _fromEpoch(row.deletedAt!),
    );
  }

  Future<List<Sale>> _mapSales(List<SaleRow> rows) async {
    final out = <Sale>[];
    for (final row in rows) {
      out.add(await _mapSale(row));
    }
    return out;
  }

  Expression<bool> _matchesFilter($SalesTable t, SaleListFilter filter) {
    var expr = _scoped(t);
    if (filter.saleStatus != null) {
      final status = filter.saleStatus!;
      if (status == SaleStatus.unposted) {
        expr = expr &
            t.saleStatus.isIn(const [
              'unposted',
              'draft',
              'pending',
              'cancelled',
              'rejected',
            ]);
      } else {
        expr = expr &
            t.saleStatus.isIn(const ['posted', 'confirmed', 'completed']);
      }
    }
    if (filter.paymentStatus != null) {
      expr = expr & t.paymentStatus.equals(filter.paymentStatus!.storageValue);
    }
    if (filter.paymentMethod != null) {
      expr = expr & t.paymentMethod.equals(filter.paymentMethod!.storageValue);
    }
    if (filter.dataSource != null) {
      expr = expr & t.dataSource.equals(filter.dataSource!.storageValue);
    }
    if (filter.syncStatus != null) {
      expr = expr & t.syncStatus.equals(filter.syncStatus!.storageValue);
    }
    if (filter.customerId != null && filter.customerId!.isNotEmpty) {
      expr = expr & t.customerId.equals(filter.customerId!);
    }
    if (filter.fromDate != null) {
      expr =
          expr &
          t.saleDate.isBiggerOrEqualValue(
            filter.fromDate!.toUtc().millisecondsSinceEpoch,
          );
    }
    if (filter.toDate != null) {
      final end = DateTime.utc(
        filter.toDate!.year,
        filter.toDate!.month,
        filter.toDate!.day,
        23,
        59,
        59,
        999,
      );
      expr =
          expr & t.saleDate.isSmallerOrEqualValue(end.millisecondsSinceEpoch);
    }
    final q = filter.query.trim().toLowerCase();
    if (q.isNotEmpty) {
      expr = expr & _matchesTextQuery(t, q);
    }
    return expr;
  }

  /// SQL text match on header + line snapshots (no Dart hydrate).
  Expression<bool> _matchesTextQuery($SalesTable t, String normalized) {
    final contains = '%$normalized%';
    var header =
        t.saleNumber.collate(Collate.noCase).like(contains) |
        t.customerName.collate(Collate.noCase).like(contains) |
        t.customerCode.collate(Collate.noCase).like(contains);
    // Short digit query (e.g. "42") also matches multi-device absolute
    // numbers whose local sequence ends with that value (…000042).
    if (RegExp(r'^\d{1,6}$').hasMatch(normalized)) {
      final padded = normalized.padLeft(6, '0');
      header =
          header |
          t.saleNumber.collate(Collate.noCase).like('%$padded') |
          t.saleNumber.equals(normalized);
    }
    final itemMatch = existsQuery(
      _db.select(_db.saleItems)
        ..where(
          (i) =>
              i.saleUuid.equalsExp(t.uuid) &
              (i.productName.collate(Collate.noCase).like(contains) |
                  i.productCode.collate(Collate.noCase).like(contains) |
                  i.barcode.collate(Collate.noCase).like(contains)),
        ),
    );
    return header | itemMatch;
  }

  SaleListItem _mapListItem(SaleRow row) {
    final createdAt = _fromEpoch(row.createdAt);
    final saleDateMs = row.saleDate;
    final saleDate = saleDateMs <= 0 ? createdAt : _fromEpoch(saleDateMs);
    return SaleListItem(
      id: row.id,
      uuid: row.uuid,
      saleNumber: row.saleNumber,
      saleDate: saleDate,
      settlementType: SaleSettlementTypeX.fromStorage(row.settlementType),
      customerName: row.customerName,
      currencyCode: row.currencyCode,
      total: row.total,
      saleStatus: SaleStatusX.fromStorage(row.saleStatus),
      paymentStatus: PaymentStatusX.fromStorage(row.paymentStatus),
    );
  }

  Future<void> _enqueue(Sale sale, SyncOperationType type) async {
    final queue = _syncQueue;
    if (queue == null) {
      return;
    }
    await queue.enqueue(
      SyncOperation.create(
        entityType: entityType,
        entityId: sale.uuid,
        type: type,
        baseVersion: sale.version,
        payload: _salePayload(sale),
      ),
    );
  }

  Map<String, dynamic> _salePayload(Sale sale) {
    return {
      'uuid': sale.uuid,
      'saleNumber': sale.saleNumber,
      'saleDate': sale.saleDate.toUtc().millisecondsSinceEpoch,
      'settlementType': sale.settlementType.storageValue,
      'voucherBookId': sale.voucherBookId,
      'customerId': sale.customerId,
      'customerCode': sale.customerCode,
      'customerName': sale.customerName,
      'customerAccountId': sale.customerAccountId,
      'cashAccountId': sale.cashAccountId,
      'currencyCode': sale.currencyCode,
      'baseCurrencyCode': sale.baseCurrencyCode,
      'exchangeRate': sale.exchangeRate,
      'subtotal': sale.subtotal,
      'itemDiscountTotal': sale.itemDiscountTotal,
      'discountType': sale.discountType.storageValue,
      'discountValue': sale.discountValue,
      'discountAmount': sale.discountAmount,
      'taxRate': sale.taxRate,
      'taxAmount': sale.taxAmount,
      'total': sale.total,
      'paidAmount': sale.paidAmount,
      'remainingAmount': sale.remainingAmount,
      'paymentStatus': sale.paymentStatus.storageValue,
      'paymentMethod': sale.paymentMethod.storageValue,
      'saleStatus': sale.saleStatus.storageValue,
      'notes': sale.notes,
      'createdAt': sale.createdAt.toUtc().millisecondsSinceEpoch,
      'updatedAt': sale.updatedAt.toUtc().millisecondsSinceEpoch,
      'submittedAt': sale.submittedAt?.toUtc().millisecondsSinceEpoch,
      'confirmedAt': sale.confirmedAt?.toUtc().millisecondsSinceEpoch,
      'completedAt': sale.completedAt?.toUtc().millisecondsSinceEpoch,
      'cancelledAt': sale.cancelledAt?.toUtc().millisecondsSinceEpoch,
      'externalId': sale.externalId,
      'externalDocumentNumber': sale.externalDocumentNumber,
      'externalStatus': sale.externalStatus,
      'dataSource': sale.dataSource.storageValue,
      'version': sale.version,
      'deletedAt': sale.deletedAt?.toUtc().millisecondsSinceEpoch,
      'items': [
        for (final item in sale.items)
          {
            'uuid': item.uuid,
            'productId': item.productId,
            'productName': item.productName,
            'productCode': item.productCode,
            'barcode': item.barcode,
            'quantity': item.quantity,
            'mainQuantity': item.mainQuantity,
            'subQuantity': item.subQuantity,
            'packSize': item.packSize,
            'unitPrice': item.unitPrice,
            'baseUnitPrice': item.baseUnitPrice,
            'discountType': item.discountType.storageValue,
            'discountValue': item.discountValue,
            'discountAmount': item.discountAmount,
            'taxAmount': item.taxAmount,
            'subtotal': item.subtotal,
            'total': item.total,
            'lineOrder': item.lineOrder,
          },
      ],
      'payments': [
        for (final payment in sale.payments)
          {
            'uuid': payment.uuid,
            'amount': payment.amount,
            'method': payment.method.storageValue,
            'paidAt': payment.paidAt.toUtc().millisecondsSinceEpoch,
            'createdAt': payment.createdAt.toUtc().millisecondsSinceEpoch,
            'notes': payment.notes,
            'externalId': payment.externalId,
          },
      ],
    };
  }

  Future<void> _replaceChildren({
    required String saleUuid,
    required List<SaleItemDraft> items,
    required List<SalePaymentDraft> payments,
    required double taxRate,
    required double taxAmount,
    required double paidAmount,
    required PaymentMethod paymentMethod,
  }) async {
    await (_db.delete(
      _db.saleItems,
    )..where((t) => t.saleUuid.equals(saleUuid))).go();
    await (_db.delete(
      _db.salePayments,
    )..where((t) => t.saleUuid.equals(saleUuid))).go();

    final lines = _calculator.calculateLines(items);
    final lineNetTotal = lines.fold<double>(0, (s, l) => s + l.total);
    var order = 0;
    for (final line in lines) {
      final share = lineNetTotal <= 0 ? 0.0 : line.total / lineNetTotal;
      final lineTax = taxAmount * share;
      await _db
          .into(_db.saleItems)
          .insert(
            SaleItemsCompanion.insert(
              uuid: line.lineUuid ?? generateUuidV4(),
              saleUuid: saleUuid,
              productId: line.productId,
              productName: line.productName,
              productCode: line.productCode,
              barcode: Value(line.barcode),
              quantity: line.quantity,
              mainQuantity: Value(line.mainQuantity),
              subQuantity: Value(line.subQuantity),
              packSize: Value(line.packSize),
              unitPrice: line.unitPrice,
              baseUnitPrice: Value(line.baseUnitPrice),
              discountType: Value(line.discountType.storageValue),
              discountValue: Value(line.discountValue),
              discountAmount: Value(line.discountAmount),
              taxAmount: Value(lineTax),
              subtotal: line.subtotal,
              total: line.total,
              lineOrder: Value(order++),
            ),
          );
    }

    final now = DateTime.now().toUtc();
    if (payments.isNotEmpty) {
      for (final payment in payments) {
        await _db
            .into(_db.salePayments)
            .insert(
              SalePaymentsCompanion.insert(
                uuid: generateUuidV4(),
                saleUuid: saleUuid,
                amount: payment.amount,
                method: Value(payment.method.storageValue),
                paidAt: (payment.paidAt ?? now).toUtc().millisecondsSinceEpoch,
                createdAt: now.millisecondsSinceEpoch,
                notes: Value(payment.notes),
                externalId: Value(payment.externalId),
              ),
            );
      }
    } else if (paidAmount > 0) {
      await _db
          .into(_db.salePayments)
          .insert(
            SalePaymentsCompanion.insert(
              uuid: generateUuidV4(),
              saleUuid: saleUuid,
              amount: paidAmount,
              method: Value(paymentMethod.storageValue),
              paidAt: now.millisecondsSinceEpoch,
              createdAt: now.millisecondsSinceEpoch,
            ),
          );
    }
  }

  @override
  Future<List<Sale>> getAll() async {
    final rows =
        await (_db.select(_db.sales)
              ..where(_scoped)
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();
    return _mapSales(rows);
  }

  @override
  Stream<List<Sale>> watchAll() async* {
    final query = _db.select(_db.sales)
      ..where(_scoped)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    await for (final rows in query.watch()) {
      yield await _mapSales(rows);
    }
  }

  @override
  Future<Sale?> getById(int id) async {
    final row = await (_db.select(
      _db.sales,
    )..where((t) => t.id.equals(id) & _scoped(t))).getSingleOrNull();
    return row == null ? null : _mapSale(row);
  }

  @override
  Future<Sale?> getByUuid(String uuid) async {
    final row = await (_db.select(
      _db.sales,
    )..where((t) => t.uuid.equals(uuid) & _scoped(t))).getSingleOrNull();
    return row == null ? null : _mapSale(row);
  }

  @override
  Future<Sale?> getBySaleNumber(String saleNumber) async {
    final code = saleNumber.trim().toUpperCase();
    if (code.isEmpty) {
      return null;
    }
    final row =
        await (_db.select(_db.sales)
              ..where((t) => t.saleNumber.equals(code) & _scoped(t)))
            .getSingleOrNull();
    return row == null ? null : _mapSale(row);
  }

  @override
  Future<List<Sale>> search(SaleListFilter filter) async {
    final query = _db.select(_db.sales)
      ..where((t) => _matchesFilter(t, filter))
      ..orderBy([(t) => OrderingTerm.desc(t.saleDate)]);
    final rows = await query.get();
    return _mapSales(rows);
  }

  @override
  Stream<List<Sale>> watchFiltered(SaleListFilter filter) async* {
    final query = _db.select(_db.sales)
      ..where((t) => _matchesFilter(t, filter))
      ..orderBy([(t) => OrderingTerm.desc(t.saleDate)]);
    await for (final rows in query.watch()) {
      yield await _mapSales(rows);
    }
  }

  @override
  Future<SalePagedResult<SaleListItem>> searchListPaged(
    SaleListFilter filter, {
    int page = 0,
    int pageSize = 30,
  }) async {
    final safePage = page < 0 ? 0 : page;
    final safeSize = pageSize <= 0 ? 30 : pageSize;

    final countQuery = _db.selectOnly(_db.sales)
      ..addColumns([_db.sales.id.count()])
      ..where(_matchesFilter(_db.sales, filter));
    final countRow = await countQuery.getSingle();
    final totalCount = countRow.read(_db.sales.id.count()) ?? 0;

    final start = safePage * safeSize;
    if (totalCount == 0 || start >= totalCount) {
      return SalePagedResult<SaleListItem>(
        items: const [],
        totalCount: totalCount,
        page: safePage,
        pageSize: safeSize,
      );
    }

    final select = _db.select(_db.sales)
      ..where((t) => _matchesFilter(t, filter))
      ..orderBy([(t) => OrderingTerm.desc(t.saleDate)])
      ..limit(safeSize, offset: start);
    final rows = await select.get();
    return SalePagedResult<SaleListItem>(
      items: rows.map(_mapListItem).toList(growable: false),
      totalCount: totalCount,
      page: safePage,
      pageSize: safeSize,
    );
  }

  @override
  Future<List<SaleListItem>> listRecent({int limit = 8}) async {
    final safeLimit = limit <= 0 ? 8 : limit;
    final rows =
        await (_db.select(_db.sales)
              ..where(_scoped)
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
              ..limit(safeLimit))
            .get();
    return rows.map(_mapListItem).toList(growable: false);
  }

  @override
  Stream<void> watchListChanges() {
    return (_db.select(_db.sales)..where(_scoped)).watch().map((_) {});
  }

  @override
  Future<int> nextLocalSequence({int? minExclusive}) async {
    final rows = await (_db.selectOnly(_db.sales)
          ..addColumns([_db.sales.saleNumber])
          ..where(_scoped(_db.sales)))
        .get();
    var maxSeq = minExclusive ?? 0;
    for (final row in rows) {
      final raw = (row.read(_db.sales.saleNumber) ?? '').trim();
      final n = parseSaleNumberSequence(raw);
      if (n != null && n > maxSeq) {
        maxSeq = n;
      }
    }
    return maxSeq + 1;
  }

  @override
  Future<Sale> insert(SaleDraft draft, {required String saleNumber}) async {
    if (draft.saleStatus == SaleStatus.posted) {
      _permissionGuard.requireAny(SalesPermissions.post);
    } else {
      _permissionGuard.requireAny(SalesPermissions.create);
    }
    _validator.validate(draft);

    final summary = _calculator.calculate(
      items: draft.items,
      saleDiscountType: draft.discountType,
      saleDiscountValue: draft.discountValue,
      taxRatePercent: draft.taxRate,
      paidAmount: draft.paidAmount,
    );
    _validator.assertPaidNotOverTotal(
      total: summary.total,
      paidAmount: draft.paidAmount,
    );

    final now = DateTime.now().toUtc();
    final uuid = generateUuidV4();
    final normalizedNumber = saleNumber.trim().toUpperCase();

    final existing = await getBySaleNumber(normalizedNumber);
    if (existing != null) {
      throw const SaleException(SaleException.duplicateSaleNumber);
    }

    await _db.transaction(() async {
      await _db
          .into(_db.sales)
          .insert(
            SalesCompanion.insert(
              uuid: uuid,
              saleNumber: normalizedNumber,
              saleDate: Value(BusinessDate.utcDayMs(draft.saleDate)),
              settlementType: Value(draft.settlementType.storageValue),
              voucherBookId: Value(draft.voucherBookId),
              customerId: Value(draft.customerId),
              customerCode: Value(draft.customerCode),
              customerName: Value(draft.customerName),
              customerAccountId: Value(draft.customerAccountId),
              cashAccountId: Value(draft.cashAccountId),
              currencyCode: Value(draft.currencyCode),
              baseCurrencyCode: Value(draft.baseCurrencyCode),
              exchangeRate: Value(draft.exchangeRate),
              subtotal: summary.subtotal,
              itemDiscountTotal: summary.itemDiscountTotal,
              discountType: Value(draft.discountType.storageValue),
              discountValue: Value(draft.discountValue),
              discountAmount: Value(summary.saleDiscount),
              taxRate: Value(draft.taxRate),
              taxAmount: Value(summary.tax),
              total: summary.total,
              paidAmount: Value(summary.paidAmount),
              remainingAmount: Value(summary.remainingAmount),
              paymentStatus: Value(summary.paymentStatus.storageValue),
              paymentMethod: Value(draft.paymentMethod.storageValue),
              saleStatus: Value(draft.saleStatus.storageValue),
              notes: Value(draft.notes),
              createdAt: now.millisecondsSinceEpoch,
              updatedAt: now.millisecondsSinceEpoch,
              externalId: Value(draft.externalId),
              externalDocumentNumber: Value(draft.externalDocumentNumber),
              externalStatus: Value(draft.externalStatus),
              dataSource: Value(draft.dataSource.storageValue),
              syncStatus: const Value('pending'),
              companyId: Value(_currentCompanyId),
            ),
          );
      await _replaceChildren(
        saleUuid: uuid,
        items: draft.items,
        payments: draft.payments,
        taxRate: draft.taxRate,
        taxAmount: summary.tax,
        paidAmount: summary.paidAmount,
        paymentMethod: draft.paymentMethod,
      );
    });

    final sale = await getByUuid(uuid);
    if (sale == null) {
      throw const SaleException(SaleException.notFound);
    }
    await _enqueue(sale, SyncOperationType.create);
    return sale;
  }

  @override
  Future<Sale> update(int id, SaleDraft draft) async {
    final existing = await getById(id);
    if (existing == null) {
      throw const SaleException(SaleException.notFound);
    }
    if (existing.saleStatus == SaleStatus.posted) {
      throw const JournalException(JournalException.postedImmutable);
    }
    _validator.validate(draft);
    final summary = _calculator.calculate(
      items: draft.items,
      saleDiscountType: draft.discountType,
      saleDiscountValue: draft.discountValue,
      taxRatePercent: draft.taxRate,
      paidAmount: draft.paidAmount,
    );
    _validator.assertPaidNotOverTotal(
      total: summary.total,
      paidAmount: draft.paidAmount,
    );

    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await (_db.update(_db.sales)..where((t) => t.id.equals(id) & _scoped(t))).write(
        SalesCompanion(
          saleDate: Value(BusinessDate.utcDayMs(draft.saleDate)),
          settlementType: Value(draft.settlementType.storageValue),
          voucherBookId: Value(draft.voucherBookId),
          customerId: Value(draft.customerId),
          customerCode: Value(draft.customerCode),
          customerName: Value(draft.customerName),
          customerAccountId: Value(draft.customerAccountId),
          cashAccountId: Value(draft.cashAccountId),
          currencyCode: Value(draft.currencyCode),
          baseCurrencyCode: Value(draft.baseCurrencyCode),
          exchangeRate: Value(draft.exchangeRate),
          subtotal: Value(summary.subtotal),
          itemDiscountTotal: Value(summary.itemDiscountTotal),
          discountType: Value(draft.discountType.storageValue),
          discountValue: Value(draft.discountValue),
          discountAmount: Value(summary.saleDiscount),
          taxRate: Value(draft.taxRate),
          taxAmount: Value(summary.tax),
          total: Value(summary.total),
          paidAmount: Value(summary.paidAmount),
          remainingAmount: Value(summary.remainingAmount),
          paymentStatus: Value(summary.paymentStatus.storageValue),
          paymentMethod: Value(draft.paymentMethod.storageValue),
          notes: Value(draft.notes),
          updatedAt: Value(now.millisecondsSinceEpoch),
          externalId: Value(draft.externalId),
          externalDocumentNumber: Value(draft.externalDocumentNumber),
          externalStatus: Value(draft.externalStatus),
          dataSource: Value(draft.dataSource.storageValue),
          syncStatus: const Value('pending'),
          version: Value(existing.version + 1),
          companyId: Value(_currentCompanyId),
        ),
      );
      await _replaceChildren(
        saleUuid: existing.uuid,
        items: draft.items,
        payments: draft.payments,
        taxRate: draft.taxRate,
        taxAmount: summary.tax,
        paidAmount: summary.paidAmount,
        paymentMethod: draft.paymentMethod,
      );
    });

    final sale = await getById(id);
    if (sale == null) {
      throw const SaleException(SaleException.notFound);
    }
    await _enqueue(sale, SyncOperationType.update);
    return sale;
  }

  @override
  Future<Sale> updateStatus(int id, SaleStatusUpdate update) async {
    final existing = await getById(id);
    if (existing == null) {
      throw const SaleException(SaleException.notFound);
    }
    final now = DateTime.now().toUtc();
    await (_db.update(_db.sales)..where((t) => t.id.equals(id))).write(
      SalesCompanion(
        saleStatus: Value(update.saleStatus.storageValue),
        submittedAt: update.clearSubmittedAt
            ? const Value(null)
            : update.submittedAt != null
            ? Value(_toEpoch(update.submittedAt))
            : const Value.absent(),
        confirmedAt: update.clearConfirmedAt
            ? const Value(null)
            : update.confirmedAt != null
            ? Value(_toEpoch(update.confirmedAt))
            : const Value.absent(),
        completedAt: update.clearCompletedAt
            ? const Value(null)
            : update.completedAt != null
            ? Value(_toEpoch(update.completedAt))
            : const Value.absent(),
        cancelledAt: update.clearCancelledAt
            ? const Value(null)
            : update.cancelledAt != null
            ? Value(_toEpoch(update.cancelledAt))
            : const Value.absent(),
        externalId: update.externalId != null
            ? Value(update.externalId)
            : const Value.absent(),
        externalDocumentNumber: update.externalDocumentNumber != null
            ? Value(update.externalDocumentNumber)
            : const Value.absent(),
        externalStatus: update.externalStatus != null
            ? Value(update.externalStatus)
            : const Value.absent(),
        updatedAt: Value(now.millisecondsSinceEpoch),
        syncStatus: const Value('pending'),
        version: Value(existing.version + 1),
      ),
    );
    final sale = await getById(id);
    if (sale == null) {
      throw const SaleException(SaleException.notFound);
    }
    await _enqueue(sale, SyncOperationType.update);
    return sale;
  }

  @override
  Future<void> softDelete(int id) async {
    final existing = await getById(id);
    if (existing == null) {
      return;
    }
    _permissionGuard.requireAny(SalesPermissions.delete);
    if (existing.saleStatus.isPosted) {
      throw const JournalException(JournalException.postedImmutable);
    }

    final now = DateTime.now().toUtc();
    await (_db.update(_db.sales)..where((t) => t.id.equals(id))).write(
      SalesCompanion(
        deletedAt: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
        syncStatus: const Value('pending'),
        version: Value(existing.version + 1),
      ),
    );
    final sale = await getByUuid(existing.uuid);
    if (sale != null) {
      await _enqueue(sale, SyncOperationType.delete);
    }
  }

  @override
  Future<CustomerSaleTotals> totalsForCustomer(String customerId) async {
    final query = _db.selectOnly(_db.sales)
      ..addColumns([
        _db.sales.id.count(),
        _db.sales.total.sum(),
        _db.sales.paidAmount.sum(),
        _db.sales.remainingAmount.sum(),
      ])
      ..where(_scoped(_db.sales) & _db.sales.customerId.equals(customerId));
    final row = await query.getSingle();
    return CustomerSaleTotals(
      totalSales: row.read(_db.sales.total.sum()) ?? 0,
      paidAmount: row.read(_db.sales.paidAmount.sum()) ?? 0,
      outstandingAmount: row.read(_db.sales.remainingAmount.sum()) ?? 0,
      saleCount: row.read(_db.sales.id.count()) ?? 0,
    );
  }

  @override
  Future<List<Sale>> listByAccountLink(String accountUuid) async {
    final id = accountUuid.trim();
    if (id.isEmpty) {
      return const [];
    }
    final rows =
        await (_db.select(_db.sales)
              ..where(
                (t) =>
                    _scoped(t) &
                    (t.customerAccountId.equals(id) |
                        t.cashAccountId.equals(id)),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.saleDate)]))
            .get();
    return _mapSales(rows);
  }

  Future<void> markSynced({
    required String uuid,
    required int remoteVersion,
    DateTime? syncedAt,
  }) async {
    final at = syncedAt ?? DateTime.now().toUtc();
    await (_db.update(_db.sales)..where((t) => t.uuid.equals(uuid) & _tenantScoped(t))).write(
      SalesCompanion(
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(at.millisecondsSinceEpoch),
        version: Value(remoteVersion),
      ),
    );
  }

  Future<void> markConflict(String uuid) async {
    await (_db.update(_db.sales)..where((t) => t.uuid.equals(uuid) & _tenantScoped(t))).write(
      const SalesCompanion(syncStatus: Value('conflict')),
    );
  }

  Future<void> applyRemotePayload(Map<String, dynamic> payload) async {
    final uuid = payload['uuid'] as String?;
    if (uuid == null || uuid.isEmpty) {
      return;
    }

    await _db.transaction(() async {
      final existing = await getByUuid(uuid);
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final deletedAt = payload['deletedAt'] as int?;
      final remoteVersion = (payload['version'] as int?) ?? 1;

      // Dirty local: pending/conflict/syncing → mark conflict if remote is newer.
      if (existing != null &&
          (existing.syncStatus.needsUpload ||
              existing.syncStatus == SyncStatus.conflict ||
              existing.syncStatus == SyncStatus.syncing)) {
        if (remoteVersion > existing.version) {
          await markConflict(uuid);
        }
        return;
      }

      // Stale remote: incoming version <= local → skip (idempotent pull).
      if (existing != null && remoteVersion <= existing.version) {
        return;
      }

      if (existing == null) {
        await _db
            .into(_db.sales)
            .insert(
              SalesCompanion.insert(
                uuid: uuid,
                saleNumber: (payload['saleNumber'] as String?) ?? uuid,
                saleDate: Value((payload['saleDate'] as int?) ?? now),
                settlementType: Value(
                  (payload['settlementType'] as String?) ?? 'cash',
                ),
                voucherBookId: Value(payload['voucherBookId'] as String?),
                customerId: Value(payload['customerId'] as String?),
                customerCode: Value(payload['customerCode'] as String?),
                customerName: Value(payload['customerName'] as String?),
                customerAccountId: Value(
                  payload['customerAccountId'] as String?,
                ),
                cashAccountId: Value(payload['cashAccountId'] as String?),
                currencyCode: Value(
                  (payload['currencyCode'] as String?) ?? 'SAR',
                ),
                baseCurrencyCode: Value(
                  (payload['baseCurrencyCode'] as String?) ?? 'SAR',
                ),
                exchangeRate: Value(
                  (payload['exchangeRate'] as num?)?.toDouble() ?? 1,
                ),
                subtotal: (payload['subtotal'] as num?)?.toDouble() ?? 0,
                itemDiscountTotal:
                    (payload['itemDiscountTotal'] as num?)?.toDouble() ?? 0,
                discountType: Value(
                  (payload['discountType'] as String?) ?? 'fixed',
                ),
                discountValue: Value(
                  (payload['discountValue'] as num?)?.toDouble() ?? 0,
                ),
                discountAmount: Value(
                  (payload['discountAmount'] as num?)?.toDouble() ?? 0,
                ),
                taxRate: Value((payload['taxRate'] as num?)?.toDouble() ?? 0),
                taxAmount: Value(
                  (payload['taxAmount'] as num?)?.toDouble() ?? 0,
                ),
                total: (payload['total'] as num?)?.toDouble() ?? 0,
                paidAmount: Value(
                  (payload['paidAmount'] as num?)?.toDouble() ?? 0,
                ),
                remainingAmount: Value(
                  (payload['remainingAmount'] as num?)?.toDouble() ?? 0,
                ),
                paymentStatus: Value(
                  (payload['paymentStatus'] as String?) ?? 'unpaid',
                ),
                paymentMethod: Value(
                  (payload['paymentMethod'] as String?) ?? 'cash',
                ),
                saleStatus: Value(
                  (payload['saleStatus'] as String?) ?? 'unposted',
                ),
                notes: Value(payload['notes'] as String?),
                createdAt: (payload['updatedAt'] as int?) ?? now,
                updatedAt: (payload['updatedAt'] as int?) ?? now,
                submittedAt: Value(payload['submittedAt'] as int?),
                confirmedAt: Value(payload['confirmedAt'] as int?),
                completedAt: Value(payload['completedAt'] as int?),
                cancelledAt: Value(payload['cancelledAt'] as int?),
                externalId: Value(payload['externalId'] as String?),
                externalDocumentNumber: Value(
                  payload['externalDocumentNumber'] as String?,
                ),
                externalStatus: Value(payload['externalStatus'] as String?),
                dataSource: Value(
                  (payload['dataSource'] as String?) ?? 'synchronized',
                ),
                syncStatus: const Value('synced'),
                lastSyncedAt: Value(now),
                version: Value((payload['version'] as int?) ?? 1),
                deletedAt: Value(deletedAt),
                companyId: Value(payload['companyId']?.toString() ?? _currentCompanyId),
              ),
            );
      } else {
        await (_db.update(_db.sales)..where((t) => t.uuid.equals(uuid) & _scoped(t))).write(
          SalesCompanion(
            saleNumber: Value(
              (payload['saleNumber'] as String?) ?? existing.saleNumber,
            ),
            saleDate: Value(
              (payload['saleDate'] as int?) ??
                  existing.saleDate.toUtc().millisecondsSinceEpoch,
            ),
            settlementType: Value(
              (payload['settlementType'] as String?) ??
                  existing.settlementType.storageValue,
            ),
            voucherBookId: Value(payload['voucherBookId'] as String?),
            customerId: Value(payload['customerId'] as String?),
            customerCode: Value(payload['customerCode'] as String?),
            customerName: Value(payload['customerName'] as String?),
            customerAccountId: Value(payload['customerAccountId'] as String?),
            cashAccountId: Value(payload['cashAccountId'] as String?),
            currencyCode: Value(
              (payload['currencyCode'] as String?) ?? existing.currencyCode,
            ),
            baseCurrencyCode: Value(
              (payload['baseCurrencyCode'] as String?) ??
                  existing.baseCurrencyCode,
            ),
            exchangeRate: Value(
              (payload['exchangeRate'] as num?)?.toDouble() ??
                  existing.exchangeRate,
            ),
            subtotal: Value((payload['subtotal'] as num?)?.toDouble() ?? 0),
            itemDiscountTotal: Value(
              (payload['itemDiscountTotal'] as num?)?.toDouble() ?? 0,
            ),
            discountType: Value(
              (payload['discountType'] as String?) ?? 'fixed',
            ),
            discountValue: Value(
              (payload['discountValue'] as num?)?.toDouble() ?? 0,
            ),
            discountAmount: Value(
              (payload['discountAmount'] as num?)?.toDouble() ?? 0,
            ),
            taxRate: Value((payload['taxRate'] as num?)?.toDouble() ?? 0),
            taxAmount: Value((payload['taxAmount'] as num?)?.toDouble() ?? 0),
            total: Value((payload['total'] as num?)?.toDouble() ?? 0),
            paidAmount: Value((payload['paidAmount'] as num?)?.toDouble() ?? 0),
            remainingAmount: Value(
              (payload['remainingAmount'] as num?)?.toDouble() ?? 0,
            ),
            paymentStatus: Value(
              (payload['paymentStatus'] as String?) ?? 'unpaid',
            ),
            paymentMethod: Value(
              (payload['paymentMethod'] as String?) ?? 'cash',
            ),
            saleStatus: Value((payload['saleStatus'] as String?) ?? 'unposted'),
            notes: Value(payload['notes'] as String?),
            updatedAt: Value((payload['updatedAt'] as int?) ?? now),
            submittedAt: Value(payload['submittedAt'] as int?),
            confirmedAt: Value(payload['confirmedAt'] as int?),
            completedAt: Value(payload['completedAt'] as int?),
            cancelledAt: Value(payload['cancelledAt'] as int?),
            externalId: Value(payload['externalId'] as String?),
            externalDocumentNumber: Value(
              payload['externalDocumentNumber'] as String?,
            ),
            externalStatus: Value(payload['externalStatus'] as String?),
            dataSource: Value(
              (payload['dataSource'] as String?) ?? 'synchronized',
            ),
            syncStatus: const Value('synced'),
            lastSyncedAt: Value(now),
            version: Value((payload['version'] as int?) ?? existing.version),
            deletedAt: Value(deletedAt),
            companyId: Value(payload['companyId']?.toString() ?? _currentCompanyId),
          ),
        );
        await (_db.delete(
          _db.saleItems,
        )..where((t) => t.saleUuid.equals(uuid))).go();
        await (_db.delete(
          _db.salePayments,
        )..where((t) => t.saleUuid.equals(uuid))).go();
      }

      final items = payload['items'];
      if (items is List) {
        var order = 0;
        for (final raw in items) {
          if (raw is! Map) {
            continue;
          }
          final map = Map<String, dynamic>.from(raw);
          final unitPrice = (map['unitPrice'] as num?)?.toDouble() ?? 0;
          await _db
              .into(_db.saleItems)
              .insert(
                SaleItemsCompanion.insert(
                  uuid: (map['uuid'] as String?) ?? generateUuidV4(),
                  saleUuid: uuid,
                  productId: (map['productId'] as String?) ?? '',
                  productName: (map['productName'] as String?) ?? '',
                  productCode: (map['productCode'] as String?) ?? '',
                  barcode: Value(map['barcode'] as String?),
                  quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
                  mainQuantity: Value(
                    (map['mainQuantity'] as num?)?.toDouble() ??
                        (map['quantity'] as num?)?.toDouble() ??
                        0,
                  ),
                  subQuantity: Value(
                    (map['subQuantity'] as num?)?.toDouble() ?? 0,
                  ),
                  packSize: Value((map['packSize'] as int?) ?? 1),
                  unitPrice: unitPrice,
                  baseUnitPrice: Value(
                    (map['baseUnitPrice'] as num?)?.toDouble() ?? unitPrice,
                  ),
                  discountType: Value(
                    (map['discountType'] as String?) ?? 'fixed',
                  ),
                  discountValue: Value(
                    (map['discountValue'] as num?)?.toDouble() ?? 0,
                  ),
                  discountAmount: Value(
                    (map['discountAmount'] as num?)?.toDouble() ?? 0,
                  ),
                  taxAmount: Value((map['taxAmount'] as num?)?.toDouble() ?? 0),
                  subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
                  total: (map['total'] as num?)?.toDouble() ?? 0,
                  lineOrder: Value((map['lineOrder'] as int?) ?? order),
                ),
              );
          order++;
        }
      }

      final payments = payload['payments'];
      if (payments is List) {
        for (final raw in payments) {
          if (raw is! Map) {
            continue;
          }
          final map = Map<String, dynamic>.from(raw);
          await _db
              .into(_db.salePayments)
              .insert(
                SalePaymentsCompanion.insert(
                  uuid: (map['uuid'] as String?) ?? generateUuidV4(),
                  saleUuid: uuid,
                  amount: (map['amount'] as num?)?.toDouble() ?? 0,
                  method: Value((map['method'] as String?) ?? 'cash'),
                  paidAt: (map['paidAt'] as int?) ?? now,
                  createdAt: now,
                  notes: Value(map['notes'] as String?),
                  externalId: Value(map['externalId'] as String?),
                ),
              );
        }
      }
    });
  }
}
