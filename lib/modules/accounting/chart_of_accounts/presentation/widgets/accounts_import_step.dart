import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_button.dart';
import 'package:stock_count/core/widgets/app_card.dart';
import 'package:stock_count/core/widgets/app_loading.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import '../../domain/entities/account.dart';
import '../../domain/models/account_exception.dart';
import '../../domain/models/account_import_row.dart'
    show AccountImportException;
import '../../domain/services/account_labels.dart';
import '../providers/account_opening_setup_provider.dart';
import '../providers/account_providers.dart';
import 'account_import_rows_table.dart';

/// Step 1: import posting accounts under a parent group (structure only).
class AccountsImportStep extends ConsumerWidget {
  const AccountsImportStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(accountOpeningSetupProvider);
    final notifier = ref.read(accountOpeningSetupProvider.notifier);
    final parentsAsync = ref.watch(parentAccountOptionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.accountingOpeningSetupStepImportHint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        const _ImportFormatHintCard(),
        const SizedBox(height: AppSpacing.md),
        parentsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text(l10n.somethingWentWrong),
          data: (parents) => AppCard(
            child: DropdownButtonFormField<Account>(
              // ignore: deprecated_member_use
              value: state.parent != null &&
                      parents.any((p) => p.uuid == state.parent!.uuid)
                  ? parents.firstWhere((p) => p.uuid == state.parent!.uuid)
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.accountingImportParent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              items: [
                for (final parent in parents)
                  DropdownMenuItem(
                    value: parent,
                    child: Text(
                      '${parent.accountCode} — ${AccountLabels.displayName(l10n, parent)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: state.isBusy ? null : notifier.setParent,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: l10n.selectExcelFile,
          icon: Icons.upload_file_outlined,
          variant: AppButtonVariant.outlined,
          expand: true,
          onPressed: state.isBusy
              ? null
              : () => _pickFile(context, notifier),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.selectedFileName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(state.importFileName ?? l10n.noFileSelected),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AccountImportRowsTable(
          rows: state.importRows,
          enabled: !state.isBusy,
          onChanged: notifier.updateImportRow,
          onRemove: notifier.removeImportRow,
          onAdd: notifier.addImportRow,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: l10n.importButton,
          icon: Icons.file_download_done_outlined,
          expand: true,
          isLoading: state.isBusy && state.stepIndex == 0,
          onPressed: !state.canImportAccounts
              ? null
              : () => unawaited(notifier.importAccounts()),
        ),
        if (state.isBusy && state.stepIndex == 0) ...[
          const SizedBox(height: AppSpacing.md),
          AppLoading(
            style: AppLoadingStyle.linear,
            message: l10n.importSaving,
            progress: state.progress,
          ),
        ],
        if (state.importResult != null) ...[
          const SizedBox(height: AppSpacing.md),
          _Banner(
            success: true,
            messages: [
              l10n.importSuccess,
              l10n.accountingImportInsertedCount(
                state.importResult!.insertedCount,
              ),
              l10n.accountingImportSkippedCount(
                state.importResult!.skippedCount,
              ),
            ],
          ),
        ],
        if (state.errorCode != null && state.stepIndex == 0) ...[
          const SizedBox(height: AppSpacing.md),
          _Banner(
            success: false,
            messages: [
              l10n.importFailed,
              _errorMessage(l10n, state.errorCode!, state.errorDetails),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _pickFile(
    BuildContext context,
    AccountOpeningSetupNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context);
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
        message: l10n.invalidFile,
        isSuccess: false,
      );
      return;
    }
    notifier.loadImportExcel(fileName: file.name, bytes: bytes);
  }

  String _errorMessage(AppLocalizations l10n, String code, String? details) {
    return switch (code) {
      AccountImportException.parentRequired =>
        l10n.accountingImportErrorParentRequired,
      AccountImportException.parentNotGroup =>
        l10n.accountingImportErrorParentNotGroup,
      AccountImportException.noRows ||
      AccountImportException.noValidRows =>
        l10n.accountingImportErrorNoRows,
      AccountImportException.emptyWorkbook => l10n.emptyWorkbook,
      AccountImportException.decodeFailed => l10n.invalidFile,
      AccountException.duplicateAccountCode =>
        l10n.accountingErrorDuplicateCode,
      _ => details?.isNotEmpty == true ? details! : code,
    };
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.success, required this.messages});

  final bool success;
  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = success ? scheme.primary : scheme.error;
    return AppCard(
      color: color.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

class _ImportFormatHintCard extends StatelessWidget {
  const _ImportFormatHintCard();

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
              children: [
                Icon(Icons.table_chart_outlined, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.accountingImportFormatHintTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.accountingOpeningSetupImportFormatIntro,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '• ${l10n.accountingFieldCode}: ${l10n.accountingImportFormatColCodeAliases}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '• ${l10n.accountingFieldName}: ${l10n.accountingImportFormatColNameAliases}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.accountingOpeningSetupImportFormatNote,
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
