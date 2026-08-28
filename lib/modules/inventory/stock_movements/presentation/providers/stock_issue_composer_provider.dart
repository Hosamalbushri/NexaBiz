import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import 'package:stock_count/modules/inventory/products/domain/entities/product.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_issue.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/entities/stock_movement_line.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/repositories/stock_movements_repository.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_account_port.dart';
import 'package:stock_count/modules/inventory/stock_movements/domain/services/inventory_voucher_book_port.dart';

/// Draft line item for stock issue form composer.
class StockIssueLineDraft {
  const StockIssueLineDraft({
    required this.itemCode,
    required this.itemName,
    this.mainQuantity = 1.0,
    this.subQuantity = 0.0,
    this.packSize = 1.0,
    this.unitCost = 0.0,
  });

  final String itemCode;
  final String itemName;
  final double mainQuantity;
  final double subQuantity;
  final double packSize;
  final double unitCost;

  String get productName => itemName;

  double get totalQuantity =>
      mainQuantity + (packSize > 0 ? subQuantity / packSize : 0.0);

  double get totalCost => totalQuantity * unitCost;

  StockIssueLineDraft copyWith({
    String? itemCode,
    String? itemName,
    double? mainQuantity,
    double? subQuantity,
    double? packSize,
    double? unitCost,
  }) {
    return StockIssueLineDraft(
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      mainQuantity: mainQuantity ?? this.mainQuantity,
      subQuantity: subQuantity ?? this.subQuantity,
      packSize: packSize ?? this.packSize,
      unitCost: unitCost ?? this.unitCost,
    );
  }
}

/// Editable draft state for Stock Issue Form.
class StockIssueComposerState {
  const StockIssueComposerState({
    required this.issueDate,
    this.voucherBook,
    this.previewIssueNumber,
    this.account,
    this.currencyCode = 'SAR',
    this.exchangeRate = 1.0,
    this.warehouse,
    this.notes,
    this.lines = const [],
    this.isSaving = false,
    this.error,
    this.editingIssueId,
  });

  final DateTime issueDate;
  final InventoryVoucherBookRef? voucherBook;
  final String? previewIssueNumber;
  final InventoryAccountRef? account;
  final String currencyCode;
  final double exchangeRate;
  final String? warehouse;
  final String? notes;
  final List<StockIssueLineDraft> lines;
  final bool isSaving;
  final String? error;
  final String? editingIssueId;

  List<StockIssueLineDraft> get items => lines;

  double get totalQuantity =>
      lines.fold(0.0, (sum, line) => sum + line.totalQuantity);

  double get totalCost =>
      lines.fold(0.0, (sum, line) => sum + line.totalCost);

  StockIssueComposerState copyWith({
    DateTime? issueDate,
    InventoryVoucherBookRef? voucherBook,
    bool clearVoucherBook = false,
    String? previewIssueNumber,
    bool clearPreviewIssueNumber = false,
    InventoryAccountRef? account,
    bool clearAccount = false,
    String? currencyCode,
    double? exchangeRate,
    String? warehouse,
    bool clearWarehouse = false,
    String? notes,
    bool clearNotes = false,
    List<StockIssueLineDraft>? lines,
    bool? isSaving,
    String? error,
    bool clearError = false,
    String? editingIssueId,
    bool clearEditingIssueId = false,
  }) {
    return StockIssueComposerState(
      issueDate: issueDate ?? this.issueDate,
      voucherBook:
          clearVoucherBook ? null : (voucherBook ?? this.voucherBook),
      previewIssueNumber: clearPreviewIssueNumber
          ? null
          : (previewIssueNumber ?? this.previewIssueNumber),
      account: clearAccount ? null : (account ?? this.account),
      currencyCode: currencyCode ?? this.currencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      warehouse: clearWarehouse ? null : (warehouse ?? this.warehouse),
      notes: clearNotes ? null : (notes ?? this.notes),
      lines: lines ?? this.lines,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      editingIssueId: clearEditingIssueId
          ? null
          : (editingIssueId ?? this.editingIssueId),
    );
  }
}

class StockIssueComposerNotifier
    extends StateNotifier<StockIssueComposerState> {
  StockIssueComposerNotifier()
      : super(StockIssueComposerState(issueDate: DateTime.now()));

  void reset([String? defaultCurrencyCode]) {
    state = StockIssueComposerState(
      issueDate: DateTime.now(),
      currencyCode: defaultCurrencyCode ?? 'YER',
    );
  }

  void loadFromIssue(StockIssue issue) {
    init(issueToEdit: issue);
  }

  void init({
    StockIssue? issueToEdit,
    InventoryVoucherBookRef? defaultBook,
    String? defaultCurrencyCode,
  }) {
    if (issueToEdit != null) {
      state = StockIssueComposerState(
        editingIssueId: issueToEdit.id,
        issueDate: issueToEdit.issueDate,
        previewIssueNumber: issueToEdit.issueNumber,
        currencyCode: issueToEdit.currencyCode,
        exchangeRate: issueToEdit.exchangeRate,
        warehouse: issueToEdit.warehouse,
        notes: issueToEdit.notes,
        account: issueToEdit.accountId != null
            ? InventoryAccountRef(
                accountId: issueToEdit.accountId!,
                code: '',
                name: issueToEdit.accountName ?? '',
              )
            : null,
        lines: issueToEdit.lines
            .map(
              (l) => StockIssueLineDraft(
                itemCode: l.itemCode,
                itemName: l.itemName,
                mainQuantity: l.mainQuantity,
                subQuantity: l.subQuantity,
                packSize: l.packSize,
                unitCost: l.unitCost,
              ),
            )
            .toList(),
      );
    } else {
      state = StockIssueComposerState(
        issueDate: DateTime.now(),
        voucherBook: defaultBook,
        currencyCode: defaultCurrencyCode ?? 'YER',
        previewIssueNumber: defaultBook?.previewNumber,
      );
    }
  }

  void setIssueDate(DateTime date) {
    state = state.copyWith(issueDate: date);
  }

  void setVoucherBook(InventoryVoucherBookRef? book) {
    state = state.copyWith(
      voucherBook: book,
      previewIssueNumber: book?.previewNumber,
    );
  }

  void setAccount(InventoryAccountRef? account) {
    state = state.copyWith(
      account: account,
      clearAccount: account == null,
    );
  }

  void setCurrency(String code, [double rate = 1.0]) {
    state = state.copyWith(currencyCode: code, exchangeRate: rate);
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

  void addProduct(Product product) {
    addLine(StockIssueLineDraft(
      itemCode: product.itemCode,
      itemName: product.name,
      packSize: product.packSize > 0 ? product.packSize.toDouble() : 1.0,
      unitCost: product.unitCost,
      mainQuantity: 1.0,
      subQuantity: 0.0,
    ));
  }

  void addLine(StockIssueLineDraft line) {
    state = state.copyWith(lines: [...state.lines, line]);
  }

  void updateQuantities({
    required int index,
    required double mainQty,
    required double subQty,
  }) {
    if (index < 0 || index >= state.lines.length) return;
    final updated = List<StockIssueLineDraft>.from(state.lines);
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
    final updated = List<StockIssueLineDraft>.from(state.lines);
    updated[index] = updated[index].copyWith(unitCost: unitCost);
    state = state.copyWith(lines: updated);
  }

  void updateLine(int index, StockIssueLineDraft line) {
    if (index < 0 || index >= state.lines.length) return;
    final updated = List<StockIssueLineDraft>.from(state.lines);
    updated[index] = line;
    state = state.copyWith(lines: updated);
  }

  void removeItem(int index) => removeLine(index);

  void removeLine(int index) {
    if (index < 0 || index >= state.lines.length) return;
    final updated = List<StockIssueLineDraft>.from(state.lines)..removeAt(index);
    state = state.copyWith(lines: updated);
  }

  Future<bool> save({
    required StockMovementsRepository repo,
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

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      String number = '';
      if (state.editingIssueId != null) {
        number = state.previewIssueNumber ?? '';
      }

      if (number.isEmpty) {
        if (state.voucherBook != null) {
          number = await voucherPort.allocateIssueNumber(state.voucherBook!.bookId);
        } else {
          number = 'ISS-${DateTime.now().millisecondsSinceEpoch % 10000}';
        }
      }

      final issueId = state.editingIssueId ?? generateUuidV4();
      final issue = StockIssue(
        id: issueId,
        issueNumber: number,
        issueDate: state.issueDate,
        accountId: state.account?.accountId,
        accountName: state.account?.name,
        currencyCode: state.currencyCode,
        exchangeRate: state.exchangeRate,
        voucherBookId: state.voucherBook != null
            ? int.tryParse(state.voucherBook!.bookId)
            : null,
        warehouse: state.warehouse,
        notes: state.notes,
        lines: state.lines.map((l) {
          return StockMovementLine(
            movementUuid: issueId,
            movementType: 'issue',
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

      await repo.saveIssue(issue);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

final stockIssueComposerProvider = StateNotifierProvider.autoDispose<
    StockIssueComposerNotifier, StockIssueComposerState>((ref) {
  return StockIssueComposerNotifier();
});
