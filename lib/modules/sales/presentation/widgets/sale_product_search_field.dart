import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/digit_normalization.dart';
import '../../domain/services/sale_product_catalog_port.dart';
import '../providers/sale_providers.dart';
import 'sale_status_badge.dart';

/// Inline product name search with live results (no separate search sheet).
class SaleProductSearchField extends ConsumerStatefulWidget {
  const SaleProductSearchField({
    super.key,
    required this.onProductSelected,
    this.onScan,
  });

  final ValueChanged<SaleProductRef> onProductSelected;
  final VoidCallback? onScan;

  @override
  ConsumerState<SaleProductSearchField> createState() =>
      _SaleProductSearchFieldState();
}

class _SaleProductSearchFieldState
    extends ConsumerState<SaleProductSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  var _loading = false;
  var _showResults = false;
  List<SaleProductRef> _results = const [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Delay so a result tap can register before hiding.
        Future<void>.delayed(const Duration(milliseconds: 120), () {
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
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
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
        .read(saleProductCatalogPortProvider)
        .search(query, limit: 30);
    if (!mounted || _controller.text.trim() != query) {
      return;
    }
    setState(() {
      _results = results;
      _loading = false;
      _showResults = true;
    });
  }

  void _select(SaleProductRef product) {
    widget.onProductSelected(product);
    _controller.clear();
    setState(() {
      _results = const [];
      _loading = false;
      _showResults = false;
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final query = _controller.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.35,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.sm,
              end: AppSpacing.xs,
              top: 4,
              bottom: 4,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.search,
                    inputFormatters: const [WesternDigitsInputFormatter()],
                    onChanged: _onChanged,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: l10n.salesSearchProductHint,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ),
                if (query.isNotEmpty)
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                    onPressed: () {
                      _controller.clear();
                      _onChanged('');
                    },
                    icon: const Icon(Icons.close, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                if (widget.onScan != null)
                  IconButton.filledTonal(
                    tooltip: l10n.salesScanProduct,
                    onPressed: widget.onScan,
                    icon: const Icon(Icons.qr_code_scanner),
                  ),
              ],
            ),
          ),
        ),
        if (_showResults && query.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            clipBehavior: Clip.antiAlias,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
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
                        l10n.salesProductNotFound,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _results.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.35,
                          ),
                        ),
                        itemBuilder: (context, index) {
                          final product = _results[index];
                          return ListTile(
                            title: Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            trailing: SaleMoneyText(
                              product.unitPrice,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            onTap: () => _select(product),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}
