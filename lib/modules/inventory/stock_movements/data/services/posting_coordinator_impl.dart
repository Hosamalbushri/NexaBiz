import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_dependency_detector.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/stock_validation_service.dart';

class PostingCoordinatorImpl implements PostingCoordinator {
  PostingCoordinatorImpl({
    required InventoryDatabase db,
    required StockValidationService stockValidationService,
    required InventoryDependencyDetector dependencyDetector,
    required PostingEngine postingEngine,
    InventoryAccountingPoster? accountingPoster,
  })  : _db = db,
        _stockValidationService = stockValidationService,
        _dependencyDetector = dependencyDetector,
        _postingEngine = postingEngine,
        _accountingPoster = accountingPoster;

  final InventoryDatabase _db;
  final StockValidationService _stockValidationService;
  final InventoryDependencyDetector _dependencyDetector;
  final PostingEngine _postingEngine;
  final InventoryAccountingPoster? _accountingPoster;

  @override
  Future<PostResult> post({
    required InventoryDocumentRef document,
    String? userId,
  }) async {
    // 1. Fetch line items
    final dbLines = await (_db.select(_db.stockMovementLines)
          ..where((tbl) => tbl.movementUuid.equals(document.documentId)))
        .get();

    if (dbLines.isEmpty) {
      return const PostInvalidStatus(reason: 'المستند لا يحتوي على أصناف للترحيل.');
    }

    // 2. Validate outbound stock if outbound
    final isOutbound = document.documentType == InventoryDocumentType.stockIssue ||
        document.documentType == InventoryDocumentType.salesInvoice;

    if (isOutbound) {
      final outboundRequests = dbLines
          .map((l) => OutboundLineRequest(
                itemCode: l.itemCode,
                itemName: l.itemName,
                requestedQuantity: l.quantity,
              ))
          .toList();

      final shortages = await _stockValidationService.validateOutboundLines(
        lines: outboundRequests,
        warehouseId: document.warehouseId,
      );

      if (shortages.isNotEmpty) {
        return PostStockShortage(shortages: shortages);
      }
    }

    // 3. Execute Posting via PostingEngine
    double value = 0.0;
    if (document.documentType == InventoryDocumentType.stockReceipt) {
      final inboundLines = dbLines
          .map((l) => InboundLineData(
                lineUuid: l.uuid,
                itemCode: l.itemCode,
                itemName: l.itemName,
                quantity: l.quantity,
                unitCost: l.unitCost,
              ))
          .toList();

      value = await _postingEngine.applyInboundPosting(
        document: document,
        lines: inboundLines,
        warehouseId: document.warehouseId,
        documentDate: document.documentDate,
      );
    } else if (document.documentType == InventoryDocumentType.stockIssue) {
      final outboundLines = dbLines
          .map((l) => OutboundLineData(
                lineUuid: l.uuid,
                itemCode: l.itemCode,
                itemName: l.itemName,
                quantity: l.quantity,
              ))
          .toList();

      value = await _postingEngine.applyOutboundPosting(
        document: document,
        lines: outboundLines,
        warehouseId: document.warehouseId,
        valuationMethod: CostValuationMethod.fifo,
      );
    } else if (document.documentType == InventoryDocumentType.stockTransfer) {
      final transferLines = dbLines
          .map((l) => TransferLineData(
                lineUuid: l.uuid,
                itemCode: l.itemCode,
                itemName: l.itemName,
                quantity: l.quantity,
              ))
          .toList();

      final trs = await (_db.select(_db.stockTransfers)
            ..where((tbl) => tbl.uuid.equals(document.documentId)))
          .get();

      final fromWh = trs.isNotEmpty ? trs.first.fromWarehouseId : document.warehouseId ?? '';
      final toWh = trs.isNotEmpty ? trs.first.toWarehouseId : '';

      value = await _postingEngine.applyTransferPosting(
        document: document,
        lines: transferLines,
        fromWarehouseId: fromWh,
        toWarehouseId: toWh,
        valuationMethod: CostValuationMethod.fifo,
      );
    }

    // 4. Update Document Status in Database to posted & fetch accountId
    final now = DateTime.now().toUtc();
    String? docAccountId;

    if (document.documentType == InventoryDocumentType.stockReceipt) {
      final rec = await (_db.select(_db.stockReceipts)
            ..where((tbl) => tbl.uuid.equals(document.documentId)))
          .getSingleOrNull();
      docAccountId = rec?.accountId;

      await (_db.update(_db.stockReceipts)..where((tbl) => tbl.uuid.equals(document.documentId))).write(
        StockReceiptsCompanion(
          status: const Value('posted'),
          postedAt: Value(now.millisecondsSinceEpoch),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
    } else if (document.documentType == InventoryDocumentType.stockIssue) {
      final iss = await (_db.select(_db.stockIssues)
            ..where((tbl) => tbl.uuid.equals(document.documentId)))
          .getSingleOrNull();
      docAccountId = iss?.accountId;

      await (_db.update(_db.stockIssues)..where((tbl) => tbl.uuid.equals(document.documentId))).write(
        StockIssuesCompanion(
          status: const Value('posted'),
          postedAt: Value(now.millisecondsSinceEpoch),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
    }

    // 5. Post Accounting Journal Entry to General Ledger (isPosted = true)
    if (_accountingPoster != null && value > 0) {
      await _accountingPoster!.postAccountingEntry(
        document: document,
        totalAmount: value,
        accountId: docAccountId,
        isPosted: true,
      );
    }

    // 6. Write to InventoryAuditTrail
    await _recordAudit(
      documentId: document.documentId,
      documentType: document.documentType.storageValue,
      eventType: 'post',
      userId: userId,
    );

    final updatedDocRef = InventoryDocumentRef(
      documentId: document.documentId,
      documentNumber: document.documentNumber,
      documentType: document.documentType,
      documentDate: document.documentDate,
      warehouseId: document.warehouseId,
      status: InventoryDocumentStatus.posted,
    );

    return PostSuccess(document: updatedDocRef, postedValue: value);
  }

  @override
  Future<UnpostResult> unpost({
    required InventoryDocumentRef document,
    String? requestedBy,
    String? reason,
  }) async {
    // 1. Check dependencies
    final dependentDocs = await _dependencyDetector.findDependentDocuments(
      document: document,
    );

    if (dependentDocs.isNotEmpty) {
      return UnpostBlockedByDependencies(
        dependentDocuments: dependentDocs,
        message: 'لا يمكن إلغاء الترحيل وجود حركات مرحّلة لاحقة تعتمد عليها.',
      );
    }

    // 2. Execute reverse posting
    await _postingEngine.reversePosting(document: document);

    // 3. Update Document Status in Database to draft
    final now = DateTime.now().toUtc();
    if (document.documentType == InventoryDocumentType.stockReceipt) {
      await (_db.update(_db.stockReceipts)..where((tbl) => tbl.uuid.equals(document.documentId))).write(
        StockReceiptsCompanion(
          status: const Value('draft'),
          postedAt: const Value(null),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
    } else if (document.documentType == InventoryDocumentType.stockIssue) {
      await (_db.update(_db.stockIssues)..where((tbl) => tbl.uuid.equals(document.documentId))).write(
        StockIssuesCompanion(
          status: const Value('draft'),
          postedAt: const Value(null),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
    }

    // 4. Update Accounting Journal Entry status to draft (isPosted = false)
    if (_accountingPoster != null) {
      await _accountingPoster!.setAccountingEntryPostingStatus(
        document: document,
        isPosted: false,
      );
    }

    // 5. Write to InventoryAuditTrail
    await _recordAudit(
      documentId: document.documentId,
      documentType: document.documentType.storageValue,
      eventType: 'unpost',
      userId: requestedBy,
      notes: reason,
    );

    return const UnpostSuccess();
  }

  Future<void> _recordAudit({
    required String documentId,
    required String documentType,
    required String eventType,
    String? userId,
    String? notes,
  }) async {
    await _db.into(_db.inventoryAuditTrail).insert(
          InventoryAuditTrailCompanion(
            uuid: Value(generateUuidV4()),
            documentId: Value(documentId),
            documentType: Value(documentType),
            eventType: Value(eventType),
            userId: Value(userId),
            notes: Value(notes),
            timestamp: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  }
}
