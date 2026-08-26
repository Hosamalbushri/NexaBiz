import 'dart:typed_data';

import 'package:stock_count/modules/inventory/stock_count/domain/models/import_validation_exception.dart';
import 'product_excel_import_datasource.dart';

/// Isolate entry for parsing product Excel bytes (no Flutter bindings).
ProductImportIsolateOutcome importProductsExcelIsolate(Uint8List bytes) {
  try {
    const datasource = ProductExcelImportDatasource();
    final result = datasource.importBytes(bytes);
    return ProductImportIsolateOutcome.success(result);
  } on ImportValidationException catch (error) {
    return ProductImportIsolateOutcome.failure(error.code);
  } catch (_) {
    return ProductImportIsolateOutcome.failure(
      ImportValidationException.decodeFailed,
    );
  }
}

class ProductImportIsolateOutcome {
  const ProductImportIsolateOutcome._({this.result, this.errorCode});

  factory ProductImportIsolateOutcome.success(ProductImportResult result) {
    return ProductImportIsolateOutcome._(result: result);
  }

  factory ProductImportIsolateOutcome.failure(String errorCode) {
    return ProductImportIsolateOutcome._(errorCode: errorCode);
  }

  final ProductImportResult? result;
  final String? errorCode;

  bool get isSuccess => result != null;
}
