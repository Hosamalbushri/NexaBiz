import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

/// Canonical Chip Input control for NexaBiz ERP backed by `shadcn_flutter`.
///
/// Allows users to type and create removable tag/chip elements inline.
class AppChipInput<T> extends StatefulWidget {
  const AppChipInput({
    super.key,
    required this.chipBuilder,
    required this.onChipSubmitted,
    this.onChipsChanged,
    this.controller,
    this.initialChips,
    this.placeholder,
    this.hintText,
    this.label,
    this.enabled = true,
    this.autofocus = false,
    this.readOnly = false,
    this.useChips,
    this.autoInsertSuggestion = true,
    this.clipboardHandler,
  });

  /// Builder for rendering each chip item widget.
  final shadcn.ChipWidgetBuilder<T> chipBuilder;

  /// Callback to convert entered text into a chip of type [T].
  final shadcn.ChipSubmissionCallback<T> onChipSubmitted;

  /// Callback fired whenever the list of chips changes.
  final ValueChanged<List<T>>? onChipsChanged;

  /// Optional controller to programmatically manage chips.
  final shadcn.ChipEditingController<T>? controller;

  /// Initial list of chips when controller is not supplied.
  final List<T>? initialChips;

  /// Placeholder text for the input field.
  final String? placeholder;

  /// Alternative hint text parameter.
  final String? hintText;

  /// Optional label rendered above or around the input.
  final String? label;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether the field should autofocus.
  final bool autofocus;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Whether to display visual chip cards (defaults to theme).
  final bool? useChips;

  /// Whether suggestions should auto-insert on selection.
  final bool autoInsertSuggestion;

  /// Clipboard handler for serialization.
  final shadcn.ClipboardHandler<T>? clipboardHandler;

  @override
  State<AppChipInput<T>> createState() => _AppChipInputState<T>();
}

class _AppChipInputState<T> extends State<AppChipInput<T>> {
  shadcn.ChipEditingController<T>? _internalController;

  shadcn.ChipEditingController<T> get _effectiveController {
    if (widget.controller != null) return widget.controller!;
    return _internalController ??= shadcn.ChipEditingController<T>()
      ..chips = widget.initialChips ?? [];
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectivePlaceholder = widget.placeholder ?? widget.hintText;

    return shadcn.ChipInput<T>(
      controller: _effectiveController,
      chipBuilder: widget.chipBuilder,
      onChipSubmitted: widget.onChipSubmitted,
      onChipsChanged: widget.onChipsChanged,
      placeholder: effectivePlaceholder != null ? Text(effectivePlaceholder) : null,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      useChips: widget.useChips,
      autoInsertSuggestion: widget.autoInsertSuggestion,
      clipboardHandler: widget.clipboardHandler,
    );
  }
}
