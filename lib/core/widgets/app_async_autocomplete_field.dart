import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../utils/async_search_token.dart';
import '../utils/digit_normalization.dart';

/// Generic debounced async autocomplete search field.
///
/// Handles input normalization, debouncing, and stale result discarding via [AsyncSearchToken].
class AppAsyncAutocompleteField<T> extends StatefulWidget {
  const AppAsyncAutocompleteField({
    super.key,
    required this.fetchOptions,
    required this.itemBuilder,
    this.onSelected,
    this.itemLabelBuilder,
    this.initialQuery,
    this.onQueryChanged,
    this.onCancel,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.minQueryLength = 1,
    this.autofocus = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.decoration,
    this.inputFormatters,
    this.textInputAction = TextInputAction.done,
    this.onEditingComplete,
    this.onSubmitted,
    this.emptyBuilder,
    this.noResultsText,
    this.errorBuilder,
    this.errorText,
    this.maxResultsHeight = 180,
    this.showLabelAbove = false,
  });

  /// Async or sync callback to fetch autocomplete items for [query].
  final FutureOr<List<T>> Function(String query) fetchOptions;

  /// Builds each dropdown item widget.
  final Widget Function(BuildContext context, T option) itemBuilder;

  /// Callback when an item is selected from the dropdown (or cleared if null).
  final ValueChanged<T?>? onSelected;

  /// Optional label builder for selected items to set display text in the text field.
  final String Function(T option)? itemLabelBuilder;

  /// Initial search query text.
  final String? initialQuery;

  /// Callback fired on raw text changes (e.g. for walk-in input).
  final ValueChanged<String>? onQueryChanged;

  /// Callback fired when the cancel / clear button is pressed.
  final VoidCallback? onCancel;

  /// Optional controller override.
  final TextEditingController? controller;

  /// Optional focus node override.
  final FocusNode? focusNode;

  /// Label string (rendered above or in decoration depending on [showLabelAbove]).
  final String? label;

  /// Hint string for the text field.
  final String? hint;

  /// Debounce duration before triggering [fetchOptions].
  final Duration debounceDuration;

  /// Minimum query length before triggering search.
  final int minQueryLength;

  /// Whether the input field should autofocus.
  final bool autofocus;

  /// Whether the input field is enabled.
  final bool enabled;

  /// Prefix icon or widget.
  final Widget? prefixIcon;

  /// Custom suffix icon or widget (shown when not loading).
  final Widget? suffixIcon;

  /// Explicit decoration override.
  final InputDecoration? decoration;

  /// TextInputFormatters for digit normalization or formatting.
  final List<TextInputFormatter>? inputFormatters;

  /// Keyboard action.
  final TextInputAction? textInputAction;

  /// Editing complete callback.
  final VoidCallback? onEditingComplete;

  /// Submitted callback.
  final ValueChanged<String>? onSubmitted;

  /// Custom empty state builder.
  final Widget Function(BuildContext context)? emptyBuilder;

  /// Optional message displayed when search yields empty results.
  final String? noResultsText;

  /// Custom error state builder.
  final Widget Function(BuildContext context)? errorBuilder;

  /// Optional message displayed when search fails.
  final String? errorText;

  /// Maximum height of the dropdown results card.
  final double maxResultsHeight;

  /// Whether to render [label] as a bold header widget above the text field.
  final bool showLabelAbove;

  @override
  State<AppAsyncAutocompleteField<T>> createState() =>
      _AppAsyncAutocompleteFieldState<T>();
}

class _AppAsyncAutocompleteFieldState<T>
    extends State<AppAsyncAutocompleteField<T>> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController(text: widget.initialQuery ?? '');
  late final bool _ownsController = widget.controller == null;

  late final FocusNode _focusNode =
      widget.focusNode ?? FocusNode(skipTraversal: true);
  late final bool _ownsFocusNode = widget.focusNode == null;

  final _searchToken = AsyncSearchToken();
  Timer? _debounceTimer;

  List<T> _options = const [];
  bool _isLoading = false;
  bool _showResults = false;
  bool _searchFailed = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && _controller.text != widget.initialQuery) {
      _controller.text = widget.initialQuery!;
    }
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppAsyncAutocompleteField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery &&
        widget.initialQuery != null &&
        widget.initialQuery != _controller.text) {
      _controller.text = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _debounceTimer?.cancel();
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      Future<void>.delayed(const Duration(milliseconds: 140), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() => _showResults = false);
        }
      });
    } else if (_normalizedQuery.length >= widget.minQueryLength) {
      if (_options.isNotEmpty || _searchFailed) {
        setState(() => _showResults = true);
      } else {
        _onQueryChanged(_controller.text);
      }
    }
  }

  String get _normalizedQuery =>
      normalizeDigitsToWestern(_controller.text).trim();

  void _onQueryChanged(String rawQuery) {
    widget.onQueryChanged?.call(rawQuery);
    final query = normalizeDigitsToWestern(rawQuery).trim();
    _debounceTimer?.cancel();

    if (query.length < widget.minQueryLength) {
      _searchToken.next();
      setState(() {
        _options = const [];
        _isLoading = false;
        _showResults = false;
        _searchFailed = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showResults = true;
      _searchFailed = false;
    });

    _debounceTimer =
        Timer(widget.debounceDuration, () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    final currentToken = _searchToken.next();
    try {
      final results = await widget.fetchOptions(query);
      if (!_searchToken.isCurrent(currentToken) || !mounted) {
        return;
      }
      setState(() {
        _options = results;
        _isLoading = false;
        _showResults = true;
        _searchFailed = false;
      });
    } catch (_) {
      if (!_searchToken.isCurrent(currentToken) || !mounted) {
        return;
      }
      setState(() {
        _options = const [];
        _isLoading = false;
        _showResults = true;
        _searchFailed = true;
      });
    }
  }

  void _selectOption(T option) {
    if (widget.itemLabelBuilder != null) {
      _controller.text = widget.itemLabelBuilder!(option);
    }
    widget.onSelected?.call(option);
    setState(() {
      _options = const [];
      _isLoading = false;
      _showResults = false;
      _searchFailed = false;
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final query = _normalizedQuery;

    final defaultDecoration = InputDecoration(
      isDense: true,
      filled: true,
      fillColor: scheme.surface,
      labelText: widget.showLabelAbove ? null : widget.label,
      hintText: widget.hint,
      prefixIcon: widget.prefixIcon ??
          Icon(
            Icons.search_rounded,
            color: scheme.primary,
          ),
      suffixIcon: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : widget.suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );

    final effectiveDecoration = widget.decoration != null
        ? widget.decoration!.copyWith(
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (widget.decoration!.suffixIcon ?? widget.suffixIcon),
          )
        : defaultDecoration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabelAbove && widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters ??
              const [WesternDigitsInputFormatter()],
          decoration: effectiveDecoration,
          onChanged: _onQueryChanged,
          onEditingComplete: () {
            widget.onEditingComplete?.call();
            _focusNode.unfocus();
          },
          onSubmitted: (val) {
            widget.onSubmitted?.call(val);
            _focusNode.unfocus();
          },
        ),
        if (_showResults && query.length >= widget.minQueryLength) ...[
          const SizedBox(height: AppSpacing.xs),
          Material(
            color: scheme.surface,
            elevation: 2,
            shadowColor: scheme.shadow.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: widget.maxResultsHeight),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : _searchFailed
                      ? (widget.errorBuilder?.call(context) ??
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(
                              widget.errorText ?? 'Search failed',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.error,
                              ),
                            ),
                          ))
                      : _options.isEmpty
                          ? (widget.emptyBuilder?.call(context) ??
                              (widget.noResultsText != null
                                  ? Padding(
                                      padding: const EdgeInsets.all(
                                          AppSpacing.md),
                                      child: Text(
                                        widget.noResultsText!,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink()))
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: _options.length,
                              separatorBuilder: (_, _) => Divider(
                                height: 1,
                                color: scheme.outlineVariant
                                    .withValues(alpha: 0.35),
                              ),
                              itemBuilder: (context, index) {
                                final option = _options[index];
                                return InkWell(
                                  onTap: () => _selectOption(option),
                                  child: widget.itemBuilder(context, option),
                                );
                              },
                            ),
            ),
          ),
        ],
      ],
    );
  }
}

