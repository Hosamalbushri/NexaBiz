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

          // Check if it's a posted Stock Issue
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

          // Check if it's a posted Stock Return
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

    // 3. Subsequent Posted Movements (Chronological Sequence Enforcement)
    int? docPostedAt;
    int? docDate;

    if (doc.documentType == InventoryDocumentType.stockReceipt) {
      final rec = await (_db.select(_db.stockReceipts)
            ..where((tbl) => tbl.uuid.equals(doc.documentId)))
          .getSingleOrNull();
      if (rec != null) {
        docPostedAt = rec.postedAt;
        docDate = rec.receiptDate;
      }
    } else if (doc.documentType == InventoryDocumentType.stockIssue) {
      final iss = await (_db.select(_db.stockIssues)
            ..where((tbl) => tbl.uuid.equals(doc.documentId)))
          .getSingleOrNull();
      if (iss != null) {
        docPostedAt = iss.postedAt;
        docDate = iss.issueDate;
      }
    } else if (doc.documentType == InventoryDocumentType.stockReturn) {
      final ret = await (_db.select(_db.stockReturns)
            ..where((tbl) => tbl.uuid.equals(doc.documentId)))
          .getSingleOrNull();
      if (ret != null) {
        docPostedAt = ret.postedAt;
        docDate = ret.returnDate;
      }
    } else if (doc.documentType == InventoryDocumentType.stockTransfer) {
      final trf = await (_db.select(_db.stockTransfers)
            ..where((tbl) => tbl.uuid.equals(doc.documentId)))
          .getSingleOrNull();
      if (trf != null) {
        docPostedAt = trf.postedAt;
        docDate = trf.transferDate;
      }
    }

    final benchmarkTs = docPostedAt ?? docDate ?? doc.documentDate.millisecondsSinceEpoch;

    // Subsequent posted StockReceipts
    final allReceipts = await (_db.select(_db.stockReceipts)
          ..where((tbl) => tbl.status.equals('posted'))
          ..where((tbl) => tbl.deletedAt.isNull()))
        .get();

    for (final rec in allReceipts) {
      if (rec.uuid == doc.documentId) continue;
      final pAt = rec.postedAt ?? rec.receiptDate;
      if (pAt > benchmarkTs) {
        direct.add(
          InventoryDocumentRef(
            documentId: rec.uuid,
            documentNumber: rec.receiptNumber,
            documentType: InventoryDocumentType.stockReceipt,
            documentDate: DateTime.fromMillisecondsSinceEpoch(rec.receiptDate),
            status: InventoryDocumentStatus.posted,
          ),
        );
      }
    }

    // Subsequent posted StockIssues
    final allIssues = await (_db.select(_db.stockIssues)
          ..where((tbl) => tbl.status.equals('posted'))
          ..where((tbl) => tbl.deletedAt.isNull()))
        .get();

    for (final iss in allIssues) {
      if (iss.uuid == doc.documentId) continue;
      final pAt = iss.postedAt ?? iss.issueDate;
      if (pAt > benchmarkTs) {
        direct.add(
          InventoryDocumentRef(
            documentId: iss.uuid,
            documentNumber: iss.issueNumber,
            documentType: InventoryDocumentType.stockIssue,
            documentDate: DateTime.fromMillisecondsSinceEpoch(iss.issueDate),
            warehouseId: iss.warehouse,
            status: InventoryDocumentStatus.posted,
          ),
        );
      }
    }

    // Subsequent posted StockReturns
    final allReturns = await (_db.select(_db.stockReturns)
          ..where((tbl) => tbl.status.equals('posted'))
          ..where((tbl) => tbl.deletedAt.isNull()))
        .get();

    for (final ret in allReturns) {
      if (ret.uuid == doc.documentId) continue;
      final pAt = ret.postedAt ?? ret.returnDate;
      if (pAt > benchmarkTs) {
        direct.add(
          InventoryDocumentRef(
            documentId: ret.uuid,
            documentNumber: ret.returnNumber,
            documentType: InventoryDocumentType.stockReturn,
            documentDate: DateTime.fromMillisecondsSinceEpoch(ret.returnDate),
            warehouseId: ret.warehouse,
            status: InventoryDocumentStatus.posted,
          ),
        );
      }
    }

    // Subsequent posted StockTransfers
    final allTransfers = await (_db.select(_db.stockTransfers)
          ..where((tbl) => tbl.status.equals('posted'))
          ..where((tbl) => tbl.deletedAt.isNull()))
        .get();

    for (final trf in allTransfers) {
      if (trf.uuid == doc.documentId) continue;
      final pAt = trf.postedAt ?? trf.transferDate;
      if (pAt > benchmarkTs) {
        direct.add(
          InventoryDocumentRef(
            documentId: trf.uuid,
            documentNumber: trf.transferNumber,
            documentType: InventoryDocumentType.stockTransfer,
            documentDate: DateTime.fromMillisecondsSinceEpoch(trf.transferDate),
            warehouseId: trf.fromWarehouseId,
            status: InventoryDocumentStatus.posted,
          ),
        );
      }
    }

    return direct;
  }
}
