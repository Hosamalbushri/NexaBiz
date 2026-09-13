import 'package:drift/drift.dart';
import 'package:stock_count/core/data/multi_tenant_repository_guard.dart';
import 'package:stock_count/core/auth/domain/services/local_authorization_guard.dart';
import 'package:stock_count/core/database/tenant_database_name.dart';
import 'package:stock_count/core/database/nexabiz_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import '../../domain/services/inventory_dependency_detector.dart';

class InventoryDependencyDetectorImpl implements InventoryDependencyDetector {
  InventoryDependencyDetectorImpl(this._db, [String Function()? readCompanyId])
    : _readCompanyId = readCompanyId;

  final NexabizDatabase _db;
  final String Function()? _readCompanyId;

  String get _currentCompanyId {
    final id = _readCompanyId?.call();
    return MultiTenantRepositoryGuard.enforceCompanyContext(
      companyId: id,
      activeCompanyId: id,
    );
  }

  @override
  Future<List<InventoryDocumentRef>> findDependentDocuments({
    required InventoryDocumentRef document,
  }) async {
    final visitedDocIds = <String>{document.documentId};
    final dependentDocs = <InventoryDocumentRef>[];

    await _collectDependencies(document, visitedDocIds, dependentDocs);

    // Sort dependent documents in reverse chronological order (newest first)
    dependentDocs.sort((a, b) => b.documentDate.compareTo(a.documentDate));

    return dependentDocs;
  }

  Future<void> _collectDependencies(
    InventoryDocumentRef currentDoc,
    Set<String> visitedDocIds,
    List<InventoryDocumentRef> results,
  ) async {
    final directDependents = await _findDirectDependents(currentDoc);

    for (final dep in directDependents) {
      if (!visitedDocIds.contains(dep.documentId)) {
        visitedDocIds.add(dep.documentId);
        results.add(dep);

        // Recursively find cascading dependencies for this dependent document
        await _collectDependencies(dep, visitedDocIds, results);
      }
    }
  }

  Future<List<InventoryDocumentRef>> _findDirectDependents(
    InventoryDocumentRef doc,
  ) async {
    final direct = <InventoryDocumentRef>[];

    // 1. Direct dependencies via Cost Layers & Consumptions (Inbound -> Outbound)
    final layers =
        await (_db.select(_db.inventoryCostLayers)..where(
              (tbl) =>
                  tbl.movementUuid.equals(doc.documentId) &
                  tbl.companyId.equals(_currentCompanyId) &
                  tbl.deletedAt.isNull(),
            ))
            .get();

    for (final layer in layers) {
      final consumptions = await (_db.select(
        _db.inventoryCostConsumptions,
      )..where((tbl) => tbl.layerUuid.equals(layer.id))).get();

      for (final cons in consumptions) {
        final lineUuid = cons.issueLineUuid;

        // Check if lineUuid belongs to a stock_movement_line
        final lines = await (_db.select(
          _db.stockMovementLines,
        )..where((tbl) => tbl.id.equals(lineUuid))).get();

        if (lines.isNotEmpty) {
          final l = lines.first;
          final headerUuid = l.receiptId ?? l.issueId ?? l.returnId ?? l.transferId ?? '';

          // Check Stock Issue
          final issues =
              await (_db.select(_db.stockIssues)
                    ..where((tbl) => tbl.id.equals(headerUuid))
                    ..where((tbl) => tbl.deletedAt.isNull()))
                  .get();

          if (issues.isNotEmpty) {
            final issueRow = issues.first;
            final status = InventoryDocumentStatus.fromStorage(issueRow.status);
            if (status == InventoryDocumentStatus.posted) {
              direct.add(
                InventoryDocumentRef(
                  documentId: issueRow.id,
                  documentNumber: issueRow.issueNumber,
                  documentType: InventoryDocumentType.stockIssue,
                  documentDate: DateTime.fromMillisecondsSinceEpoch(
                    issueRow.issueDate,
                  ),
                  warehouseId: issueRow.warehouse,
                  status: status,
                ),
              );
            }
          }

          // Check Stock Return
          final returns =
              await (_db.select(_db.stockReturns)
                    ..where((tbl) => tbl.id.equals(headerUuid))
                    ..where((tbl) => tbl.deletedAt.isNull()))
                  .get();

          if (returns.isNotEmpty) {
            final retRow = returns.first;
            final status = InventoryDocumentStatus.fromStorage(retRow.status);
            if (status == InventoryDocumentStatus.posted) {
              direct.add(
                InventoryDocumentRef(
                  documentId: retRow.id,
                  documentNumber: retRow.returnNumber,
                  documentType: InventoryDocumentType.stockReturn,
                  documentDate: DateTime.fromMillisecondsSinceEpoch(
                    retRow.returnDate,
                  ),
                  warehouseId: retRow.warehouse,
                  status: status,
                ),
              );
            }
          }

          // Check Stock Transfer
          final transfers =
              await (_db.select(_db.stockTransfers)
                    ..where((tbl) => tbl.id.equals(headerUuid))
                    ..where((tbl) => tbl.deletedAt.isNull()))
                  .get();

          if (transfers.isNotEmpty) {
            final trRow = transfers.first;
            final status = InventoryDocumentStatus.fromStorage(trRow.status);
            if (status == InventoryDocumentStatus.posted) {
              direct.add(
                InventoryDocumentRef(
                  documentId: trRow.id,
                  documentNumber: trRow.transferNumber,
                  documentType: InventoryDocumentType.stockTransfer,
                  documentDate: DateTime.fromMillisecondsSinceEpoch(
                    trRow.transferDate,
                  ),
                  warehouseId: trRow.fromWarehouseId,
                  status: status,
                ),
              );
            }
          }
        } else {
          // Outbound consumption from Sales Invoice or external movement
          direct.add(
            InventoryDocumentRef(
              documentId: cons.issueLineUuid,
              documentNumber: 'فاتورة مبيعات / سحب مخزني',
              documentType: InventoryDocumentType.salesInvoice,
              documentDate: DateTime.fromMillisecondsSinceEpoch(cons.createdAt),
              status: InventoryDocumentStatus.posted,
            ),
          );
        }
      }
    }

    // 2. Direct dependencies via originalDocumentId (e.g. StockReturn referencing an Issue/Receipt)
    final returnsReferencingDoc =
        await (_db.select(_db.stockReturns)
              ..where((tbl) => tbl.originalDocumentId.equals(doc.documentId))
              ..where((tbl) => tbl.deletedAt.isNull()))
            .get();

    for (final retRow in returnsReferencingDoc) {
      final status = InventoryDocumentStatus.fromStorage(retRow.status);
      if (status == InventoryDocumentStatus.posted) {
        direct.add(
          InventoryDocumentRef(
            documentId: retRow.id,
            documentNumber: retRow.returnNumber,
            documentType: InventoryDocumentType.stockReturn,
            documentDate: DateTime.fromMillisecondsSinceEpoch(
              retRow.returnDate,
            ),
            warehouseId: retRow.warehouse,
            status: status,
          ),
        );
      }
    }

    // 3. Chronological Downstream Stock Deficit Check:
    // Only block unposting if removing this document's quantity would cause a stock deficit (< 0)
    // on any subsequent outbound movement for the item.
    final docLines = await (_db.select(_db.stockMovementLines)..where(
          (tbl) =>
              tbl.receiptId.equals(doc.documentId) |
              tbl.issueId.equals(doc.documentId) |
              tbl.returnId.equals(doc.documentId) |
              tbl.transferId.equals(doc.documentId),
        )).get();

    final docDateEpoch = doc.documentDate.millisecondsSinceEpoch;

    for (final line in docLines) {
      final itemCode = line.itemCode;
      final targetWh = doc.warehouseId ?? '';

      if (targetWh.isEmpty) continue;

      // Get current stock balance for item in warehouse
      final whStocks = await (_db.select(_db.productWarehouseStocks)
            ..where(
              (w) =>
                  w.itemCode.equals(itemCode) &
                  w.warehouseId.equals(targetWh) &
                  w.companyId.equals(_currentCompanyId),
            ))
          .get();

      final currentOnHand = whStocks.isNotEmpty ? whStocks.first.onHandQty : 0.0;

      // If document is inbound (e.g. receipt), unposting will REDUCE stock balance by line.quantity
      // Check if currentOnHand - line.quantity < 0
      final isInbound = doc.documentType == InventoryDocumentType.stockReceipt ||
          (doc.documentType == InventoryDocumentType.stockReturn &&
              line.movementType == 'sales_return');

      if (isInbound && (currentOnHand - line.quantity) < -0.000001) {
        // Stock shortage would occur! Find the latest downstream outbound movement to flag as blocker.
        final subIssues = await (_db.select(_db.stockIssues)
              ..where((tbl) => tbl.warehouse.equals(targetWh))
              ..where((tbl) => tbl.issueDate.isBiggerThan(Constant(docDateEpoch)))
              ..where((tbl) => tbl.status.equals('posted'))
              ..where((tbl) => tbl.deletedAt.isNull()))
            .get();

        if (subIssues.isNotEmpty) {
          final iss = subIssues.first;
          final depRef = InventoryDocumentRef(
            documentId: iss.id,
            documentNumber: iss.issueNumber,
            documentType: InventoryDocumentType.stockIssue,
            documentDate: DateTime.fromMillisecondsSinceEpoch(iss.issueDate),
            warehouseId: iss.warehouse,
            status: InventoryDocumentStatus.posted,
          );
          if (!direct.contains(depRef)) direct.add(depRef);
        }
      }
    }

    return direct;
  }
}
