import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/authentication/data/local_auth_store.dart';
import 'package:stock_count/modules/inventory/shared/data/database/inventory_database.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/enums/cost_valuation_method.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_dependency_detector.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_coordinator.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/posting_engine.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/stock_validation_service.dart';

import 'package:stock_count/core/domain/ports/period_validator_port.dart';
import 'package:stock_count/core/errors/journal_exception.dart';
import 'package:stock_count/core/errors/missing_account_exception.dart';
import 'package:stock_count/modules/sync/sync.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_accounting_poster.dart';

import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/modules/inventory/permissions/inventory_permission_package.dart';

import 'package:stock_count/modules/system_setup/domain/services/initialization_guard.dart';

class PostingCoordinatorImpl implements PostingCoordinator {
  PostingCoordinatorImpl({
    required InventoryDatabase db,
    required StockValidationService stockValidationService,
    required InventoryDependencyDetector dependencyDetector,
    required PostingEngine postingEngine,
    PeriodValidatorPort? periodValidator,
    required InventoryAccountingPoster accountingPoster,
    required PermissionGuard permissionGuard,
    String Function()? readCompanyId,
    SyncQueue? syncQueue,
    InitializationGuard? initializationGuard,
  })  : _db = db,
        _stockValidationService = stockValidationService,
        _dependencyDetector = dependencyDetector,
        _postingEngine = postingEngine,
        _periodValidator = periodValidator,
        _accountingPoster = accountingPoster,
        _permissionGuard = permissionGuard,
        _readCompanyId = readCompanyId,
        _syncQueue = syncQueue,
        _initializationGuard = initializationGuard;

  final InventoryDatabase _db;
  final StockValidationService _stockValidationService;
  final InventoryDependencyDetector _dependencyDetector;
  final PostingEngine _postingEngine;
  final PeriodValidatorPort? _periodValidator;
  final InventoryAccountingPoster _accountingPoster;
  final PermissionGuard _permissionGuard;
  final String Function()? _readCompanyId;
  final SyncQueue? _syncQueue;
  final InitializationGuard? _initializationGuard;


  String get _currentCompanyId =>
      _readCompanyId?.call() ?? LocalAuthDefaults.companyId;

  final Map<String, Completer<void>> _activePostingLocks = {};

  Future<T> _synchronizedDocument<T>(String documentId, Future<T> Function() action) async {
    while (_activePostingLocks.containsKey(documentId)) {
      try {
        await _activePostingLocks[documentId]!.future;
      } catch (_) {}
    }

    final completer = Completer<void>();
    _activePostingLocks[documentId] = completer;

    try {
      return await action();
    } finally {
      if (!completer.isCompleted) {
        completer.complete();
      }
      _activePostingLocks.remove(documentId);
    }
  }

  @override
  Future<PostResult> post({
    required InventoryDocumentRef document,
    String? userId,
  }) async {
    await _initializationGuard?.assertInitialized();

    final requiredPostPermissions = switch (document.documentType) {
      InventoryDocumentType.stockReceipt => InventoryPermissions.receiptsPost,
      InventoryDocumentType.stockIssue => InventoryPermissions.issuesPost,
      InventoryDocumentType.stockTransfer => InventoryPermissions.transfersPost,
      InventoryDocumentType.stockReturn => InventoryPermissions.returnsPost,
      _ => InventoryPermissions.receiptsPost,
    };
    try {
      _permissionGuard.requireAny(requiredPostPermissions);
    } on PermissionDeniedException catch (e) {
      await _recordAudit(
        documentId: document.documentId,
        documentType: document.documentType.storageValue,
        eventType: 'unauthorized_attempt',
        userId: userId,
        notes: 'مرفوض: لا تملك صلاحية ترحيل مستندات المخزون',
        metadata: {
          'operation': 'post',
          'errorReason': e.toString(),
        },
      );
      rethrow;
    }

    return _synchronizedDocument(document.documentId, () async {
      final dbCompanyId = await _getDatabaseCompanyId(document);
      if (dbCompanyId != null && dbCompanyId != _currentCompanyId) {
        return const PostInvalidStatus(reason: 'مستند تابع لشركة أخرى');
      }


      bool accountingPosted = false;
      try {
        return await _db.transaction(() async {
          // 1. Check current persisted status in database for authoritative idempotency & stale UI prevention
          final currentDbStatus = await _getDatabaseStatus(document);
          if (currentDbStatus == 'posted') {
            // Idempotent return: Document is ALREADY posted in the database!
            final dbLines = await (_db.select(_db.stockMovementLines)
                  ..where((tbl) => tbl.movementUuid.equals(document.documentId)))
                .get();
            double value = 0.0;
            for (final l in dbLines) {
              value += (l.postedCost ?? l.unitCost) * l.quantity;
            }

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

          if (currentDbStatus == 'cancelled') {
            return const PostInvalidStatus(reason: 'المستند ملغي ولا يمكن ترحيله');
          }

          // 1.5. Validate Accounting Period before performing any inventory cost/stock mutations
          if (_periodValidator != null) {
            try {
              await _periodValidator!.assertEntryAllowed(document.documentDate);
            } on JournalException catch (e) {
              await _recordAudit(
                documentId: document.documentId,
                documentType: document.documentType.storageValue,
                eventType: 'unauthorized_attempt',
                userId: userId,
                notes: 'لا يمكن ترحيل المستند: الفترة المحاسبية مغلقة للمستند بتاريخ ${document.documentDate}. (${e.message})',
                metadata: {
                  'operation': 'post',
                  'errorReason': e.message,
                  'attemptedDate': document.documentDate.toIso8601String(),
                },
              );
              return PostInvalidStatus(
                reason: 'لا يمكن ترحيل المستند: الفترة المحاسبية مغلقة للمستند بتاريخ ${document.documentDate}. (${e.message})',
              );
            }
          }

          // 2. Fetch line items
          final dbLines = await (_db.select(_db.stockMovementLines)
                ..where((tbl) => tbl.movementUuid.equals(document.documentId)))
              .get();

          if (dbLines.isEmpty) {
            return const PostInvalidStatus(reason: 'المستند لا يحتوي على أصناف للترحيل.');
          }

          // 3. Validate outbound stock if outbound
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

          // 4. Validate unit cost
          for (final l in dbLines) {
            if (l.unitCost <= 0 || l.totalCost <= 0) {
              return PostInvalidStatus(
                reason: 'لا يمكن ترحيل المستند بتكلفة صفرية للصنف (${l.itemName}). يرجى إدخال التكلفة أولاً.',
              );
            }
          }

          // 5. Execute Posting via PostingEngine
          double value = 0.0;
          try {
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
            } else if (document.documentType == InventoryDocumentType.stockIssue ||
                document.documentType == InventoryDocumentType.salesInvoice) {
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
                valuationMethod: CostValuationMethod.weightedAverage,
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
                valuationMethod: CostValuationMethod.weightedAverage,
              );
            } else if (document.documentType == InventoryDocumentType.stockReturn) {
              final returns = await (_db.select(_db.stockReturns)
                    ..where((tbl) => tbl.uuid.equals(document.documentId)))
                  .get();

              if (returns.isNotEmpty) {
                final ret = returns.first;
                final isOutbound = ret.returnType == 'purchase_return' || ret.returnType == 'purchaseReturn';
                if (isOutbound) {
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
                } else {
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
                }
              }
            }
          } on JournalException catch (e) {
            if (e.code == JournalException.insufficientStock) {
              final shortages = dbLines
                  .map((l) => StockShortageItem(
                        itemCode: l.itemCode,
                        itemName: l.itemName,
                        requested: l.quantity,
                        available: 0.0,
                        shortage: l.quantity,
                      ))
                  .toList();
              return PostStockShortage(shortages: shortages);
            }
            rethrow;
          }

          // 5.5. Execute Accounting Posting inside the atomic database transaction
          final totalAmount = value > 0 ? value : dbLines.fold(0.0, (sum, l) => sum + l.totalCost);
          final docAccountId = await _resolveDocumentAccountId(document);
          await _accountingPoster.postAccountingEntry(
            document: document,
            totalAmount: totalAmount,
            accountId: docAccountId,
            isPosted: true,
          );
          accountingPosted = true;

          // 6. Update Document Status in Database to posted for all document types
          final now = DateTime.now().toUtc();
          await _updateDocumentStatusInDb(document.documentId, document.documentType, 'posted', now.millisecondsSinceEpoch);

          // 7. Write to InventoryAuditTrail (atomic inside transaction)
          await _recordAudit(
            documentId: document.documentId,
            documentType: document.documentType.storageValue,
            eventType: 'post',
            userId: userId,
            metadata: {
              'before': {'status': currentDbStatus ?? 'draft'},
              'after': {'status': 'posted', 'postedValue': value},
              'postedValue': value,
              'lineCount': dbLines.length,
            },
          );

          // 8. Enqueue Outbox Sync Operation
          if (_syncQueue != null) {
            await _syncQueue!.enqueue(
              SyncOperation.create(
                entityType: _getSyncEntityType(document.documentType),
                entityId: document.documentId,
                type: SyncOperationType.create,
                companyId: _currentCompanyId,
                payload: {
                  'documentId': document.documentId,
                  'documentNumber': document.documentNumber,
                  'documentType': document.documentType.storageValue,
                  'documentDate': document.documentDate.toIso8601String(),
                  'warehouseId': document.warehouseId,
                  'status': 'posted',
                  'companyId': _currentCompanyId,
                  'postedValue': value,
                  'lines': dbLines
                      .map((l) => {
                            'lineUuid': l.uuid,
                            'itemCode': l.itemCode,
                            'itemName': l.itemName,
                            'quantity': l.quantity,
                            'unitCost': l.unitCost,
                            'totalCost': l.totalCost,
                            'postedCost': l.postedCost,
                          })
                      .toList(),
                },
              ),
            );
          }

          final updatedDocRef = InventoryDocumentRef(
            documentId: document.documentId,
            documentNumber: document.documentNumber,
            documentType: document.documentType,
            documentDate: document.documentDate,
            warehouseId: document.warehouseId,
            status: InventoryDocumentStatus.posted,
          );

          return PostSuccess(document: updatedDocRef, postedValue: value);
        });
      } on JournalException catch (e) {
        return PostInvalidStatus(
          reason: 'فشل الترحيل المحاسبي: ${e.message}',
        );
      } on MissingAccountException catch (e) {
        return PostInvalidStatus(
          reason: 'فشل الترحيل المحاسبي: ${e.message}',
        );
      } catch (e) {
        if (accountingPosted) {
          try {
            await _accountingPoster.reverseAccountingEntry(document: document);
          } catch (compErr) {
            await _recordAudit(
              documentId: document.documentId,
              documentType: document.documentType.storageValue,
              eventType: 'compensation_failure',
              userId: userId,
              notes: 'فشل إلغاء القيد المحاسبي أثناء التعويض بعد فشل الترحيل: $compErr',
              metadata: {
                'postingError': e.toString(),
                'compensationError': compErr.toString(),
              },
            );
          }
        }
        rethrow;
      }
    });
  }

  @override
  Future<UnpostResult> unpost({
    required InventoryDocumentRef document,
    String? requestedBy,
    String? reason,
  }) async {
    await _initializationGuard?.assertInitialized();

    final requiredUnpostPermissions = switch (document.documentType) {
      InventoryDocumentType.stockReceipt => InventoryPermissions.receiptsReverse,
      InventoryDocumentType.stockIssue => InventoryPermissions.issuesReverse,
      InventoryDocumentType.stockTransfer => InventoryPermissions.transfersReverse,
      InventoryDocumentType.stockReturn => InventoryPermissions.returnsReverse,
      _ => InventoryPermissions.receiptsReverse,
    };
    try {
      _permissionGuard.requireAny(requiredUnpostPermissions);
    } on PermissionDeniedException catch (e) {
      await _recordAudit(
        documentId: document.documentId,
        documentType: document.documentType.storageValue,
        eventType: 'unauthorized_attempt',
        userId: requestedBy,
        notes: 'مرفوض: لا تملك صلاحية إلغاء ترحيل مستندات المخزون',
        metadata: {
          'operation': 'unpost',
          'errorReason': e.toString(),
        },
      );
      rethrow;
    }

    return _synchronizedDocument(document.documentId, () async {
      final dbCompanyId = await _getDatabaseCompanyId(document);
      if (dbCompanyId != null && dbCompanyId != _currentCompanyId) {
        return const UnpostBlockedByDependencies(
          dependentDocuments: [],
          message: 'مستند تابع لشركة أخرى',
        );
      }


      return await _db.transaction(() async {
        // 1. Check current persisted status in database for authoritative idempotency & unposting protection
        final currentDbStatus = await _getDatabaseStatus(document);
        if (currentDbStatus == 'draft' || currentDbStatus == null) {
          // Idempotent return: Document is ALREADY draft/unposted in the database!
          return const UnpostSuccess();
        }

        // 1.5. Validate Accounting Period before performing unpost reversal
        if (_periodValidator != null) {
          try {
            await _periodValidator!.assertEntryAllowed(document.documentDate);
          } on JournalException catch (e) {
            await _recordAudit(
              documentId: document.documentId,
              documentType: document.documentType.storageValue,
              eventType: 'unauthorized_attempt',
              userId: requestedBy,
              notes: 'لا يمكن إلغاء الترحيل: الفترة المحاسبية مغلقة للمستند بتاريخ ${document.documentDate}. (${e.message})',
              metadata: {
                'operation': 'unpost',
                'errorReason': e.message,
                'attemptedDate': document.documentDate.toIso8601String(),
              },
            );
            return UnpostBlockedByDependencies(
              dependentDocuments: const [],
              message: 'لا يمكن إلغاء الترحيل: الفترة المحاسبية مغلقة للمستند بتاريخ ${document.documentDate}. (${e.message})',
            );
          }
        }

        // 2. Check dependencies
        final dependentDocs = await _dependencyDetector.findDependentDocuments(
          document: document,
        );

        if (dependentDocs.isNotEmpty) {
          return UnpostBlockedByDependencies(
            dependentDocuments: dependentDocs,
            message: 'لا يمكن إلغاء الترحيل وجود حركات مرحّلة لاحقة تعتمد عليها.',
          );
        }

        // 3. Execute reverse posting via PostingEngine & Accounting Poster
        await _postingEngine.reversePosting(document: document);
        await _accountingPoster.reverseAccountingEntry(document: document);

        // 4. Update Document Status in Database to draft
        await _updateDocumentStatusInDb(document.documentId, document.documentType, 'draft', null);

        // 5. Write to InventoryAuditTrail
        await _recordAudit(
          documentId: document.documentId,
          documentType: document.documentType.storageValue,
          eventType: 'unpost',
          userId: requestedBy,
          notes: reason,
          metadata: {
            'reason': reason,
            'before': {'status': currentDbStatus ?? 'posted'},
            'after': {'status': 'draft'},
          },
        );

        // 6. Enqueue Outbox Reversal Sync Operation
        if (_syncQueue != null) {
          await _syncQueue!.enqueue(
            SyncOperation.create(
              entityType: 'inventory_reversal',
              entityId: document.documentId,
              type: SyncOperationType.update,
              companyId: _currentCompanyId,
              payload: {
                'documentId': document.documentId,
                'documentNumber': document.documentNumber,
                'documentType': document.documentType.storageValue,
                'action': 'unpost',
                'reason': reason,
                'requestedBy': requestedBy,
                'companyId': _currentCompanyId,
              },
            ),
          );
        }

        return const UnpostSuccess();
      });
    });
  }

  String _getSyncEntityType(InventoryDocumentType docType) {
    return docType.storageValue;
  }

  Future<String?> _getDatabaseStatus(InventoryDocumentRef document) async {
    switch (document.documentType) {
      case InventoryDocumentType.stockReceipt:
        final rec = await (_db.select(_db.stockReceipts)
              ..where((tbl) => tbl.uuid.equals(document.documentId)))
            .getSingleOrNull();
        return rec?.status;
      case InventoryDocumentType.stockIssue:
        final iss = await (_db.select(_db.stockIssues)
              ..where((tbl) => tbl.uuid.equals(document.documentId)))
            .getSingleOrNull();
        return iss?.status;
      case InventoryDocumentType.stockReturn:
        final ret = await (_db.select(_db.stockReturns)
              ..where((tbl) => tbl.uuid.equals(document.documentId)))
            .getSingleOrNull();
        return ret?.status;
      case InventoryDocumentType.stockTransfer:
        final tr = await (_db.select(_db.stockTransfers)
              ..where((tbl) => tbl.uuid.equals(document.documentId)))
            .getSingleOrNull();
        return tr?.status;
      default:
        final lines = await (_db.select(_db.stockMovementLines)
              ..where((tbl) => tbl.movementUuid.equals(document.documentId)))
            .get();
        if (lines.isNotEmpty && lines.every((l) => l.postedAt != null)) {
          return 'posted';
        }
        return null;
    }
  }

  Future<String?> _getDatabaseCompanyId(InventoryDocumentRef document) async {
    switch (document.documentType) {
      case InventoryDocumentType.stockReceipt:
        final rec = await (_db.select(_db.stockReceipts)
              ..where((tbl) => tbl.uuid.equals(document.documentId)))
            .getSingleOrNull();
        return rec?.companyId;
      case InventoryDocumentType.stockIssue:
        final iss = await (_db.select(_db.stockIssues)
              ..where((tbl) => tbl.uuid.equals(document.documentId)))
            .getSingleOrNull();
        return iss?.companyId;
      case InventoryDocumentType.stockReturn:
        final ret = await (_db.select(_db.stockReturns)
              ..where((tbl) => tbl.uuid.equals(document.documentId)))
            .getSingleOrNull();
        return ret?.companyId;
      case InventoryDocumentType.stockTransfer:
        final tr = await (_db.select(_db.stockTransfers)
              ..where((tbl) => tbl.uuid.equals(document.documentId)))
            .getSingleOrNull();
        return tr?.companyId;
      default:
        return null;
    }
  }

  Future<void> _updateDocumentStatusInDb(
    String documentId,
    InventoryDocumentType docType,
    String status,
    int? postedAtEpoch,
  ) async {
    final nowEpoch = DateTime.now().toUtc().millisecondsSinceEpoch;
    switch (docType) {
      case InventoryDocumentType.stockReceipt:
        await (_db.update(_db.stockReceipts)
              ..where((tbl) =>
                  tbl.uuid.equals(documentId) &
                  tbl.companyId.equals(_currentCompanyId)))
            .write(
          StockReceiptsCompanion(
            status: Value(status),
            postedAt: Value(postedAtEpoch),
            updatedAt: Value(nowEpoch),
          ),
        );
        break;
      case InventoryDocumentType.stockIssue:
        await (_db.update(_db.stockIssues)
              ..where((tbl) =>
                  tbl.uuid.equals(documentId) &
                  tbl.companyId.equals(_currentCompanyId)))
            .write(
          StockIssuesCompanion(
            status: Value(status),
            postedAt: Value(postedAtEpoch),
            updatedAt: Value(nowEpoch),
          ),
        );
        break;
      case InventoryDocumentType.stockReturn:
        await (_db.update(_db.stockReturns)
              ..where((tbl) =>
                  tbl.uuid.equals(documentId) &
                  tbl.companyId.equals(_currentCompanyId)))
            .write(
          StockReturnsCompanion(
            status: Value(status),
            postedAt: Value(postedAtEpoch),
            updatedAt: Value(nowEpoch),
          ),
        );
        break;
      case InventoryDocumentType.stockTransfer:
        await (_db.update(_db.stockTransfers)
              ..where((tbl) =>
                  tbl.uuid.equals(documentId) &
                  tbl.companyId.equals(_currentCompanyId)))
            .write(
          StockTransfersCompanion(
            status: Value(status),
            postedAt: Value(postedAtEpoch),
            updatedAt: Value(nowEpoch),
          ),
        );
        break;

      default:
        break;
    }
  }

  Future<String?> _resolveDocumentAccountId(InventoryDocumentRef document) async {
    switch (document.documentType) {
      case InventoryDocumentType.stockReceipt:
        final rec = await (_db.select(_db.stockReceipts)
              ..where((tbl) => tbl.uuid.equals(document.documentId)))
            .getSingleOrNull();
        return rec?.accountId;
      case InventoryDocumentType.stockIssue:
        final iss = await (_db.select(_db.stockIssues)
              ..where((tbl) => tbl.uuid.equals(document.documentId)))
            .getSingleOrNull();
        return iss?.accountId;
      default:
        return null;
    }
  }

  Future<void> _recordAudit({
    required String documentId,
    required String documentType,
    required String eventType,
    String? userId,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    final recent = await (_db.select(_db.inventoryAuditTrail)
          ..where((tbl) =>
              tbl.documentId.equals(documentId) &
              tbl.eventType.equals(eventType) &
              tbl.timestamp.isBiggerOrEqualValue(DateTime.now().millisecondsSinceEpoch - 100)))
        .get();

    if (recent.isNotEmpty) return;

    final eventUuid = generateUuidV4();
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await _db.into(_db.inventoryAuditTrail).insert(
          InventoryAuditTrailCompanion(
            uuid: Value(eventUuid),
            documentId: Value(documentId),
            documentType: Value(documentType),
            eventType: Value(eventType),
            userId: Value(userId),
            notes: Value(notes),
            timestamp: Value(nowMs),
            metadata: Value(metadata != null ? jsonEncode(metadata) : null),
            companyId: Value(_currentCompanyId),
          ),
        );

    if (_syncQueue != null) {
      await _syncQueue!.enqueue(
        SyncOperation.create(
          entityType: 'audit_event',
          entityId: eventUuid,
          type: SyncOperationType.create,
          companyId: _currentCompanyId,
          payload: {
            'uuid': eventUuid,
            'documentId': documentId,
            'documentType': documentType,
            'eventType': eventType,
            'userId': userId,
            'notes': notes,
            'timestamp': nowMs,
            'metadata': metadata,
            'companyId': _currentCompanyId,
          },
        ),
      );
    }
  }
}
