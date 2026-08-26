import 'dart:typed_data';

import '../../domain/models/import_validation_exception.dart';
import 'customer_excel_import_datasource.dart';

/// Isolate entry for parsing customer Excel bytes (no Flutter bindings).
CustomerImportIsolateOutcome importCustomersExcelIsolate(Uint8List bytes) {
  try {
    const datasource = CustomerExcelImportDatasource();
    final result = datasource.importBytes(bytes);
    return CustomerImportIsolateOutcome.success(result);
  } on ImportValidationException catch (error) {
    return CustomerImportIsolateOutcome.failure(error.code);
  } catch (_) {
    return CustomerImportIsolateOutcome.failure(
      ImportValidationException.decodeFailed,
    );
  }
}

class CustomerImportIsolateOutcome {
  const CustomerImportIsolateOutcome._({this.result, this.errorCode});

  factory CustomerImportIsolateOutcome.success(CustomerImportResult result) {
    return CustomerImportIsolateOutcome._(result: result);
  }

  factory CustomerImportIsolateOutcome.failure(String errorCode) {
    return CustomerImportIsolateOutcome._(errorCode: errorCode);
  }

  final CustomerImportResult? result;
  final String? errorCode;

  bool get isSuccess => result != null;
}
