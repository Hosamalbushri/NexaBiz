import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../domain/entities/product.dart';
import '../../domain/models/import_validation_exception.dart';

class ProductImportResult {
  const ProductImportResult({
    required this.drafts,
    required this.importedCount,
    required this.ignoredCount,
    this.duplicateCount = 0,
    this.warnings = const [],
  });

  final List<ProductDraft> drafts;
  final int importedCount;
  final int ignoredCount;
  final int duplicateCount;
  final List<String> warnings;
}

/// Parses product catalog rows from Excel (separate from stock-count import).
///
/// Required columns: item code, name, pack size, price.
class ProductExcelImportDatasource {
  const ProductExcelImportDatasource();

  ProductImportResult importBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const ImportValidationException(
        ImportValidationException.decodeFailed,
        'Empty file bytes',
      );
    }

    final Excel excel;
    try {
      excel = Excel.decodeBytes(bytes);
    } catch (error) {
      throw ImportValidationException(
        ImportValidationException.decodeFailed,
        error.toString(),
      );
    }

    if (excel.tables.isEmpty) {
      throw const ImportValidationException(
        ImportValidationException.emptyWorkbook,
      );
    }

    final sheet = excel.tables.values.first;
    if (sheet.rows.isEmpty) {
      throw const ImportValidationException(
        ImportValidationException.emptyWorkbook,
      );
    }

    final header = sheet.rows.first;
    final columns = _resolveColumns(header);
    final warnings = <String>[];
    if (columns.unresolved) {
      warnings.add('headers_fallback');
    }

    final draftsByCode = <String, ProductDraft>{};
    var ignored = 0;
    var duplicates = 0;

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final code = _cellString(row, columns.code);
      final name = _cellString(row, columns.name);
      final packSize = _cellInt(row, columns.packSize);
      final price = _cellDouble(row, columns.price);

      if (code == null ||
          code.isEmpty ||
          name == null ||
          name.isEmpty ||
          packSize == null ||
          packSize <= 0 ||
          price == null ||
          price < 0) {
        ignored++;
        continue;
      }

      final draft = ProductDraft(
        itemCode: code,
        name: name,
        packSize: packSize,
        price: price,
      );

      if (draftsByCode.containsKey(code)) {
        duplicates++;
      }
      draftsByCode[code] = draft;
    }

    if (draftsByCode.isEmpty) {
      throw const ImportValidationException(
        ImportValidationException.noValidRows,
      );
    }

    final drafts = draftsByCode.values.toList(growable: false);
    return ProductImportResult(
      drafts: drafts,
      importedCount: drafts.length,
      ignoredCount: ignored,
      duplicateCount: duplicates,
      warnings: warnings,
    );
  }

  _ColumnMap _resolveColumns(List<Data?> header) {
    int? find(List<String> aliases) {
      for (var i = 0; i < header.length; i++) {
        final value = header[i]?.value?.toString().trim().toLowerCase() ?? '';
        if (aliases.contains(value)) {
          return i;
        }
      }
      return null;
    }

    final code = find(const [
      'item code',
      'itemcode',
      'code',
      'رقم السلعة',
      'الرمز',
      'رمز',
    ]);
    final name = find(const [
      'item name',
      'itemname',
      'name',
      'اسم السلعة',
      'الاسم',
      'اسم',
    ]);
    final packSize = find(const [
      'pack size',
      'packsize',
      'pack',
      'حجم العبوة',
      'العبوة',
      'عبوة',
    ]);
    final price = find(const [
      'price',
      'unit price',
      'السعر',
      'سعر',
    ]);

    return _ColumnMap(
      code: code ?? 0,
      name: name ?? 1,
      packSize: packSize ?? 2,
      price: price ?? 3,
      unresolved: code == null ||
          name == null ||
          packSize == null ||
          price == null,
    );
  }

  String? _cellString(List<Data?> row, int index) {
    if (index >= row.length) {
      return null;
    }
    final value = row[index]?.value;
    if (value == null) {
      return null;
    }
    return value.toString().trim();
  }

  double? _cellDouble(List<Data?> row, int index) {
    final raw = _cellString(row, index);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return double.tryParse(raw.replaceAll(',', ''));
  }

  int? _cellInt(List<Data?> row, int index) {
    final value = _cellDouble(row, index);
    return value?.round();
  }
}

class _ColumnMap {
  const _ColumnMap({
    required this.code,
    required this.name,
    required this.packSize,
    required this.price,
    this.unresolved = false,
  });

  final int code;
  final int name;
  final int packSize;
  final int price;
  final bool unresolved;
}
