import 'package:flutter/material.dart';

import 'app_dialog.dart';

/// Canonical NexaBiz Form Dialog Component (`NexaBizFormDialog<T>`).
///
/// Composes `AppDialog<T>` with `Form` & `AppFormSection`s, providing a standardized modal form container
/// with sectioning support, validation execution, submit/cancel action bar, loading state,
/// global error presentation, and typed modal result contract via `Navigator.pop(result)`.
class AppFormDialog<T> extends StatelessWidget {
  const AppFormDialog({
    super.key,
    this.formKey,
    this.title,
    this.subtitle,
    this.icon,
    this.errorMessage,
    required this.children,
    this.onSubmit,
    this.submitLabel = 'Save',
    this.onCancel,
    this.cancelLabel = 'Cancel',
    this.isSubmitting = false,
    this.size = AppDialogSize.medium,
    this.showCloseButton = true,
    this.extraActions,
    this.spacing = 16.0,
  });

  /// Optional form validation key.
  final GlobalKey<FormState>? formKey;

  /// Optional dialog title string.
  final String? title;

  /// Optional subtitle or detailed description.
  final String? subtitle;

  /// Optional header leading icon.
  final IconData? icon;

  /// Optional global error banner message.
  final String? errorMessage;

  /// List of form section or field widgets.
  final List<Widget> children;

  /// Callback when submit action button is clicked.
  final VoidCallback? onSubmit;

  /// Label for submit button (default: 'Save').
  final String submitLabel;

  /// Callback when cancel action button is clicked.
  final VoidCallback? onCancel;

  /// Label for cancel button (default: 'Cancel').
  final String cancelLabel;

  /// Whether form submission is currently in progress.
  final bool isSubmitting;

  /// Predefined dialog max-width sizing variant.
  final AppDialogSize size;

  /// Whether to display a header close button.
  final bool showCloseButton;

  /// Optional extra action buttons.
  final List<Widget>? extraActions;

  /// Spacing between children/sections.
  final double spacing;

  /// Static helper to launch a form dialog and return typed result `T?`.
  static Future<T?> show<T>({
    required BuildContext context,
    GlobalKey<FormState>? formKey,
    String? title,
    String? subtitle,
    IconData? icon,
    String? errorMessage,
    required List<Widget> children,
    VoidCallback? onSubmit,
    String submitLabel = 'Save',
    VoidCallback? onCancel,
    String cancelLabel = 'Cancel',
    bool isSubmitting = false,
    AppDialogSize size = AppDialogSize.medium,
    bool showCloseButton = true,
    List<Widget>? extraActions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible && !isSubmitting,
      builder: (dialogContext) {
        return AppFormDialog<T>(
          formKey: formKey,
          title: title,
          subtitle: subtitle,
          icon: icon,
          errorMessage: errorMessage,
          onSubmit: onSubmit,
          submitLabel: submitLabel,
          onCancel: onCancel,
          cancelLabel: cancelLabel,
          isSubmitting: isSubmitting,
          size: size,
          showCloseButton: showCloseButton,
          extraActions: extraActions,
          children: children,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog<T>(
      title: title,
      description: subtitle,
      icon: icon,
      errorMessage: errorMessage,
      isLoading: isSubmitting,
      size: size,
      showCloseButton: showCloseButton,
      confirmLabel: submitLabel,
      onConfirm: onSubmit,
      cancelLabel: cancelLabel,
      onCancel: onCancel ?? () => Navigator.of(context).pop(null),
      actions: extraActions,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1) SizedBox(height: spacing),
            ],
          ],
        ),
      ),
    );
  }
}
