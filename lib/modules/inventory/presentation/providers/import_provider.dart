import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/excel_import_isolate.dart';
import '../../domain/models/import_session.dart';
import '../../domain/models/import_validation_exception.dart';
import 'inventory_providers.dart';

class ImportUiState {
  const ImportUiState({
    this.selectedFileName,
    this.bytes,
    this.isImporting = false,
    this.progress = 0,
    this.progressLabelKey,
    this.result,
    this.errorMessage,
    this.duplicateCount = 0,
  });

  final String? selectedFileName;
  final Uint8List? bytes;
  final bool isImporting;
  final double progress;
  final String? progressLabelKey;
  final ImportSessionResult? result;
  final String? errorMessage;
  final int duplicateCount;

  bool get hasSelectedFile => bytes != null && bytes!.isNotEmpty;

  ImportUiState copyWith({
    String? selectedFileName,
    Uint8List? bytes,
    bool? isImporting,
    double? progress,
    String? progressLabelKey,
    ImportSessionResult? result,
    String? errorMessage,
    int? duplicateCount,
    bool clearResult = false,
    bool clearError = false,
    bool clearProgressLabel = false,
  }) {
    return ImportUiState(
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
    );
  }
}

class ImportNotifier extends StateNotifier<ImportUiState> {
  ImportNotifier(this._ref) : super(const ImportUiState());

  final Ref _ref;

  void setSelectedFile({required String fileName, required Uint8List bytes}) {
    state = ImportUiState(selectedFileName: fileName, bytes: bytes);
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
    );

    try {
      final outcome = await compute(importInventoryExcelIsolate, bytes);
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

      await _ref.read(replaceInventoryItemsProvider).call(imported.items);
      bumpInventoryRevision(_ref);

      final result = ImportSessionResult(
        importedCount: imported.importedCount,
        ignoredCount: imported.ignoredCount,
      );
      state = state.copyWith(
        isImporting: false,
        progress: 1,
        clearProgressLabel: true,
        result: result,
        duplicateCount: imported.duplicateCount,
      );
      return result;
    } catch (error) {
      state = state.copyWith(
        isImporting: false,
        progress: 0,
        clearProgressLabel: true,
        errorMessage: error.toString(),
      );
      return null;
    }
  }
}

final importProvider =
    StateNotifierProvider.autoDispose<ImportNotifier, ImportUiState>((ref) {
      return ImportNotifier(ref);
    });
