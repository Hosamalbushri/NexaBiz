import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/models/import_validation_exception.dart';
import '../providers/import_provider.dart';

class InventoryImportPage extends ConsumerWidget {
  const InventoryImportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final importState = ref.watch(importProvider);
    final notifier = ref.read(importProvider.notifier);

    return Scaffold(
      appBar: CustomAppBar(
        title: localization.importPageTitle,
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton(
              label: localization.selectExcelFile,
              icon: Icons.upload_file_outlined,
              variant: AppButtonVariant.outlined,
              expand: true,
              onPressed: importState.isImporting
                  ? null
                  : () => _pickFile(context, notifier),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localization.selectedFileName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    importState.selectedFileName ??
                        localization.noFileSelected,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: localization.importButton,
              icon: Icons.file_download_done_outlined,
              expand: true,
              isLoading: importState.isImporting,
              onPressed: importState.isImporting || !importState.hasSelectedFile
                  ? null
                  : () => _import(context, ref),
            ),
            if (importState.isImporting) ...[
              const SizedBox(height: 24),
              AppLoading(
                style: AppLoadingStyle.linear,
                message: _progressMessage(localization, importState),
                progress: importState.progress,
              ),
            ],
            if (importState.result != null) ...[
              const SizedBox(height: 24),
              _ResultBanner(
                isSuccess: true,
                messages: [
                  localization.importSuccess,
                  localization.importedItemsCount(
                    importState.result!.importedCount,
                  ),
                  localization.ignoredRowsCount(
                    importState.result!.ignoredCount,
                  ),
                  if (importState.duplicateCount > 0)
                    localization.duplicateRowsCount(importState.duplicateCount),
                ],
              ),
            ],
            if (importState.errorMessage != null) ...[
              const SizedBox(height: 24),
              _ResultBanner(
                isSuccess: false,
                messages: [
                  localization.importFailed,
                  _errorMessage(localization, importState.errorMessage!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _progressMessage(AppLocalizations localization, ImportUiState state) {
    switch (state.progressLabelKey) {
      case 'parsing':
        return localization.importParsing;
      case 'saving':
        return localization.importSaving;
      default:
        return localization.importing;
    }
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

  Future<void> _pickFile(BuildContext context, ImportNotifier notifier) async {
    final localization = AppLocalizations.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: localization.invalidFile,
        isSuccess: false,
      );
      return;
    }

    notifier.setSelectedFile(fileName: file.name, bytes: bytes);
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final localization = AppLocalizations.of(context);
    final result = await ref.read(importProvider.notifier).importFile();

    if (!context.mounted) {
      return;
    }

    if (result != null) {
      showAppSnackBar(
        context,
        message: localization.importSuccess,
        isSuccess: true,
      );
      context.pop();
    } else {
      showAppSnackBar(
        context,
        message: localization.importFailed,
        isSuccess: false,
      );
    }
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({
    required this.isSuccess,
    required this.messages,
  });

  final bool isSuccess;
  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    final color =
        isSuccess ? Colors.green : Theme.of(context).colorScheme.error;

    return AppCard(
      color: color.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                isSuccess
                    ? AppLocalizations.of(context).success
                    : AppLocalizations.of(context).failure,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final message in messages)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(message),
            ),
        ],
      ),
    );
  }
}
