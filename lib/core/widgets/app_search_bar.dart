import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        return AppTextField(
          controller: _controller,
          focusNode: widget.focusNode,
          hint: widget.hint,
          autofocus: widget.autofocus,
          prefixIcon: Icons.search_rounded,
          textInputAction: TextInputAction.search,
          onChanged: widget.onChanged,
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
        );
      },
    );
  }
}
