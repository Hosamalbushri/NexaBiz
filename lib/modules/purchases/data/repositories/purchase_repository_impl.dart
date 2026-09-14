import 'package:drift/drift.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/entities/purchase_invoice.dart';
import '../../domain/entities/purchase_item.dart';
import '../../domain/repositories/purchase_repository.dart';

/// Drift-backed Repository Implementation for Purchases on `nexabiz.sqlite`.
class PurchaseRepositoryImpl implements PurchaseRepository {
  final NexabizDatabase _db;
  final String Function()? _readCompanyId;

  PurchaseRepositoryImpl(this._db, {this._readCompanyId});

  String get _currentCompanyId {
    final companyId = _readCompanyId?.call();
    if (companyId == null || companyId.trim().isEmpty) {
      throw StateError(
          'Active company scope context is required for PurchaseRepository operations.');
    }
    return companyId;
  }

  Supplier _mapSupplier(SupplierData row) {
    return Supplier(
      id: row.id,
      companyId: row.companyId,
      nameAr: row.name,
      nameEn: row.name,
      code: row.supplierCode,
      taxNumber: row.taxNumber,
      phone: row.phone,
      email: row.email,
      address: row.address,
      currentBalance: row.currentBalance,
      currencyCode: row.currencyCode,
      isActive: row.status == 'active',
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<List<PurchaseItem>> _loadItems(String purchaseId) async {
    final rows = await (_db.select(_db.purchaseItems)
          ..where((t) => t.purchaseId.equals(purchaseId))
          ..orderBy([(t) => OrderingTerm.asc(t.lineOrder)]))
        .get();
    return rows.map<PurchaseItem>((r) => PurchaseItem(
      id: r.id,
      productId: r.productId,
      productNameAr: r.productName,
      productNameEn: r.productName,
      quantity: r.quantity,
      unitPrice: r.unitPrice,
      discountAmount: r.discountAmount,
      taxAmount: r.taxAmount,
      totalPrice: r.total,
    )).toList();
  }

  PurchaseInvoiceStatus _mapStatus(String statusStr) {
    switch (statusStr) {
      case 'posted':
        return PurchaseInvoiceStatus.posted;
      case 'cancelled':
        return PurchaseInvoiceStatus.cancelled;
      case 'paid':
        return PurchaseInvoiceStatus.paid;
      default:
        return PurchaseInvoiceStatus.draft;
    }
  }

  Future<PurchaseInvoice> _mapInvoice(PurchaseRow row) async {
    final items = await _loadItems(row.id);
    return PurchaseInvoice(
      id: row.id,
      companyId: row.companyId ?? '',
      invoiceNumber: row.purchaseNumber,
      supplierId: row.supplierId ?? '',
      supplierName: row.supplierName ?? '',
      warehouseId: row.warehouseId ?? '',
      invoiceDate: DateTime.fromMillisecondsSinceEpoch(row.purchaseDate, isUtc: true),
      items: items,
      subtotal: row.subtotal,
      taxTotal: row.taxAmount,
      discountTotal: row.discountAmount,
      grandTotal: row.total,
      currencyCode: row.currencyCode,
      status: _mapStatus(row.purchaseStatus),
      notes: row.notes,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
    );
  }

  @override
  Future<List<Supplier>> getSuppliers(String companyId) async {
    final rows = await (_db.select(_db.suppliers)
          ..where((t) => t.companyId.equals(companyId)))
        .get();
    return rows.map(_mapSupplier).toList();
  }

  @override
  Future<Supplier?> getSupplierById(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;
    final row = await (_db.select(_db.suppliers)
          ..where((t) => t.id.equals(trimmed)))
        .getSingleOrNull();
    return row == null ? null : _mapSupplier(row);
  }

  @override
  Future<Supplier> createSupplier(Supplier supplier) async {
    final newId = supplier.id.isNotEmpty ? supplier.id : generateUuidV7();
    final now = DateTime.now().toUtc();
    await _db.into(_db.suppliers).insert(
          SuppliersCompanion.insert(
            id: Value(newId),
            supplierCode: supplier.code ?? 'SUP-${newId.substring(0, 6)}',
            name: supplier.nameAr.isNotEmpty ? supplier.nameAr : supplier.nameEn,
            phone: Value(supplier.phone),
            email: Value(supplier.email),
            address: Value(supplier.address),
            taxNumber: Value(supplier.taxNumber),
            currentBalance: Value(supplier.currentBalance),
            currencyCode: Value(supplier.currencyCode),
            status: Value(supplier.isActive ? 'active' : 'inactive'),
            companyId: supplier.companyId,
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    final created = await getSupplierById(newId);
    return created!;
  }

  @override
  Future<List<PurchaseInvoice>> getPurchaseInvoices([String? companyId]) async {
    final targetCompanyId = (companyId != null && companyId.isNotEmpty) ? companyId : _currentCompanyId;
    final rows = await (_db.select(_db.purchases)
          ..where((t) => t.companyId.equals(targetCompanyId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    final result = <PurchaseInvoice>[];
    for (final row in rows) {
      result.add(await _mapInvoice(row));
    }
    return result;
  }

  @override
  Future<PurchaseInvoice?> getPurchaseInvoiceById(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;
    final row = await (_db.select(_db.purchases)
          ..where((t) => t.id.equals(trimmed) & t.companyId.equals(_currentCompanyId) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _mapInvoice(row);
  }

  @override
  Future<PurchaseInvoice> createPurchaseInvoice(PurchaseInvoice invoice) async {
    final newId = invoice.id.isNotEmpty ? invoice.id : generateUuidV7();
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final purchaseDateMs = invoice.invoiceDate.toUtc().millisecondsSinceEpoch;

    await _db.transaction(() async {
      await _db.into(_db.purchases).insert(
            PurchasesCompanion.insert(
              id: Value(newId),
              purchaseNumber: invoice.invoiceNumber,
              purchaseDate: Value(purchaseDateMs),
              warehouseId: Value(invoice.warehouseId),
              supplierId: Value(invoice.supplierId),
              supplierName: Value(invoice.supplierName),
              currencyCode: invoice.currencyCode,
              baseCurrencyCode: invoice.currencyCode,
              subtotal: invoice.subtotal,
              itemDiscountTotal: invoice.discountTotal,
              discountAmount: Value(invoice.discountTotal),
              taxAmount: Value(invoice.taxTotal),
              total: invoice.grandTotal,
              purchaseStatus: Value(invoice.status.name),
              notes: Value(invoice.notes),
              companyId: Value(invoice.companyId),
              createdAt: now,
              updatedAt: now,
            ),
          );

      int lineOrder = 0;
      for (final item in invoice.items) {
        final itemUuid = item.id.isNotEmpty ? item.id : generateUuidV7();
        final name = item.productNameAr.isNotEmpty ? item.productNameAr : item.productNameEn;
        await _db.into(_db.purchaseItems).insert(
              PurchaseItemsCompanion.insert(
                id: Value(itemUuid),
                purchaseId: newId,
                productId: item.productId,
                productName: name,
                productCode: 'PROD-${item.productId.substring(0, 6)}',
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                subtotal: item.unitPrice * item.quantity,
                total: item.totalPrice,
                lineOrder: Value(lineOrder++),
              ),
            );
      }
    });

    final created = await getPurchaseInvoiceById(newId);
    return created!;
  }

  @override
  Future<void> postPurchaseInvoice(String invoiceId) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.purchases)..where((t) => t.id.equals(invoiceId)))
        .write(
      PurchasesCompanion(
        purchaseStatus: const Value('posted'),
        updatedAt: Value(now),
      ),
    );
  }
}
