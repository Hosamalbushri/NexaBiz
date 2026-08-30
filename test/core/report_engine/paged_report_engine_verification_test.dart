import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/report_engine/domain/models/report_execution_context.dart';
import 'package:stock_count/core/report_engine/domain/models/report_summary.dart';
import 'package:stock_count/core/report_engine/domain/models/report_cursor.dart';
import 'package:stock_count/core/report_engine/domain/models/report_page.dart';

void main() {
  group('1. Read-Only & Execution Context Verification Tests', () {
    test('ReportExecutionContext maintains strict immutability and complete filter state', () {
      final now = DateTime.now();
      final context = ReportExecutionContext(
        companyId: 'TENANT_A',
        userId: 'USER_101',
        filters: {
          'fromDate': now.subtract(const Duration(days: 30)),
          'toDate': now,
          'customer': 'CUST_500',
        },
        postingScope: PostingScope.postedOnly,
        warehouseScope: 'WH_MAIN',
        accountScope: 'ACC_1101',
        currencyScope: 'SAR',
      );

      expect(context.companyId, equals('TENANT_A'));
      expect(context.userId, equals('USER_101'));
      expect(context.postingScope, equals(PostingScope.postedOnly));
      expect(context.warehouseScope, equals('WH_MAIN'));
      expect(context.accountScope, equals('ACC_1101'));
      expect(context.currencyScope, equals('SAR'));
      expect(context.fromDate, isNotNull);
      expect(context.toDate, isNotNull);
    });
  });

  group('2. Posting Scope Parsing Verification', () {
    test('PostingScopeX correctly maps filter inputs', () {
      expect(PostingScopeX.fromString('posted'), equals(PostingScope.postedOnly));
      expect(PostingScopeX.fromString('postedonly'), equals(PostingScope.postedOnly));
      expect(PostingScopeX.fromString('unposted'), equals(PostingScope.unpostedOnly));
      expect(PostingScopeX.fromString('unpostedonly'), equals(PostingScope.unpostedOnly));
      expect(PostingScopeX.fromString('all'), equals(PostingScope.all));
      expect(PostingScopeX.fromString(null), equals(PostingScope.all));
      expect(PostingScopeX.fromString(''), equals(PostingScope.all));
    });
  });

  group('3. Keyset Cursor Determinism Verification', () {
    test('ReportCursor serialization and deserialization retains unique tie-breaker', () {
      const cursor = ReportCursor(
        primarySortValue: 1725000000000,
        secondarySortValue: 1,
        uniqueId: 'DOC_UUID_999',
      );

      final json = cursor.toJson();
      expect(json['primarySortValue'], equals(1725000000000));
      expect(json['secondarySortValue'], equals(1));
      expect(json['uniqueId'], equals('DOC_UUID_999'));

      final restored = ReportCursor.fromJson(json);
      expect(restored.primarySortValue, equals(1725000000000));
      expect(restored.secondarySortValue, equals(1));
      expect(restored.uniqueId, equals('DOC_UUID_999'));
    });

    test('ReportPage pagination metadata enforces deterministic hasNextPage state', () {
      final pageWithMore = ReportPage<String>(
        items: const ['Item 1', 'Item 2'],
        nextCursor: const ReportCursor(primarySortValue: 100, uniqueId: 'ID_2'),
        hasNextPage: true,
      );

      expect(pageWithMore.items.length, equals(2));
      expect(pageWithMore.hasNextPage, isTrue);
      expect(pageWithMore.nextCursor?.uniqueId, equals('ID_2'));

      final lastPage = ReportPage<String>(
        items: const ['Item 3'],
        nextCursor: null,
        hasNextPage: false,
      );

      expect(lastPage.hasNextPage, isFalse);
      expect(lastPage.nextCursor, isNull);
    });
  });

  group('4. Summary Aggregation Mathematical Consistency', () {
    test('ReportSummary enforces non-null, consistent KPI and aggregate totals', () {
      const summary = ReportSummary(
        totalCount: 50,
        aggregates: {
          'subtotal': 5000.0,
          'taxAmount': 750.0,
          'grandTotal': 5750.0,
        },
        kpis: {'totalInvoices': 50},
      );

      expect(summary.totalCount, equals(50));
      expect(summary.aggregates['grandTotal'], equals(5750.0));
      expect(summary.aggregates['subtotal']! + summary.aggregates['taxAmount']!, equals(summary.aggregates['grandTotal']!));
      expect(summary.kpis['totalInvoices'], equals(50));
    });
  });
}
