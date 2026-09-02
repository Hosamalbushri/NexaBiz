import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_field_shell.dart';

/// Design-system text field primitive for NexaBiz ERP.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.required = false,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
    this.density = AppFieldDensity.standard,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final bool required;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final bool autofocus;
  final AppFieldDensity density;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppFieldShell(
      label: label,
      required: required,
      errorText: errorText,
      helperText: helperText,
      density: density,
      enabled: enabled,
      readOnly: readOnly,
      prefix: prefixIcon == null
          ? null
          : Icon(
              prefixIcon,
              size: 20,
              color: scheme.primary,
            ),
      suffix: suffixIcon,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        readOnly: readOnly,
        autofocus: autofocus,
        obscureText: obscureText,
        maxLines: maxLines,
        minLines: minLines,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: hint,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
