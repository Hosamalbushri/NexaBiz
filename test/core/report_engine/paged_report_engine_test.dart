import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/report_engine/domain/models/report_execution_context.dart';
import 'package:stock_count/core/report_engine/domain/models/report_summary.dart';
import 'package:stock_count/core/report_engine/domain/models/report_cursor.dart';
import 'package:stock_count/core/report_engine/domain/models/report_page.dart';

void main() {
  group('Report Engine Phase 1 Core Domain Models', () {
    test('ReportExecutionContext defaults and PostingScope parsing', () {
      const ctx = ReportExecutionContext(
        companyId: 'COMPANY_001',
        postingScope: PostingScope.postedOnly,
      );

      expect(ctx.companyId, equals('COMPANY_001'));
      expect(ctx.postingScope, equals(PostingScope.postedOnly));
      expect(PostingScopeX.fromString('posted'), equals(PostingScope.postedOnly));
      expect(PostingScopeX.fromString('unposted'), equals(PostingScope.unpostedOnly));
      expect(PostingScopeX.fromString('all'), equals(PostingScope.all));
    });

    test('ReportSummary calculation container', () {
      const summary = ReportSummary(
        totalCount: 150,
        aggregates: {'subtotal': 15000.0, 'grandTotal': 17250.0},
        kpis: {'countInvoices': 150},
      );

      expect(summary.totalCount, equals(150));
      expect(summary.aggregates['grandTotal'], equals(17250.0));
      expect(summary.kpis['countInvoices'], equals(150));
    });

    test('ReportCursor determinism and serialization', () {
      const cursor = ReportCursor(
        primarySortValue: 1725000000000,
        uniqueId: '42',
      );

      final json = cursor.toJson();
      expect(json['primarySortValue'], equals(1725000000000));
      expect(json['uniqueId'], equals('42'));

      final restored = ReportCursor.fromJson(json);
      expect(restored.primarySortValue, equals(1725000000000));
      expect(restored.uniqueId, equals('42'));
    });

    test('ReportPage chunk encapsulation', () {
      final page = ReportPage<String>(
        items: const ['Row1', 'Row2'],
        nextCursor: const ReportCursor(primarySortValue: 100, uniqueId: '2'),
        hasNextPage: true,
      );

      expect(page.items.length, equals(2));
      expect(page.hasNextPage, isTrue);
      expect(page.nextCursor?.uniqueId, equals('2'));
    });
  });
}
