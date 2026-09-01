import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/core/errors/journal_exception.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/cost_layer.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/cost_layer_service.dart';
import 'package:stock_count/modules/inventory/cost_valuation/domain/services/cost_method_inheritance_resolver.dart';
import 'package:stock_count/modules/system_setup/domain/services/initialization_guard.dart';
import '../../domain/services/posting_engine.dart';

class PostingEngineImpl implements PostingEngine {
  PostingEngineImpl(
    this._db,
    this._costLayerService, [
    this._inheritanceResolver,
    String Function()? readCompanyId,
    InitializationGuard? initializationGuard,
  ])  : _readCompanyId = readCompanyId,
        _initializationGuard = initializationGuard;

  final InventoryDatabase _db;
  final CostLayerService _costLayerService;
  final CostMethodInheritanceResolver? _inheritanceResolver;
  final String Function()? _readCompanyId;
  final InitializationGuard? _initializationGuard;

  String get _currentCompanyId =>
      _readCompanyId?.call() ?? LocalAuthDefaults.companyId;

  @override
  Future<double> applyInboundPosting({
    required InventoryDocumentRef document,
    required List<InboundLineData> lines,
    required String? warehouseId,
    required DateTime documentDate,
  }) async {
    await _initializationGuard?.assertInitialized();
    final nowEpoch = DateTime.now().millisecondsSinceEpoch;
    final rate = (document.exchangeRate > 0) ? document.exchangeRate : 1.0;
    double totalValue = 0.0;

    await _db.transaction(() async {
      for (final line in lines) {
        // Defensive check: skip if line is already posted
        final dbLine = await (_db.select(_db.stockMovementLines)
              ..where((tbl) => tbl.uuid.equals(line.lineUuid)))
            .getSingleOrNull();

        if (dbLine != null && dbLine.postedAt != null) {
          totalValue += (dbLine.postedCost ?? 0.0) * dbLine.quantity;
          continue;
        }

        final baseUnitCost = line.unitCost * rate;
        final lineTotalCost = line.quantity * baseUnitCost;

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
          totalCost: lineTotalCost,
          closed: false,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          companyId: _currentCompanyId,
        );

        await _costLayerService.createLayer(layer);
        await _adjustProductQty(line.itemCode, warehouseId, line.quantity);

        // Update line posted details
        await (_db.update(_db.stockMovementLines)
              ..where((tbl) => tbl.uuid.equals(line.lineUuid)))
            .write(
          StockMovementLinesCompanion(
            postedCost: Value(baseUnitCost),
            postedAt: Value(nowEpoch),
          ),
        );

        totalValue += lineTotalCost;
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
    await _initializationGuard?.assertInitialized();
    final nowEpoch = DateTime.now().millisecondsSinceEpoch;
    double totalCogs = 0.0;

    await _db.transaction(() async {
      for (final line in lines) {
        // Defensive check: skip if line is already posted
        final dbLine = await (_db.select(_db.stockMovementLines)
              ..where((tbl) => tbl.uuid.equals(line.lineUuid)))
            .getSingleOrNull();

        if (dbLine != null && dbLine.postedAt != null) {
          totalCogs += (dbLine.postedCost ?? 0.0) * dbLine.quantity;
          continue;
        }

        final effectiveValuationMethod = _inheritanceResolver != null
            ? (await _inheritanceResolver.resolveForProduct(
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

        if (consumptionResult.isShortage) {
          throw JournalException(
            JournalException.insufficientStock,
            'Insufficient cost layer stock available for line item ${line.itemCode}. Shortage: ${consumptionResult.shortageQty}',
          );
        }

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
    await _initializationGuard?.assertInitialized();
    final nowEpoch = DateTime.now().millisecondsSinceEpoch;
    double totalTransferredValue = 0.0;

    await _db.transaction(() async {
      for (final line in lines) {
        // Defensive check: skip if line is already posted
        final dbLine = await (_db.select(_db.stockMovementLines)
              ..where((tbl) => tbl.uuid.equals(line.lineUuid)))
            .getSingleOrNull();

        if (dbLine != null && dbLine.postedAt != null) {
          totalTransferredValue += (dbLine.postedCost ?? 0.0) * dbLine.quantity;
          continue;
        }

        final effectiveValuationMethod = _inheritanceResolver != null
            ? (await _inheritanceResolver.resolveForProduct(
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

        if (consumptionResult.isShortage) {
          throw JournalException(
            JournalException.insufficientStock,
            'Insufficient cost layer stock in source warehouse $fromWarehouseId for ${line.itemCode}. Shortage: ${consumptionResult.shortageQty}',
          );
        }

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
          companyId: _currentCompanyId,
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
    await _initializationGuard?.assertInitialized();
    await _db.transaction(() async {
      switch (document.documentType) {
        case InventoryDocumentType.stockReceipt:
          final lines = await (_db.select(_db.stockMovementLines)
                ..where((tbl) => tbl.movementUuid.equals(document.documentId)))
              .get();

          for (final line in lines) {
            await _adjustProductQty(line.itemCode, document.warehouseId, -line.quantity);
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
          }

          await _setDocumentStatus(document, InventoryDocumentStatus.draft, null);
          break;

        case InventoryDocumentType.stockReturn:
          final returns = await (_db.select(_db.stockReturns)
                ..where((tbl) => tbl.uuid.equals(document.documentId)))
              .get();

          if (returns.isNotEmpty) {
            final ret = returns.first;
            final isPurchaseReturn = ret.returnType == 'purchase_return' || ret.returnType == 'purchaseReturn';

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
    double deltaQty, {
    String? companyId,
  }) async {
    final effectiveCompanyId = companyId ?? _currentCompanyId;

    if (deltaQty < 0) {
      final reqQty = -deltaQty;

      // 1. Check overall product table stock
      final prodQuery = _db.select(_db.products)
        ..where((p) =>
            p.itemCode.equals(itemCode) &
            p.companyId.equals(effectiveCompanyId));
      final prods = await prodQuery.get();

      final availProd = prods.isNotEmpty ? prods.first.onHandQty : 0.0;
      if (availProd < reqQty - 0.000001) {
        throw JournalException(
          JournalException.insufficientStock,
          'Insufficient product stock available for $itemCode. Required: $reqQty, Available: $availProd',
        );
      }

      final p = prods.first;
      final newQty = p.onHandQty + deltaQty;
      final updatedProdCount = await (_db.update(_db.products)
            ..where((tbl) =>
                tbl.id.equals(p.id) &
                tbl.companyId.equals(effectiveCompanyId) &
                tbl.onHandQty.isBiggerOrEqualValue(reqQty)))
          .write(
        ProductsCompanion(onHandQty: Value(newQty)),
      );

      if (updatedProdCount == 0) {
        throw JournalException(
          JournalException.insufficientStock,
          'Insufficient product stock available for $itemCode due to concurrent inventory consumption.',
        );
      }

      // 2. Check warehouse-specific stock if warehouseId is provided
      if (warehouseId != null && warehouseId.isNotEmpty) {
        final whQuery = _db.select(_db.productWarehouseStocks)
          ..where((w) =>
              w.itemCode.equals(itemCode) &
              w.warehouseId.equals(warehouseId) &
              w.companyId.equals(effectiveCompanyId));

        final whStocks = await whQuery.get();
        final availWh = whStocks.isNotEmpty ? whStocks.first.onHandQty : 0.0;

        if (availWh < reqQty - 0.000001) {
          throw JournalException(
            JournalException.insufficientStock,
            'Insufficient warehouse stock available for $itemCode in warehouse $warehouseId. Required: $reqQty, Available: $availWh',
          );
        }

        final whStock = whStocks.first;
        final newWhQty = whStock.onHandQty + deltaQty;

        final updatedWhCount = await (_db.update(_db.productWarehouseStocks)
              ..where((w) =>
                  w.uuid.equals(whStock.uuid) &
                  w.companyId.equals(effectiveCompanyId) &
                  w.onHandQty.isBiggerOrEqualValue(reqQty)))
            .write(
          ProductWarehouseStocksCompanion(onHandQty: Value(newWhQty)),
        );

        if (updatedWhCount == 0) {
          throw JournalException(
            JournalException.insufficientStock,
            'Insufficient warehouse stock available for $itemCode in warehouse $warehouseId due to concurrent inventory consumption.',
          );
        }
      }
    } else {
      // Inbound / Positive deltaQty: Increment stock
      final prodQuery = _db.select(_db.products)
        ..where((p) =>
            p.itemCode.equals(itemCode) &
            p.companyId.equals(effectiveCompanyId));
      final prods = await prodQuery.get();

      if (prods.isNotEmpty) {
        final p = prods.first;
        final newQty = p.onHandQty + deltaQty;
        await (_db.update(_db.products)
              ..where((tbl) =>
                  tbl.id.equals(p.id) &
                  tbl.companyId.equals(effectiveCompanyId)))
            .write(
          ProductsCompanion(onHandQty: Value(newQty)),
        );
      } else {
        await _db.into(_db.products).insert(
              ProductsCompanion(
                uuid: Value(generateUuidV4()),
                itemCode: Value(itemCode),
                name: Value(itemCode),
                packSize: const Value(1),
                price: const Value(0.0),
                onHandQty: Value(deltaQty),
                createdAt: Value(DateTime.now().millisecondsSinceEpoch),
                updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
                companyId: Value(effectiveCompanyId),
              ),
            );
      }

      if (warehouseId != null && warehouseId.isNotEmpty) {
        final whQuery = _db.select(_db.productWarehouseStocks)
          ..where((w) =>
              w.itemCode.equals(itemCode) &
              w.warehouseId.equals(warehouseId) &
              w.companyId.equals(effectiveCompanyId));

        final whStocks = await whQuery.get();

        if (whStocks.isNotEmpty) {
          final whStock = whStocks.first;
          final newWhQty = whStock.onHandQty + deltaQty;
          await (_db.update(_db.productWarehouseStocks)
                ..where((w) =>
                    w.uuid.equals(whStock.uuid) &
                    w.companyId.equals(effectiveCompanyId)))
              .write(
            ProductWarehouseStocksCompanion(onHandQty: Value(newWhQty)),
          );
        } else {
          await _db.into(_db.productWarehouseStocks).insert(
                ProductWarehouseStocksCompanion(
                  uuid: Value(generateUuidV4()),
                  itemCode: Value(itemCode),
                  warehouseId: Value(warehouseId),
                  onHandQty: Value(deltaQty),
                  createdAt: Value(DateTime.now().millisecondsSinceEpoch),
                  updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
                  companyId: Value(effectiveCompanyId),
                ),
              );
        }
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
              ..where((tbl) =>
                  tbl.uuid.equals(doc.documentId) &
                  tbl.companyId.equals(_currentCompanyId)))
            .write(
          StockReceiptsCompanion(
            status: Value(statusStr),
            postedAt: postedAtEpoch != null ? Value(postedAtEpoch) : const Value.absent(),
          ),
        );
        if (postedAtEpoch == null) {
          await (_db.update(_db.stockMovementLines)
                ..where((tbl) => tbl.movementUuid.equals(doc.documentId)))
              .write(const StockMovementLinesCompanion(postedAt: Value(null), postedCost: Value(null)));
        }
        break;
      case InventoryDocumentType.stockIssue:
        await (_db.update(_db.stockIssues)
              ..where((tbl) =>
                  tbl.uuid.equals(doc.documentId) &
                  tbl.companyId.equals(_currentCompanyId)))
            .write(
          StockIssuesCompanion(
            status: Value(statusStr),
            postedAt: postedAtEpoch != null ? Value(postedAtEpoch) : const Value.absent(),
          ),
        );
        if (postedAtEpoch == null) {
          await (_db.update(_db.stockMovementLines)
                ..where((tbl) => tbl.movementUuid.equals(doc.documentId)))
              .write(const StockMovementLinesCompanion(postedAt: Value(null), postedCost: Value(null)));
        }
        break;
      case InventoryDocumentType.stockReturn:
        await (_db.update(_db.stockReturns)
              ..where((tbl) =>
                  tbl.uuid.equals(doc.documentId) &
                  tbl.companyId.equals(_currentCompanyId)))
            .write(
          StockReturnsCompanion(
            status: Value(statusStr),
            postedAt: postedAtEpoch != null ? Value(postedAtEpoch) : const Value.absent(),
          ),
        );
        if (postedAtEpoch == null) {
          await (_db.update(_db.stockMovementLines)
                ..where((tbl) => tbl.movementUuid.equals(doc.documentId)))
              .write(const StockMovementLinesCompanion(postedAt: Value(null), postedCost: Value(null)));
        }
        break;
      case InventoryDocumentType.stockTransfer:
        await (_db.update(_db.stockTransfers)
              ..where((tbl) =>
                  tbl.uuid.equals(doc.documentId) &
                  tbl.companyId.equals(_currentCompanyId)))
            .write(
          StockTransfersCompanion(
            status: Value(statusStr),
            postedAt: postedAtEpoch != null ? Value(postedAtEpoch) : const Value.absent(),
          ),
        );
        if (postedAtEpoch == null) {
          await (_db.update(_db.stockMovementLines)
                ..where((tbl) => tbl.movementUuid.equals(doc.documentId)))
              .write(const StockMovementLinesCompanion(postedAt: Value(null), postedCost: Value(null)));
        }
        break;

      default:
        break;
    }
  }
}
