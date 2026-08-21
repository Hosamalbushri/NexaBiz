import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/async_search_token.dart';
import '../utils/digit_normalization.dart';
import 'app_text_field.dart';

/// Generic debounced async autocomplete search field.
///
/// Handles input normalization, debouncing, and stale result discarding via [AsyncSearchToken].
class AppAsyncAutocompleteField<T> extends StatefulWidget {
  const AppAsyncAutocompleteField({
    super.key,
    required this.fetchOptions,
    required this.onSelected,
    required this.itemBuilder,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.debounceDuration = const Duration(milliseconds: 250),
    this.minQueryLength = 1,
    this.autofocus = false,
  });

  final Future<List<T>> Function(String query) fetchOptions;
  final ValueChanged<T> onSelected;
  final Widget Function(BuildContext context, T option) itemBuilder;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final Duration debounceDuration;
  final int minQueryLength;
  final bool autofocus;

  @override
  State<AppAsyncAutocompleteField<T>> createState() =>
      _AppAsyncAutocompleteFieldState<T>();
}

class _AppAsyncAutocompleteFieldState<T>
    extends State<AppAsyncAutocompleteField<T>> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final bool _ownsController = widget.controller == null;
  final _searchToken = AsyncSearchToken();
  Timer? _debounceTimer;
  List<T> _options = const [];
  bool _isLoading = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onQueryChanged(String rawQuery) {
    final query = normalizeDigitsToWestern(rawQuery).trim();
    _debounceTimer?.cancel();

    if (query.length < widget.minQueryLength) {
      setState(() {
        _options = const [];
        _isLoading = false;
      });
      return;
    }

    _debounceTimer = Timer(widget.debounceDuration, () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    final currentToken = _searchToken.next();
    setState(() => _isLoading = true);

    try {
      final results = await widget.fetchOptions(query);
      if (!_searchToken.isCurrent(currentToken) || !mounted) {
        return;
      }
      setState(() {
        _options = results;
        _isLoading = false;
      });
    } catch (_) {
      if (_searchToken.isCurrent(currentToken) && mounted) {
        setState(() {
          _options = const [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          controller: _controller,
          focusNode: widget.focusNode,
          label: widget.label,
          hint: widget.hint,
          autofocus: widget.autofocus,
          prefixIcon: Icons.search_rounded,
          onChanged: _onQueryChanged,
          suffixIcon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
        if (_options.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _options.length,
              itemBuilder: (context, index) {
                final option = _options[index];
                return InkWell(
                  onTap: () {
                    widget.onSelected(option);
                    setState(() => _options = const []);
                  },
                  child: widget.itemBuilder(context, option),
                );
              },
            ),
          ),
      ],
    );
  }
}
