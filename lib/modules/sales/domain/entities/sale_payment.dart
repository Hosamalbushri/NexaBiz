import 'payment_method.dart';

/// Payment recorded against a sale (supports future multi-payment).
class SalePayment {
  const SalePayment({
    required this.id,
    required this.uuid,
    required this.saleUuid,
    required this.amount,
    required this.method,
    required this.paidAt,
    required this.createdAt,
    this.notes,
    this.externalId,
  });

  final int id;
  final String uuid;
  final String saleUuid;
  final double amount;
  final PaymentMethod method;
  final DateTime paidAt;
  final DateTime createdAt;
  final String? notes;
  final String? externalId;

  SalePayment copyWith({
    int? id,
    String? uuid,
    String? saleUuid,
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
      uuid: uuid ?? this.uuid,
      saleUuid: saleUuid ?? this.saleUuid,
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
