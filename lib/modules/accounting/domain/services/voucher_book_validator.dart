import '../entities/voucher_book.dart';
import '../entities/voucher_book_type.dart';
import '../models/voucher_book_exception.dart';

/// Validates voucher book drafts before persistence.
class VoucherBookValidator {
  const VoucherBookValidator();

  void validate(VoucherBookDraft draft) {
    final name = draft.name.trim();
    if (name.isEmpty) {
      throw const VoucherBookException('Name is required');
    }
    if (name.length > 120) {
      throw const VoucherBookException('Name is too long');
    }

    if (draft.isGroup) {
      if (draft.parentId != null && draft.parentId!.trim().isNotEmpty) {
        throw const VoucherBookException('Section groups cannot have a parent');
      }
      if (!VoucherBookType.sections.contains(draft.bookType)) {
        throw const VoucherBookException('Invalid section type');
      }
      return;
    }

    final parentId = draft.parentId?.trim();
    if (parentId == null || parentId.isEmpty) {
      throw const VoucherBookException('Parent section is required');
    }
    if (draft.currentNumber < 1) {
      throw const VoucherBookException('Current number must be at least 1');
    }
    if (draft.endNumber < 1) {
      throw const VoucherBookException('End number must be at least 1');
    }
    if (draft.endNumber < draft.currentNumber) {
      throw const VoucherBookException(
        'End number must be greater than or equal to current number',
      );
    }
    final allowed = VoucherBookType.leafKindsFor(draft.bookType.section);
    if (!allowed.contains(draft.bookType)) {
      throw const VoucherBookException('Invalid book type for section');
    }
  }
}
