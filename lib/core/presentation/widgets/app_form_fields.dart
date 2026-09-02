import 'package:flutter/material.dart';

/// Standardized text input field with minimum 48dp touch target and semantic labels.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.focusNode,
    this.semanticLabel,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final int? maxLines;
  final int? minLines;
  final FocusNode? focusNode;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label ?? hint,
      textField: true,
      enabled: enabled,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: TextFormField(
          controller: controller,
          initialValue: initialValue,
          obscureText: obscureText,
          readOnly: readOnly,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          maxLines: maxLines,
          minLines: minLines,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            helperText: helperText,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0, // Ensures >= 48dp target height
            ),
          ),
        ),
      ),
    );
  }
}

/// Standardized dropdown menu field with accessible selection.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.value,
    this.label,
    this.hint,
    this.errorText,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  final List<T> items;
  final DropdownMenuItem<T> Function(T item) itemBuilder;
  final T? value;
  final String? label;
  final String? hint;
  final String? errorText;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label ?? hint,
      enabled: enabled,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: DropdownButtonFormField<T>(
          initialValue: value,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            errorText: errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
          ),
          items: items.map(itemBuilder).toList(),
        ),
      ),
    );
  }
}

/// Standardized form section layout container with card framing.
class AppFormSection extends StatelessWidget {
  const AppFormSection({
    super.key,
    required this.title,
    required this.children,
    this.description,
    this.icon,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}
