import 'dart:typed_data';

import '../../domain/models/import_validation_exception.dart';
import 'excel_import_datasource.dart';

class IsolateImportOutcome {
  const IsolateImportOutcome.success(this.result) : errorCode = null;

  const IsolateImportOutcome.failure(this.errorCode) : result = null;

  final ImportResult? result;
  final String? errorCode;

  bool get isSuccess => result != null;
}

/// Top-level entry point for isolate-based Excel parsing.
IsolateImportOutcome importInventoryExcelIsolate(Uint8List bytes) {
  try {
    final result = ExcelImportDatasource().importBytes(bytes);
    return IsolateImportOutcome.success(result);
  } on ImportValidationException catch (error) {
    return IsolateImportOutcome.failure(error.code);
  } catch (_) {
    return const IsolateImportOutcome.failure(
      ImportValidationException.decodeFailed,
    );
  }
}
