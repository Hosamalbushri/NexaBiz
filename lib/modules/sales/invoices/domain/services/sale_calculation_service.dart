import '../entities/discount_type.dart';
import '../entities/payment_status.dart';
import '../entities/sale_item.dart';
import '../entities/sale_summary.dart';
import 'sale_money.dart';

/// Input for a single calculated line (may omit uuid for ephemeral UI drafts).
class SaleLineCalculation {
  const SaleLineCalculation({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.quantity,
    required this.mainQuantity,
    required this.subQuantity,
    required this.packSize,
    required this.unitPrice,
    required this.baseUnitPrice,
    required this.discountType,
    required this.discountValue,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
    this.barcode,
    this.lineUuid,
  });

  final String? lineUuid;
  final String productId;
  final String productName;
  final String productCode;
  final String? barcode;
  final double quantity;
  final double mainQuantity;
  final double subQuantity;
  final int packSize;
  final double unitPrice;
  final double baseUnitPrice;
  final DiscountType discountType;
  final double discountValue;
  final double subtotal;
  final double discountAmount;
  final double total;
}

/// Pure calculation service for sale totals — keep out of widgets.
class SaleCalculationService {
  const SaleCalculationService();

  SaleLineCalculation calculateLine(SaleItemDraft draft) {
    final qty = draft.quantity;
    final unit = draft.unitPrice;
    final subtotal = SaleMoney.round(qty * unit);
    final discountAmount = SaleMoney.applyDiscount(
      base: subtotal,
      isPercentage: draft.discountType == DiscountType.percentage,
      discountValue: draft.discountValue,
    );
    final total = SaleMoney.clampNonNegative(subtotal - discountAmount);
    return SaleLineCalculation(
      lineUuid: draft.lineUuid,
      productId: draft.productId,
      productName: draft.productName,
      productCode: draft.productCode,
      barcode: draft.barcode,
      quantity: qty,
      mainQuantity: draft.mainQuantity,
      subQuantity: draft.subQuantity,
      packSize: draft.packSize,
      unitPrice: SaleMoney.round(unit),
      baseUnitPrice: SaleMoney.round(draft.baseUnitPrice),
      discountType: draft.discountType,
      discountValue: draft.discountValue,
      subtotal: subtotal,
      discountAmount: discountAmount,
      total: total,
    );
  }

  SaleSummary calculate({
    required List<SaleItemDraft> items,
    DiscountType saleDiscountType = DiscountType.fixed,
    double saleDiscountValue = 0,
    double taxRatePercent = 0,
    double paidAmount = 0,
  }) {
    final lines = items.map(calculateLine).toList(growable: false);
    final subtotalCents = lines.fold<int>(
      0,
      (sum, line) => sum + SaleMoney.toCents(line.subtotal),
    );
    final itemDiscountCents = lines.fold<int>(
      0,
      (sum, line) => sum + SaleMoney.toCents(line.discountAmount),
    );
    final afterItemsCents = subtotalCents - itemDiscountCents;
    final afterItems = SaleMoney.fromCents(afterItemsCents < 0 ? 0 : afterItemsCents);

    final saleDiscount = SaleMoney.applyDiscount(
      base: afterItems,
      isPercentage: saleDiscountType == DiscountType.percentage,
      discountValue: saleDiscountValue,
    );
    final netCents =
        SaleMoney.toCents(afterItems) - SaleMoney.toCents(saleDiscount);
    final net = SaleMoney.fromCents(netCents < 0 ? 0 : netCents);

    final rate = taxRatePercent < 0 ? 0.0 : taxRatePercent;
    final tax = SaleMoney.round(net * rate / 100);
    final total = SaleMoney.round(net + tax);
    final paid = SaleMoney.clampNonNegative(paidAmount);
    final remaining = SaleMoney.clampNonNegative(total - paid);
    final status = PaymentStatusX.fromAmounts(total: total, paidAmount: paid);

    return SaleSummary(
      subtotal: SaleMoney.fromCents(subtotalCents),
      itemDiscountTotal: SaleMoney.fromCents(itemDiscountCents),
      saleDiscount: saleDiscount,
      tax: tax,
      total: total,
      paidAmount: paid,
      remainingAmount: remaining,
      paymentStatus: status,
    );
  }

  List<SaleLineCalculation> calculateLines(List<SaleItemDraft> items) {
    return items.map(calculateLine).toList(growable: false);
  }
}
