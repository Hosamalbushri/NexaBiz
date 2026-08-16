import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_radius.dart';
import '../utils/grouped_decimal_input.dart';

export '../utils/grouped_decimal_input.dart'
    show
        formatGroupedDecimal,
        parseGroupedDecimal,
        GroupedDecimalInputFormatter;

/// Visual density for [AppAmountField] / [FinancialNumberField].
enum AppAmountFieldVariant {
  /// Full Material form field (labels, suffix currency, etc.).
  form,

  /// Dense centered cell for tables / spreadsheets.
  compact,

  /// Borderless / unfilled — embeds inside custom cards (e.g. discount row).
  bare,
}

/// Canonical financial/quantity numeric input for the whole app.
///
/// Prefer this (or the [FinancialNumberField] typedef) over ad-hoc
/// [TextField]s with manual comma stripping.
///
/// - **Display:** thousand separators while typing (`1,250,000.75`)
/// - **Domain:** [onChanged] always receives a raw [double]
/// - **Caret:** preserved across formatting; focus defaults caret to end
///
/// ```dart
/// AppAmountField(
///   value: amount,
///   onChanged: setAmount,
///   label: 'Amount',
///   suffixText: 'SAR',
///   decimalPlaces: 2,
/// )
/// ```
class AppAmountField extends StatefulWidget {
  const AppAmountField({
    super.key,
    required this.value,
    required this.onChanged,
    this.decimalPlaces = 2,
    this.emptyWhenZero = false,
    this.trimTrailingZeros = true,
    this.allowNegative = false,
    this.variant = AppAmountFieldVariant.form,
    this.label,
    this.hint,
    this.prefixText,
    this.suffixText,
    this.errorText,
    this.enabled = true,
    this.readOnly = false,
    this.textAlign,
    this.focusNode,
    this.autofocus = false,
    this.skipTraversal = false,
    this.selectAllOnFocus = false,
    this.placeCaretAtEndOnFocus = true,
    this.textInputAction = TextInputAction.done,
    this.keepFocusOnSubmit = false,
    this.onEditingComplete,
    this.onSubmitted,
  });

  /// Current numeric value shown when the field is not focused.
  final double value;

  /// Fired on every accepted keystroke (parsed value, `0` when empty).
  final ValueChanged<double> onChanged;

  final int decimalPlaces;
  final bool emptyWhenZero;
  final bool trimTrailingZeros;
  final bool allowNegative;
  final AppAmountFieldVariant variant;
  final String? label;
  final String? hint;
  final String? prefixText;
  final String? suffixText;
  final String? errorText;
  final bool enabled;
  final bool readOnly;
  final TextAlign? textAlign;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool skipTraversal;

  /// When true, focuses by selecting the whole value.
  final bool selectAllOnFocus;

  /// When true (default), tabbing / focusing with caret at start moves it
  /// to the end so Backspace removes the last digit. Mid-field taps keep
  /// their caret position.
  final bool placeCaretAtEndOnFocus;

  final TextInputAction textInputAction;

  /// When true, Done/submit does not unfocus (spreadsheet-style).
  final bool keepFocusOnSubmit;

  final VoidCallback? onEditingComplete;
  final ValueChanged<double>? onSubmitted;

  @override
  State<AppAmountField> createState() => _AppAmountFieldState();
}

/// Alias matching product docs — same widget as [AppAmountField].
typedef FinancialNumberField = AppAmountField;

class _AppAmountFieldState extends State<AppAmountField> {
  late final TextEditingController _controller;
  FocusNode? _ownedFocus;
  var _syncing = false;

  FocusNode get _focus => widget.focusNode ?? _ownedFocus!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _ownedFocus = FocusNode(skipTraversal: widget.skipTraversal);
    }
    _controller = TextEditingController(text: _format(widget.value));
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppAmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownedFocus)?.removeListener(_onFocusChange);
      if (widget.focusNode == null && _ownedFocus == null) {
        _ownedFocus = FocusNode(skipTraversal: widget.skipTraversal);
      }
      _focus.addListener(_onFocusChange);
    }
    if (!_focus.hasFocus &&
        (oldWidget.value != widget.value ||
            oldWidget.decimalPlaces != widget.decimalPlaces ||
            oldWidget.emptyWhenZero != widget.emptyWhenZero ||
            oldWidget.trimTrailingZeros != widget.trimTrailingZeros ||
            oldWidget.allowNegative != widget.allowNegative)) {
      _writeFormatted(widget.value);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _ownedFocus?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focus.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_focus.hasFocus) {
          return;
        }
        final text = _controller.text;
        if (text.isEmpty) {
          return;
        }
        if (widget.selectAllOnFocus) {
          _controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: text.length,
          );
          return;
        }
        if (!widget.placeCaretAtEndOnFocus) {
          return;
        }
        final sel = _controller.selection;
        // Tab-in / default focus often lands at offset 0. Mid taps keep offset.
        if (sel.isCollapsed && sel.baseOffset == 0) {
          _controller.selection = TextSelection.collapsed(
            offset: text.length,
          );
        }
      });
      return;
    }
    _writeFormatted(widget.value);
  }

  String _format(double value) {
    return formatGroupedDecimal(
      value,
      decimalPlaces: widget.decimalPlaces,
      emptyWhenZero: widget.emptyWhenZero,
      trimTrailingZeros: widget.trimTrailingZeros,
    );
  }

  void _writeFormatted(double value) {
    final next = _format(value);
    if (_controller.text == next) {
      return;
    }
    _syncing = true;
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _syncing = false;
  }

  double _parse(String raw) {
    final parsed = parseGroupedDecimal(raw) ?? 0;
    if (!widget.allowNegative && parsed < 0) {
      return 0;
    }
    if (widget.decimalPlaces <= 0) {
      return parsed.roundToDouble();
    }
    return parsed;
  }

  void _handleRawChanged(String raw) {
    if (_syncing) {
      return;
    }
    widget.onChanged(_parse(raw));
  }

  void _handleSubmit() {
    final parsed = _parse(_controller.text);
    _writeFormatted(parsed);
    widget.onSubmitted?.call(parsed);
    widget.onEditingComplete?.call();
    if (!widget.keepFocusOnSubmit) {
      _focus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final align = widget.textAlign ??
        (widget.variant == AppAmountFieldVariant.compact
            ? TextAlign.center
            : TextAlign.start);

    final formatters = <TextInputFormatter>[
      const WesternDigitsInputFormatter(),
      GroupedDecimalInputFormatter(
        decimalPlaces: widget.decimalPlaces,
        allowNegative: widget.allowNegative,
      ),
    ];

    final decoration = switch (widget.variant) {
      AppAmountFieldVariant.form => InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixText: widget.prefixText,
          suffixText: widget.suffixText,
          errorText: widget.errorText,
        ),
      AppAmountFieldVariant.compact => InputDecoration(
          isDense: true,
          filled: true,
          fillColor: hasError
              ? scheme.errorContainer.withValues(alpha: 0.35)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          prefixText: widget.prefixText,
          suffixText: widget.suffixText,
          errorText: widget.errorText,
          errorMaxLines: 2,
          errorStyle: theme.textTheme.labelSmall?.copyWith(
            color: scheme.error,
            fontWeight: FontWeight.w700,
            height: 1.15,
            fontSize: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(
              color: hasError
                  ? scheme.error
                  : scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(
              color: hasError ? scheme.error : scheme.primary,
              width: 1.4,
            ),
          ),
        ),
      AppAmountFieldVariant.bare => InputDecoration(
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: widget.hint,
          prefixText: widget.prefixText,
          suffixText: widget.suffixText,
          errorText: widget.errorText,
        ),
    };

    return TextField(
      controller: _controller,
      focusNode: _focus,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      textAlign: align,
      keyboardType: TextInputType.numberWithOptions(
        decimal: widget.decimalPlaces > 0,
        signed: widget.allowNegative,
      ),
      textInputAction: widget.textInputAction,
      inputFormatters: widget.readOnly ? const [] : formatters,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: widget.variant == AppAmountFieldVariant.compact
            ? FontWeight.w800
            : FontWeight.w600,
        color: hasError ? scheme.error : null,
      ),
      decoration: decoration,
      onChanged: widget.readOnly ? null : _handleRawChanged,
      onEditingComplete: widget.readOnly ? null : _handleSubmit,
      onSubmitted: widget.readOnly ? null : (_) => _handleSubmit(),
    );
  }
}

/// Read-only amount text with locale-aware thousand separators.
class AppAmountText extends StatelessWidget {
  const AppAmountText(
    this.value, {
    super.key,
    this.decimalPlaces = 2,
    this.style,
    this.textAlign,
  });

  final double value;
  final int decimalPlaces;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatAppAmount(context, value, decimalPlaces: decimalPlaces),
      style: style,
      textAlign: textAlign,
    );
  }
}

/// Locale display helper for lists, details, and reports.
String formatAppAmount(
  BuildContext context,
  double value, {
  int decimalPlaces = 2,
}) {
  final locale = Localizations.localeOf(context).toString();
  final pattern =
      decimalPlaces <= 0 ? '#,##0' : '#,##0.${'0' * decimalPlaces}';
  return NumberFormat(pattern, locale).format(value);
}
