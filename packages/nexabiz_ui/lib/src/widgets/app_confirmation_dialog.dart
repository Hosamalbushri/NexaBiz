import 'package:flutter/material.dart';

import 'app_dialog.dart';

enum AppDialogTone { info, warning, danger }

/// Canonical composable confirmation dialog for NexaBiz ERP.
///
/// Features semantic tones (info, warning, danger), title, message,
/// optional custom body content, and confirm/cancel callbacks.
class AppConfirmationDialog extends StatelessWidget {
  const AppConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.tone = AppDialogTone.warning,
    this.isLoading = false,
    this.customBody,
  });

  final String title;
  final String message;
  final VoidCallback onConfirm;
  final String confirmLabel;
  final String cancelLabel;
  final AppDialogTone tone;
  final bool isLoading;
  final Widget? customBody;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    AppDialogTone tone = AppDialogTone.warning,
    Widget? customBody,
  }) {
    return AppDialog.show<bool>(
      context: context,
      title: title,
      icon: tone == AppDialogTone.danger
          ? Icons.error_outline_rounded
          : tone == AppDialogTone.warning
              ? Icons.warning_amber_rounded
              : Icons.info_outline_rounded,
      isDestructive: tone == AppDialogTone.danger,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: onConfirm,
      size: AppDialogSize.small,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (customBody != null) ...[
              const SizedBox(height: 16),
              customBody,
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = switch (tone) {
      AppDialogTone.info => Icons.info_outline_rounded,
      AppDialogTone.warning => Icons.warning_amber_rounded,
      AppDialogTone.danger => Icons.error_outline_rounded,
    };

    return AppDialog<bool>(
      title: title,
      icon: icon,
      isDestructive: tone == AppDialogTone.danger,
      isLoading: isLoading,
      size: AppDialogSize.small,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: onConfirm,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            if (customBody != null) ...[
              const SizedBox(height: 16),
              customBody!,
            ],
          ],
        ),
      ),
    );
  }
}
