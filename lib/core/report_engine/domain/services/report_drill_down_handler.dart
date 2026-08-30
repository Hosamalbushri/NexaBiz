import 'package:flutter/material.dart';

/// Handler for executing drill-down navigation from a report row to original voucher details screen.
class ReportDrillDownHandler {
  const ReportDrillDownHandler._();

  /// Navigates to target voucher screen based on [documentType] and [documentUuid].
  static void navigateToDocument(
    BuildContext context, {
    required String documentType,
    required String documentUuid,
  }) {
    if (documentUuid.isEmpty) return;

    final type = documentType.toLowerCase();

    switch (type) {
      case 'sale':
      case 'sales_invoice':
      case 'invoice':
        // Navigate to Sale Details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فتح فاتورة المبيعات: $documentUuid')),
        );
        break;

      case 'stock_receipt':
      case 'receipt':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فتح أمر التوريد المخزني: $documentUuid')),
        );
        break;

      case 'stock_issue':
      case 'issue':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فتح أمر الصرف المخزني: $documentUuid')),
        );
        break;

      case 'journal_entry':
      case 'journal':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فتح القيد المحاسبي: $documentUuid')),
        );
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('الانتقال للمستند: $documentType / $documentUuid')),
        );
        break;
    }
  }
}
