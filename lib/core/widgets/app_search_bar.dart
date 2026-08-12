import 'package:flutter/material.dart';

import '../utils/digit_normalization.dart';
import 'app_text_field.dart';

/// Search field with consistent styling and clear action.
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    required this.onChanged,
    this.controller,
    this.focusNode,
    this.hint,
    this.autofocus = false,
  });

  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final bool autofocus;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final bool _ownsController = widget.controller == null;
  late var _hasText = _controller.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerTick);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerTick);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerTick() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText == _hasText || !mounted) {
      return;
    }
    setState(() => _hasText = hasText);
  }

  void _handleChanged(String value) {
    widget.onChanged(normalizeDigitsToWestern(value));
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      focusNode: widget.focusNode,
      hint: widget.hint,
      autofocus: widget.autofocus,
      prefixIcon: Icons.search_rounded,
      textInputAction: TextInputAction.search,
      inputFormatters: const [WesternDigitsInputFormatter()],
      onChanged: _handleChanged,
      suffixIcon: _hasText
          ? IconButton(
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              onPressed: _clear,
              icon: const Icon(Icons.close_rounded),
            )
          : null,
    );
  }
}
