import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/modules/accounting/journals/domain/entities/journal_entry.dart';
import 'package:stock_count/modules/accounting/journals/domain/services/journal_source_category_resolver.dart';

void main() {
  group('JournalSourceCategoryResolver Unit Tests', () {
    JournalEntryHeader makeHeader({
      String? sourceType,
      String voucherType = '',
    }) {
      return JournalEntryHeader(
        id: 'test-uuid',
        entryDate: DateTime(2026, 1, 1),
        voucherNumber: 'JV-001',
        voucherType: voucherType,
        totalDebit: 100,
        totalCredit: 100,
        currencyCode: 'SAR',
        description: 'Test',
        isPosted: true,
        sourceType: sourceType,
      );
    }

    test(
      'isManual identifies null, empty, manual, or journal_manual correctly',
      () {
        expect(
          JournalSourceCategoryResolver.isManual(makeHeader(sourceType: null)),
          true,
        );
        expect(
          JournalSourceCategoryResolver.isManual(makeHeader(sourceType: '')),
          true,
        );
        expect(
          JournalSourceCategoryResolver.isManual(
            makeHeader(sourceType: 'manual'),
          ),
          true,
        );
        expect(
          JournalSourceCategoryResolver.isManual(
            makeHeader(sourceType: 'journal_manual'),
          ),
          true,
        );
        expect(
          JournalSourceCategoryResolver.isManual(
            makeHeader(sourceType: 'sale'),
          ),
          false,
        );
        expect(
          JournalSourceCategoryResolver.isManual(
            makeHeader(sourceType: 'stock_receipt'),
          ),
          false,
        );
      },
    );

    test(
      'resolve maps machine-readable sourceType keys deterministically without string matching',
      () {
        expect(
          JournalSourceCategoryResolver.resolve(makeHeader(sourceType: 'sale')),
          JournalSourceCategory.sales,
        );
        expect(
          JournalSourceCategoryResolver.resolve(
            makeHeader(sourceType: 'sales_invoice'),
          ),
          JournalSourceCategory.sales,
        );
        expect(
          JournalSourceCategoryResolver.resolve(
            makeHeader(sourceType: 'stock_receipt'),
          ),
          JournalSourceCategory.inventory,
        );
        expect(
          JournalSourceCategoryResolver.resolve(
            makeHeader(sourceType: 'stock_issue'),
          ),
          JournalSourceCategory.inventory,
        );
        expect(
          JournalSourceCategoryResolver.resolve(
            makeHeader(sourceType: 'receipt'),
          ),
          JournalSourceCategory.receiptsPayments,
        );
        expect(
          JournalSourceCategoryResolver.resolve(
            makeHeader(sourceType: 'payment'),
          ),
          JournalSourceCategory.receiptsPayments,
        );
        expect(
          JournalSourceCategoryResolver.resolve(
            makeHeader(sourceType: 'opening_balance'),
          ),
          JournalSourceCategory.opening,
        );
        expect(
          JournalSourceCategoryResolver.resolve(
            makeHeader(sourceType: 'period_closing'),
          ),
          JournalSourceCategory.closing,
        );
        expect(
          JournalSourceCategoryResolver.resolve(
            makeHeader(sourceType: 'custom_extension'),
          ),
          JournalSourceCategory.other,
        );
      },
    );

    test('resolution is independent of display voucherType strings', () {
      final headerWithArabicVoucher = makeHeader(
        sourceType: 'sale',
        voucherType: 'مبيعات نقدية',
      );
      final headerWithEnglishVoucher = makeHeader(
        sourceType: 'sale',
        voucherType: 'Cash Sale Invoice',
      );

      expect(
        JournalSourceCategoryResolver.resolve(headerWithArabicVoucher),
        JournalSourceCategory.sales,
      );
      expect(
        JournalSourceCategoryResolver.resolve(headerWithEnglishVoucher),
        JournalSourceCategory.sales,
      );
    });
  });
}
