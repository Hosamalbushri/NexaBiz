import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';

class QuantityInputCard extends StatelessWidget {
  const QuantityInputCard({
    super.key,
    required this.mainController,
    required this.secondaryController,
    required this.mainFocusNode,
    required this.secondaryFocusNode,
    required this.onMainChanged,
    required this.onSecondaryChanged,
    required this.onMainSubmitted,
    required this.onSave,
    this.enabled = true,
  });

  final TextEditingController mainController;
  final TextEditingController secondaryController;
  final FocusNode mainFocusNode;
  final FocusNode secondaryFocusNode;
  final ValueChanged<String> onMainChanged;
  final ValueChanged<String> onSecondaryChanged;
  final VoidCallback onMainSubmitted;
  final VoidCallback onSave;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            AppTextField(
              controller: mainController,
              focusNode: mainFocusNode,
              label: localization.mainQuantity,
              enabled: enabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onChanged: onMainChanged,
              onSubmitted: (_) => onMainSubmitted(),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: secondaryController,
              focusNode: secondaryFocusNode,
              label: localization.subQuantity,
              enabled: enabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onChanged: onSecondaryChanged,
              onSubmitted: (_) => onSave(),
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }
}
