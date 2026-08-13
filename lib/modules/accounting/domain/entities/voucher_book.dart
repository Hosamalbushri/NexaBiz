import 'voucher_book_type.dart';

/// Numbering book or section group for sequential voucher numbers.
class VoucherBook {
  const VoucherBook({
    required this.id,
    required this.uuid,
    required this.name,
    required this.bookType,
    required this.isGroup,
    required this.currentNumber,
    required this.endNumber,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
    this.notes,
  });

  final int id;
  final String uuid;

  /// Parent section group uuid; null for roots.
  final String? parentId;

  final String name;
  final VoucherBookType bookType;

  /// When true, this row is a section folder (children hold the sequences).
  final bool isGroup;

  /// Current number in the book (next value to allocate).
  final int currentNumber;

  /// Last number available in this book.
  final int endNumber;

  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;

  bool get canAllocate =>
      !isGroup && isActive && currentNumber >= 1 && currentNumber <= endNumber;

  bool get isExhausted => !isGroup && currentNumber > endNumber;

  VoucherBook copyWith({
    int? id,
    String? uuid,
    String? parentId,
    bool clearParentId = false,
    String? name,
    VoucherBookType? bookType,
    bool? isGroup,
    int? currentNumber,
    int? endNumber,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    bool clearNotes = false,
  }) {
    return VoucherBook(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      name: name ?? this.name,
      bookType: bookType ?? this.bookType,
      isGroup: isGroup ?? this.isGroup,
      currentNumber: currentNumber ?? this.currentNumber,
      endNumber: endNumber ?? this.endNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }
}

class VoucherBookDraft {
  const VoucherBookDraft({
    required this.name,
    required this.bookType,
    this.parentId,
    this.isGroup = false,
    this.currentNumber = 1,
    this.endNumber = 9999,
    this.isActive = true,
    this.notes,
  });

  final String name;
  final VoucherBookType bookType;
  final String? parentId;
  final bool isGroup;
  final int currentNumber;
  final int endNumber;
  final bool isActive;
  final String? notes;
}

/// Section group with its child numbering books.
class VoucherBookSectionNode {
  const VoucherBookSectionNode({required this.group, required this.children});

  final VoucherBook group;
  final List<VoucherBook> children;
}
