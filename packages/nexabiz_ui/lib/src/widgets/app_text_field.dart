import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;
import 'app_field_shell.dart';

/// Design-system text field primitive for NexaBiz ERP.
///
/// Mirroring the exact visual styling of [AppSelectField] (Warehouse Cost Valuation Field):
/// - Primary-tinted 20px prefix icons
/// - `FontWeight.w600` input text styling
/// - Matching hint text color & typography
/// - Seamless [AppFieldShell] surface container integration
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
    final colorScheme = theme.colorScheme;
    final shadcnTheme = shadcn.Theme.of(context);

    final hasShadcnTheme =
        context.findAncestorWidgetOfExactType<shadcn.ComponentTheme>() != null ||
            context.findAncestorWidgetOfExactType<shadcn.Theme>() != null;

    final bodyMediumStyle = theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: enabled
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ) ??
        TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: enabled
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        );

    final hintTextStyle = theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ) ??
        TextStyle(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        );

    final childInput = hasShadcnTheme
        ? shadcn.TextField(
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
            onChanged: onChanged != null ? (value) => onChanged!(value) : null,
            onSubmitted:
                onSubmitted != null ? (value) => onSubmitted!(value) : null,
            placeholder: hint != null ? Text(hint!, style: hintTextStyle) : null,
            border: const Border(),
          )
        : TextField(
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
            style: bodyMediumStyle,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: hint,
              hintStyle: hintTextStyle,
            ),
          );

    final prefixWidget = prefixIcon == null
        ? null
        : Icon(
            prefixIcon,
            size: 20,
            color: enabled
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          );

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
