import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/services/sale_product_catalog_port.dart';
import '../providers/sale_barcode_capture_provider.dart';
import '../providers/sale_providers.dart';
import 'sale_status_badge.dart';

Future<SaleProductRef?> showSaleProductSelector(BuildContext context) {
  return showModalBottomSheet<SaleProductRef>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _ProductSelectorSheet(),
  );
}

class _ProductSelectorSheet extends ConsumerStatefulWidget {
  const _ProductSelectorSheet();

  @override
  ConsumerState<_ProductSelectorSheet> createState() =>
      _ProductSelectorSheetState();
}

class _ProductSelectorSheetState extends ConsumerState<_ProductSelectorSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  var _loading = true;
  List<SaleProductRef> _results = const [];

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _search(value);
    });
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    final results = await ref
        .read(saleProductCatalogPortProvider)
        .search(query);
    if (!mounted) {
      return;
    }
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  Future<void> _scan() async {
    final raw = await ref.read(saleBarcodeCaptureProvider)(context);
    if (raw == null || !mounted) {
      return;
    }
    final product = await ref
        .read(saleProductCatalogPortProvider)
        .resolveScan(raw);
    if (!mounted) {
      return;
    }
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).salesProductNotFound),
        ),
      );
      return;
    }
    Navigator.of(context).pop(product);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.85;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.salesAddProduct,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: _onChanged,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: l10n.salesSearchProductHint,
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filledTonal(
                      tooltip: l10n.salesScanProduct,
                      onPressed: _scan,
                      icon: const Icon(Icons.qr_code_scanner),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                ? Center(child: Text(l10n.salesProductsEmpty))
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = _results[index];
                      return ListTile(
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          [
                            product.itemCode,
                            if (product.barcode != null) product.barcode,
                          ].join(' · '),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SaleMoneyText(
                              product.unitPrice,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              l10n.salesAdd,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.of(context).pop(product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
