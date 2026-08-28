import 'package:stock_count/modules/inventory/shared/domain/enums/inventory_document_status.dart';

class DocumentLockChecker {
  const DocumentLockChecker();

  void assertCanEdit({
    required String documentNumber,
    required InventoryDocumentStatus status,
  }) {
    if (status == InventoryDocumentStatus.posted) {
      throw StateError(
        'المستند ($documentNumber) مرحّل مقفل محاسبياً ومخزنياً. لا يمكن التعديل عليه إلا بعد إلغاء الترحيل.',
      );
    }
    if (status == InventoryDocumentStatus.cancelled) {
      throw StateError(
        'المستند ($documentNumber) ملغى. لا يمكن التعديل عليه.',
      );
    }
  }

  void assertCanDelete({
    required String documentNumber,
    required InventoryDocumentStatus status,
  }) {
    if (status == InventoryDocumentStatus.posted) {
      throw StateError(
        'المستند ($documentNumber) مرحّل مقفل محاسبياً ومخزنياً. لا يمكن حذفه إلا بعد إلغاء الترحيل والعكس المحاسبي.',
      );
    }
  }
}
