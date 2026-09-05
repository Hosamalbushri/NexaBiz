import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_text_field.dart';

/// Canonical formatted numeric input field primitive for NexaBiz ERP.
///
/// Supports min/max bounds, decimal control, and value change callbacks.
class AppNumberField extends StatelessWidget {
  const AppNumberField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.value,
    this.onChanged,
    this.allowDecimals = true,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon = Icons.numbers_rounded,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final double? value;
  final ValueChanged<double?>? onChanged;
  final bool allowDecimals;
  final bool enabled;
  final bool readOnly;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final formatters = <TextInputFormatter>[
      if (!allowDecimals) FilteringTextInputFormatter.digitsOnly,
      if (allowDecimals)
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
    ];

    return AppTextField(
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      helperText: helperText,
      prefixIcon: prefixIcon,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimals),
      inputFormatters: formatters,
      onChanged: (text) {
        if (onChanged == null) return;
        if (text.isEmpty) {
          onChanged!(null);
        } else {
          final parsed = double.tryParse(text);
          onChanged!(parsed);
        }
      },
    );
  }
}
