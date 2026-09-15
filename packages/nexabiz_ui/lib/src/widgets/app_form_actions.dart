import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../theme/tokens/tokens.dart';
import 'app_button.dart';

/// Canonical form actions bar composite for NexaBiz ERP forms.
///
/// Features primary submit button, optional secondary cancel button,
/// loading state, and optional sticky bottom bar layout.
class AppFormActions extends StatelessWidget {
  const AppFormActions({
    super.key,
    required this.onSubmit,
    this.submitLabel = 'Save',
    this.onCancel,
    this.cancelLabel = 'Cancel',
    this.isLoading = false,
    this.isSticky = true,
    this.submitIcon = Icons.check_rounded,
    this.cancelIcon = Icons.close_rounded,
    this.extraActions,
  });

  final VoidCallback? onSubmit;
  final String submitLabel;
  final VoidCallback? onCancel;
  final String cancelLabel;
  final bool isLoading;
  final bool isSticky;
  final IconData? submitIcon;
  final IconData? cancelIcon;
  final List<Widget>? extraActions;

  @override
  Widget build(BuildContext context) {
    final theme = shadcn.Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (extraActions != null) ...[
          ...extraActions!,
          const Spacer(),
        ],
        if (onCancel != null) ...[
          AppButton(
            label: cancelLabel,
            onPressed: isLoading ? null : onCancel,
            variant: AppButtonVariant.outlined,
            icon: cancelIcon,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        AppButton(
          label: submitLabel,
          onPressed: isLoading ? null : onSubmit,
          variant: AppButtonVariant.filled,
          icon: submitIcon,
          isLoading: isLoading,
        ),
      ],
    );

    if (!isSticky) return content;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.card,
        border: Border(
          top: BorderSide(
            color: colorScheme.border.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: content,
    );
  }
}

