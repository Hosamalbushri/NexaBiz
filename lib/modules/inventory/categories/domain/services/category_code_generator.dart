import '../entities/category.dart';
import '../repositories/category_repository.dart';

/// Builds the next sequential Inventory Category code under a parent category or root warehouse.
class CategoryCodeGenerator {
  const CategoryCodeGenerator(this._repository);

  final CategoryRepository _repository;

  static const int sequenceWidth = 2;

  /// Generates the next recommended code under a parent category or warehouse.
  Future<String> generate({
    required String warehouseId,
    Category? parentCategory,
  }) async {
    final allCategories = await _repository.getAllCategories();
    final whCategories = allCategories
        .where((c) => c.warehouseId == warehouseId && !c.isDeleted)
        .toList();

    if (parentCategory == null) {
      // Root category under warehouse
      final rootCategories =
          whCategories.where((c) => c.parentId == null).toList();
      var maxRootNum = 0;

      for (final cat in rootCategories) {
        final val = int.tryParse(cat.code.trim());
        if (val != null && val > maxRootNum) {
          maxRootNum = val;
        }
      }

      final nextCode = maxRootNum == 0 ? 1000 : ((maxRootNum ~/ 1000) + 1) * 1000;
      return nextCode.toString();
    } else {
      // Subcategory under parent
      final parentCode = parentCategory.code.trim();
      final siblings = whCategories
          .where((c) => c.parentId == parentCategory.id)
          .toList();

      var maxSiblingNum = 0;

      for (final sibling in siblings) {
        final codeStr = sibling.code.trim();
        final val = int.tryParse(codeStr);
        if (val != null && val > maxSiblingNum) {
          maxSiblingNum = val;
        } else if (codeStr.startsWith(parentCode)) {
          final suffix = codeStr.substring(parentCode.length);
          final suffixVal = int.tryParse(suffix);
          if (suffixVal != null && suffixVal > maxSiblingNum) {
            maxSiblingNum = suffixVal;
          }
        }
      }

      if (maxSiblingNum == 0) {
        return '$parentCode${1.toString().padLeft(sequenceWidth, '0')}';
      } else {
        return (maxSiblingNum + 1).toString();
      }
    }
  }
}
