import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import 'app_chip_input.dart';

/// Canonical Chip Input with Autocomplete control for NexaBiz ERP.
///
/// Wraps an [AppChipInput] with `shadcn_flutter` [AutoComplete] overlay popovers
/// to provide inline tag creation driven by suggestions.
class AppChipAutocomplete<T> extends StatelessWidget {
  const AppChipAutocomplete({
    super.key,
    required this.suggestions,
    required this.chipBuilder,
    required this.onChipSubmitted,
    this.onChipsChanged,
    this.controller,
    this.initialChips,
    this.placeholder,
    this.hintText,
    this.enabled = true,
    this.autofocus = false,
    this.readOnly = false,
    this.useChips,
    this.mode = shadcn.AutoCompleteMode.replaceWord,
    this.popoverConstraints,
    this.popoverWidthConstraint = shadcn.PopoverConstraint.flexible,
  });

  /// Autocomplete string suggestions list.
  final List<String> suggestions;

  /// Builder for rendering each chip item widget.
  final shadcn.ChipWidgetBuilder<T> chipBuilder;

  /// Callback to convert selected suggestion or entered text into a chip.
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

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether the field should autofocus.
  final bool autofocus;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Whether to display visual chip cards.
  final bool? useChips;

  /// Matching mode for autocomplete suggestions.
  final shadcn.AutoCompleteMode mode;

  /// Optional popover constraints.
  final BoxConstraints? popoverConstraints;

  /// Popover width constraint strategy.
  final shadcn.PopoverConstraint popoverWidthConstraint;

  @override
  Widget build(BuildContext context) {
    return shadcn.AutoComplete(
      suggestions: suggestions,
      mode: mode,
      popoverConstraints: popoverConstraints,
      popoverWidthConstraint: popoverWidthConstraint,
      child: AppChipInput<T>(
        controller: controller,
        initialChips: initialChips,
        chipBuilder: chipBuilder,
        onChipSubmitted: onChipSubmitted,
        onChipsChanged: onChipsChanged,
        placeholder: placeholder,
        hintText: hintText,
        enabled: enabled,
        autofocus: autofocus,
        readOnly: readOnly,
        useChips: useChips,
        autoInsertSuggestion: true,
      ),
    );
  }
}
