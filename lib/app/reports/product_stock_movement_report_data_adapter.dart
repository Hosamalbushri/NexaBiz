import 'package:drift/drift.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/reports/shared/domain/services/product_stock_movement_report_data_port.dart';
import 'package:stock_count/modules/sales/shared/data/database/sales_database.dart';

/// Concrete implementation of [ProductStockMovementReportDataPort]
/// reading directly from [InventoryDatabase] and [SalesDatabase].
class ProductStockMovementReportDataAdapter
    implements ProductStockMovementReportDataPort {
  ProductStockMovementReportDataAdapter({
    required this.db,
    this.salesDb,
    required this.loadCompanyProfile,
  });

  final InventoryDatabase db;
  final SalesDatabase? salesDb;
  final Future<CompanyProfile> Function() loadCompanyProfile;

  @override
  Future<ProductStockMovementReportPayload> load({
    required String productId,
    String? warehouseId,
    DateTime? fromDate,
    DateTime? toDate,
    required ProductStockMovementReportLabels labels,
  }) async {
    await loadCompanyProfile();

    // 1. Fetch Product details
    String productCode = productId;
    String productName = productId;
    int mainCapacity = 24; // Default carton unit capacity as per standard sample
    const int subCapacity = 1;

    double productUnitCost = 0.0;

    final prodQuery = await (db.select(db.products)
          ..where((tbl) => tbl.uuid.equals(productId) | tbl.itemCode.equals(productId)))
        .getSingleOrNull();

    if (prodQuery != null) {
      productCode = prodQuery.itemCode;
      productName = prodQuery.name;
      productUnitCost = prodQuery.unitCost;
      if (prodQuery.packSize > 0) {
        mainCapacity = prodQuery.packSize;
      }
    }

    double resolveLineCost(double qty, double totalCost, double unitCost) {
      if (totalCost > 0) return totalCost;
      if (unitCost > 0) return qty * unitCost;
      return qty * productUnitCost;
    }

    // 2. Fetch Warehouse details
    String warehouseName = labels.allWarehousesLabel;
    if (warehouseId != null && warehouseId.isNotEmpty) {
      final whQuery = await (db.select(db.warehouses)
            ..where((tbl) => tbl.uuid.equals(warehouseId)))
          .getSingleOrNull();
      if (whQuery != null) {
        warehouseName = whQuery.name;
      }
    }

    // 3. Fetch all Stock Movements for this product
    // We join lines with receipts, issues, transfers, and returns.
    final allLines = await (db.select(db.stockMovementLines)
          ..where((tbl) => tbl.itemCode.equals(productCode) | tbl.movementUuid.equals(productId)))
        .get();

    // Fetch Receipts
    final receiptsMap = <String, StockReceiptRow>{};
    final receipts = await (db.select(db.stockReceipts)..where((tbl) => tbl.deletedAt.isNull())).get();
    for (final r in receipts) {
      receiptsMap[r.uuid] = r;
    }

    // Fetch Issues
    final issuesMap = <String, StockIssueRow>{};
    final issues = await (db.select(db.stockIssues)..where((tbl) => tbl.deletedAt.isNull())).get();
    for (final i in issues) {
      issuesMap[i.uuid] = i;
    }

    // Fetch Transfers
    final transfersMap = <String, StockTransferRow>{};
    final transfers = await (db.select(db.stockTransfers)..where((tbl) => tbl.deletedAt.isNull())).get();
    for (final t in transfers) {
      transfersMap[t.uuid] = t;
    }

    // Fetch Returns
    final returnsMap = <String, StockReturnRow>{};
    final returns = await (db.select(db.stockReturns)..where((tbl) => tbl.deletedAt.isNull())).get();
    for (final ret in returns) {
      returnsMap[ret.uuid] = ret;
    }

    // Build unified raw movements list
    final rawMovements = <_RawMovementItem>[];

    for (final line in allLines) {
      final lineUnitCost = line.unitCost > 0 ? line.unitCost : productUnitCost;
      final lineCost = resolveLineCost(line.quantity, line.totalCost, line.unitCost);

      if (receiptsMap.containsKey(line.movementUuid)) {
        final rec = receiptsMap[line.movementUuid]!;
        final date = DateTime.fromMillisecondsSinceEpoch(rec.receiptDate);
        rawMovements.add(_RawMovementItem(
          date: date,
          docType: 'أمر توريد',
          voucherBook: 'د/وارد من الرئيسي',
          docNum: rec.receiptNumber,
          docUuid: rec.uuid,
          isIncoming: true,
          quantity: line.quantity,
          mainQuantity: line.mainQuantity,
          subQuantity: line.subQuantity,
          unitCost: lineUnitCost,
          cost: lineCost,
          warehouseId: null,
        ));
      } else if (issuesMap.containsKey(line.movementUuid)) {
        final iss = issuesMap[line.movementUuid]!;
        final date = DateTime.fromMillisecondsSinceEpoch(iss.issueDate);
        rawMovements.add(_RawMovementItem(
          date: date,
          docType: 'أمر صرف',
          voucherBook: iss.accountName ?? 'د/صرف للرئيسي',
          docNum: iss.issueNumber,
          docUuid: iss.uuid,
          isIncoming: false,
          quantity: line.quantity,
          mainQuantity: line.mainQuantity,
          subQuantity: line.subQuantity,
          unitCost: lineUnitCost,
          cost: lineCost,
          warehouseId: iss.warehouse,
        ));
      } else if (transfersMap.containsKey(line.movementUuid)) {
        final tr = transfersMap[line.movementUuid]!;
        final date = DateTime.fromMillisecondsSinceEpoch(tr.transferDate);
        // Transfer Out from source
        if (warehouseId == null || warehouseId == tr.fromWarehouseId) {
          rawMovements.add(_RawMovementItem(
            date: date,
            docType: 'تحويل مخزني',
            voucherBook: 'تحويل صادرة',
            docNum: tr.transferNumber,
            docUuid: tr.uuid,
            isIncoming: false,
            quantity: line.quantity,
            mainQuantity: line.mainQuantity,
            subQuantity: line.subQuantity,
            unitCost: lineUnitCost,
            cost: lineCost,
            warehouseId: tr.fromWarehouseId,
          ));
        }
        // Transfer In to target
        if (warehouseId == null || warehouseId == tr.toWarehouseId) {
          rawMovements.add(_RawMovementItem(
            date: date,
            docType: 'تحويل مخزني',
            voucherBook: 'تحويل واردة',
            docNum: tr.transferNumber,
            docUuid: tr.uuid,
            isIncoming: true,
            quantity: line.quantity,
            mainQuantity: line.mainQuantity,
            subQuantity: line.subQuantity,
            unitCost: lineUnitCost,
            cost: lineCost,
            warehouseId: tr.toWarehouseId,
          ));
        }
      } else if (returnsMap.containsKey(line.movementUuid)) {
        final ret = returnsMap[line.movementUuid]!;
        final date = DateTime.fromMillisecondsSinceEpoch(ret.returnDate);
        final isSalesReturn = ret.returnType == 'sales_return';
        rawMovements.add(_RawMovementItem(
          date: date,
          docType: isSalesReturn ? 'مردود بيع' : 'مردود شراء',
          voucherBook: ret.partyName ?? (isSalesReturn ? 'مردود بيع' : 'مردود شراء'),
          docNum: ret.returnNumber,
          docUuid: ret.uuid,
          isIncoming: isSalesReturn, // Sales return is incoming to stock
          quantity: line.quantity,
          mainQuantity: line.mainQuantity,
          subQuantity: line.subQuantity,
          unitCost: lineUnitCost,
          cost: lineCost,
          warehouseId: ret.warehouse,
        ));
      }
    }

    // 3b. Fetch Sales Invoices from SalesDatabase
    if (salesDb != null) {
      final salesMap = <String, SaleRow>{};
      final salesList = await (salesDb!.select(salesDb!.sales)
            ..where((tbl) => tbl.deletedAt.isNull()))
          .get();
      for (final s in salesList) {
        // Exclude cancelled sales
        if (s.saleStatus != 'cancelled') {
          salesMap[s.uuid] = s;
        }
      }

      final saleItems = await (salesDb!.select(salesDb!.saleItems)
            ..where((tbl) => tbl.productId.equals(productId) | tbl.productCode.equals(productCode)))
          .get();

      for (final item in saleItems) {
        if (salesMap.containsKey(item.saleUuid)) {
          final sale = salesMap[item.saleUuid]!;
          final date = DateTime.fromMillisecondsSinceEpoch(
            sale.saleDate > 0 ? sale.saleDate : sale.createdAt,
          );
          final saleItemCost = item.quantity * productUnitCost;
          rawMovements.add(_RawMovementItem(
            date: date,
            docType: 'فاتورة مبيعات',
            voucherBook: (sale.customerName != null && sale.customerName!.isNotEmpty)
                ? sale.customerName!
                : (sale.settlementType == 'cash' ? 'مبيعات نقدية' : 'مبيعات آجلة'),
            docNum: sale.saleNumber,
            docUuid: sale.uuid,
            isIncoming: false,
            quantity: item.quantity,
            mainQuantity: item.mainQuantity,
            subQuantity: item.subQuantity,
            unitCost: productUnitCost,
            cost: saleItemCost,
            warehouseId: null,
          ));
        }
      }
    }

    // Filter by warehouse if specified
    var filtered = rawMovements;
    if (warehouseId != null && warehouseId.isNotEmpty) {
      filtered = rawMovements.where((m) => m.warehouseId == null || m.warehouseId == warehouseId).toList();
    }

    // Sort chronologically (oldest to newest), with incoming movements listed before outgoing movements on same timestamp
    filtered.sort((a, b) {
      final dateCmp = a.date.compareTo(b.date);
      if (dateCmp != 0) return dateCmp;
      if (a.isIncoming != b.isIncoming) {
        return a.isIncoming ? -1 : 1;
      }
      return a.docNum.compareTo(b.docNum);
    });

    // 4. Calculate Opening Balance before `fromDate`
    double openQty = 0.0;
    double openCost = 0.0;

    final fromEpoch = fromDate != null ? DateTime(fromDate.year, fromDate.month, fromDate.day) : null;
    final toEpoch = toDate != null ? DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59) : null;

    final periodItems = <_RawMovementItem>[];

    for (final item in filtered) {
      if (fromEpoch != null && item.date.isBefore(fromEpoch)) {
        if (item.isIncoming) {
          openQty += item.quantity;
          openCost += item.cost;
        } else {
          openQty -= item.quantity;
          openCost -= item.cost;
        }
      } else if (toEpoch != null && item.date.isAfter(toEpoch)) {
        // After range, ignore
        continue;
      } else {
        periodItems.add(item);
      }
    }

    final int openCartons = openQty.truncate();
    final double openPieces = ((openQty - openCartons) * mainCapacity).roundToDouble();

    final openingBalance = ProductStockOpeningBalance(
      cartons: openCartons,
      pieces: openPieces,
      totalQty: openQty,
      totalCost: openCost,
    );

    // 5. Build Movement Rows & Running Totals
    double runningQty = openQty;
    double runningCost = openCost;

    double totalInCost = 0.0;
    double totalOutCost = 0.0;
    double totalInQty = 0.0;
    double totalOutQty = 0.0;

    final rows = <ProductStockMovementRow>[];

    for (final item in periodItems) {
      final inQty = item.isIncoming ? item.quantity : 0.0;
      final inCost = item.isIncoming ? item.cost : 0.0;
      final outQty = item.isIncoming ? 0.0 : item.quantity;
      final outCost = item.isIncoming ? 0.0 : item.cost;

      if (item.isIncoming) {
        totalInQty += item.quantity;
        totalInCost += item.cost;
        runningQty += item.quantity;
        runningCost += item.cost;
      } else {
        totalOutQty += item.quantity;
        totalOutCost += item.cost;
        runningQty -= item.quantity;
        runningCost -= item.cost;
      }

      final int itemCartons = (item.mainQuantity > 0 || item.subQuantity > 0)
          ? item.mainQuantity.toInt()
          : item.quantity.truncate();
      final double itemPieces = (item.mainQuantity > 0 || item.subQuantity > 0)
          ? item.subQuantity
          : ((item.quantity - item.quantity.truncate()) * mainCapacity).roundToDouble();

      final inCartons = item.isIncoming ? itemCartons : 0;
      final inPieces = item.isIncoming ? itemPieces : 0.0;

      final outCartons = item.isIncoming ? 0 : itemCartons;
      final outPieces = item.isIncoming ? 0.0 : itemPieces;

      final balCartons = runningQty.truncate();
      final balPieces = ((runningQty - balCartons) * mainCapacity).roundToDouble();

      rows.add(ProductStockMovementRow(
        documentDate: item.date,
        documentType: item.docType,
        voucherBook: item.voucherBook,
        documentNumber: item.docNum,
        documentUuid: item.docUuid,
        unitCost: item.unitCost,
        inCartons: inCartons,
        inPieces: inPieces,
        inTotalQty: inQty,
        inCost: inCost,
        outCartons: outCartons,
        outPieces: outPieces,
        outTotalQty: outQty,
        outCost: outCost,
        balanceCartons: balCartons,
        balancePieces: balPieces,
        balanceTotalQty: runningQty,
        balanceCost: runningCost,
      ));
    }

    return ProductStockMovementReportPayload(
      labels: labels,
      fromDate: fromDate,
      toDate: toDate,
      warehouseName: warehouseName,
      productCode: productCode,
      productName: productName,
      mainUnitCapacity: mainCapacity,
      subUnitCapacity: subCapacity,
      openingBalance: openingBalance,
      rows: rows,
      totalIncomingCost: totalInCost,
      totalOutgoingCost: totalOutCost,
      totalIncomingQty: totalInQty,
      totalOutgoingQty: totalOutQty,
    );
  }
}

class _RawMovementItem {
  _RawMovementItem({
    required this.date,
    required this.docType,
    required this.voucherBook,
    required this.docNum,
    this.docUuid,
    required this.isIncoming,
    required this.quantity,
    this.mainQuantity = 0.0,
    this.subQuantity = 0.0,
    required this.unitCost,
    required this.cost,
    this.warehouseId,
  });

  final DateTime date;
  final String docType;
  final String voucherBook;
  final String docNum;
  final String? docUuid;
  final bool isIncoming;
  final double quantity;
  final double mainQuantity;
  final double subQuantity;
  final double unitCost;
  final double cost;
  final String? warehouseId;
}
