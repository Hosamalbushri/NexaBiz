import 'package:flutter/material.dart';

import '../theme/tokens/tokens.dart';
import 'app_button.dart';

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
    return showDialog<bool>(
      context: context,
      builder: (context) => AppConfirmationDialog(
        title: title,
        message: message,
        onConfirm: () {
          onConfirm();
          Navigator.of(context).pop(true);
        },
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        tone: tone,
        customBody: customBody,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (icon, iconColor, buttonVariant) = switch (tone) {
      AppDialogTone.info => (
          Icons.info_outline_rounded,
          scheme.primary,
          AppButtonVariant.filled,
        ),
      AppDialogTone.warning => (
          Icons.warning_amber_rounded,
          AppColors.warning,
          AppButtonVariant.filled,
        ),
      AppDialogTone.danger => (
          Icons.error_outline_rounded,
          scheme.error,
          AppButtonVariant.filled,
        ),
    };

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadii.radiusDialog),
      title: Row(
        children: [
          Icon(icon, color: iconColor, size: AppIcons.lg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (customBody != null) ...[
              const SizedBox(height: AppSpacing.md),
              customBody!,
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        AppButton(
          label: confirmLabel,
          onPressed: isLoading ? null : onConfirm,
          variant: buttonVariant,
          isLoading: isLoading,
        ),
      ],
    );
  }
}
