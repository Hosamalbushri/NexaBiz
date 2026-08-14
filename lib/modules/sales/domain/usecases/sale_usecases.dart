import '../entities/sale.dart';
import '../entities/sale_item.dart';
import '../entities/sale_status.dart';
import '../models/sale_exception.dart';
import '../models/sale_list_filter.dart';
import '../repositories/sale_repository.dart';
import '../services/sale_accounting_bridge_port.dart';
import '../services/sale_calculation_service.dart';
import '../services/sale_inventory_effect_port.dart';
import '../services/sale_ledger_posting_port.dart';
import '../services/sale_number_allocator_port.dart';
import '../services/sale_validator.dart';
import '../services/sale_voucher_book_port.dart';
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
    required SaleRepository repository,
    required SaleNumberAllocatorPort numberAllocator,
    SaleVoucherBookPort voucherBookPort = const NoOpSaleVoucherBookPort(),
    SaleLedgerPostingPort ledgerPosting = const NoOpSaleLedgerPostingPort(),
    SaleAccountingBridgePort accountingBridge =
        const NoOpSaleAccountingBridgePort(),
    SaleValidator validator = const SaleValidator(),
    SaleCalculationService calculator = const SaleCalculationService(),
  }) : _repository = repository,
       _numberAllocator = numberAllocator,
       _voucherBookPort = voucherBookPort,
       _ledgerPosting = ledgerPosting,
       _accountingBridge = accountingBridge,
       _validator = validator,
       _calculator = calculator;

  final SaleRepository _repository;
  final SaleNumberAllocatorPort _numberAllocator;
  final SaleVoucherBookPort _voucherBookPort;
  final SaleLedgerPostingPort _ledgerPosting;
  final SaleAccountingBridgePort _accountingBridge;
  final SaleValidator _validator;
  final SaleCalculationService _calculator;

  Future<Sale> call(SaleDraft draft) async {
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
      } catch (_) {
        await _repository.softDelete(sale.id);
        throw const SaleException(SaleException.ledgerPostingFailed);
      }
    }
    return sale;
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
    required SaleRepository repository,
    SaleValidator validator = const SaleValidator(),
    SaleCalculationService calculator = const SaleCalculationService(),
    SaleWorkflowService workflow = const SaleWorkflowService(),
    SaleLedgerPostingPort ledgerPosting = const NoOpSaleLedgerPostingPort(),
    SaleAccountingBridgePort accountingBridge =
        const NoOpSaleAccountingBridgePort(),
  }) : _repository = repository,
       _validator = validator,
       _calculator = calculator,
       _workflow = workflow,
       _ledgerPosting = ledgerPosting,
       _accountingBridge = accountingBridge;

  final SaleRepository _repository;
  final SaleValidator _validator;
  final SaleCalculationService _calculator;
  final SaleWorkflowService _workflow;
  final SaleLedgerPostingPort _ledgerPosting;
  final SaleAccountingBridgePort _accountingBridge;

  Future<Sale> call(int id, SaleDraft draft) async {
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
  }
}

/// Posts an unposted sale (UI label: Post / ترحيل).
class ConfirmSale {
  ConfirmSale({
    required SaleRepository repository,
    required SaleAccountingBridgePort accountingBridge,
    required SaleInventoryEffectPort inventoryEffect,
    SaleLedgerPostingPort ledgerPosting = const NoOpSaleLedgerPostingPort(),
    SaleWorkflowService workflow = const SaleWorkflowService(),
  }) : _repository = repository,
       _accountingBridge = accountingBridge,
       _inventoryEffect = inventoryEffect,
       _ledgerPosting = ledgerPosting,
       _workflow = workflow;

  final SaleRepository _repository;
  final SaleAccountingBridgePort _accountingBridge;
  final SaleInventoryEffectPort _inventoryEffect;
  final SaleLedgerPostingPort _ledgerPosting;
  final SaleWorkflowService _workflow;

  Future<Sale> call(int id) async {
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
    // Integrated mode keeps operational submit only — no local ledger entry.
    if (!integrated) {
      try {
        await _ledgerPosting.syncSale(updated);
      } catch (_) {
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
        throw const SaleException(SaleException.ledgerPostingFailed);
      }
    }
    return updated;
  }
}

class CancelSale {
  CancelSale({
    required SaleRepository repository,
    required SaleInventoryEffectPort inventoryEffect,
    SaleLedgerPostingPort ledgerPosting = const NoOpSaleLedgerPostingPort(),
    SaleWorkflowService workflow = const SaleWorkflowService(),
  }) : _repository = repository,
       _inventoryEffect = inventoryEffect,
       _ledgerPosting = ledgerPosting,
       _workflow = workflow;

  final SaleRepository _repository;
  final SaleInventoryEffectPort _inventoryEffect;
  final SaleLedgerPostingPort _ledgerPosting;
  final SaleWorkflowService _workflow;

  Future<void> call(int id) async {
    final sale = await _repository.getById(id);
    if (sale == null) {
      throw const SaleException(SaleException.notFound);
    }
    _workflow.assertCanCancel(sale);
    final hadInventoryEffect = sale.saleStatus.affectsInventory;

    await _ledgerPosting.voidSale(sale);

    if (hadInventoryEffect) {
      await _inventoryEffect.onCancelled(sale);
    }

    await _repository.softDelete(id);
  }
}

/// Complete is removed from the unposted/posted lifecycle.
class CompleteSale {
  CompleteSale({required SaleRepository repository}) : _repository = repository;

  // Kept so existing providers/tests can construct the use case.
  // ignore: unused_field
  final SaleRepository _repository;

  Future<Sale> call(int id) async {
    throw const SaleException(SaleException.invalidStatusTransition);
  }
}

class DuplicateSale {
  DuplicateSale({
    required SaleRepository repository,
    required CreateSale createSale,
  }) : _repository = repository,
       _createSale = createSale;

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
