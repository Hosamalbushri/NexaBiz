import 'payment_method.dart';

/// Payment recorded against a sale (supports future multi-payment).
class SalePayment {
  const SalePayment({
    required this.id,
    required this.saleId,
    required this.amount,
    required this.method,
    required this.paidAt,
    required this.createdAt,
    this.notes,
    this.externalId,
  });

  final String id;
  final String saleId;
  final double amount;
  final PaymentMethod method;
  final DateTime paidAt;
  final DateTime createdAt;
  final String? notes;
  final String? externalId;

  String get uuid => id;
  String get saleUuid => saleId;

  SalePayment copyWith({
    String? id,
    String? saleId,
    double? amount,
    PaymentMethod? method,
    DateTime? paidAt,
    DateTime? createdAt,
    String? notes,
    bool clearNotes = false,
    String? externalId,
    bool clearExternalId = false,
  }) {
    return SalePayment(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      notes: clearNotes ? null : (notes ?? this.notes),
      externalId: clearExternalId ? null : (externalId ?? this.externalId),
    );
  }
}

class SalePaymentDraft {
  const SalePaymentDraft({
    required this.amount,
    required this.method,
    this.paidAt,
    this.notes,
    this.externalId,
  });

  final double amount;
  final PaymentMethod method;
  final DateTime? paidAt;
  final String? notes;
  final String? externalId;
}
