import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/custom_app_bar.dart';
import 'report_exception.dart';
import 'report_file_actions.dart';

/// Preview hand-off before navigating to [PdfDocumentPreviewPage].
class PdfDocumentPreviewArgs {
  const PdfDocumentPreviewArgs({
    required this.bytes,
    required this.title,
    required this.fileName,
  });

  final Uint8List bytes;
  final String title;
  final String fileName;

  /// Simple hand-off for GoRouter (extra is not always reliable across rebuilds).
  static PdfDocumentPreviewArgs? holder;
}

/// Shared PDF preview with print / share actions (reports, invoices, …).
class PdfDocumentPreviewPage extends StatefulWidget {
  const PdfDocumentPreviewPage({super.key});

  @override
  State<PdfDocumentPreviewPage> createState() => _PdfDocumentPreviewPageState();
}

class _PdfDocumentPreviewPageState extends State<PdfDocumentPreviewPage> {
  final _actions = const ReportFileActions();
  var _busy = false;

  Future<void> _runAction(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
    } on ReportException catch (e) {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context);
      showAppSnackBar(
        context,
        message: _mapError(l10n, e),
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final args = PdfDocumentPreviewArgs.holder;

    if (args == null) {
      return Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        appBar: CustomAppBar(
          title: l10n.reportsPreviewTitle,
          showBackButton: true,
        ),
        body: _MissingPreviewBody(message: l10n.reportsPreviewMissing),
      );
    }

    final canvas = Color.lerp(
      scheme.surfaceContainerHighest,
      scheme.surfaceContainerLowest,
      0.35,
    )!;

    return Scaffold(
      backgroundColor: canvas,
      appBar: CustomAppBar(
        title: args.title,
        showBackButton: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: scheme.surface,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.reportsPreviewTitle,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      args.fileName,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: PdfPreview(
              build: (_) async => args.bytes,
              useActions: false,
              allowPrinting: false,
              allowSharing: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              pdfFileName: args.fileName,
              maxPageWidth: 920,
              scrollViewDecoration: BoxDecoration(color: canvas),
              previewPageMargin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              pdfPreviewPageDecoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xs),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              loadingWidget: Center(
                child: CircularProgressIndicator(color: scheme.primary),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        color: scheme.surface,
        elevation: 8,
        shadowColor: scheme.shadow.withValues(alpha: 0.12),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _runAction(
                            () => _actions.shareBytes(
                              bytes: args.bytes,
                              fileName: args.fileName,
                              subject: args.title,
                            ),
                          ),
                    icon: const Icon(Icons.share_outlined),
                    label: Text(l10n.reportsActionShare),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _runAction(
                            () => _actions.printBytes(
                              bytes: args.bytes,
                              name: args.fileName,
                            ),
                          ),
                    icon: const Icon(Icons.print_outlined),
                    label: Text(l10n.reportsActionPrint),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _mapError(AppLocalizations l10n, ReportException e) {
    return switch (e.code) {
      ReportException.printFailed => l10n.reportsErrorPrint,
      ReportException.shareFailed => l10n.reportsErrorShare,
      ReportException.fileWriteFailed => l10n.reportsErrorFile,
      _ => l10n.reportsErrorGeneric,
    };
  }
}

class _MissingPreviewBody extends StatelessWidget {
  const _MissingPreviewBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(
                Icons.description_outlined,
                size: 36,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
