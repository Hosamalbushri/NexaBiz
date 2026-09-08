import 'package:equatable/equatable.dart';

/// Supplier domain entity representing a vendor/supplier in NexaBiz.
class Supplier extends Equatable {
  final String id;
  final String companyId;
  final String nameAr;
  final String nameEn;
  final String? code;
  final String? taxNumber;
  final String? phone;
  final String? email;
  final String? address;
  final double currentBalance;
  final String? currencyCode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Supplier({
    required this.id,
    required this.companyId,
    required this.nameAr,
    required this.nameEn,
    this.code,
    this.taxNumber,
    this.phone,
    this.email,
    this.address,
    this.currentBalance = 0.0,
    this.currencyCode,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        companyId,
        nameAr,
        nameEn,
        code,
        taxNumber,
        phone,
        email,
        address,
        currentBalance,
        currencyCode,
        isActive,
        createdAt,
        updatedAt,
      ];
}
