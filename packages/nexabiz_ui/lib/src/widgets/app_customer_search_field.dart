import 'dart:async';

import 'package:flutter/material.dart';

import 'app_async_autocomplete_field.dart';

/// Reusable design-system customer search field wrapping [AppAsyncAutocompleteField].
class AppCustomerSearchField<T> extends StatelessWidget {
  const AppCustomerSearchField({
    super.key,
    required this.fetchOptions,
    required this.itemLabelBuilder,
    required this.onSelected,
    this.controller,
    this.focusNode,
    this.initialQuery = '',
    this.label,
    this.hint,
    this.showLabelAbove = true,
    this.autofocus = false,
    this.minQueryLength = 2,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.onQueryChanged,
    this.onCancel,
    this.onEditingComplete,
    this.onSubmitted,
    this.noResultsText,
    this.errorText,
    this.itemBuilder,
    this.prefixIcon = Icons.person_outline_rounded,
    this.decoration,
  });

  final Future<List<T>> Function(String query) fetchOptions;
  final String Function(T option) itemLabelBuilder;
  final ValueChanged<T?> onSelected;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String initialQuery;
  final String? label;
  final String? hint;
  final bool showLabelAbove;
  final bool autofocus;
  final int minQueryLength;
  final Duration debounceDuration;
  final ValueChanged<String>? onQueryChanged;
  final VoidCallback? onCancel;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final String? noResultsText;
  final String? errorText;
  final Widget Function(BuildContext context, T option)? itemBuilder;
  final IconData? prefixIcon;
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return AppAsyncAutocompleteField<T>(
      controller: controller,
      focusNode: focusNode,
      initialQuery: initialQuery,
      label: label,
      showLabelAbove: showLabelAbove,
      hint: hint,
      autofocus: autofocus,
      minQueryLength: minQueryLength,
      debounceDuration: debounceDuration,
      fetchOptions: fetchOptions,
      itemLabelBuilder: itemLabelBuilder,
      onSelected: onSelected,
      onQueryChanged: onQueryChanged,
      onCancel: onCancel,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      noResultsText: noResultsText,
      errorText: errorText,
      decoration: decoration,
      itemBuilder:
          itemBuilder ??
          (context, item) {
            final theme = Theme.of(context);
            final scheme = theme.colorScheme;
            return ListTile(
              dense: true,
              leading: prefixIcon != null
                  ? Icon(prefixIcon, color: scheme.primary)
                  : null,
              title: Text(
                itemLabelBuilder(item),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
    );
  }
}
