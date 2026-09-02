import 'package:flutter/material.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';

/// Canonical currency dropdown selector primitive.
class AppCurrencySelector extends StatelessWidget {
  const AppCurrencySelector({
    super.key,
    required this.currencies,
    required this.selectedCurrency,
    required this.onChanged,
    this.label = 'العملة',
    this.enabled = true,
  });

  final List<String> currencies;
  final String selectedCurrency;
  final ValueChanged<String?>? onChanged;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      initialValue: currencies.contains(selectedCurrency) ? selectedCurrency : null,
      items: currencies
          .map((code) => DropdownMenuItem<String>(
                value: code,
                child: Text(
                  code,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ))
          .toList(),
      onChanged: enabled ? onChanged : null,
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
    );
  }
}
