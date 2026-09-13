import 'package:flutter/foundation.dart';
import 'package:stock_count/shared/contracts/errors/currency_exception.dart';

@immutable
class Currency {
  const Currency({
    required this.id,
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.symbol,
    required this.decimalDigits,
    required this.isDefault,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.companyId,
  });

  final String id;
  final String code;
  final String nameAr;
  final String nameEn;
  final String symbol;
  final int decimalDigits;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? companyId;

  String get uuid => id;

  String localizedName(bool isArabic) {
    if (isArabic) {
      return nameAr.trim().isNotEmpty ? nameAr.trim() : nameEn.trim();
    } else {
      return nameEn.trim().isNotEmpty ? nameEn.trim() : nameAr.trim();
    }
  }

  Currency copyWith({
    String? id,
    String? code,
    String? nameAr,
    String? nameEn,
    String? symbol,
    int? decimalDigits,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? companyId,
  }) {
    return Currency(
      id: id ?? this.id,
      code: code ?? this.code,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      symbol: symbol ?? this.symbol,
      decimalDigits: decimalDigits ?? this.decimalDigits,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      companyId: companyId ?? this.companyId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code;

  @override
  int get hashCode => Object.hash(id, code);

  @override
  String toString() =>
      'Currency($code, $nameAr, isDefault: $isDefault, isActive: $isActive)';
}

@immutable
class CurrencyDraft {
  const CurrencyDraft({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.symbol,
    this.id,
    this.uuid,
    this.decimalDigits = 2,
    this.isDefault = false,
    this.isActive = true,
  });

  final String? id;
  final String? uuid;
  final String code;
  final String nameAr;
  final String nameEn;
  final String symbol;
  final int decimalDigits;
  final bool isDefault;
  final bool isActive;

  String? get effectiveId => id ?? uuid;

  void validate() {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      throw const CurrencyValidationException(
        'رمز العملة لا يمكن أن يكون فارغاً.',
      );
    }
    if (decimalDigits < 0 || decimalDigits > 6) {
      throw const CurrencyValidationException(
        'عدد الخانات العشرية يجب أن يكون بين 0 و 6.',
      );
    }
    if (nameAr.trim().isEmpty && nameEn.trim().isEmpty) {
      throw const CurrencyValidationException(
        'اسم العملة لا يمكن أن يكون فارغاً.',
      );
    }
  }
}
