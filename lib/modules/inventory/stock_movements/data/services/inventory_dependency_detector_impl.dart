import 'package:drift/drift.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import '../../domain/services/inventory_dependency_detector.dart';

class InventoryDependencyDetectorImpl implements InventoryDependencyDetector {
  InventoryDependencyDetectorImpl(this._db);

  final InventoryDatabase _db;

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
    final layers = await (_db.select(_db.inventoryCostLayers)
          ..where((tbl) => tbl.movementUuid.equals(doc.documentId))
          ..where((tbl) => tbl.deletedAt.isNull()))
        .get();

    for (final layer in layers) {
      final consumptions = await (_db.select(_db.inventoryCostConsumptions)
            ..where((tbl) => tbl.layerUuid.equals(layer.uuid)))
          .get();

      for (final cons in consumptions) {
        final lineUuid = cons.issueLineUuid;

        // Check if lineUuid belongs to a stock_movement_line
        final lines = await (_db.select(_db.stockMovementLines)
              ..where((tbl) => tbl.uuid.equals(lineUuid)))
            .get();

        if (lines.isNotEmpty) {
          final headerUuid = lines.first.movementUuid;

          // Check Stock Issue
          final issues = await (_db.select(_db.stockIssues)
                ..where((tbl) => tbl.uuid.equals(headerUuid))
                ..where((tbl) => tbl.deletedAt.isNull()))
              .get();

          if (issues.isNotEmpty) {
            final issueRow = issues.first;
            final status = InventoryDocumentStatus.fromStorage(issueRow.status);
            if (status == InventoryDocumentStatus.posted) {
              direct.add(
                InventoryDocumentRef(
                  documentId: issueRow.uuid,
                  documentNumber: issueRow.issueNumber,
                  documentType: InventoryDocumentType.stockIssue,
                  documentDate: DateTime.fromMillisecondsSinceEpoch(issueRow.issueDate),
                  warehouseId: issueRow.warehouse,
                  status: status,
                ),
              );
            }
          }

          // Check Stock Return
          final returns = await (_db.select(_db.stockReturns)
                ..where((tbl) => tbl.uuid.equals(headerUuid))
                ..where((tbl) => tbl.deletedAt.isNull()))
              .get();

          if (returns.isNotEmpty) {
            final retRow = returns.first;
            final status = InventoryDocumentStatus.fromStorage(retRow.status);
            if (status == InventoryDocumentStatus.posted) {
              direct.add(
                InventoryDocumentRef(
                  documentId: retRow.uuid,
                  documentNumber: retRow.returnNumber,
                  documentType: InventoryDocumentType.stockReturn,
                  documentDate: DateTime.fromMillisecondsSinceEpoch(retRow.returnDate),
                  warehouseId: retRow.warehouse,
                  status: status,
                ),
              );
            }
          }

          // Check Stock Transfer
          final transfers = await (_db.select(_db.stockTransfers)
                ..where((tbl) => tbl.uuid.equals(headerUuid))
                ..where((tbl) => tbl.deletedAt.isNull()))
              .get();

          if (transfers.isNotEmpty) {
            final trRow = transfers.first;
            final status = InventoryDocumentStatus.fromStorage(trRow.status);
            if (status == InventoryDocumentStatus.posted) {
              direct.add(
                InventoryDocumentRef(
                  documentId: trRow.uuid,
                  documentNumber: trRow.transferNumber,
                  documentType: InventoryDocumentType.stockTransfer,
                  documentDate: DateTime.fromMillisecondsSinceEpoch(trRow.transferDate),
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

    // 2. Direct dependencies via originalMovementUuid (e.g. StockReturn referencing an Issue/Receipt)
    final returnsReferencingDoc = await (_db.select(_db.stockReturns)
          ..where((tbl) => tbl.originalMovementUuid.equals(doc.documentId))
          ..where((tbl) => tbl.deletedAt.isNull()))
        .get();

    for (final retRow in returnsReferencingDoc) {
      final status = InventoryDocumentStatus.fromStorage(retRow.status);
      if (status == InventoryDocumentStatus.posted) {
        direct.add(
          InventoryDocumentRef(
            documentId: retRow.uuid,
            documentNumber: retRow.returnNumber,
            documentType: InventoryDocumentType.stockReturn,
            documentDate: DateTime.fromMillisecondsSinceEpoch(retRow.returnDate),
            warehouseId: retRow.warehouse,
            status: status,
          ),
        );
      }
    }

    // 3. Chronological Downstream Movements Check:
    // Check if any line item in doc has subsequent posted movements after doc.documentDate
    final docLines = await (_db.select(_db.stockMovementLines)
          ..where((tbl) => tbl.movementUuid.equals(doc.documentId)))
        .get();

    final itemCodes = docLines.map((l) => l.itemCode).toSet();
    final docDateEpoch = doc.documentDate.millisecondsSinceEpoch;

    for (final itemCode in itemCodes) {
      final subLines = await (_db.select(_db.stockMovementLines)
            ..where((tbl) => tbl.itemCode.equals(itemCode)))
          .get();

      for (final l in subLines) {
        if (l.movementUuid == doc.documentId) continue;

        // Check Stock Issue
        final subIssues = await (_db.select(_db.stockIssues)
              ..where((tbl) => tbl.uuid.equals(l.movementUuid))
              ..where((tbl) => tbl.issueDate.isBiggerThan(Constant(docDateEpoch)))
              ..where((tbl) => tbl.deletedAt.isNull()))
            .get();

        for (final iss in subIssues) {
          if (InventoryDocumentStatus.fromStorage(iss.status) == InventoryDocumentStatus.posted) {
            final depRef = InventoryDocumentRef(
              documentId: iss.uuid,
              documentNumber: iss.issueNumber,
              documentType: InventoryDocumentType.stockIssue,
              documentDate: DateTime.fromMillisecondsSinceEpoch(iss.issueDate),
              warehouseId: iss.warehouse,
              status: InventoryDocumentStatus.posted,
            );
            if (!direct.contains(depRef)) direct.add(depRef);
          }
        }

        // Check Stock Receipts
        final subReceipts = await (_db.select(_db.stockReceipts)
              ..where((tbl) => tbl.uuid.equals(l.movementUuid))
              ..where((tbl) => tbl.receiptDate.isBiggerThan(Constant(docDateEpoch)))
              ..where((tbl) => tbl.deletedAt.isNull()))
            .get();

        for (final rec in subReceipts) {
          if (InventoryDocumentStatus.fromStorage(rec.status) == InventoryDocumentStatus.posted) {
            final depRef = InventoryDocumentRef(
              documentId: rec.uuid,
              documentNumber: rec.receiptNumber,
              documentType: InventoryDocumentType.stockReceipt,
              documentDate: DateTime.fromMillisecondsSinceEpoch(rec.receiptDate),
              status: InventoryDocumentStatus.posted,
            );
            if (!direct.contains(depRef)) direct.add(depRef);
          }
        }
      }
    }

    return direct;
  }
}
