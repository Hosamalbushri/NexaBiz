import 'package:flutter/material.dart';

import '../theme/tokens/tokens.dart';
import 'app_text_field.dart';

/// Canonical search field primitive for NexaBiz ERP.
///
/// Features search prefix icon, clear suffix button, hint text,
/// and value change & submit callbacks.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.enabled = true,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final hasText = controller?.text.isNotEmpty ?? false;

    return AppTextField(
      controller: controller,
      hint: hint,
      prefixIcon: Icons.search_rounded,
      enabled: enabled,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      suffixIcon: hasText && enabled
          ? IconButton(
              icon: const Icon(Icons.close_rounded, size: AppIcons.xs),
              onPressed: () {
                controller?.clear();
                onChanged?.call('');
                onClear?.call();
              },
            )
          : null,
    );
  }
}
