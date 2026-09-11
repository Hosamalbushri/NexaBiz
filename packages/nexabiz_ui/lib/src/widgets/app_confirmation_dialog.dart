import 'package:flutter/material.dart';

import 'app_dialog.dart';

/// Backward-compatibility wrapper for confirmation dialogs delegating directly
/// to the single unified canonical component `AppDialog.confirm()`.
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
    return AppDialog.confirm(
      context: context,
      title: title,
      message: message,
      onConfirm: onConfirm,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      tone: tone,
      customBody: customBody,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: title,
      size: AppDialogSize.small,
      isLoading: isLoading,
      isDestructive: tone == AppDialogTone.danger,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: onConfirm,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (customBody != null) ...[
              const SizedBox(height: 14),
              customBody!,
            ],
          ],
        ),
      ),
    );
  }
}
