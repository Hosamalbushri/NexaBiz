import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../../../core/utils/grouped_decimal_input.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/models/import_validation_exception.dart';
import '../../domain/services/pack_size_parser.dart';

class ImportResult {
  const ImportResult({
    required this.items,
    required this.importedCount,
    required this.ignoredCount,
    this.duplicateCount = 0,
    this.warnings = const [],
  });

  final List<InventoryItem> items;
  final int importedCount;
  final int ignoredCount;
  final int duplicateCount;
  final List<String> warnings;
}

/// Parses inventory rows from an Excel workbook.
class ExcelImportDatasource {
  ExcelImportDatasource({PackSizeParser? packSizeParser})
    : _packSizeParser = packSizeParser ?? const PackSizeParser();

  final PackSizeParser _packSizeParser;

  ImportResult importBytes(Uint8List bytes) {
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
    final columnIndex = _resolveColumns(header);
    final warnings = <String>[];

    if (columnIndex.codeUnresolved || columnIndex.nameUnresolved) {
      warnings.add('headers_fallback');
    }

    final itemsByCode = <String, InventoryItem>{};
    var ignored = 0;
    var duplicates = 0;

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final code = _cellString(row, columnIndex.code);
      final name = _cellString(row, columnIndex.name);
      if (code == null || code.isEmpty || name == null || name.isEmpty) {
        ignored++;
        continue;
      }

      final barcode = _cellString(row, columnIndex.barcode);
      final packSize =
          _packSizeParser.parse(name) ?? _cellInt(row, columnIndex.packSize);

      final systemQty = _resolveSystemQuantity(
        row: row,
        columns: columnIndex,
        packSize: packSize,
      );

      final item = InventoryItem(
        itemCode: code,
        itemName: name,
        barcode: barcode,
        packSize: packSize,
        systemQuantity: systemQty,
      );

      if (itemsByCode.containsKey(code)) {
        duplicates++;
      }
      itemsByCode[code] = item;
    }

    if (itemsByCode.isEmpty) {
      throw const ImportValidationException(
        ImportValidationException.noValidRows,
      );
    }

    final items = itemsByCode.values.toList(growable: false);
    return ImportResult(
      items: items,
      importedCount: items.length,
      ignoredCount: ignored,
      duplicateCount: duplicates,
      warnings: warnings,
    );
  }

  double _resolveSystemQuantity({
    required List<Data?> row,
    required _ColumnMap columns,
    required int? packSize,
  }) {
    final main = _cellDouble(row, columns.mainQuantity);
    final sub = _cellDouble(row, columns.subQuantity);
    final legacy = _cellDouble(row, columns.legacySystemQuantity);

    if (main != null || sub != null) {
      final mainValue = main ?? 0;
      final subValue = sub ?? 0;
      final pack = (packSize != null && packSize > 0) ? packSize : 1;
      // Stored as main + fractional sub units (matches [InventoryItem] getters).
      return mainValue + (subValue / pack);
    }

    return legacy ?? 0;
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
    ]);
    final name = find(const [
      'item name',
      'itemname',
      'name',
      'اسم السلعة',
      'الاسم',
    ]);
    final mainQuantity = find(const [
      'main quantity',
      'main qty',
      'system main quantity',
      'system main qty',
      'الكمية الرئيسية',
      'كمية رئيسية',
    ]);
    final subQuantity = find(const [
      'sub quantity',
      'sub qty',
      'secondary quantity',
      'system sub quantity',
      'system sub qty',
      'الكمية الفرعية',
      'كمية فرعية',
    ]);
    final legacySystemQuantity = find(const [
      'system quantity',
      'quantity',
      'qty',
      'الكمية النظامية',
      'الكمية',
    ]);

    return _ColumnMap(
      code: code ?? 0,
      name: name ?? 1,
      barcode: find(const ['barcode', 'الباركود']),
      mainQuantity: mainQuantity ?? (legacySystemQuantity == null ? 2 : null),
      subQuantity: subQuantity ?? (legacySystemQuantity == null ? 3 : null),
      legacySystemQuantity: legacySystemQuantity,
      packSize: find(const ['pack size', 'packsize', 'حجم العبوة']),
      codeUnresolved: code == null,
      nameUnresolved: name == null,
    );
  }

  String? _cellString(List<Data?> row, int? index) {
    if (index == null || index >= row.length) {
      return null;
    }
    final value = row[index]?.value;
    if (value == null) {
      return null;
    }
    if (value is IntCellValue) {
      return value.value.toString();
    }
    if (value is DoubleCellValue) {
      final number = value.value;
      if (number.isFinite && number == number.roundToDouble()) {
        return number.toInt().toString();
      }
      return number.toString();
    }
    if (value is TextCellValue) {
      return value.value.toString().trim();
    }
    return value.toString().trim();
  }

  double? _cellDouble(List<Data?> row, int? index) {
    final raw = _cellString(row, index);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return parseGroupedDecimal(raw);
  }

  int? _cellInt(List<Data?> row, int? index) {
    final value = _cellDouble(row, index);
    return value?.round();
  }
}

class _ColumnMap {
  const _ColumnMap({
    required this.code,
    required this.name,
    required this.barcode,
    required this.mainQuantity,
    required this.subQuantity,
    required this.legacySystemQuantity,
    required this.packSize,
    this.codeUnresolved = false,
    this.nameUnresolved = false,
  });

  final int code;
  final int name;
  final int? barcode;
  final int? mainQuantity;
  final int? subQuantity;
  final int? legacySystemQuantity;
  final int? packSize;
  final bool codeUnresolved;
  final bool nameUnresolved;
}
