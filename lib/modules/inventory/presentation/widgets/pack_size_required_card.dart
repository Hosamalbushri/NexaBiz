import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/services/pack_size_parser.dart';

/// Warning + required pack-size entry when an item has no usable pack.
class PackSizeRequiredCard extends StatelessWidget {
  const PackSizeRequiredCard({
    super.key,
    required this.warningStatus,
    required this.controller,
    required this.focusNode,
    required this.isSaving,
    required this.onChanged,
    required this.onSave,
  });

  final PackSizeNameStatus warningStatus;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSaving;
  final ValueChanged<String> onChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.warningContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _warningMessage(localization),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: controller,
            focusNode: focusNode,
            label: localization.packSize,
            hint: localization.packSizeRequiredHint,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: onChanged,
            onSubmitted: (_) => onSave(),
            autofocus: true,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: localization.savePackSize,
            icon: Icons.inventory_2_outlined,
            isLoading: isSaving,
            expand: true,
            onPressed: onSave,
          ),
        ],
      ),
    );
  }

  String _warningMessage(AppLocalizations localization) {
    switch (warningStatus) {
      case PackSizeNameStatus.incompleteMarker:
        return localization.packSizeIncompleteMarkerWarning;
      case PackSizeNameStatus.invalidValue:
        return localization.packSizeInvalidWarning;
      case PackSizeNameStatus.missingMarker:
      case PackSizeNameStatus.resolved:
        return localization.packSizeMissingWarning;
    }
  }
}
