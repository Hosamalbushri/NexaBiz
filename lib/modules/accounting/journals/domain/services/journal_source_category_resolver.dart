import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';

/// Language-independent journal source categories for presentation and filtering.
enum JournalSourceCategory {
  sales,
  inventory,
  receiptsPayments,
  opening,
  closing,
  manual,
  other;

  /// Whether this category is an automated system-generated journal.
  bool get isAutomated => this != JournalSourceCategory.manual;
}

/// Domain service for resolving journal source categories from machine-readable source types.
class JournalSourceCategoryResolver {
  const JournalSourceCategoryResolver._();

  /// Determines if a journal entry header is a manual journal entry.
  static bool isManual(JournalEntryHeader entry) {
    return isManualSourceType(entry.sourceType);
  }

  /// Determines if a raw sourceType string represents a manual entry.
  static bool isManualSourceType(String? sourceType) {
    if (sourceType == null || sourceType.trim().isEmpty) {
      return true;
    }
    final normalized = sourceType.trim().toLowerCase();
    return normalized == 'manual' || normalized == 'journal_manual';
  }

  /// Resolves the canonical [JournalSourceCategory] for a journal entry header using strict machine-readable source keys.
  static JournalSourceCategory resolve(JournalEntryHeader entry) {
    return resolveFromSourceType(entry.sourceType);
  }

  /// Resolves the canonical [JournalSourceCategory] from a machine-readable sourceType identifier.
  /// Substring/language string matching is strictly prohibited.
  static JournalSourceCategory resolveFromSourceType(String? sourceType) {
    if (sourceType == null || sourceType.trim().isEmpty) {
      return JournalSourceCategory.manual;
    }

    final normalized = sourceType.trim().toLowerCase();

    return switch (normalized) {
      'sale' ||
      'sales' ||
      'sale_invoice' ||
      'sales_invoice' ||
      'sale_return' =>
        JournalSourceCategory.sales,
      'stock_receipt' ||
      'stock_issue' ||
      'stock_transfer' ||
      'inventory' ||
      'stock' =>
        JournalSourceCategory.inventory,
      'receipt' ||
      'payment' ||
      'transfer' ||
      'currency_exchange' ||
      'cash_register' ||
      'rp' =>
        JournalSourceCategory.receiptsPayments,
      'opening_balance' || 'opening' => JournalSourceCategory.opening,
      'period_closing' || 'closing' => JournalSourceCategory.closing,
      'manual' || 'journal_manual' => JournalSourceCategory.manual,
      _ => JournalSourceCategory.other,
    };
  }
}
