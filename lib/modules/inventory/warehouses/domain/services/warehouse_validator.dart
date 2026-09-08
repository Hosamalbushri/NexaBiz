import 'package:flutter/foundation.dart';
import '../entities/warehouse.dart';
import '../entities/warehouse_accounting_binding.dart';

/// Result of evaluating a warehouse's data and accounting readiness.
@immutable
class WarehouseValidationResult {
  const WarehouseValidationResult({
    required this.isValid,
    required this.isAccountingReady,
    required this.errors,
    required this.warnings,
  });

  final bool isValid;
  final bool isAccountingReady;
  final List<String> errors;
  final List<String> warnings;
}

/// Domain validator enforcing completeness and accounting readiness per warehouse.
class WarehouseValidator {
  const WarehouseValidator._();

  static WarehouseValidationResult validate({
    required Warehouse warehouse,
    WarehouseAccountingBinding? binding,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    if (warehouse.code.trim().isEmpty) {
      errors.add('كود المستودع مطلوب');
    }
    if (warehouse.name.trim().isEmpty) {
      errors.add('اسم المستودع مطلوب');
    }

    if (binding == null) {
      errors.add(
        'يلزم تحديد التهيئة والربط المحاسبي للمستودع (أصل المخزون وتكلفة المبيعات)',
      );
    } else {
      final hasAsset = binding.inventoryAssetAccountId != null &&
          binding.inventoryAssetAccountId!.trim().isNotEmpty;
      final hasCogs = binding.cogsAccountId != null &&
          binding.cogsAccountId!.trim().isNotEmpty;
      final hasAdj = binding.inventoryAdjustmentAccountId != null &&
          binding.inventoryAdjustmentAccountId!.trim().isNotEmpty;

      if (!hasAsset) {
        errors.add(
          'حساب أصل المخزون غير محدد لهذا المستودع',
        );
      }
      if (!hasCogs) {
        errors.add(
          'حساب تكلفة البضاعة المباعة (COGS) غير محدد لهذا المستودع',
        );
      }
      if (!hasAdj) {
        warnings.add(
          'حساب تسويات وانحرافات المخزون غير محدد لهذا المستودع',
        );
      }
    }

    final isAccountingReady = binding != null &&
        binding.inventoryAssetAccountId != null &&
        binding.inventoryAssetAccountId!.trim().isNotEmpty &&
        binding.cogsAccountId != null &&
        binding.cogsAccountId!.trim().isNotEmpty;

    return WarehouseValidationResult(
      isValid: errors.isEmpty,
      isAccountingReady: isAccountingReady,
      errors: errors,
      warnings: warnings,
    );
  }
}
