import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_async_autocomplete_field.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_customer_lookup_port.dart';
import '../providers/sale_providers.dart';
import '../../domain/services/sale_autocomplete_defaults.dart';

/// Inline customer search with live results, built using [AppAsyncAutocompleteField].
class SaleCustomerSearchField extends ConsumerStatefulWidget {
  const SaleCustomerSearchField({
    super.key,
    required this.onCustomerSelected,
    this.onQueryChanged,
    this.onCancel,
    this.initialQuery = '',
    this.hintText,
    this.autofocus = false,
  });

  final ValueChanged<SaleCustomerRef> onCustomerSelected;

  /// Fired on each typed change (cash walk-in name).
  final ValueChanged<String>? onQueryChanged;

  /// Closes the search UI (e.g. when opened via search icon).
  final VoidCallback? onCancel;

  final String initialQuery;
  final String? hintText;
  final bool autofocus;

  @override
  ConsumerState<SaleCustomerSearchField> createState() =>
      _SaleCustomerSearchFieldState();
}

class _SaleCustomerSearchFieldState
    extends ConsumerState<SaleCustomerSearchField> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode(skipTraversal: true);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void didUpdateWidget(covariant SaleCustomerSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery &&
        widget.initialQuery != _controller.text) {
      _controller.text = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<List<SaleCustomerRef>> _search(String query) async {
    return ref
        .read(saleCustomerLookupPortProvider)
        .search(query, limit: SaleAutocompleteDefaults.resultLimit);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final customDecoration = InputDecoration(
      isDense: true,
      filled: true,
      fillColor: scheme.surface,
      hintText: widget.hintText ?? l10n.salesSearchCustomerHint,
      hintStyle: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface.withValues(alpha: 0.45),
      ),
      prefixIcon: Icon(
        Icons.search_rounded,
        color: scheme.primary,
      ),
      suffixIcon: IconButton(
        tooltip: widget.onCancel != null
            ? MaterialLocalizations.of(context).cancelButtonLabel
            : MaterialLocalizations.of(context).deleteButtonTooltip,
        onPressed: () {
          if (widget.onCancel != null) {
            widget.onCancel!();
            return;
          }
          _controller.clear();
          widget.onQueryChanged?.call('');
        },
        icon: Icon(
          Icons.close_rounded,
          color: scheme.onSurfaceVariant,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: BorderSide(
          color: scheme.primary,
          width: 1.4,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 12,
      ),
    );

    return AppAsyncAutocompleteField<SaleCustomerRef>(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      minQueryLength: SaleAutocompleteDefaults.customerMinLength,
      debounceDuration: const Duration(
        milliseconds: SaleAutocompleteDefaults.debounceMs,
      ),
      decoration: customDecoration,
      fetchOptions: _search,
      itemLabelBuilder: (c) => c.name,
      onQueryChanged: widget.onQueryChanged,
      onSelected: (customer) {
        if (customer != null) {
          widget.onQueryChanged?.call(customer.name);
          widget.onCustomerSelected(customer);
        }
      },
      onEditingComplete: () {
        widget.onQueryChanged?.call(_controller.text);
      },
      onSubmitted: (val) {
        widget.onQueryChanged?.call(val);
      },
      noResultsText: l10n.salesCustomerNotFound,
      errorText: l10n.salesAutocompleteSearchFailed,
      itemBuilder: (context, customer) {
        final phone = customer.phone?.trim();
        final hasPhone = phone != null && phone.isNotEmpty;
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: scheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (hasPhone)
                      Text(
                        phone,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

