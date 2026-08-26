import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/modules/sales/shared/domain/services/sale_voucher_book_port.dart';
import '../providers/sale_providers.dart';

Future<SaleVoucherBookRef?> showSaleVoucherBookSelector(BuildContext context) {
  return showModalBottomSheet<SaleVoucherBookRef>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _VoucherBookSheet(),
  );
}

class _VoucherBookSheet extends ConsumerStatefulWidget {
  const _VoucherBookSheet();

  @override
  ConsumerState<_VoucherBookSheet> createState() => _VoucherBookSheetState();
}

class _VoucherBookSheetState extends ConsumerState<_VoucherBookSheet> {
  var _loading = true;
  List<SaleVoucherBookRef> _books = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final books = await ref
        .read(saleVoucherBookPortProvider)
        .listActiveSalesBooks();
    if (!mounted) {
      return;
    }
    setState(() {
      _books = books;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.55,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l10n.salesVoucherBook,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _books.isEmpty
                ? Center(child: Text(l10n.salesVoucherBookEmpty))
                : ListView.separated(
                    itemCount: _books.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final book = _books[index];
                      return ListTile(
                        title: Text(book.name),
                        subtitle: Text(
                          '${l10n.salesInvoiceNumber}: ${book.previewNumber}',
                        ),
                        enabled: book.canAllocate,
                        onTap: book.canAllocate
                            ? () => Navigator.of(context).pop(book)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
