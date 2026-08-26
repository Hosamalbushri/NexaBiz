import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_data_source.dart';
import '../../domain/models/import_validation_exception.dart';

class CustomerImportResult {
  const CustomerImportResult({
    required this.drafts,
    required this.importedCount,
    required this.ignoredCount,
    this.duplicateCount = 0,
    this.warnings = const [],
  });

  final List<CustomerDraft> drafts;
  final int importedCount;
  final int ignoredCount;
  final int duplicateCount;
  final List<String> warnings;
}

/// Parses customer master rows from Excel.
///
/// Required columns: customer code, name.
/// Optional: phone, email, address, notes, external id.
class CustomerExcelImportDatasource {
  const CustomerExcelImportDatasource();

  CustomerImportResult importBytes(Uint8List bytes) {
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

    final draftsByCode = <String, CustomerDraft>{};
    var ignored = 0;
    var duplicates = 0;

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final code = _cellString(row, columns.code);
      final name = _cellString(row, columns.name);

      if (code == null || code.isEmpty || name == null || name.isEmpty) {
        ignored++;
        continue;
      }

      final externalId = columns.externalId == null
          ? null
          : _cellString(row, columns.externalId!);
      final hasExternal = externalId != null && externalId.trim().isNotEmpty;

      final draft = CustomerDraft(
        customerCode: code,
        name: name,
        phone: columns.phone == null ? null : _cellString(row, columns.phone!),
        email: columns.email == null ? null : _cellString(row, columns.email!),
        address: columns.address == null
            ? null
            : _cellString(row, columns.address!),
        notes: columns.notes == null ? null : _cellString(row, columns.notes!),
        externalId: hasExternal ? externalId : null,
        dataSource: hasExternal
            ? CustomerDataSource.external
            : CustomerDataSource.local,
      );

      final key = code.trim().toUpperCase();
      if (draftsByCode.containsKey(key)) {
        duplicates++;
      }
      draftsByCode[key] = draft;
    }

    if (draftsByCode.isEmpty) {
      throw const ImportValidationException(
        ImportValidationException.noValidRows,
      );
    }

    final drafts = draftsByCode.values.toList(growable: false);
    return CustomerImportResult(
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
      'customer code',
      'customercode',
      'code',
      'رمز العميل',
      'رمز',
      'الرمز',
    ]);
    final name = find(const [
      'customer name',
      'customername',
      'name',
      'اسم العميل',
      'الاسم',
      'اسم',
    ]);
    final phone = find(const [
      'phone',
      'mobile',
      'tel',
      'الهاتف',
      'جوال',
      'موبايل',
    ]);
    final email = find(const [
      'email',
      'e-mail',
      'البريد',
      'البريد الإلكتروني',
      'ايميل',
    ]);
    final address = find(const ['address', 'العنوان', 'عنوان']);
    final notes = find(const ['notes', 'note', 'ملاحظات', 'ملاحظة']);
    final externalId = find(const [
      'external id',
      'externalid',
      'ext id',
      'المعرف الخارجي',
      'معرف خارجي',
    ]);

    return _ColumnMap(
      code: code ?? 0,
      name: name ?? 1,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
      externalId: externalId,
      unresolved: code == null || name == null,
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
    // Excel often stores codes as numbers; DoubleCellValue → "12210001.0".
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
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.externalId,
    this.unresolved = false,
  });

  final int code;
  final int name;
  final int? phone;
  final int? email;
  final int? address;
  final int? notes;
  final int? externalId;
  final bool unresolved;
}
