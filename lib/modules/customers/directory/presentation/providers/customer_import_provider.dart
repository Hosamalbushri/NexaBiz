import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/notifications/presentation/providers/notifications_provider.dart';
import 'package:stock_count/app/presentation/providers/dashboard_services_provider.dart';
import 'package:stock_count/core/di/app_providers.dart';
import 'package:stock_count/core/notifications/notification_type.dart';
import '../../data/datasources/customer_excel_import_isolate.dart';
import '../../domain/models/customer_exception.dart';
import '../../domain/models/import_session.dart';
import '../../domain/models/import_validation_exception.dart';
import 'customer_providers.dart';

class CustomerImportUiState {
  const CustomerImportUiState({
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

  CustomerImportUiState copyWith({
    String? selectedFileName,
    Uint8List? bytes,
    bool clearBytes = false,
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
    return CustomerImportUiState(
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
      insertedCount: insertedCount ?? this.insertedCount,
      updatedCount: updatedCount ?? this.updatedCount,
    );
  }
}

class CustomerImportNotifier extends StateNotifier<CustomerImportUiState> {
  CustomerImportNotifier(this._ref) : super(const CustomerImportUiState());

  final Ref _ref;
  KeepAliveLink? _keepAlive;

  void setSelectedFile({required String fileName, required Uint8List bytes}) {
    state = CustomerImportUiState(selectedFileName: fileName, bytes: bytes);
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
      progress: 0.08,
      progressLabelKey: 'parsing',
      clearError: true,
      clearResult: true,
      duplicateCount: 0,
      insertedCount: 0,
      updatedCount: 0,
    );

    try {
      final outcome = await compute(importCustomersExcelIsolate, bytes);
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
        progress: 0.28,
        progressLabelKey: 'linking',
        duplicateCount: imported.duplicateCount,
      );

      var drafts = imported.drafts;
      final autoLink = await _ref
          .read(settingsRepositoryProvider)
          .loadCustomersAutoLinkAccount();
      if (autoLink) {
        final parent = await _ref
            .read(linkMissingCustomerAccountsProvider)
            .resolveParent();
        if (parent != null) {
          drafts = await _ref
              .read(ensureCustomerAccountLinksProvider)
              .applyAll(
                drafts,
                parentId: parent.accountId,
                onProgress: (processed, total) {
                  if (total <= 0) {
                    return;
                  }
                  final fraction = processed / total;
                  state = state.copyWith(
                    progress: 0.28 + (fraction * 0.22),
                    progressLabelKey: 'linking',
                  );
                },
              );
        }
      }

      state = state.copyWith(progress: 0.52, progressLabelKey: 'saving');

      final upsert = await _ref
          .read(upsertCustomersUseCaseProvider)
          .call(
            drafts,
            onProgress: (processed, total) {
              if (total <= 0) {
                return;
              }
              final fraction = processed / total;
              state = state.copyWith(
                progress: 0.52 + (fraction * 0.45),
                progressLabelKey: 'saving',
              );
            },
          );

      final result = ImportSessionResult(
        importedCount: upsert.totalCount,
        ignoredCount: imported.ignoredCount,
      );
      state = state.copyWith(
        isImporting: false,
        progress: 1,
        clearProgressLabel: true,
        clearBytes: true,
        result: result,
        duplicateCount: imported.duplicateCount,
        insertedCount: upsert.insertedCount,
        updatedCount: upsert.updatedCount,
      );
      await _notifySuccess(result, upsert);
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
    } on CustomerException catch (error) {
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

  Future<void> _notifySuccess(
    ImportSessionResult result,
    CustomerUpsertResult upsert,
  ) async {
    final l10n = _l10n;
    await _ref
        .read(notificationServiceProvider)
        .showSuccess(
          title: l10n.customersImportTitle,
          message:
              '${l10n.customersImportInsertedCount(upsert.insertedCount)} · '
              '${l10n.customersImportUpdatedCount(upsert.updatedCount)}',
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
        return localization.customersNoValidRows;
      case ImportValidationException.decodeFailed:
        return localization.invalidFile;
      case CustomerException.duplicateCustomerCode:
        return localization.customersErrorDuplicateCode;
      case CustomerException.duplicateExternalId:
        return localization.customersErrorDuplicateExternalId;
      default:
        return code;
    }
  }
}

final customerImportProvider =
    StateNotifierProvider.autoDispose<
      CustomerImportNotifier,
      CustomerImportUiState
    >(CustomerImportNotifier.new);
