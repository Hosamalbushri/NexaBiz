import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'app_field_shell.dart';

/// Canonical date selection field primitive for NexaBiz ERP.
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint = 'اختر التاريخ...',
    this.required = false,
    this.enabled = true,
    this.readOnly = false,
    this.firstDate,
    this.lastDate,
    this.dateFormat = 'yyyy-MM-dd',
    this.errorText,
    this.helperText,
    this.density = AppFieldDensity.standard,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? label;
  final String hint;
  final bool required;
  final bool enabled;
  final bool readOnly;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String dateFormat;
  final String? errorText;
  final String? helperText;
  final AppFieldDensity density;

  Future<void> _selectDate(BuildContext context) async {
    if (!enabled || readOnly) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final formatted = value != null ? DateFormat(dateFormat).format(value!) : null;

    return AppFieldShell(
      label: label,
      required: required,
      errorText: errorText,
      helperText: helperText,
      density: density,
      enabled: enabled,
      readOnly: readOnly,
      onTap: () => _selectDate(context),
      prefix: Icon(
        Icons.calendar_today_rounded,
        size: 18,
        color: scheme.primary,
      ),
      child: Text(
        formatted ?? hint,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: formatted != null ? FontWeight.w600 : FontWeight.w400,
          color: formatted != null
              ? scheme.onSurface
              : scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
