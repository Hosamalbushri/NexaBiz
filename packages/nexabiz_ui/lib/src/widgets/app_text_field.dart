import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'app_field_shell.dart';

/// Design-system text field primitive for NexaBiz ERP built natively on [shadcn.TextField].
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
  final dynamic prefixIcon;
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
    final theme = shadcn.Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hintTextStyle = theme.typography.small.copyWith(
      color: colorScheme.mutedForeground,
    );

    final childInput = shadcn.TextField(
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
      onChanged: onChanged != null
          ? (value) {
              final binding = WidgetsBinding.instance;
              if (binding.buildOwner?.debugBuilding ?? false) {
                binding.addPostFrameCallback((_) => onChanged!(value));
              } else {
                onChanged!(value);
              }
            }
          : null,
      onSubmitted: onSubmitted != null
          ? (value) {
              final binding = WidgetsBinding.instance;
              if (binding.buildOwner?.debugBuilding ?? false) {
                binding.addPostFrameCallback((_) => onSubmitted!(value));
              } else {
                onSubmitted!(value);
              }
            }
          : null,
      placeholder: hint != null ? Text(hint!, style: hintTextStyle) : null,
      border: const Border(),
    );

    final prefixWidget = prefixIcon is IconData
        ? Icon(
            prefixIcon as IconData,
            size: 18,
            color: enabled
                ? colorScheme.primary
                : colorScheme.mutedForeground,
          )
        : prefixIcon as Widget?;

    return AppFieldShell(
      label: label,
      required: required,
      errorText: errorText,
      helperText: helperText,
      density: density,
      enabled: enabled,
      readOnly: readOnly,
      focusNode: focusNode,
      prefix: prefixWidget,
      suffix: suffixIcon,
      child: childInput,
    );
  }
}
