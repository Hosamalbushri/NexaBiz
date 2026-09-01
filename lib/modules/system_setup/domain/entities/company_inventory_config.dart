import 'package:flutter/foundation.dart';

/// Company-scoped inventory configuration.
/// Enforces ONE inventory base currency per tenant.
@immutable
class CompanyInventoryConfig {
  const CompanyInventoryConfig({
    required this.companyId,
    required this.inventoryBaseCurrencyId,
    this.allowNegativeStock = false,
    this.defaultCostingMethod = 'FIFO',
    this.quantityPrecision = 2,
    this.costPrecision = 2,
    this.currencyPrecision = 2,
    this.allowReturnsWithoutInvoice = false,
    this.requireStockCountApproval = true,
    this.autoPostAccountingEntries = true,
    this.updatedAt,
  });

  final String companyId;

  /// Single base currency symbol/code (e.g. 'YER') for inventory valuation.
  final String inventoryBaseCurrencyId;

  /// Operational settings
  final bool allowNegativeStock;
  final String defaultCostingMethod;
  final int quantityPrecision;
  final int costPrecision;
  final int currencyPrecision;
  final bool allowReturnsWithoutInvoice;
  final bool requireStockCountApproval;
  final bool autoPostAccountingEntries;
  final DateTime? updatedAt;

  CompanyInventoryConfig copyWith({
    String? companyId,
    String? inventoryBaseCurrencyId,
    bool? allowNegativeStock,
    String? defaultCostingMethod,
    int? quantityPrecision,
    int? costPrecision,
    int? currencyPrecision,
    bool? allowReturnsWithoutInvoice,
    bool? requireStockCountApproval,
    bool? autoPostAccountingEntries,
    DateTime? updatedAt,
  }) {
    return CompanyInventoryConfig(
      companyId: companyId ?? this.companyId,
      inventoryBaseCurrencyId:
          inventoryBaseCurrencyId ?? this.inventoryBaseCurrencyId,
      allowNegativeStock: allowNegativeStock ?? this.allowNegativeStock,
      defaultCostingMethod: defaultCostingMethod ?? this.defaultCostingMethod,
      quantityPrecision: quantityPrecision ?? this.quantityPrecision,
      costPrecision: costPrecision ?? this.costPrecision,
      currencyPrecision: currencyPrecision ?? this.currencyPrecision,
      allowReturnsWithoutInvoice:
          allowReturnsWithoutInvoice ?? this.allowReturnsWithoutInvoice,
      requireStockCountApproval:
          requireStockCountApproval ?? this.requireStockCountApproval,
      autoPostAccountingEntries:
          autoPostAccountingEntries ?? this.autoPostAccountingEntries,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'companyId': companyId,
    'inventoryBaseCurrencyId': inventoryBaseCurrencyId,
    'allowNegativeStock': allowNegativeStock,
    'defaultCostingMethod': defaultCostingMethod,
    'quantityPrecision': quantityPrecision,
    'costPrecision': costPrecision,
    'currencyPrecision': currencyPrecision,
    'allowReturnsWithoutInvoice': allowReturnsWithoutInvoice,
    'requireStockCountApproval': requireStockCountApproval,
    'autoPostAccountingEntries': autoPostAccountingEntries,
    'updatedAt': updatedAt?.toUtc().millisecondsSinceEpoch,
  };

  factory CompanyInventoryConfig.fromJson(Map<dynamic, dynamic> json) {
    final rawUpdated = json['updatedAt'];
    return CompanyInventoryConfig(
      companyId: (json['companyId'] as String?)?.trim() ?? '',
      inventoryBaseCurrencyId:
          (json['inventoryBaseCurrencyId'] as String?)?.trim().toUpperCase() ??
          'YER',
      allowNegativeStock: json['allowNegativeStock'] == true,
      defaultCostingMethod:
          (json['defaultCostingMethod'] as String?)?.trim() ?? 'FIFO',
      quantityPrecision: (json['quantityPrecision'] as int?) ?? 2,
      costPrecision: (json['costPrecision'] as int?) ?? 2,
      currencyPrecision: (json['currencyPrecision'] as int?) ?? 2,
      allowReturnsWithoutInvoice: json['allowReturnsWithoutInvoice'] == true,
      requireStockCountApproval: json['requireStockCountApproval'] != false,
      autoPostAccountingEntries: json['autoPostAccountingEntries'] != false,
      updatedAt: rawUpdated is int
          ? DateTime.fromMillisecondsSinceEpoch(rawUpdated, isUtc: true)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyInventoryConfig &&
          runtimeType == other.runtimeType &&
          companyId == other.companyId &&
          inventoryBaseCurrencyId == other.inventoryBaseCurrencyId &&
          allowNegativeStock == other.allowNegativeStock &&
          defaultCostingMethod == other.defaultCostingMethod &&
          quantityPrecision == other.quantityPrecision &&
          costPrecision == other.costPrecision &&
          currencyPrecision == other.currencyPrecision &&
          allowReturnsWithoutInvoice == other.allowReturnsWithoutInvoice &&
          requireStockCountApproval == other.requireStockCountApproval &&
          autoPostAccountingEntries == other.autoPostAccountingEntries &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      companyId.hashCode ^
      inventoryBaseCurrencyId.hashCode ^
      allowNegativeStock.hashCode ^
      defaultCostingMethod.hashCode ^
      quantityPrecision.hashCode ^
      costPrecision.hashCode ^
      currencyPrecision.hashCode ^
      allowReturnsWithoutInvoice.hashCode ^
      requireStockCountApproval.hashCode ^
      autoPostAccountingEntries.hashCode ^
      updatedAt.hashCode;
}
