import '../entities/sale.dart';
import '../entities/sale_status.dart';
import '../models/sale_exception.dart';

/// Pure status transition rules for the sales lifecycle.
class SaleWorkflowService {
  const SaleWorkflowService();

  SaleStatus nextOnConfirm({required bool integratedMode}) {
    return integratedMode ? SaleStatus.pending : SaleStatus.confirmed;
  }

  void assertCanConfirm(Sale sale) {
    if (!sale.saleStatus.canConfirm) {
      throw const SaleException(SaleException.invalidStatusTransition);
    }
  }

  void assertCanCancel(Sale sale) {
    if (!sale.saleStatus.canCancel) {
      throw const SaleException(SaleException.invalidStatusTransition);
    }
  }

  void assertCanComplete(Sale sale) {
    if (!sale.saleStatus.canComplete) {
      throw const SaleException(SaleException.invalidStatusTransition);
    }
  }

  void assertCanEdit(Sale sale) {
    if (!sale.saleStatus.isEditable) {
      throw const SaleException(SaleException.invalidStatusTransition);
    }
  }
}
