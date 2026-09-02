import 'package:stock_count/core/permissions/permission_guard.dart';
import 'package:stock_count/core/errors/journal_exception.dart';
import 'package:stock_count/modules/sales/permissions/sales_permission_package.dart';
import '../entities/sale.dart';
import '../entities/sale_item.dart';
import '../entities/sale_status.dart';
import '../models/sale_exception.dart';
import '../models/sale_list_filter.dart';
import '../repositories/sale_repository.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_accounting_bridge_port.dart';
import '../services/sale_calculation_service.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_inventory_effect_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_ledger_posting_port.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_number_allocator_port.dart';
import '../services/sale_validator.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_voucher_book_port.dart';
import '../services/sale_workflow_service.dart';

class WatchSales {
  const WatchSales(this._repository);

  final SaleRepository _repository;

  Stream<List<Sale>> call([SaleListFilter filter = const SaleListFilter()]) {
    return _repository.watchFiltered(filter);
  }
}

class GetSaleById {
  const GetSaleById(this._repository);

  final SaleRepository _repository;

  Future<Sale?> call(int id) => _repository.getById(id);
}

class CreateSale {
  CreateSale({
    required this._repository,
    required this._numberAllocator,
    required PermissionGuard permissionGuard,
    this._voucherBookPort = const NoOpSaleVoucherBookPort(),
    this._ledgerPosting = const NoOpSaleLedgerPostingPort(),
    this._accountingBridge =
        const NoOpSaleAccountingBridgePort(),
    this._validator = const SaleValidator(),
    this._calculator = const SaleCalculationService(),
  }) : _guard = permissionGuard;

  final SaleRepository _repository;
  final SaleNumberAllocatorPort _numberAllocator;
  final PermissionGuard _guard;
  final SaleVoucherBookPort _voucherBookPort;
  final SaleLedgerPostingPort _ledgerPosting;
  final SaleAccountingBridgePort _accountingBridge;
  final SaleValidator _validator;
  final SaleCalculationService _calculator;

  bool _isExecuting = false;

  Future<Sale> call(SaleDraft draft) async {
    if (_isExecuting) {
      throw const SaleException(SaleException.concurrentOperationBlocked);
    }
    _isExecuting = true;
    try {
      _guard.requireAny(SalesPermissions.create);
      final merged = _normalize(draft);
      _validator.validate(merged);
      final summary = _calculator.calculate(
        items: merged.items,
        saleDiscountType: merged.discountType,
        saleDiscountValue: merged.discountValue,
        taxRatePercent: merged.taxRate,
        paidAmount: merged.paidAmount,
      );
      _validator.assertPaidNotOverTotal(
        total: summary.total,
        paidAmount: merged.paidAmount,
      );
      final bookId = merged.voucherBookId?.trim();
      final saleNumber = (bookId != null && bookId.isNotEmpty)
          ? await _voucherBookPort.allocateSaleNumber(bookId)
          : await _numberAllocator.allocateNext();
      final sale = await _repository.insert(merged, saleNumber: saleNumber);

      final integrated = await _accountingBridge.isIntegratedMode;
      if (!integrated) {
        try {
          await _ledgerPosting.syncSale(sale);
        } on JournalException {
          await _repository.softDelete(sale.id);
          rethrow;
        } catch (_) {
          await _repository.softDelete(sale.id);
          throw const SaleException(SaleException.ledgerPostingFailed);
        }
      }
      return sale;
    } finally {
      _isExecuting = false;
    }
  }

  SaleDraft _normalize(SaleDraft draft) {
    return SaleDraft(
      saleDate: draft.saleDate,
      settlementType: draft.settlementType,
      voucherBookId: draft.voucherBookId,
      customerId: draft.customerId,
      customerCode: draft.customerCode,
      customerName: draft.customerName,
      customerAccountId: draft.customerAccountId,
      cashAccountId: draft.cashAccountId,
      currencyCode: draft.currencyCode,
      baseCurrencyCode: draft.baseCurrencyCode,
      exchangeRate: draft.exchangeRate,
      items: [
        for (final item in draft.items) item.withNormalizedQuantities(),
      ],
      discountType: draft.discountType,
      discountValue: draft.discountValue,
      taxRate: draft.taxRate,
      paidAmount: draft.paidAmount,
      paymentMethod: draft.paymentMethod,
      notes: draft.notes,
      saleStatus: draft.saleStatus,
      dataSource: draft.dataSource,
      externalId: draft.externalId,
      externalDocumentNumber: draft.externalDocumentNumber,
      externalStatus: draft.externalStatus,
      payments: draft.payments,
    );
  }
}

class UpdateSale {
  UpdateSale({
    required this._repository,
    this._validator = const SaleValidator(),
    this._calculator = const SaleCalculationService(),
    this._workflow = const SaleWorkflowService(),
    this._ledgerPosting = const NoOpSaleLedgerPostingPort(),
    this._accountingBridge =
        const NoOpSaleAccountingBridgePort(),
  });

  final SaleRepository _repository;
  final SaleValidator _validator;
  final SaleCalculationService _calculator;
  final SaleWorkflowService _workflow;
  final SaleLedgerPostingPort _ledgerPosting;
  final SaleAccountingBridgePort _accountingBridge;

  bool _isExecuting = false;

  Future<Sale> call(int id, SaleDraft draft) async {
    if (_isExecuting) {
      throw const SaleException(SaleException.concurrentOperationBlocked);
    }
    _isExecuting = true;
    try {
      final existing = await _repository.getById(id);
      if (existing == null) {
        throw const SaleException(SaleException.notFound);
      }
      _workflow.assertCanEdit(existing);
      final merged = SaleDraft(
        saleDate: draft.saleDate,
        settlementType: draft.settlementType,
        voucherBookId: draft.voucherBookId,
        customerId: draft.customerId,
        customerCode: draft.customerCode,
        customerName: draft.customerName,
        customerAccountId: draft.customerAccountId,
        cashAccountId: draft.cashAccountId,
        currencyCode: draft.currencyCode,
        baseCurrencyCode: draft.baseCurrencyCode,
        exchangeRate: draft.exchangeRate,
        items: [
          for (final item in draft.items) item.withNormalizedQuantities(),
        ],
        discountType: draft.discountType,
        discountValue: draft.discountValue,
        taxRate: draft.taxRate,
        paidAmount: draft.paidAmount,
        paymentMethod: draft.paymentMethod,
        notes: draft.notes,
        saleStatus: existing.saleStatus,
        dataSource: draft.dataSource,
        externalId: draft.externalId,
        externalDocumentNumber: draft.externalDocumentNumber,
        externalStatus: draft.externalStatus,
        payments: draft.payments,
      );
      _validator.validate(merged);
      final summary = _calculator.calculate(
        items: merged.items,
        saleDiscountType: merged.discountType,
        saleDiscountValue: merged.discountValue,
        taxRatePercent: merged.taxRate,
        paidAmount: merged.paidAmount,
      );
      _validator.assertPaidNotOverTotal(
        total: summary.total,
        paidAmount: merged.paidAmount,
      );
      final updated = await _repository.update(id, merged);

      final integrated = await _accountingBridge.isIntegratedMode;
      if (!integrated) {
        await _ledgerPosting.syncSale(updated);
      }
      return updated;
    } finally {
      _isExecuting = false;
    }
  }
}

/// Posts an unposted sale (UI label: Post / ترحيل).
class ConfirmSale {
  ConfirmSale({
    required this._repository,
    required this._accountingBridge,
    required this._inventoryEffect,
    required PermissionGuard permissionGuard,
    this._ledgerPosting = const NoOpSaleLedgerPostingPort(),
    this._workflow = const SaleWorkflowService(),
  }) : _guard = permissionGuard;

  final SaleRepository _repository;
  final SaleAccountingBridgePort _accountingBridge;
  final SaleInventoryEffectPort _inventoryEffect;
  final PermissionGuard _guard;
  final SaleLedgerPostingPort _ledgerPosting;
  final SaleWorkflowService _workflow;

  bool _isExecuting = false;

  Future<Sale> call(int id) async {
    if (_isExecuting) {
      throw const SaleException(SaleException.concurrentOperationBlocked);
    }
    _isExecuting = true;
    try {
      _guard.requireAny(SalesPermissions.post);
      if (!isSalePostingEnabled(_inventoryEffect)) {
        throw const SaleException(SaleException.postingRequiresInventory);
      }
      final sale = await _repository.getById(id);
      if (sale == null) {
        throw const SaleException(SaleException.notFound);
      }
      _workflow.assertCanPost(sale);
      final integrated = await _accountingBridge.isIntegratedMode;
      final next = _workflow.nextOnPost(integratedMode: integrated);
      final now = DateTime.now().toUtc();

      // Submit accounting against the projected post document first so a
      // bridge failure leaves the sale editable (still unposted).
      if (integrated) {
        final projected = sale.copyWith(
          saleStatus: next,
          confirmedAt: now,
          submittedAt: now,
        );
        try {
          await _accountingBridge.submitOperationalSale(projected);
        } catch (_) {
          throw const SaleException(SaleException.externalIntegrationFailed);
        }
      }

      final updated = await _repository.updateStatus(
        id,
        SaleStatusUpdate(
          saleStatus: next,
          confirmedAt: now,
          submittedAt: integrated ? now : null,
        ),
      );

      try {
        await _inventoryEffect.onConfirmed(updated);
      } catch (_) {
        // Roll back post so the document stays editable if stock effect fails.
        await _repository.updateStatus(
          id,
          SaleStatusUpdate(
            saleStatus: sale.saleStatus,
            clearConfirmedAt: true,
            clearSubmittedAt: true,
          ),
        );
        rethrow;
      }

      // Standalone sales upsert local journal as posted.
      // When perpetual inventory posting is enabled, DocumentPostingOrchestrator handles all journal posting (Revenue + COGS).
      if (!integrated && !isSalePostingEnabled(_inventoryEffect)) {
        try {
          await _ledgerPosting.syncSale(updated);
        } catch (e) {
          await _repository.updateStatus(
            id,
            SaleStatusUpdate(
              saleStatus: sale.saleStatus,
              clearConfirmedAt: true,
              clearSubmittedAt: true,
            ),
          );
          try {
            await _inventoryEffect.onCancelled(updated);
          } catch (_) {
            // Best-effort reverse; surface ledger failure to the caller.
          }
          if (e is JournalException) {
            rethrow;
          }
          throw const SaleException(SaleException.ledgerPostingFailed);
        }
      }
      return updated;
    } finally {
      _isExecuting = false;
    }
  }
}

class CancelSale {
  CancelSale({
    required this._repository,
    required this._inventoryEffect,
    required PermissionGuard permissionGuard,
    this._ledgerPosting = const NoOpSaleLedgerPostingPort(),
    this._workflow = const SaleWorkflowService(),
  }) : _guard = permissionGuard;

  final SaleRepository _repository;
  final SaleInventoryEffectPort _inventoryEffect;
  final PermissionGuard _guard;
  final SaleLedgerPostingPort _ledgerPosting;
  final SaleWorkflowService _workflow;

  Future<void> call(int id) async {
    _guard.requireAny(SalesPermissions.cancel);
    final sale = await _repository.getById(id);
    if (sale == null) {
      throw const SaleException(SaleException.notFound);
    }
    _workflow.assertCanCancel(sale);
    final hadInventoryEffect = sale.saleStatus.affectsInventory;

    if (!isSalePostingEnabled(_inventoryEffect)) {
      await _ledgerPosting.voidSale(sale);
    }

    if (hadInventoryEffect) {
      await _inventoryEffect.onCancelled(sale);
    }

    await _repository.softDelete(id);
  }
}

/// Complete is removed from the unposted/posted lifecycle.
class CompleteSale {
  CompleteSale({required this._repository});

  // Kept so existing providers/tests can construct the use case.
  // ignore: unused_field
  final SaleRepository _repository;

  Future<Sale> call(int id) async {
    throw const SaleException(SaleException.invalidStatusTransition);
  }
}

class DuplicateSale {
  DuplicateSale({
    required this._repository,
    required this._createSale,
  });

  final SaleRepository _repository;
  final CreateSale _createSale;

  Future<Sale> call(int id) async {
    final sale = await _repository.getById(id);
    if (sale == null) {
      throw const SaleException(SaleException.notFound);
    }
    return _createSale(
      SaleDraft(
        saleDate: DateTime.now().toUtc(),
        settlementType: sale.settlementType,
        voucherBookId: sale.voucherBookId,
        customerId: sale.customerId,
        customerCode: sale.customerCode,
        customerName: sale.customerName,
        customerAccountId: sale.customerAccountId,
        cashAccountId: sale.cashAccountId,
        currencyCode: sale.currencyCode,
        baseCurrencyCode: sale.baseCurrencyCode,
        exchangeRate: sale.exchangeRate,
        items: [
          for (final item in sale.items)
            SaleItemDraft.normalized(
              productId: item.productId,
              productName: item.productName,
              productCode: item.productCode,
              barcode: item.barcode,
              mainQuantity: item.mainQuantity,
              subQuantity: item.subQuantity,
              packSize: item.packSize,
              unitPrice: item.unitPrice,
              baseUnitPrice: item.baseUnitPrice,
              discountType: item.discountType,
              discountValue: item.discountValue,
            ),
        ],
        discountType: sale.discountType,
        discountValue: sale.discountValue,
        taxRate: sale.taxRate,
        paidAmount: 0,
        paymentMethod: sale.paymentMethod,
        notes: sale.notes,
      ),
    );
  }
}

class DeleteSale {
  const DeleteSale(this._repository);

  final SaleRepository _repository;

  Future<void> call(int id) => _repository.softDelete(id);
}
