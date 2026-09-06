import 'package:stock_count/modules/accounting/shared/domain/services/account_mapping_resolver.dart';

abstract class WarehouseAccountingValidationResult {
  const WarehouseAccountingValidationResult();
}

class WarehouseAccountingValidationSuccess extends WarehouseAccountingValidationResult {
  const WarehouseAccountingValidationSuccess({required this.accountUuid});
  final String accountUuid;
}

class WarehouseAccountingValidationFailure extends WarehouseAccountingValidationResult {
  const WarehouseAccountingValidationFailure({
    required this.reason,
    required this.role,
  });
  final String reason;
  final AccountRole role;
}

abstract class WarehouseAccountingValidationService {
  Future<WarehouseAccountingValidationResult> validateAccount({
    required String accountIdOrCode,
    required AccountRole role,
    required String companyId,
  });
}
