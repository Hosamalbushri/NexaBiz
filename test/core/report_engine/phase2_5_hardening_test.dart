import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/report_engine/domain/models/report_cursor.dart';
import 'package:stock_count/core/report_engine/domain/models/report_dataset.dart';
import 'package:stock_count/core/report_engine/domain/models/report_execution_context.dart';
import 'package:stock_count/core/report_engine/domain/models/report_page.dart';
import 'package:stock_count/core/report_engine/domain/models/report_summary.dart';
import 'package:stock_count/core/report_engine/domain/services/paged_report_data_provider.dart';

class MockHardenedProvider implements PagedReportDataProvider<ReportRowData> {
  @override
  String get reportId => 'HARDENED_TEST_REPORT';

  final List<Map<String, dynamic>> mockDatabase = List.generate(
    100,
    (i) => {
      'id': i + 1,
      'company_id': (i % 2 == 0) ? 'COMPANY_A' : 'COMPANY_B',
      'sale_date': 1700000000 + (i ~/ 5) * 86400,
      'amount': (i + 1) * 50.0,
      'sale_status': 'posted',
    },
  );

  @override
  Future<ReportSummary> fetchSummary(ReportExecutionContext context) async {
    final filtered = mockDatabase.where((row) =>
        row['company_id'] == context.companyId &&
        (context.postingScope == PostingScope.all ||
            (context.postingScope == PostingScope.postedOnly && row['sale_status'] == 'posted'))).toList();

    final sumAmount = filtered.fold<double>(0.0, (acc, r) => acc + (r['amount'] as double));

    return ReportSummary(
      totalCount: filtered.length,
      aggregates: {'grandTotal': sumAmount},
    );
  }

  @override
  Future<ReportPage<ReportRowData>> fetchPage(
    ReportExecutionContext context, {
    ReportCursor? cursor,
    int pageSize = 50,
  }) async {
    final isAscending = context.sorting.ascending;

    final filtered = mockDatabase.where((row) =>
        row['company_id'] == context.companyId &&
        (context.postingScope == PostingScope.all ||
            (context.postingScope == PostingScope.postedOnly && row['sale_status'] == 'posted'))).toList();

    filtered.sort((a, b) {
      final cmpDate = (a['sale_date'] as int).compareTo(b['sale_date'] as int);
      if (cmpDate != 0) return isAscending ? cmpDate : -cmpDate;
      final cmpId = (a['id'] as int).compareTo(b['id'] as int);
      return isAscending ? cmpId : -cmpId;
    });

    Iterable<Map<String, dynamic>> paged = filtered;
    if (cursor != null) {
      final cursorDate = cursor.primarySortValue as int;
      final cursorId = int.parse(cursor.uniqueId);

      paged = filtered.where((row) {
        final d = row['sale_date'] as int;
        final id = row['id'] as int;
        if (isAscending) {
          return d > cursorDate || (d == cursorDate && id > cursorId);
        } else {
          return d < cursorDate || (d == cursorDate && id < cursorId);
        }
      });
    }

    final chunk = paged.take(pageSize).toList();
    final hasNext = paged.length > pageSize;

    final items = chunk.map((r) => ReportRowData(values: {
      'id': r['id'].toString(),
      'companyId': r['company_id'].toString(),
      'saleDate': r['sale_date'].toString(),
      'amount': r['amount'].toString(),
    })).toList();

    ReportCursor? nextCursor;
    if (chunk.isNotEmpty && hasNext) {
      final last = chunk.last;
      nextCursor = ReportCursor(
        primarySortValue: last['sale_date'] as int,
        uniqueId: last['id'].toString(),
      );
    }

    return ReportPage<ReportRowData>(
      items: items,
      nextCursor: nextCursor,
      hasNextPage: hasNext,
    );
  }
}

void main() {
  group('Phase 2.5 Hardening & Correctness Audit Tests', () {
    late MockHardenedProvider provider;
    late ReportExecutionContext contextCompanyA;
    late ReportExecutionContext contextCompanyB;

    setUp(() {
      provider = MockHardenedProvider();
      contextCompanyA = const ReportExecutionContext(companyId: 'COMPANY_A');
      contextCompanyB = const ReportExecutionContext(companyId: 'COMPANY_B');
    });

    test('Tenant isolation: Company A queries NEVER contain Company B rows', () async {
      final summaryA = await provider.fetchSummary(contextCompanyA);
      final pageA = await provider.fetchPage(contextCompanyA);

      expect(summaryA.totalCount, equals(50));
      expect(pageA.items.every((item) => item['companyId'] == 'COMPANY_A'), isTrue);

      final summaryB = await provider.fetchSummary(contextCompanyB);
      final pageB = await provider.fetchPage(contextCompanyB);

      expect(summaryB.totalCount, equals(50));
      expect(pageB.items.every((item) => item['companyId'] == 'COMPANY_B'), isTrue);
    });

    test('Keyset Pagination overlap exclusion (Page 1 ∩ Page 2 = ∅)', () async {
      final page1 = await provider.fetchPage(contextCompanyA, cursor: null, pageSize: 25);
      expect(page1.items.length, equals(25));
      expect(page1.hasNextPage, isTrue);
      expect(page1.nextCursor, isNotNull);

      final page2 = await provider.fetchPage(contextCompanyA, cursor: page1.nextCursor, pageSize: 25);
      expect(page2.items.length, equals(25));

      final set1 = page1.items.map((i) => i['id']).toSet();
      final set2 = page2.items.map((i) => i['id']).toSet();

      final intersection = set1.intersection(set2);
      expect(intersection, isEmpty);
    });

    test('Summary vs Detail predicate equivalence', () async {
      final summary = await provider.fetchSummary(contextCompanyA);
      final page1 = await provider.fetchPage(contextCompanyA, cursor: null, pageSize: 25);
      final page2 = await provider.fetchPage(contextCompanyA, cursor: page1.nextCursor, pageSize: 25);

      final totalPageItemsCount = page1.items.length + page2.items.length;
      expect(summary.totalCount, equals(totalPageItemsCount));
    });

    test('Descending Keyset cursor progression', () async {
      const descContext = ReportExecutionContext(
        companyId: 'COMPANY_A',
        sorting: ReportSortSpec(columnKey: 'date', ascending: false),
      );

      final page1 = await provider.fetchPage(descContext, cursor: null, pageSize: 25);
      expect(page1.items.length, equals(25));
      expect(page1.hasNextPage, isTrue);

      final page2 = await provider.fetchPage(descContext, cursor: page1.nextCursor, pageSize: 25);
      expect(page2.items.length, equals(25));

      final firstPageLastDate = int.parse(page1.items.last['saleDate']!);
      final secondPageFirstDate = int.parse(page2.items.first['saleDate']!);

      expect(secondPageFirstDate <= firstPageLastDate, isTrue);
    });
  });
}
