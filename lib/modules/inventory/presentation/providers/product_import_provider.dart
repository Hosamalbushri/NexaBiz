import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/product_excel_import_isolate.dart';
import '../../domain/models/import_session.dart';
import '../../domain/models/import_validation_exception.dart';
import 'product_providers.dart';

class ProductImportUiState {
  const ProductImportUiState({
    this.selectedFileName,
    this.bytes,
    this.isImporting = false,
    this.progress = 0,
    this.progressLabelKey,
    this.result,
    this.errorMessage,
    this.duplicateCount = 0,
    this.insertedCount = 0,
    this.updatedCount = 0,
  });

  final String? selectedFileName;
  final Uint8List? bytes;
  final bool isImporting;
  final double progress;
  final String? progressLabelKey;
  final ImportSessionResult? result;
  final String? errorMessage;
  final int duplicateCount;
  final int insertedCount;
  final int updatedCount;

  bool get hasSelectedFile => bytes != null && bytes!.isNotEmpty;

  ProductImportUiState copyWith({
    String? selectedFileName,
    Uint8List? bytes,
    bool? isImporting,
    double? progress,
    String? progressLabelKey,
    ImportSessionResult? result,
    String? errorMessage,
    int? duplicateCount,
    int? insertedCount,
    int? updatedCount,
    bool clearResult = false,
    bool clearError = false,
    bool clearProgressLabel = false,
  }) {
    return ProductImportUiState(
      selectedFileName: selectedFileName ?? this.selectedFileName,
      bytes: bytes ?? this.bytes,
      isImporting: isImporting ?? this.isImporting,
      progress: progress ?? this.progress,
      progressLabelKey: clearProgressLabel
          ? null
          : (progressLabelKey ?? this.progressLabelKey),
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      duplicateCount: duplicateCount ?? this.duplicateCount,
      insertedCount: insertedCount ?? this.insertedCount,
      updatedCount: updatedCount ?? this.updatedCount,
    );
  }
}

class ProductImportNotifier extends StateNotifier<ProductImportUiState> {
  ProductImportNotifier(this._ref) : super(const ProductImportUiState());

  final Ref _ref;

  void setSelectedFile({required String fileName, required Uint8List bytes}) {
    state = ProductImportUiState(selectedFileName: fileName, bytes: bytes);
  }

  Future<ImportSessionResult?> importFile() async {
    final bytes = state.bytes;
    if (bytes == null || bytes.isEmpty) {
      state = state.copyWith(errorMessage: 'no_file', clearResult: true);
      return null;
    }

    state = state.copyWith(
      isImporting: true,
      progress: 0.15,
      progressLabelKey: 'parsing',
      clearError: true,
      clearResult: true,
      duplicateCount: 0,
      insertedCount: 0,
      updatedCount: 0,
    );

    try {
      final outcome = await compute(importProductsExcelIsolate, bytes);
      if (!outcome.isSuccess) {
        state = state.copyWith(
          isImporting: false,
          progress: 0,
          clearProgressLabel: true,
          errorMessage:
              outcome.errorCode ?? ImportValidationException.decodeFailed,
        );
        return null;
      }

      final imported = outcome.result!;
      state = state.copyWith(
        progress: 0.65,
        progressLabelKey: 'saving',
        duplicateCount: imported.duplicateCount,
      );

      final upsert = await _ref
          .read(upsertProductsUseCaseProvider)
          .call(imported.drafts);
      bumpProductsRevision(_ref);

      final result = ImportSessionResult(
        importedCount: upsert.totalCount,
        ignoredCount: imported.ignoredCount,
      );
      state = state.copyWith(
        isImporting: false,
        progress: 1,
        clearProgressLabel: true,
        result: result,
        duplicateCount: imported.duplicateCount,
        insertedCount: upsert.insertedCount,
        updatedCount: upsert.updatedCount,
      );
      return result;
    } catch (_) {
      state = state.copyWith(
        isImporting: false,
        progress: 0,
        clearProgressLabel: true,
        errorMessage: ImportValidationException.decodeFailed,
      );
      return null;
    }
  }
}

final productImportProvider =
    StateNotifierProvider.autoDispose<
      ProductImportNotifier,
      ProductImportUiState
    >(ProductImportNotifier.new);
