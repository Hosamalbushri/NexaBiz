import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/digit_normalization.dart';
import '../../domain/services/sale_customer_lookup_port.dart';
import '../providers/sale_providers.dart';

/// Inline customer search with live results (same pattern as product search).
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
  Timer? _debounce;
  var _loading = false;
  var _showResults = false;
  List<SaleCustomerRef> _results = const [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future<void>.delayed(const Duration(milliseconds: 140), () {
          if (mounted && !_focusNode.hasFocus) {
            setState(() => _showResults = false);
          }
        });
      } else if (_controller.text.trim().isNotEmpty) {
        setState(() => _showResults = true);
      }
    });
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
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onQueryChanged?.call(value);
    _debounce?.cancel();
    final query = normalizeDigitsToWestern(value).trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _loading = false;
        _showResults = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _showResults = true;
    });
    _debounce = Timer(const Duration(milliseconds: 220), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    final results = await ref
        .read(saleCustomerLookupPortProvider)
        .search(query, limit: 30);
    if (!mounted ||
        normalizeDigitsToWestern(_controller.text).trim() != query) {
      return;
    }
    setState(() {
      _results = results;
      _loading = false;
      _showResults = true;
    });
  }

  void _select(SaleCustomerRef customer) {
    widget.onCustomerSelected(customer);
    _controller.text = customer.name;
    widget.onQueryChanged?.call(customer.name);
    setState(() {
      _results = const [];
      _loading = false;
      _showResults = false;
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final query = _controller.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          inputFormatters: const [WesternDigitsInputFormatter()],
          textInputAction: TextInputAction.done,
          onChanged: _onChanged,
          onEditingComplete: () => _focusNode.unfocus(),
          onSubmitted: (_) => _focusNode.unfocus(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
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
                _onChanged('');
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
          ),
        ),
        if (_showResults && query.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Material(
            color: scheme.surface,
            elevation: 2,
            shadowColor: scheme.shadow.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: _loading
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
                  : _results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        l10n.salesCustomerNotFound,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: scheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                      itemBuilder: (context, index) {
                        final customer = _results[index];
                        final phone = customer.phone?.trim();
                        final hasPhone = phone != null && phone.isNotEmpty;
                        return InkWell(
                          onTap: () => _select(customer),
                          child: Padding(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer.name,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (hasPhone)
                                        Text(
                                          phone,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
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
