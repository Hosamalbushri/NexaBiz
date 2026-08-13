import '../entities/sale.dart';
import '../entities/sale_item.dart';
import '../entities/sale_status.dart';
import '../models/sale_exception.dart';
import '../models/sale_list_filter.dart';
import '../repositories/sale_repository.dart';
import '../services/sale_accounting_bridge_port.dart';
import '../services/sale_calculation_service.dart';
import '../services/sale_inventory_effect_port.dart';
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
    SaleValidator validator = const SaleValidator(),
    SaleCalculationService calculator = const SaleCalculationService(),
  }) : _repository = repository,
       _numberAllocator = numberAllocator,
       _voucherBookPort = voucherBookPort,
       _validator = validator,
       _calculator = calculator;

  final SaleRepository _repository;
  final SaleNumberAllocatorPort _numberAllocator;
  final SaleVoucherBookPort _voucherBookPort;
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
    return _repository.insert(merged, saleNumber: saleNumber);
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
  }) : _repository = repository,
       _validator = validator,
       _calculator = calculator,
       _workflow = workflow;

  final SaleRepository _repository;
  final SaleValidator _validator;
  final SaleCalculationService _calculator;
  final SaleWorkflowService _workflow;

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
    return _repository.update(id, merged);
  }
}

class ConfirmSale {
  ConfirmSale({
    required SaleRepository repository,
    required SaleAccountingBridgePort accountingBridge,
    required SaleInventoryEffectPort inventoryEffect,
    SaleWorkflowService workflow = const SaleWorkflowService(),
  }) : _repository = repository,
       _accountingBridge = accountingBridge,
       _inventoryEffect = inventoryEffect,
       _workflow = workflow;

  final SaleRepository _repository;
  final SaleAccountingBridgePort _accountingBridge;
  final SaleInventoryEffectPort _inventoryEffect;
  final SaleWorkflowService _workflow;

  Future<Sale> call(int id) async {
    final sale = await _repository.getById(id);
    if (sale == null) {
      throw const SaleException(SaleException.notFound);
    }
    _workflow.assertCanConfirm(sale);
    final integrated = await _accountingBridge.isIntegratedMode;
    final next = _workflow.nextOnConfirm(integratedMode: integrated);
    final now = DateTime.now().toUtc();
    final updated = await _repository.updateStatus(
      id,
      SaleStatusUpdate(
        saleStatus: next,
        confirmedAt: now,
        submittedAt: integrated ? now : null,
      ),
    );
    await _inventoryEffect.onConfirmed(updated);
    if (integrated) {
      try {
        await _accountingBridge.submitOperationalSale(updated);
      } catch (_) {
        throw const SaleException(SaleException.externalIntegrationFailed);
      }
    }
    return updated;
  }
}

class CancelSale {
  CancelSale({
    required SaleRepository repository,
    required SaleInventoryEffectPort inventoryEffect,
    SaleWorkflowService workflow = const SaleWorkflowService(),
  }) : _repository = repository,
       _inventoryEffect = inventoryEffect,
       _workflow = workflow;

  final SaleRepository _repository;
  final SaleInventoryEffectPort _inventoryEffect;
  final SaleWorkflowService _workflow;

  Future<Sale> call(int id) async {
    final sale = await _repository.getById(id);
    if (sale == null) {
      throw const SaleException(SaleException.notFound);
    }
    _workflow.assertCanCancel(sale);
    final hadInventoryEffect = sale.saleStatus.affectsInventory;
    final updated = await _repository.updateStatus(
      id,
      SaleStatusUpdate(
        saleStatus: SaleStatus.cancelled,
        cancelledAt: DateTime.now().toUtc(),
      ),
    );
    if (hadInventoryEffect) {
      await _inventoryEffect.onCancelled(updated);
    }
    return updated;
  }
}

class CompleteSale {
  CompleteSale({
    required SaleRepository repository,
    SaleWorkflowService workflow = const SaleWorkflowService(),
  }) : _repository = repository,
       _workflow = workflow;

  final SaleRepository _repository;
  final SaleWorkflowService _workflow;

  Future<Sale> call(int id) async {
    final sale = await _repository.getById(id);
    if (sale == null) {
      throw const SaleException(SaleException.notFound);
    }
    _workflow.assertCanComplete(sale);
    return _repository.updateStatus(
      id,
      SaleStatusUpdate(
        saleStatus: SaleStatus.completed,
        completedAt: DateTime.now().toUtc(),
      ),
    );
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
