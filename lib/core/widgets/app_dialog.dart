import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';

/// Shows a themed confirmation dialog. Returns `true` when confirmed.
Future<bool> showAppDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool isDestructive = false,
}) async {
  final localization = AppLocalizations.of(context);
  final resolvedConfirm = confirmLabel ?? localization.confirm;
  final resolvedCancel = cancelLabel ?? localization.cancel;

  final result = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final colorScheme = theme.colorScheme;

      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor:
                      isDestructive ? colorScheme.error : colorScheme.primary,
                  foregroundColor:
                      isDestructive ? colorScheme.onError : colorScheme.onPrimary,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(resolvedConfirm),
              ),
              const SizedBox(height: 8),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(resolvedCancel),
              ),
            ],
          ),
        ),
      );
    },
  );

  return result ?? false;
}
