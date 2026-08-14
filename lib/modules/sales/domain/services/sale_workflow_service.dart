import '../entities/sale.dart';
import '../entities/sale_status.dart';
import '../models/sale_exception.dart';

/// Pure status transition rules for the sales lifecycle.
class SaleWorkflowService {
  const SaleWorkflowService();

  SaleStatus nextOnPost({required bool integratedMode}) {
    // Integrated vs standalone differs by bridge/journal side effects, not status.
    return SaleStatus.posted;
  }

  /// Legacy name used by older call sites.
  SaleStatus nextOnConfirm({required bool integratedMode}) =>
      nextOnPost(integratedMode: integratedMode);

  void assertCanPost(Sale sale) {
    if (!sale.saleStatus.canPost) {
      throw const SaleException(SaleException.invalidStatusTransition);
    }
  }

  /// Compatibility alias for confirm → post rename.
  void assertCanConfirm(Sale sale) => assertCanPost(sale);

  void assertCanCancel(Sale sale) {
    if (!sale.saleStatus.canCancel) {
      throw const SaleException(SaleException.invalidStatusTransition);
    }
  }

  void assertCanEdit(Sale sale) {
    if (!sale.saleStatus.isEditable) {
      throw const SaleException(SaleException.invalidStatusTransition);
    }
  }
}
