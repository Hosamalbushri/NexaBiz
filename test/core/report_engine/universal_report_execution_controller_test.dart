import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/report_engine/application/universal_report_execution_controller.dart';
import 'package:stock_count/core/report_engine/domain/models/report_cursor.dart';
import 'package:stock_count/core/report_engine/domain/models/report_dataset.dart';
import 'package:stock_count/core/report_engine/domain/models/report_execution_context.dart';
import 'package:stock_count/core/report_engine/domain/models/report_page.dart';
import 'package:stock_count/core/report_engine/domain/models/report_summary.dart';
import 'package:stock_count/core/report_engine/domain/services/paged_report_data_provider.dart';

class MockPagedProvider implements PagedReportDataProvider<ReportRowData> {
  @override
  String get reportId => 'MOCK_REPORT';

  int fetchSummaryCallCount = 0;
  int fetchPageCallCount = 0;

  @override
  Future<ReportSummary> fetchSummary(ReportExecutionContext context) async {
    fetchSummaryCallCount++;
    return const ReportSummary(
      totalCount: 100,
      aggregates: {'total': 1000.0},
    );
  }

  @override
  Future<ReportPage<ReportRowData>> fetchPage(
    ReportExecutionContext context, {
    ReportCursor? cursor,
    int pageSize = 50,
  }) async {
    fetchPageCallCount++;
    final start = cursor == null ? 1 : int.parse(cursor.uniqueId) + 1;
    final end = (start + pageSize - 1) > 100 ? 100 : (start + pageSize - 1);
    final hasNext = end < 100;

    final List<ReportRowData> items = List.generate(
      end - start + 1,
      (i) => ReportRowData(values: {'id': '${start + i}', 'amount': (start + i) * 10.0}),
    );

    return ReportPage<ReportRowData>(
      items: items,
      nextCursor: hasNext ? ReportCursor(primarySortValue: end, uniqueId: '$end') : null,
      hasNextPage: hasNext,
    );
  }
}

void main() {
  group('UniversalReportExecutionController Phase 2 Verification', () {
    late MockPagedProvider provider;
    late ReportExecutionContext contextA;
    late ReportExecutionContext contextB;

    setUp(() {
      provider = MockPagedProvider();
      contextA = const ReportExecutionContext(companyId: 'COMPANY_A');
      contextB = const ReportExecutionContext(companyId: 'COMPANY_B');
    });

    test('Initial execution loads summary and first page correctly', () async {
      final controller = UniversalReportExecutionController(
        provider: provider,
        initialContext: contextA,
        pageSize: 50,
      );

      await controller.executeNewContext(contextA);

      expect(controller.value.summary?.totalCount, equals(100));
      expect(controller.value.items.length, equals(50));
      expect(controller.value.hasNextPage, isTrue);
      expect(controller.value.nextCursor?.uniqueId, equals('50'));
      expect(provider.fetchSummaryCallCount, equals(1));
      expect(provider.fetchPageCallCount, equals(1));
    });

    test('Incremental fetchNextPage appends second page without duplicates', () async {
      final controller = UniversalReportExecutionController(
        provider: provider,
        initialContext: contextA,
        pageSize: 50,
      );

      await controller.executeNewContext(contextA);
      await controller.fetchNextPage();

      expect(controller.value.items.length, equals(100));
      expect(controller.value.hasNextPage, isFalse);
      expect(controller.value.nextCursor, isNull);
      expect(provider.fetchPageCallCount, equals(2));
    });

    test('Context change invalidates existing pagination and cursor state', () async {
      final controller = UniversalReportExecutionController(
        provider: provider,
        initialContext: contextA,
        pageSize: 50,
      );

      await controller.executeNewContext(contextA);
      expect(controller.value.context.companyId, equals('COMPANY_A'));

      await controller.executeNewContext(contextB);
      expect(controller.value.context.companyId, equals('COMPANY_B'));
      expect(controller.value.items.length, equals(50));
      expect(provider.fetchSummaryCallCount, equals(2));
    });
  });
}
