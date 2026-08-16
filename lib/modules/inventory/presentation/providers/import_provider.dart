import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/notifications/presentation/providers/notifications_provider.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/notifications/notification_type.dart';
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
    bool clearBytes = false,
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
      bytes: clearBytes ? null : (bytes ?? this.bytes),
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
  KeepAliveLink? _keepAlive;

  void setSelectedFile({required String fileName, required Uint8List bytes}) {
    state = ImportUiState(selectedFileName: fileName, bytes: bytes);
  }

  Future<ImportSessionResult?> importFile() async {
    final bytes = state.bytes;
    if (bytes == null || bytes.isEmpty) {
      state = state.copyWith(errorMessage: 'no_file', clearResult: true);
      return null;
    }
    if (state.isImporting) {
      return null;
    }

    _keepAlive ??= _ref.keepAlive();

    state = state.copyWith(
      isImporting: true,
      progress: 0.1,
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
        await _notifyFailure(state.errorMessage!);
        return null;
      }

      final imported = outcome.result!;
      state = state.copyWith(
        progress: 0.4,
        progressLabelKey: 'saving',
        duplicateCount: imported.duplicateCount,
      );

      await _ref
          .read(replaceInventoryItemsProvider)
          .call(
            imported.items,
            onProgress: (processed, total) {
              if (total <= 0) {
                return;
              }
              state = state.copyWith(
                progress: 0.4 + ((processed / total) * 0.55),
                progressLabelKey: 'saving',
              );
            },
          );
      bumpInventoryRevision(_ref);

      final result = ImportSessionResult(
        importedCount: imported.importedCount,
        ignoredCount: imported.ignoredCount,
      );
      state = state.copyWith(
        isImporting: false,
        progress: 1,
        clearProgressLabel: true,
        clearBytes: true,
        result: result,
        duplicateCount: imported.duplicateCount,
      );
      await _notifySuccess(result);
      return result;
    } on ImportValidationException catch (error) {
      state = state.copyWith(
        isImporting: false,
        progress: 0,
        clearProgressLabel: true,
        errorMessage: error.code,
      );
      await _notifyFailure(error.code);
      return null;
    } catch (_) {
      state = state.copyWith(
        isImporting: false,
        progress: 0,
        clearProgressLabel: true,
        errorMessage: ImportValidationException.decodeFailed,
      );
      await _notifyFailure(ImportValidationException.decodeFailed);
      return null;
    } finally {
      _keepAlive?.close();
      _keepAlive = null;
    }
  }

  Future<void> _notifySuccess(ImportSessionResult result) async {
    final l10n = _l10n;
    await _ref
        .read(notificationServiceProvider)
        .showSuccess(
          title: l10n.importPageTitle,
          message: l10n.importedItemsCount(result.importedCount),
          category: NotificationCategory.general,
          persistToHistory: true,
        );
  }

  Future<void> _notifyFailure(String code) async {
    final l10n = _l10n;
    await _ref
        .read(notificationServiceProvider)
        .showError(
          title: l10n.importFailed,
          message: _errorMessage(l10n, code),
          category: NotificationCategory.general,
          persistToHistory: true,
        );
  }

  AppLocalizations get _l10n {
    final locale =
        _ref.read(localeProvider) ?? AppLocalizations.supportedLocales.first;
    return lookupAppLocalizations(locale);
  }

  String _errorMessage(AppLocalizations localization, String code) {
    switch (code) {
      case 'no_file':
        return localization.fileSelectedPrompt;
      case ImportValidationException.emptyWorkbook:
        return localization.emptyWorkbook;
      case ImportValidationException.noValidRows:
        return localization.noValidRows;
      case ImportValidationException.decodeFailed:
        return localization.invalidFile;
      default:
        return code;
    }
  }
}

final importProvider =
    StateNotifierProvider.autoDispose<ImportNotifier, ImportUiState>((ref) {
      return ImportNotifier(ref);
    });
