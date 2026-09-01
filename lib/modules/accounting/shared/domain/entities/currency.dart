import 'package:flutter/foundation.dart';

@immutable
class Currency {
  const Currency({
    required this.id,
    required this.uuid,
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

  final int id;
  final String uuid;
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

  Currency copyWith({
    int? id,
    String? uuid,
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
      uuid: uuid ?? this.uuid,
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
          uuid == other.uuid &&
          code == other.code;

  @override
  int get hashCode => Object.hash(uuid, code);

  @override
  String toString() => 'Currency($code, $nameAr, isDefault: $isDefault, isActive: $isActive)';
}

@immutable
class CurrencyDraft {
  const CurrencyDraft({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.symbol,
    this.uuid,
    this.decimalDigits = 2,
    this.isDefault = false,
    this.isActive = true,
  });

  final String? uuid;
  final String code;
  final String nameAr;
  final String nameEn;
  final String symbol;
  final int decimalDigits;
  final bool isDefault;
  final bool isActive;
}
