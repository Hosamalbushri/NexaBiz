import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/inventory_item.dart';
import '../../domain/models/report_export_labels.dart';

/// Exports inventory items to a localized Excel file on disk.
class ExcelExportDatasource {
  Future<String> export({
    required List<InventoryItem> items,
    required ReportExportLabels labels,
  }) async {
    final excel = Excel.createExcel();
    final sheetName = labels.sheetName;
    final sheet = excel[sheetName];
    if (excel.sheets.keys.contains('Sheet1') && sheetName != 'Sheet1') {
      excel.delete('Sheet1');
    }

    sheet.appendRow([
      TextCellValue(labels.reportSection),
      TextCellValue(labels.filterLabel),
    ]);
    sheet.appendRow([]);

    sheet.appendRow([
      TextCellValue(labels.code),
      TextCellValue(labels.name),
      TextCellValue(labels.systemMainQuantity),
      TextCellValue(labels.systemSubQuantity),
      TextCellValue(labels.countedMainQuantity),
      TextCellValue(labels.countedSubQuantity),
      TextCellValue(labels.varianceMainQuantity),
      TextCellValue(labels.varianceSubQuantity),
      TextCellValue(labels.status),
    ]);

    for (final item in items) {
      sheet.appendRow([
        TextCellValue(item.itemCode),
        TextCellValue(item.itemName),
        DoubleCellValue(item.systemMainQuantity),
        DoubleCellValue(item.systemSubQuantity),
        item.mainQuantity == null
            ? TextCellValue('')
            : DoubleCellValue(item.mainQuantity!),
        item.subQuantity == null
            ? TextCellValue('')
            : DoubleCellValue(item.subQuantity!),
        item.isCounted
            ? DoubleCellValue(item.differenceMainQuantity)
            : TextCellValue(''),
        item.isCounted
            ? DoubleCellValue(item.differenceSubQuantity)
            : TextCellValue(''),
        TextCellValue(labels.statusLabel(item.status)),
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final path =
        '${directory.path}/inventory_report_${labels.localeCode}_$timestamp.xlsx';
    final fileBytes = excel.encode();
    if (fileBytes == null) {
      throw StateError('Failed to encode Excel workbook.');
    }
    final file = File(path);
    await file.writeAsBytes(fileBytes, flush: true);
    return path;
  }
}
