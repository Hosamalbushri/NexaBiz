import 'package:flutter/material.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../domain/entities/voucher_book_type.dart';

String voucherBookTypeLabel(AppLocalizations l10n, VoucherBookType type) {
  return switch (type) {
    VoucherBookType.sales => l10n.accountingVoucherBookTypeSales,
    VoucherBookType.salesReturns => l10n.accountingVoucherBookTypeSalesReturns,
    VoucherBookType.receipts => l10n.accountingVoucherBookTypeReceipts,
    VoucherBookType.payments => l10n.accountingVoucherBookTypePayments,
    VoucherBookType.purchases => l10n.accountingVoucherBookTypePurchases,
    VoucherBookType.purchaseReturns =>
      l10n.accountingVoucherBookTypePurchaseReturns,
    VoucherBookType.journal => l10n.accountingVoucherBookTypeJournal,
  };
}

String voucherBookSectionLabel(AppLocalizations l10n, VoucherBookType section) {
  return voucherBookTypeLabel(l10n, section.section);
}

IconData voucherBookTypeIcon(VoucherBookType type) {
  return switch (type) {
    VoucherBookType.sales => Icons.point_of_sale_outlined,
    VoucherBookType.salesReturns => Icons.assignment_return_outlined,
    VoucherBookType.receipts => Icons.call_received_outlined,
    VoucherBookType.payments => Icons.call_made_outlined,
    VoucherBookType.purchases => Icons.shopping_cart_outlined,
    VoucherBookType.purchaseReturns => Icons.undo_outlined,
    VoucherBookType.journal => Icons.menu_book_outlined,
  };
}
