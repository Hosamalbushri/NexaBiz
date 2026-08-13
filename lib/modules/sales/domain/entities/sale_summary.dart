import '../services/sale_money.dart';
import 'payment_status.dart';

/// Calculated monetary summary for a sale (never stored as source of truth alone).
class SaleSummary {
  const SaleSummary({
    required this.subtotal,
    required this.itemDiscountTotal,
    required this.saleDiscount,
    required this.tax,
    required this.total,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentStatus,
  });

  /// Sum of line gross amounts (qty × unitPrice) before discounts.
  final double subtotal;

  /// Sum of resolved item-level discount amounts.
  final double itemDiscountTotal;

  /// Resolved sale-level discount amount.
  final double saleDiscount;

  final double tax;
  final double total;
  final double paidAmount;
  final double remainingAmount;
  final PaymentStatus paymentStatus;

  double get netBeforeTax =>
      SaleMoney.round(subtotal - itemDiscountTotal - saleDiscount);
}
