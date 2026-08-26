import '../entities/payment_status.dart';
import '../entities/sale_settlement_type.dart';
import '../entities/sale_status.dart';

/// Lightweight sales-list row (header only — no items/payments hydrate).
class SaleListItem {
  const SaleListItem({
    required this.id,
    required this.uuid,
    required this.saleNumber,
    required this.saleDate,
    required this.settlementType,
    required this.currencyCode,
    required this.total,
    required this.saleStatus,
    required this.paymentStatus,
    this.customerName,
  });

  final int id;
  final String uuid;
  final String saleNumber;
  final DateTime saleDate;
  final SaleSettlementType settlementType;
  final String? customerName;
  final String currencyCode;
  final double total;
  final SaleStatus saleStatus;
  final PaymentStatus paymentStatus;
}
