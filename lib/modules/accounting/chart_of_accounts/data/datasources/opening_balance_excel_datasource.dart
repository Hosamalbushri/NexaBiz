import 'dart:typed_data';

import 'package:excel/excel.dart';

import 'package:stock_count/core/utils/grouped_decimal_input.dart';
import 'package:stock_count/core/utils/id_generator.dart';
import '../../domain/models/account_import_row.dart';
import '../../domain/models/opening_balance_line.dart';

/// Parsed opening-balance Excel rows before account resolution.
class OpeningBalanceExcelParseResult {
  const OpeningBalanceExcelParseResult({
    required this.rows,
    this.ignoredCount = 0,
    this.warnings = const [],
  });

  final List<OpeningBalanceExcelRawRow> rows;
  final int ignoredCount;
  final List<String> warnings;
}

class OpeningBalanceExcelRawRow {
  const OpeningBalanceExcelRawRow({
    required this.accountCode,
    required this.accountId,
    required this.currencyCode,
    required this.debit,
    required this.credit,
  });

  final String accountCode;
  final String accountId;
  final String currencyCode;
  final double debit;
  final double credit;
}

/// Parses opening-balance lines from Excel.
///
/// Columns: Code or AccountId, Currency, Debit, Credit.
class OpeningBalanceExcelDatasource {
  const OpeningBalanceExcelDatasource();

  OpeningBalanceExcelParseResult parseBytes(Uint8List bytes) {
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
    final rows = <OpeningBalanceExcelRawRow>[];
    var ignored = 0;

    for (var i = startRow; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final code = columns.code == null
          ? ''
          : (_cellString(row, columns.code!) ?? '');
      final accountId = columns.accountId == null
          ? ''
          : (_cellString(row, columns.accountId!) ?? '');
      final currency = columns.currency == null
          ? ''
          : (_cellString(row, columns.currency!) ?? '');
      final debit = columns.debit == null
          ? 0.0
          : (_cellDouble(row, columns.debit!) ?? 0);
      final credit = columns.credit == null
          ? 0.0
          : (_cellDouble(row, columns.credit!) ?? 0);

      final empty = code.trim().isEmpty &&
          accountId.trim().isEmpty &&
          debit <= 0 &&
          credit <= 0;
      if (empty) {
        ignored++;
        continue;
      }
      if (code.trim().isEmpty && accountId.trim().isEmpty) {
        ignored++;
        continue;
      }

      rows.add(
        OpeningBalanceExcelRawRow(
          accountCode: code.trim(),
          accountId: accountId.trim(),
          currencyCode: currency.trim().toUpperCase(),
          debit: debit < 0 ? 0 : debit,
          credit: credit < 0 ? 0 : credit,
        ),
      );
    }

    if (rows.isEmpty) {
      throw const AccountImportException(AccountImportException.noValidRows);
    }

    return OpeningBalanceExcelParseResult(
      rows: rows,
      ignoredCount: ignored,
      warnings: warnings,
    );
  }

  /// Builds [OpeningBalanceLine]s from raw Excel rows using a lookup.
  List<OpeningBalanceLine> resolveRows({
    required List<OpeningBalanceExcelRawRow> rawRows,
    required Map<String, ({String id, String code, String name})> byCode,
    required Map<String, ({String id, String code, String name})> byId,
  }) {
    final lines = <OpeningBalanceLine>[];
    for (final raw in rawRows) {
      final account = raw.accountId.isNotEmpty
          ? byId[raw.accountId]
          : byCode[raw.accountCode];
      if (account == null) {
        throw AccountImportException(
          AccountImportException.accountNotFound,
          raw.accountId.isNotEmpty ? raw.accountId : raw.accountCode,
        );
      }
      lines.add(
        OpeningBalanceLine(
          id: generateUuidV4(),
          accountId: account.id,
          accountCode: account.code,
          accountName: account.name,
          currencyCode: raw.currencyCode,
          debit: raw.debit,
          credit: raw.credit,
        ),
      );
    }
    return lines;
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
    final accountId = find(const [
      'account id',
      'accountid',
      'uuid',
      'id',
      'معرف الحساب',
      'المعرف',
    ]);
    final currency = find(const [
      'currency',
      'currency code',
      'currencycode',
      'عملة',
      'العملة',
      'رمز العملة',
    ]);
    final debit = find(const [
      'opening debit',
      'openingdebit',
      'debit',
      'مدين افتتاحي',
      'مدين',
      'الرصيد المدين',
    ]);
    final credit = find(const [
      'opening credit',
      'openingcredit',
      'credit',
      'دائن افتتاحي',
      'دائن',
      'الرصيد الدائن',
    ]);

    final hasHeader = code != null ||
        accountId != null ||
        currency != null ||
        debit != null ||
        credit != null;
    if (!hasHeader) {
      return const _ColumnMap(
        code: 0,
        accountId: null,
        currency: 1,
        debit: 2,
        credit: 3,
        hasHeaderRow: false,
        unresolved: true,
      );
    }

    return _ColumnMap(
      code: code,
      accountId: accountId,
      currency: currency,
      debit: debit,
      credit: credit,
      hasHeaderRow: true,
      unresolved: code == null && accountId == null,
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

  double? _cellDouble(List<Data?> row, int index) {
    if (index < 0 || index >= row.length) {
      return null;
    }
    final value = row[index]?.value;
    if (value == null) {
      return null;
    }
    if (value is IntCellValue) {
      return value.value.toDouble();
    }
    if (value is DoubleCellValue) {
      return value.value;
    }
    if (value is TextCellValue) {
      return parseGroupedDecimal(value.value.toString());
    }
    return parseGroupedDecimal(value.toString());
  }
}

class _ColumnMap {
  const _ColumnMap({
    required this.code,
    required this.accountId,
    required this.currency,
    required this.debit,
    required this.credit,
    required this.hasHeaderRow,
    this.unresolved = false,
  });

  final int? code;
  final int? accountId;
  final int? currency;
  final int? debit;
  final int? credit;
  final bool hasHeaderRow;
  final bool unresolved;
}
