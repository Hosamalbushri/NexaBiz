import 'package:flutter/material.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';

/// Canonical exchange rate input field primitive.
class AppRateField extends StatelessWidget {
  const AppRateField({
    super.key,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.label = 'سعر الصرف',
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      onChanged: onChanged,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
