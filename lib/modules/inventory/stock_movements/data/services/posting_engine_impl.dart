import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/cost_layer_service.dart';
import 'package:stock_count/modules/inventory/cost_valuation/domain/services/cost_method_inheritance_resolver.dart';
import '../../domain/services/posting_engine.dart';

class PostingEngineImpl implements PostingEngine {
  PostingEngineImpl(
    this._db,
    this._costLayerService, [
    this._inheritanceResolver,
  ]);

  final InventoryDatabase _db;
  final CostLayerService _costLayerService;
  final CostMethodInheritanceResolver? _inheritanceResolver;

  @override
  Future<double> applyInboundPosting({
    required InventoryDocumentRef document,
    required List<InboundLineData> lines,
    required String? warehouseId,
    required DateTime documentDate,
  }) async {
    final nowEpoch = DateTime.now().millisecondsSinceEpoch;
    final rate = (document.exchangeRate > 0) ? document.exchangeRate : 1.0;
    double totalValue = 0.0;

    await _db.transaction(() async {
      for (final line in lines) {
        final baseUnitCost = line.unitCost * rate;
        final baseTotalCost = line.quantity * baseUnitCost;

        final layer = CostLayer(
          id: generateUuidV4(),
          itemCode: line.itemCode,
          warehouseId: warehouseId,
          movementUuid: document.documentId,
          movementType: document.documentType.storageValue,
          receivedDate: documentDate,
          receivedQty: line.quantity,
          remainingQty: line.quantity,
          unitCost: baseUnitCost,
          totalCost: baseTotalCost,
          closed: false,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );

        await _costLayerService.createLayer(layer);
        await _adjustProductQty(line.itemCode, warehouseId, line.quantity);

        // Update line posted details in base currency
        await (_db.update(_db.stockMovementLines)
              ..where((tbl) => tbl.uuid.equals(line.lineUuid)))
            .write(
          StockMovementLinesCompanion(
            postedCost: Value(baseUnitCost),
            postedAt: Value(nowEpoch),
          ),
        );

        totalValue += baseTotalCost;
      }

      // Mark header document as posted
      await _setDocumentStatus(document, InventoryDocumentStatus.posted, nowEpoch);
    });

    return totalValue;
  }

  @override
  Future<double> applyOutboundPosting({
    required InventoryDocumentRef document,
    required List<OutboundLineData> lines,
    required String? warehouseId,
    required CostValuationMethod valuationMethod,
  }) async {
    final nowEpoch = DateTime.now().millisecondsSinceEpoch;
    double totalCogs = 0.0;

    await _db.transaction(() async {
      for (final line in lines) {
        final effectiveValuationMethod = _inheritanceResolver != null
            ? (await _inheritanceResolver!.resolveForProduct(
                itemCode: line.itemCode,
                warehouseId: warehouseId,
              )).effectiveMethod
            : valuationMethod;

        final consumptionResult = await _costLayerService.consumeLayers(
          itemCode: line.itemCode,
          quantity: line.quantity,
          method: effectiveValuationMethod,
          issueLineUuid: line.lineUuid,
          movementType: document.documentType.storageValue,
          warehouseId: warehouseId,
        );

        await _adjustProductQty(line.itemCode, warehouseId, -line.quantity);

        // Update line posted details
        await (_db.update(_db.stockMovementLines)
              ..where((tbl) => tbl.uuid.equals(line.lineUuid)))
            .write(
          StockMovementLinesCompanion(
            postedCost: Value(consumptionResult.effectiveUnitCost),
            postedAt: Value(nowEpoch),
          ),
        );

        totalCogs += consumptionResult.totalCost;
      }

      // Mark header document as posted
      await _setDocumentStatus(document, InventoryDocumentStatus.posted, nowEpoch);
    });

    return totalCogs;
  }

  @override
  Future<double> applyTransferPosting({
    required InventoryDocumentRef document,
    required List<TransferLineData> lines,
    required String fromWarehouseId,
    required String toWarehouseId,
    required CostValuationMethod valuationMethod,
  }) async {
    final nowEpoch = DateTime.now().millisecondsSinceEpoch;
    double totalTransferredValue = 0.0;

    await _db.transaction(() async {
      for (final line in lines) {
        final effectiveValuationMethod = _inheritanceResolver != null
            ? (await _inheritanceResolver!.resolveForProduct(
                itemCode: line.itemCode,
                warehouseId: fromWarehouseId,
              )).effectiveMethod
            : valuationMethod;

        // 1. Consume from source warehouse
        final consumptionResult = await _costLayerService.consumeLayers(
          itemCode: line.itemCode,
          quantity: line.quantity,
          method: effectiveValuationMethod,
          issueLineUuid: line.lineUuid,
          movementType: 'stock_transfer_out',
          warehouseId: fromWarehouseId,
        );

        await _adjustProductQty(line.itemCode, fromWarehouseId, -line.quantity);

        final effectiveCost = consumptionResult.effectiveUnitCost;

        // 2. Create cost layer in destination warehouse
        final destLayer = CostLayer(
          id: generateUuidV4(),
          itemCode: line.itemCode,
          warehouseId: toWarehouseId,
          movementUuid: document.documentId,
          movementType: 'stock_transfer_in',
          receivedDate: document.documentDate,
          receivedQty: line.quantity,
          remainingQty: line.quantity,
          unitCost: effectiveCost,
          totalCost: line.quantity * effectiveCost,
          closed: false,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );

        await _costLayerService.createLayer(destLayer);
        await _adjustProductQty(line.itemCode, toWarehouseId, line.quantity);

        totalTransferredValue += (line.quantity * effectiveCost);
      }

      // Mark transfer document as posted
      await _setDocumentStatus(document, InventoryDocumentStatus.posted, nowEpoch);
    });

    return totalTransferredValue;
  }

  @override
  Future<void> reversePosting({
    required InventoryDocumentRef document,
  }) async {
    await _db.transaction(() async {
      switch (document.documentType) {
        case InventoryDocumentType.stockReceipt:
          final lines = await (_db.select(_db.stockMovementLines)
                ..where((tbl) => tbl.movementUuid.equals(document.documentId)))
              .get();

          for (final line in lines) {
            await _adjustProductQty(line.itemCode, document.warehouseId, -line.quantity);

            await (_db.update(_db.stockMovementLines)
                  ..where((tbl) => tbl.uuid.equals(line.uuid)))
                .write(
              const StockMovementLinesCompanion(
                postedCost: Value.absent(),
                postedAt: Value.absent(),
              ),
            );
          }

          await _costLayerService.reverseLayer(document.documentId);
          await _setDocumentStatus(document, InventoryDocumentStatus.draft, null);
          break;

        case InventoryDocumentType.stockIssue:
          final lines = await (_db.select(_db.stockMovementLines)
                ..where((tbl) => tbl.movementUuid.equals(document.documentId)))
              .get();

          for (final line in lines) {
            await _costLayerService.reverseConsumptions(line.uuid);
            await _adjustProductQty(line.itemCode, document.warehouseId, line.quantity);

            await (_db.update(_db.stockMovementLines)
                  ..where((tbl) => tbl.uuid.equals(line.uuid)))
                .write(
              const StockMovementLinesCompanion(
                postedCost: Value.absent(),
                postedAt: Value.absent(),
              ),
            );
          }

          await _setDocumentStatus(document, InventoryDocumentStatus.draft, null);
          break;

        case InventoryDocumentType.stockReturn:
          final returns = await (_db.select(_db.stockReturns)
                ..where((tbl) => tbl.uuid.equals(document.documentId)))
              .get();

          if (returns.isNotEmpty) {
            final ret = returns.first;
            final isPurchaseReturn = ret.returnType == 'purchase_return';

            final lines = await (_db.select(_db.stockMovementLines)
                  ..where((tbl) => tbl.movementUuid.equals(document.documentId)))
                .get();

            for (final line in lines) {
              if (isPurchaseReturn) {
                // Outbound return: reverse consumption, increase stock
                await _costLayerService.reverseConsumptions(line.uuid);
                await _adjustProductQty(line.itemCode, document.warehouseId, line.quantity);
              } else {
                // Inbound return: reverse layer, decrease stock
                await _adjustProductQty(line.itemCode, document.warehouseId, -line.quantity);
              }

              await (_db.update(_db.stockMovementLines)
                    ..where((tbl) => tbl.uuid.equals(line.uuid)))
                  .write(
                const StockMovementLinesCompanion(
                  postedCost: Value.absent(),
                  postedAt: Value.absent(),
                ),
              );
            }

            if (!isPurchaseReturn) {
              await _costLayerService.reverseLayer(document.documentId);
            }

            await _setDocumentStatus(document, InventoryDocumentStatus.draft, null);
          }
          break;

        case InventoryDocumentType.stockTransfer:
          final transfers = await (_db.select(_db.stockTransfers)
                ..where((tbl) => tbl.uuid.equals(document.documentId)))
              .get();

          if (transfers.isNotEmpty) {
            final tr = transfers.first;
            final lines = await (_db.select(_db.stockMovementLines)
                  ..where((tbl) => tbl.movementUuid.equals(document.documentId)))
                .get();

            for (final line in lines) {
              // Reverse inbound in destination warehouse
              await _adjustProductQty(line.itemCode, tr.toWarehouseId, -line.quantity);
              // Reverse outbound consumptions in source warehouse
              await _costLayerService.reverseConsumptions(line.uuid);
              await _adjustProductQty(line.itemCode, tr.fromWarehouseId, line.quantity);
            }

            await _costLayerService.reverseLayer(document.documentId);
            await _setDocumentStatus(document, InventoryDocumentStatus.draft, null);
          }
          break;

        case InventoryDocumentType.salesInvoice:
          final lines = await (_db.select(_db.stockMovementLines)
                ..where((tbl) => tbl.movementUuid.equals(document.documentId)))
              .get();

          for (final line in lines) {
            await _costLayerService.reverseConsumptions(line.uuid);
            await _adjustProductQty(line.itemCode, document.warehouseId, line.quantity);

            await (_db.update(_db.stockMovementLines)
                  ..where((tbl) => tbl.uuid.equals(line.uuid)))
                .write(
              const StockMovementLinesCompanion(
                postedCost: Value.absent(),
                postedAt: Value.absent(),
              ),
            );
          }

          await _setDocumentStatus(document, InventoryDocumentStatus.draft, null);
          break;

        default:
          break;
      }
    });
  }

  Future<void> _adjustProductQty(
    String itemCode,
    String? warehouseId,
    double deltaQty,
  ) async {
    // 1. Update overall product table stock
    final prodQuery = _db.select(_db.products)
      ..where((p) => p.itemCode.equals(itemCode));
    final prods = await prodQuery.get();

    if (prods.isNotEmpty) {
      final p = prods.first;
      final newQty = (p.onHandQty + deltaQty).clamp(0.0, double.infinity);
      await (_db.update(_db.products)..where((tbl) => tbl.id.equals(p.id))).write(
        ProductsCompanion(onHandQty: Value(newQty.toDouble())),
      );
    }

    // 2. Update warehouse-specific stock if warehouseId is provided
    if (warehouseId != null && warehouseId.isNotEmpty) {
      final whQuery = _db.select(_db.productWarehouseStocks)
        ..where((w) => w.itemCode.equals(itemCode))
        ..where((w) => w.warehouseId.equals(warehouseId));

      final whStocks = await whQuery.get();

      if (whStocks.isNotEmpty) {
        final whStock = whStocks.first;
        final newWhQty = (whStock.onHandQty + deltaQty).clamp(0.0, double.infinity);
        await (_db.update(_db.productWarehouseStocks)
              ..where((w) => w.uuid.equals(whStock.uuid)))
            .write(
          ProductWarehouseStocksCompanion(onHandQty: Value(newWhQty.toDouble())),
        );
      } else if (deltaQty > 0) {
        await _db.into(_db.productWarehouseStocks).insert(
              ProductWarehouseStocksCompanion(
                uuid: Value(generateUuidV4()),
                itemCode: Value(itemCode),
                warehouseId: Value(warehouseId),
                onHandQty: Value(deltaQty),
                createdAt: Value(DateTime.now().millisecondsSinceEpoch),
                updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );
      }
    }
  }

  Future<void> _setDocumentStatus(
    InventoryDocumentRef doc,
    InventoryDocumentStatus status,
    int? postedAtEpoch,
  ) async {
    final statusStr = status.name;

    switch (doc.documentType) {
      case InventoryDocumentType.stockReceipt:
        await (_db.update(_db.stockReceipts)
              ..where((tbl) => tbl.uuid.equals(doc.documentId)))
            .write(
          StockReceiptsCompanion(
            status: Value(statusStr),
            postedAt: Value(postedAtEpoch),
          ),
        );
        break;
      case InventoryDocumentType.stockIssue:
        await (_db.update(_db.stockIssues)
              ..where((tbl) => tbl.uuid.equals(doc.documentId)))
            .write(
          StockIssuesCompanion(
            status: Value(statusStr),
            postedAt: Value(postedAtEpoch),
          ),
        );
        break;
      case InventoryDocumentType.stockReturn:
        await (_db.update(_db.stockReturns)
              ..where((tbl) => tbl.uuid.equals(doc.documentId)))
            .write(
          StockReturnsCompanion(
            status: Value(statusStr),
            postedAt: Value(postedAtEpoch),
          ),
        );
        break;
      case InventoryDocumentType.stockTransfer:
        await (_db.update(_db.stockTransfers)
              ..where((tbl) => tbl.uuid.equals(doc.documentId)))
            .write(
          StockTransfersCompanion(
            status: Value(statusStr),
            postedAt: Value(postedAtEpoch),
          ),
        );
        break;
      default:
        break;
    }
  }
}
