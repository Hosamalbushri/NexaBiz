import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/discount_type.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/entities/sale_settlement_type.dart';
import '../../domain/entities/sale_summary.dart';
import '../../domain/services/sale_calculation_service.dart';
import '../../domain/services/sale_currency_converter.dart';
import '../../domain/services/sale_customer_lookup_port.dart';
import '../../domain/services/sale_money.dart';
import '../../domain/services/sale_product_catalog_port.dart';
import '../../domain/services/sale_treasury_account_port.dart';
import '../../domain/services/sale_voucher_book_port.dart';
import 'sale_providers.dart';

/// Editable draft state for create / edit sale screens.
class SaleComposerState {
  const SaleComposerState({
    required this.saleDate,
    this.customer,
    this.walkInCustomerName,
    this.items = const [],
    this.discountType = DiscountType.fixed,
    this.discountValue = 0,
    this.taxRate = 0,
    this.paidAmount = 0,
    this.paymentMethod = PaymentMethod.cash,
    this.notes,
    this.editingSaleId,
    this.settlementType = SaleSettlementType.cash,
    this.voucherBook,
    this.previewSaleNumber,
    this.cashAccount,
    this.currencyCode = 'SAR',
    this.baseCurrencyCode = 'SAR',
    this.exchangeRate = 1,
  });

  final DateTime saleDate;
  final SaleSettlementType settlementType;
  final SaleVoucherBookRef? voucherBook;
  final String? previewSaleNumber;
  final SaleCustomerRef? customer;

  /// Free-text name for cash / walk-in sales (no Customers row).
  final String? walkInCustomerName;
  final SaleAccountRef? cashAccount;
  final String currencyCode;
  final String baseCurrencyCode;
  final double exchangeRate;
  final List<SaleItemDraft> items;
  final DiscountType discountType;
  final double discountValue;
  final double taxRate;
  final double paidAmount;
  final PaymentMethod paymentMethod;
  final String? notes;
  final int? editingSaleId;

  bool get isCredit => settlementType.isCredit;
  bool get isCash => settlementType.isCash;

  /// Display / snapshot name: linked customer wins, else walk-in text.
  String? get resolvedCustomerName {
    final linked = customer?.name.trim();
    if (linked != null && linked.isNotEmpty) {
      return linked;
    }
    final walkIn = walkInCustomerName?.trim();
    if (walkIn != null && walkIn.isNotEmpty) {
      return walkIn;
    }
    return null;
  }

  SaleComposerState copyWith({
    DateTime? saleDate,
    SaleSettlementType? settlementType,
    SaleVoucherBookRef? voucherBook,
    bool clearVoucherBook = false,
    String? previewSaleNumber,
    bool clearPreviewSaleNumber = false,
    SaleCustomerRef? customer,
    bool clearCustomer = false,
    String? walkInCustomerName,
    bool clearWalkInCustomerName = false,
    SaleAccountRef? cashAccount,
    bool clearCashAccount = false,
    String? currencyCode,
    String? baseCurrencyCode,
    double? exchangeRate,
    List<SaleItemDraft>? items,
    DiscountType? discountType,
    double? discountValue,
    double? taxRate,
    double? paidAmount,
    PaymentMethod? paymentMethod,
    String? notes,
    bool clearNotes = false,
    int? editingSaleId,
    bool clearEditingSaleId = false,
  }) {
    return SaleComposerState(
      saleDate: saleDate ?? this.saleDate,
      settlementType: settlementType ?? this.settlementType,
      voucherBook: clearVoucherBook ? null : (voucherBook ?? this.voucherBook),
      previewSaleNumber: clearPreviewSaleNumber
          ? null
          : (previewSaleNumber ?? this.previewSaleNumber),
      customer: clearCustomer ? null : (customer ?? this.customer),
      walkInCustomerName: clearWalkInCustomerName
          ? null
          : (walkInCustomerName ?? this.walkInCustomerName),
      cashAccount: clearCashAccount ? null : (cashAccount ?? this.cashAccount),
      currencyCode: currencyCode ?? this.currencyCode,
      baseCurrencyCode: baseCurrencyCode ?? this.baseCurrencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      items: items ?? this.items,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      taxRate: taxRate ?? this.taxRate,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: clearNotes ? null : (notes ?? this.notes),
      editingSaleId: clearEditingSaleId
          ? null
          : (editingSaleId ?? this.editingSaleId),
    );
  }

  SaleDraft toDraft() {
    return SaleDraft(
      saleDate: saleDate,
      settlementType: settlementType,
      voucherBookId: voucherBook?.bookId,
      customerId: customer?.customerId,
      customerCode: customer?.customerCode,
      customerName: resolvedCustomerName,
      customerAccountId: customer?.accountId,
      cashAccountId: settlementType.isCash ? cashAccount?.accountId : null,
      currencyCode: currencyCode,
      baseCurrencyCode: baseCurrencyCode,
      exchangeRate: exchangeRate,
      items: items,
      discountType: discountType,
      discountValue: discountValue,
      taxRate: taxRate,
      paidAmount: settlementType.isCash ? paidAmount : 0,
      paymentMethod: settlementType.isCredit
          ? PaymentMethod.credit
          : paymentMethod,
      notes: notes,
    );
  }
}

class SaleComposerController extends StateNotifier<SaleComposerState> {
  SaleComposerController({
    required SaleCalculationService calculator,
    required SaleProductCatalogPort catalog,
    SaleCurrencyConverter converter = const SaleCurrencyConverter(),
    double defaultTaxRate = 0,
    required String baseCurrencyCode,
  }) : _calculator = calculator,
       _catalog = catalog,
       _converter = converter,
       super(
         SaleComposerState(
           saleDate: DateTime.now(),
           taxRate: defaultTaxRate,
           currencyCode: baseCurrencyCode,
           baseCurrencyCode: baseCurrencyCode,
           exchangeRate: 1,
         ),
       );

  final SaleCalculationService _calculator;
  final SaleProductCatalogPort _catalog;
  final SaleCurrencyConverter _converter;

  SaleSummary get summary {
    final base = _calculator.calculate(
      items: state.items,
      saleDiscountType: state.discountType,
      saleDiscountValue: state.discountValue,
      taxRatePercent: state.taxRate,
      paidAmount: 0,
    );
    // Cash invoices are treated as fully paid (no paid field in the form).
    if (state.isCash) {
      return _calculator.calculate(
        items: state.items,
        saleDiscountType: state.discountType,
        saleDiscountValue: state.discountValue,
        taxRatePercent: state.taxRate,
        paidAmount: base.total,
      );
    }
    return base;
  }

  SaleDraft buildDraft() {
    final draft = state.toDraft();
    if (!state.isCash) {
      return draft;
    }
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
      items: draft.items,
      discountType: draft.discountType,
      discountValue: draft.discountValue,
      taxRate: draft.taxRate,
      paidAmount: summary.total,
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

  void loadFromSale(Sale sale) {
    state = SaleComposerState(
      saleDate: sale.saleDate.toLocal(),
      settlementType: sale.settlementType,
      voucherBook: sale.voucherBookId == null
          ? null
          : SaleVoucherBookRef(
              bookId: sale.voucherBookId!,
              name: sale.voucherBookId!,
              nextNumber: 0,
              canAllocate: false,
            ),
      previewSaleNumber: sale.saleNumber,
      customer: sale.customerId == null
          ? null
          : SaleCustomerRef(
              customerId: sale.customerId!,
              customerCode: sale.customerCode ?? '',
              name: sale.customerName ?? '',
              accountId: sale.customerAccountId,
            ),
      walkInCustomerName:
          sale.customerId == null ? sale.customerName : null,
      cashAccount: sale.cashAccountId == null
          ? null
          : SaleAccountRef(
              accountId: sale.cashAccountId!,
              code: '',
              name: sale.cashAccountId!,
            ),
      currencyCode: sale.currencyCode,
      baseCurrencyCode: sale.baseCurrencyCode,
      exchangeRate: sale.exchangeRate,
      items: [
        for (final item in sale.items)
          SaleItemDraft.normalized(
            lineUuid: item.uuid,
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
      discountType: DiscountType.fixed,
      discountValue: sale.discountValue,
      taxRate: sale.taxRate,
      paidAmount: sale.paidAmount,
      paymentMethod: sale.paymentMethod,
      notes: sale.notes,
      editingSaleId: sale.id,
    );
  }

  void setSaleDate(DateTime date) {
    state = state.copyWith(saleDate: date);
  }

  void setSettlementType(SaleSettlementType type) {
    final method = type.isCredit ? PaymentMethod.credit : PaymentMethod.cash;
    var paid = state.paidAmount;
    if (type.isCredit) {
      paid = 0;
    }
    state = state.copyWith(
      settlementType: type,
      paymentMethod: method,
      paidAmount: paid,
    );
  }

  void setVoucherBook(SaleVoucherBookRef? book) {
    // Edit mode keeps the allocated invoice number; only create mode
    // previews the book's next sequence.
    if (state.editingSaleId != null) {
      state = state.copyWith(
        voucherBook: book,
        clearVoucherBook: book == null,
      );
      return;
    }
    state = state.copyWith(
      voucherBook: book,
      clearVoucherBook: book == null,
      previewSaleNumber: book?.previewNumber,
      clearPreviewSaleNumber: book == null,
    );
  }

  void setCustomer(SaleCustomerRef? customer) {
    state = state.copyWith(
      customer: customer,
      clearCustomer: customer == null,
      clearWalkInCustomerName: true,
    );
  }

  /// Cash invoices: free-text party name (clears any linked customer).
  void setWalkInCustomerName(String name) {
    state = state.copyWith(
      walkInCustomerName: name,
      clearWalkInCustomerName: name.isEmpty,
      clearCustomer: true,
    );
  }

  void clearCustomerParty() {
    state = state.copyWith(clearCustomer: true, clearWalkInCustomerName: true);
  }

  void setCashAccount(SaleAccountRef? account) {
    state = state.copyWith(
      cashAccount: account,
      clearCashAccount: account == null,
    );
  }

  /// Changes sale currency and converts line prices (preserving markups).
  void setCurrency({required String code, required double rateToBase}) {
    final rate = rateToBase <= 0 ? 1.0 : rateToBase;
    final previousRate = state.exchangeRate;
    final items = [
      for (final item in state.items)
        item.copyWith(
          unitPrice: _converter.baseToSale(
            _converter.saleToBase(item.unitPrice, previousRate),
            rate,
          ),
        ),
    ];
    state = state.copyWith(
      currencyCode: code,
      exchangeRate: rate,
      items: items,
    );
  }

  void setDiscount({required DiscountType type, required double value}) {
    state = state.copyWith(discountType: type, discountValue: value);
  }

  void setTaxRate(double rate) {
    state = state.copyWith(taxRate: rate);
  }

  void setPaidAmount(double amount) {
    state = state.copyWith(paidAmount: amount);
  }

  void setNotes(String? notes) {
    state = state.copyWith(notes: notes, clearNotes: notes == null);
  }

  void addProduct(SaleProductRef product, {double mainQuantity = 1}) {
    final basePrice = product.unitPrice;
    final salePrice = _converter.baseToSale(basePrice, state.exchangeRate);
    final draft = SaleItemDraft.normalized(
      productId: product.productId,
      productName: product.name,
      productCode: product.itemCode,
      barcode: product.barcode,
      mainQuantity: mainQuantity,
      subQuantity: 0,
      packSize: product.packSize,
      unitPrice: salePrice,
      baseUnitPrice: basePrice,
    );
    // Always append a new line — do not merge duplicates by quantity.
    state = state.copyWith(items: [...state.items, draft]);
  }

  /// Alias kept for existing call sites.
  void addOrIncrementProduct(
    SaleProductRef product, {
    double mainQuantity = 1,
  }) => addProduct(product, mainQuantity: mainQuantity);

  void updateItemAt(int index, SaleItemDraft item) {
    if (index < 0 || index >= state.items.length) {
      return;
    }
    final next = [...state.items];
    next[index] = item;
    state = state.copyWith(items: next);
  }

  void removeItemAt(int index) {
    if (index < 0 || index >= state.items.length) {
      return;
    }
    final next = [...state.items]..removeAt(index);
    state = state.copyWith(items: next);
  }

  void setItemQuantities({
    required int index,
    required double mainQuantity,
    required double subQuantity,
  }) {
    if (index < 0 || index >= state.items.length) {
      return;
    }
    final item = state.items[index];
    updateItemAt(
      index,
      item.copyWith(
        mainQuantity: mainQuantity,
        subQuantity: subQuantity,
      ),
    );
  }

  /// Sets unit price in sale currency. Must be >= catalog default.
  /// Returns `false` when rejected (below catalog floor).
  bool setItemUnitPrice({required int index, required double unitPrice}) {
    if (index < 0 || index >= state.items.length) {
      return false;
    }
    final item = state.items[index];
    final minSale = _converter.baseToSale(
      item.baseUnitPrice,
      state.exchangeRate,
    );
    final rounded = SaleMoney.round(unitPrice);
    if (SaleMoney.toCents(rounded) < SaleMoney.toCents(minSale)) {
      return false;
    }
    if (SaleMoney.toCents(rounded) == SaleMoney.toCents(item.unitPrice)) {
      return true;
    }
    updateItemAt(index, item.copyWith(unitPrice: rounded));
    return true;
  }

  double catalogMinUnitPrice(SaleItemDraft item) {
    return _converter.baseToSale(item.baseUnitPrice, state.exchangeRate);
  }

  void adjustMainQuantity(int index, double delta) {
    if (index < 0 || index >= state.items.length) {
      return;
    }
    final item = state.items[index];
    final nextMain = item.mainQuantity + delta;
    if (nextMain < 0) {
      return;
    }
    if (nextMain == 0 && item.subQuantity <= 0) {
      removeItemAt(index);
      return;
    }
    setItemQuantities(
      index: index,
      mainQuantity: nextMain,
      subQuantity: item.subQuantity,
    );
  }

  void setItemQuantity(int index, double quantity) {
    // Legacy single-qty API: treat as main quantity.
    setItemQuantities(index: index, mainQuantity: quantity, subQuantity: 0);
  }

  void setItemDiscount({
    required int index,
    required DiscountType type,
    required double value,
  }) {
    if (index < 0 || index >= state.items.length) {
      return;
    }
    updateItemAt(
      index,
      state.items[index].copyWith(discountType: type, discountValue: value),
    );
  }

  bool get canSave {
    if (state.voucherBook == null) {
      return false;
    }
    if (state.items.isEmpty) {
      return false;
    }
    if (state.isCredit) {
      return state.customer != null && (state.customer?.hasAccount ?? false);
    }
    return state.cashAccount != null;
  }

  Future<SaleProductRef?> resolveScan(String raw) {
    return _catalog.resolveScan(raw);
  }
}

final saleComposerProvider =
    StateNotifierProvider.autoDispose<
      SaleComposerController,
      SaleComposerState
    >((ref) {
      // Base currency resolved lazily on first frame via form init.
      return SaleComposerController(
        calculator: ref.watch(saleCalculationServiceProvider),
        catalog: ref.watch(saleProductCatalogPortProvider),
        defaultTaxRate: ref.watch(salesDefaultTaxRateProvider),
        baseCurrencyCode: 'SAR',
      );
    });
