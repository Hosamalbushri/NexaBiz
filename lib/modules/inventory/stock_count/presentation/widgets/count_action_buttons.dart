import 'package:flutter/material.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_button.dart';

class CountActionButtons extends StatelessWidget {
  const CountActionButtons({
    super.key,
    required this.isLoading,
    required this.isCounted,
    required this.onMatched,
    required this.onSave,
    required this.onEdit,
    this.enabled = true,
  });

  final bool isLoading;
  final bool isCounted;
  final VoidCallback onMatched;
  final VoidCallback onSave;
  final VoidCallback onEdit;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);

    if (isCounted) {
      return AppButton(
        label: localization.editCount,
        icon: Icons.edit_outlined,
        isLoading: isLoading,
        expand: true,
        onPressed: enabled ? onEdit : null,
      );
    }

    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: localization.matched,
            icon: Icons.check_circle_outline_rounded,
            variant: AppButtonVariant.outlined,
            isLoading: isLoading,
            expand: true,
            onPressed: enabled ? onMatched : null,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppButton(
            label: localization.saveCount,
            icon: Icons.save_outlined,
            isLoading: isLoading,
            expand: true,
            onPressed: enabled ? onSave : null,
          ),
        ),
      ],
    );
  }
}
