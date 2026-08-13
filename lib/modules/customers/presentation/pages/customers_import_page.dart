import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/services/loading_providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/models/import_validation_exception.dart';
import '../providers/customer_import_provider.dart';

class CustomersImportPage extends ConsumerWidget {
  const CustomersImportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final importState = ref.watch(customerImportProvider);
    final notifier = ref.read(customerImportProvider.notifier);

    return Scaffold(
      appBar: CustomAppBar(
        title: localization.customersImportPageTitle,
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: AppConstants.pageInsets(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CustomersImportFormatHintCard(),
            const SizedBox(height: 16),
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
                    importState.selectedFileName ?? localization.noFileSelected,
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
                  localization.customersImportInsertedCount(
                    importState.insertedCount,
                  ),
                  localization.customersImportUpdatedCount(
                    importState.updatedCount,
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

  String _progressMessage(
    AppLocalizations localization,
    CustomerImportUiState state,
  ) {
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
        return localization.customersNoValidRows;
      case ImportValidationException.decodeFailed:
        return localization.invalidFile;
      default:
        return code;
    }
  }

  Future<void> _pickFile(
    BuildContext context,
    CustomerImportNotifier notifier,
  ) async {
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
    final result = await ref
        .read(loadingControllerProvider)
        .run(
          message: localization.loadingImportingCustomers,
          action: () => ref.read(customerImportProvider.notifier).importFile(),
        );

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

class _CustomersImportFormatHintCard extends StatelessWidget {
  const _CustomersImportFormatHintCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.table_chart_outlined,
                  color: colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.customersImportFormatHintTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.customersImportFormatHintIntro,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.importFormatRequired,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _ColumnChip(
                      label: l10n.customersFieldCode,
                      detail: l10n.customersImportFormatColCodeAliases,
                      emphasized: true,
                    ),
                    _ColumnChip(
                      label: l10n.customersFieldName,
                      detail: l10n.customersImportFormatColNameAliases,
                      emphasized: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.importFormatOptional,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _ColumnChip(
                      label: l10n.customersFieldPhone,
                      detail: l10n.customersImportFormatColPhoneAliases,
                    ),
                    _ColumnChip(
                      label: l10n.customersFieldEmail,
                      detail: l10n.customersImportFormatColEmailAliases,
                    ),
                    _ColumnChip(
                      label: l10n.customersFieldAddress,
                      detail: l10n.customersImportFormatColAddressAliases,
                    ),
                    _ColumnChip(
                      label: l10n.customersFieldNotes,
                      detail: l10n.customersImportFormatColNotesAliases,
                    ),
                    _ColumnChip(
                      label: l10n.customersFieldExternalId,
                      detail: l10n.customersImportFormatColExternalIdAliases,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.importFormatSampleTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _SampleSpreadsheet(
                      headers: [
                        l10n.customersFieldCode,
                        l10n.customersFieldName,
                        l10n.customersFieldPhone,
                      ],
                      values: const ['12210001', 'Ahmed Ali', '777123456'],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.customersImportFormatSampleNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColumnChip extends StatelessWidget {
  const _ColumnChip({
    required this.label,
    required this.detail,
    this.emphasized = false,
  });

  final String label;
  final String detail;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = emphasized ? colorScheme.primary : colorScheme.tertiary;

    return Tooltip(
      message: detail,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SampleSpreadsheet extends StatelessWidget {
  const _SampleSpreadsheet({required this.headers, required this.values});

  final List<String> headers;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Table(
      border: TableBorder.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        width: 1,
      ),
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: [
        TableRow(
          decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest),
          children: [
            for (final header in headers)
              _SheetCell(text: header, isHeader: true),
          ],
        ),
        TableRow(
          decoration: BoxDecoration(color: colorScheme.surface),
          children: [for (final value in values) _SheetCell(text: value)],
        ),
      ],
    );
  }
}

class _SheetCell extends StatelessWidget {
  const _SheetCell({required this.text, this.isHeader = false});

  final String text;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        text,
        style:
            (isHeader ? theme.textTheme.labelMedium : theme.textTheme.bodySmall)
                ?.copyWith(
                  fontWeight: isHeader ? FontWeight.w800 : FontWeight.w500,
                ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.isSuccess, required this.messages});

  final bool isSuccess;
  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    final color = isSuccess
        ? Colors.green
        : Theme.of(context).colorScheme.error;

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
