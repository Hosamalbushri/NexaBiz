import 'package:flutter/material.dart';

import '../theme/tokens/app_icons.dart';
import 'app_field_shell.dart';
import 'app_text_field.dart';

/// Canonical search field primitive for NexaBiz ERP.
///
/// Features search prefix icon, clear suffix button, hint text,
/// and value change & submit callbacks.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.enabled = true,
    this.autofocus = false,
    this.density = AppFieldDensity.compact,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool enabled;
  final bool autofocus;
  final AppFieldDensity density;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  TextEditingController? _internalController;

  TextEditingController get _effectiveController =>
      widget.controller ?? (_internalController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _effectiveController.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleTextChange);
      _effectiveController.addListener(_handleTextChange);
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_handleTextChange);
    _internalController?.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _effectiveController.text.isNotEmpty;

    return AppTextField(
      controller: _effectiveController,
      hint: widget.hint,
      prefixIcon: Icons.search_rounded,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      density: widget.density,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      suffixIcon: hasText && widget.enabled
          ? IconButton(
              icon: const Icon(Icons.close_rounded, size: AppIcons.xs),
              onPressed: () {
                _effectiveController.clear();
                widget.onChanged?.call('');
                widget.onClear?.call();
              },
            )
          : null,
    );
  }
}
