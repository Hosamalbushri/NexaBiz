import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../../../core/utils/id_generator.dart';
import '../../domain/models/account_import_row.dart';

/// Parses Chart of Accounts structure rows from Excel (code + name only).
///
/// Columns: code (optional), name (required).
/// Without headers, positional order is code, name.
class AccountExcelImportDatasource {
  const AccountExcelImportDatasource();

  AccountExcelParseResult parseBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const AccountImportException(
        AccountImportException.decodeFailed,
        'Empty file bytes',
      );
    }

    final Excel excel;
    try {
      excel = Excel.decodeBytes(bytes);
    } catch (error) {
      throw AccountImportException(
        AccountImportException.decodeFailed,
        error.toString(),
      );
    }

    if (excel.tables.isEmpty) {
      throw const AccountImportException(AccountImportException.emptyWorkbook);
    }

    final sheet = excel.tables.values.first;
    if (sheet.rows.isEmpty) {
      throw const AccountImportException(AccountImportException.emptyWorkbook);
    }

    final header = sheet.rows.first;
    final columns = _resolveColumns(header);
    final warnings = <String>[];
    if (columns.unresolved) {
      warnings.add('headers_fallback');
    }

    final startRow = columns.hasHeaderRow ? 1 : 0;
    final rows = <AccountImportRow>[];
    var ignored = 0;

    for (var i = startRow; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final code = columns.code == null
          ? ''
          : (_cellString(row, columns.code!) ?? '');
      final name = columns.name == null
          ? ''
          : (_cellString(row, columns.name!) ?? '');

      final empty = name.trim().isEmpty && code.trim().isEmpty;
      if (empty) {
        ignored++;
        continue;
      }
      if (name.trim().isEmpty) {
        ignored++;
        continue;
      }

      rows.add(
        AccountImportRow(
          id: generateUuidV4(),
          code: code.trim(),
          name: name.trim(),
        ),
      );
    }

    if (rows.isEmpty) {
      throw const AccountImportException(AccountImportException.noValidRows);
    }

    return AccountExcelParseResult(
      rows: rows,
      ignoredCount: ignored,
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
      'account code',
      'accountcode',
      'code',
      'رمز الحساب',
      'رمز',
      'الرمز',
    ]);
    final name = find(const [
      'account name',
      'accountname',
      'name',
      'اسم الحساب',
      'الاسم',
      'اسم',
    ]);

    final hasHeader = code != null || name != null;
    if (!hasHeader) {
      return const _ColumnMap(
        code: 0,
        name: 1,
        hasHeaderRow: false,
        unresolved: true,
      );
    }

    return _ColumnMap(
      code: code,
      name: name,
      hasHeaderRow: true,
      unresolved: name == null,
    );
  }

  String? _cellString(List<Data?> row, int index) {
    if (index < 0 || index >= row.length) {
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
}

class _ColumnMap {
  const _ColumnMap({
    required this.code,
    required this.name,
    required this.hasHeaderRow,
    this.unresolved = false,
  });

  final int? code;
  final int? name;
  final bool hasHeaderRow;
  final bool unresolved;
}
