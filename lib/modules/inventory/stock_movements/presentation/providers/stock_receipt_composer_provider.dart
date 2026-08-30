import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/products/domain/entities/product.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_receipt.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/usecases/stock_movement_usecases.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/cost_layer_service.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_account_port.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_voucher_book_port.dart';

/// Draft line item for stock receipt form composer.
class StockReceiptLineDraft {
  const StockReceiptLineDraft({
    required this.itemCode,
    required this.itemName,
    this.mainQuantity = 1.0,
    this.subQuantity = 0.0,
    this.packSize = 1.0,
    this.unitCost = 0.0,
    double? baseUnitCost,
  }) : baseUnitCost = baseUnitCost ?? unitCost;

  final String itemCode;
  final String itemName;
  final double mainQuantity;
  final double subQuantity;
  final double packSize;
  final double unitCost;
  final double baseUnitCost;

  String get productName => itemName;

  double get totalQuantity =>
      mainQuantity + (packSize > 0 ? subQuantity / packSize : 0.0);

  double get totalCost => totalQuantity * unitCost;

  StockReceiptLineDraft copyWith({
    String? itemCode,
    String? itemName,
    double? mainQuantity,
    double? subQuantity,
    double? packSize,
    double? unitCost,
    double? baseUnitCost,
  }) {
    return StockReceiptLineDraft(
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      mainQuantity: mainQuantity ?? this.mainQuantity,
      subQuantity: subQuantity ?? this.subQuantity,
      packSize: packSize ?? this.packSize,
      unitCost: unitCost ?? this.unitCost,
      baseUnitCost: baseUnitCost ?? this.baseUnitCost,
    );
  }
}

/// Editable draft state for Stock Receipt Form.
class StockReceiptComposerState {
  const StockReceiptComposerState({
    required this.receiptDate,
    this.voucherBook,
    this.previewReceiptNumber,
    this.account,
    this.currencyCode = '',
    this.exchangeRate = 1.0,
    this.supplier,
    this.warehouse,
    this.notes,
    this.lines = const [],
    this.isSaving = false,
    this.error,
    this.editingReceiptId,
  });

  final DateTime receiptDate;
  final InventoryVoucherBookRef? voucherBook;
  final String? previewReceiptNumber;
  final InventoryAccountRef? account;
  final String currencyCode;
  final double exchangeRate;
  final String? supplier;
  final String? warehouse;
  final String? notes;
  final List<StockReceiptLineDraft> lines;
  final bool isSaving;
  final String? error;
  final String? editingReceiptId;

  List<StockReceiptLineDraft> get items => lines;

  double get totalQuantity =>
      lines.fold(0.0, (sum, line) => sum + line.totalQuantity);

  double get totalCost =>
      lines.fold(0.0, (sum, line) => sum + line.totalCost);

  StockReceiptComposerState copyWith({
    DateTime? receiptDate,
    InventoryVoucherBookRef? voucherBook,
    bool clearVoucherBook = false,
    String? previewReceiptNumber,
    bool clearPreviewReceiptNumber = false,
    InventoryAccountRef? account,
    bool clearAccount = false,
    String? currencyCode,
    double? exchangeRate,
    String? supplier,
    bool clearSupplier = false,
    String? warehouse,
    bool clearWarehouse = false,
    String? notes,
    bool clearNotes = false,
    List<StockReceiptLineDraft>? lines,
    bool? isSaving,
    String? error,
    bool clearError = false,
    String? editingReceiptId,
    bool clearEditingReceiptId = false,
  }) {
    return StockReceiptComposerState(
      receiptDate: receiptDate ?? this.receiptDate,
      voucherBook:
          clearVoucherBook ? null : (voucherBook ?? this.voucherBook),
      previewReceiptNumber: clearPreviewReceiptNumber
          ? null
          : (previewReceiptNumber ?? this.previewReceiptNumber),
      account: clearAccount ? null : (account ?? this.account),
      currencyCode: currencyCode ?? this.currencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      supplier: clearSupplier ? null : (supplier ?? this.supplier),
      warehouse: clearWarehouse ? null : (warehouse ?? this.warehouse),
      notes: clearNotes ? null : (notes ?? this.notes),
      lines: lines ?? this.lines,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      editingReceiptId: clearEditingReceiptId
          ? null
          : (editingReceiptId ?? this.editingReceiptId),
    );
  }
}

class StockReceiptComposerNotifier
    extends StateNotifier<StockReceiptComposerState> {
  StockReceiptComposerNotifier()
      : super(StockReceiptComposerState(receiptDate: DateTime.now()));

  void reset([String? defaultCurrencyCode]) {
    state = StockReceiptComposerState(
      receiptDate: DateTime.now(),
      currencyCode: defaultCurrencyCode ?? '',
    );
  }

  void loadFromReceipt(StockReceipt receipt) {
    init(receiptToEdit: receipt);
  }

  void init({
    StockReceipt? receiptToEdit,
    InventoryVoucherBookRef? defaultBook,
    String? defaultCurrencyCode,
  }) {
    if (receiptToEdit != null) {
      final accountRef = (receiptToEdit.accountId != null && receiptToEdit.accountId!.isNotEmpty)
          ? InventoryAccountRef(
              accountId: receiptToEdit.accountId!,
              code: '',
              name: receiptToEdit.accountName ?? receiptToEdit.supplier ?? '',
            )
          : null;
      state = StockReceiptComposerState(
        editingReceiptId: receiptToEdit.id,
        receiptDate: receiptToEdit.receiptDate,
        previewReceiptNumber: receiptToEdit.receiptNumber,
        account: accountRef,
        supplier: receiptToEdit.supplier,
        currencyCode: receiptToEdit.currencyCode,
        exchangeRate: receiptToEdit.exchangeRate,
        notes: receiptToEdit.notes,
        lines: receiptToEdit.lines
            .map(
              (l) => StockReceiptLineDraft(
                itemCode: l.itemCode,
                itemName: l.itemName,
                mainQuantity: l.mainQuantity,
                subQuantity: l.subQuantity,
                packSize: l.packSize,
                unitCost: l.unitCost,
                baseUnitCost: l.unitCost * (receiptToEdit.exchangeRate > 0 ? receiptToEdit.exchangeRate : 1.0),
              ),
            )
            .toList(),
      );
    } else {
      state = StockReceiptComposerState(
        receiptDate: DateTime.now(),
        voucherBook: defaultBook,
        currencyCode: defaultCurrencyCode ?? '',
        previewReceiptNumber: defaultBook?.previewNumber,
      );
    }
  }

  void setReceiptDate(DateTime date) {
    state = state.copyWith(receiptDate: date);
  }

  void setVoucherBook(InventoryVoucherBookRef? book) {
    state = state.copyWith(
      voucherBook: book,
      previewReceiptNumber: book?.previewNumber,
    );
  }

  void setAccount(InventoryAccountRef? account) {
    state = state.copyWith(
      account: account,
      supplier: account?.name,
      clearAccount: account == null,
    );
  }

  void setCurrency(String code, [double rate = 1.0]) {
    final effectiveRate = rate <= 0 ? 1.0 : rate;
    final updatedLines = state.lines.map((l) {
      final convertedCost = l.baseUnitCost / effectiveRate;
      return l.copyWith(unitCost: convertedCost);
    }).toList();
    state = state.copyWith(
      currencyCode: code,
      exchangeRate: effectiveRate,
      lines: updatedLines,
    );
  }

  void setWarehouse(String? warehouse) {
    state = state.copyWith(
      warehouse: warehouse,
      clearWarehouse: warehouse == null || warehouse.isEmpty,
    );
  }

  void setNotes(String? notes) {
    state = state.copyWith(
      notes: notes,
      clearNotes: notes == null || notes.isEmpty,
    );
  }

  Future<void> addProduct(Product product, {CostLayerService? costLayerService}) async {
    double baseCost = product.unitCost;
    if (baseCost <= 0 && costLayerService != null) {
      baseCost = await costLayerService.getItemCostValuation(
        itemCode: product.itemCode,
        warehouseId: state.warehouse,
      );
    }
    final rate = state.exchangeRate <= 0 ? 1.0 : state.exchangeRate;
    final docUnitCost = baseCost / rate;

    addLine(StockReceiptLineDraft(
      itemCode: product.itemCode,
      itemName: product.name,
      packSize: product.packSize > 0 ? product.packSize.toDouble() : 1.0,
      unitCost: docUnitCost,
      baseUnitCost: baseCost,
      mainQuantity: 1.0,
      subQuantity: 0.0,
    ));
  }

  void addLine(StockReceiptLineDraft line) {
    state = state.copyWith(lines: [...state.lines, line]);
  }

  void updateQuantities({
    required int index,
    required double mainQty,
    required double subQty,
  }) {
    if (index < 0 || index >= state.lines.length) return;
    final updated = List<StockReceiptLineDraft>.from(state.lines);
    updated[index] = updated[index].copyWith(
      mainQuantity: mainQty,
      subQuantity: subQty,
    );
    state = state.copyWith(lines: updated);
  }

  void updateUnitCost({
    required int index,
    required double unitCost,
  }) {
    if (index < 0 || index >= state.lines.length) return;
    final updated = List<StockReceiptLineDraft>.from(state.lines);
    final rate = state.exchangeRate <= 0 ? 1.0 : state.exchangeRate;
    updated[index] = updated[index].copyWith(
      unitCost: unitCost,
      baseUnitCost: unitCost * rate,
    );
    state = state.copyWith(lines: updated);
  }

  void updateLine(int index, StockReceiptLineDraft line) {
    if (index < 0 || index >= state.lines.length) return;
    final updated = List<StockReceiptLineDraft>.from(state.lines);
    updated[index] = line;
    state = state.copyWith(lines: updated);
  }

  void removeItem(int index) => removeLine(index);

  void removeLine(int index) {
    if (index < 0 || index >= state.lines.length) return;
    final updated = List<StockReceiptLineDraft>.from(state.lines)..removeAt(index);
    state = state.copyWith(lines: updated);
  }

  Future<bool> save({
    required StockMovementUseCases useCases,
    required InventoryVoucherBookPort voucherPort,
  }) async {
    if (state.lines.isEmpty) {
      state = state.copyWith(error: 'يرجى إضافة صنف واحد على الأقل');
      return false;
    }

    if (state.account == null || state.account!.accountId.trim().isEmpty) {
      state = state.copyWith(error: 'يرجى اختيار الحساب المحاسبي للمستند أولاً');
      return false;
    }

    for (final line in state.lines) {
      if (line.unitCost <= 0 || line.totalCost <= 0) {
        state = state.copyWith(
          error: 'لا يمكن حفظ أمر التوريد بتكلفة صفرية للصنف (${line.itemName}). يرجى إدخال تكلفة الصنف.',
        );
        return false;
      }
    }

    if (state.totalCost <= 0) {
      state = state.copyWith(error: 'لا يمكن حفظ أمر التوريد بتكلفة إجمالية صفرية.');
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      String number = '';
      if (state.editingReceiptId != null) {
        number = state.previewReceiptNumber ?? '';
      }

      if (number.isEmpty) {
        if (state.voucherBook != null) {
          number = await voucherPort.allocateReceiptNumber(state.voucherBook!.bookId);
        } else {
          number = 'REC-${DateTime.now().millisecondsSinceEpoch % 10000}';
        }
      }

      final receiptId = state.editingReceiptId ?? generateUuidV4();
      final receipt = StockReceipt(
        id: receiptId,
        receiptNumber: number,
        receiptDate: state.receiptDate,
        supplier: state.account?.name ?? state.supplier,
        accountId: state.account?.accountId,
        accountName: state.account?.name ?? state.supplier,
        currencyCode: state.currencyCode,
        exchangeRate: state.exchangeRate,
        notes: state.notes,
        lines: state.lines.map((l) {
          return StockMovementLine(
            movementUuid: receiptId,
            movementType: 'receipt',
            itemCode: l.itemCode,
            itemName: l.itemName,
            mainQuantity: l.mainQuantity,
            subQuantity: l.subQuantity,
            packSize: l.packSize,
            quantity: l.totalQuantity,
            unitCost: l.unitCost,
            totalCost: l.totalCost,
          );
        }).toList(),
      );

      await useCases.saveReceipt(receipt);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

final stockReceiptComposerProvider = StateNotifierProvider.autoDispose<
    StockReceiptComposerNotifier, StockReceiptComposerState>((ref) {
  return StockReceiptComposerNotifier();
});
