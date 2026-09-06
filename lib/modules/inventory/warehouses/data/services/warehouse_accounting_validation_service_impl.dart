import 'package:drift/drift.dart';
import 'package:stock_count/modules/accounting/shared/data/database/accounting_database.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';
import 'package:stock_count/modules/inventory/warehouses/domain/services/warehouse_accounting_validation_service.dart';

class WarehouseAccountingValidationServiceImpl implements WarehouseAccountingValidationService {
  WarehouseAccountingValidationServiceImpl({
    required AccountingDatabase accountingDb,
  }) : _accountingDb = accountingDb;

  final AccountingDatabase _accountingDb;

  @override
  Future<WarehouseAccountingValidationResult> validateAccount({
    required String accountIdOrCode,
    required AccountRole role,
    required String companyId,
  }) async {
    final target = accountIdOrCode.trim();
    if (target.isEmpty) {
      return WarehouseAccountingValidationFailure(
        reason: 'الحساب المحاسبي المحدد فارغ.',
        role: role,
      );
    }

    final account = await (_accountingDb.select(_accountingDb.accounts)..where(
          (tbl) =>
              (tbl.uuid.equals(target) | tbl.accountCode.equals(target)),
        ))
        .getSingleOrNull();

    // Check 1: Account exists
    if (account == null) {
      return WarehouseAccountingValidationFailure(
        reason: 'الحساب المحاسبي غير موجود في دليل الحسابات ($target).',
        role: role,
      );
    }

    // Check 2: Belongs to company (Multi-tenant isolation)
    if (account.companyId != companyId) {
      return WarehouseAccountingValidationFailure(
        reason:
            'حظر محاسبي: الحساب المحاسبي ($target) تابع لشركة أخرى ولا يمكن استخدامه.',
        role: role,
      );
    }

    // Check 3: Active status
    if (!account.isActive) {
      return WarehouseAccountingValidationFailure(
        reason: 'الحساب المحاسبي ($target) غير نشط ورقمياً غير متاح للترخيص.',
        role: role,
      );
    }

    // Check 4: Not deleted
    if (account.deletedAt != null) {
      return WarehouseAccountingValidationFailure(
        reason: 'الحساب المحاسبي ($target) محذوف ولا يمكن إجراء ترحيل عليه.',
        role: role,
      );
    }

    // Check 5: Detail account (not group)
    if (account.isGroup) {
      return WarehouseAccountingValidationFailure(
        reason:
            'الحساب المحاسبي ($target) حساب رئيسي/تجميعي ولا يمكن الترحيل المباشر عليه.',
        role: role,
      );
    }

    // Check 6: Account type compatibility
    final accountTypeLower = account.accountType.trim().toLowerCase();
    final isCompatible = switch (role) {
      AccountRole.inventory => accountTypeLower == 'asset',
      AccountRole.cogs => accountTypeLower == 'expense',
      AccountRole.payable =>
        accountTypeLower == 'liability' || accountTypeLower == 'payable' || accountTypeLower == 'asset',
      AccountRole.receivable =>
        accountTypeLower == 'asset' || accountTypeLower == 'receivable',
      AccountRole.revenue =>
        accountTypeLower == 'revenue' || accountTypeLower == 'income',
      AccountRole.cash => accountTypeLower == 'asset',
      _ => true,
    };

    if (!isCompatible) {
      return WarehouseAccountingValidationFailure(
        reason:
            'نوع الحساب (${account.accountType}) غير متوافق مع الدور المحاسبي المطلوبة (${role.name}).',
        role: role,
      );
    }

    return WarehouseAccountingValidationSuccess(accountUuid: account.uuid);
  }
}
