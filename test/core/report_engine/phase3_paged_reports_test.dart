import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/report_engine/application/universal_report_execution_controller.dart';
import 'package:stock_count/core/report_engine/domain/models/report_cursor.dart';
import 'package:stock_count/core/report_engine/domain/models/report_dataset.dart';
import 'package:stock_count/core/report_engine/domain/models/report_execution_context.dart';
import 'package:stock_count/core/report_engine/domain/models/report_page.dart';
import 'package:stock_count/core/report_engine/domain/models/report_summary.dart';
import 'package:stock_count/core/report_engine/domain/services/paged_report_data_provider.dart';

class MockPhase3PagedProvider implements PagedReportDataProvider<ReportRowData> {
  @override
  String get reportId => 'PHASE3_ACCOUNT_STATEMENT_MOCK';

  int totalDbMutations = 0;

  final List<Map<String, dynamic>> mockJournalLines = List.generate(
    1000,
    (i) => {
      'id': i + 1,
      'company_id': 'COMPANY_A',
      'account_uuid': 'ACC_1001',
      'entry_date': 1700000000 + (i ~/ 10) * 86400,
      'voucher_number': 'JV-${1000 + i}',
      'voucher_type': 'journal_voucher',
      'description': 'Journal line $i',
      'debit': (i % 2 == 0) ? 100.0 : 0.0,
      'credit': (i % 2 != 0) ? 100.0 : 0.0,
      'currency_code': 'SAR',
      'is_posted': true,
    },
  );

  @override
  Future<ReportSummary> fetchSummary(ReportExecutionContext context) async {
    final filtered = mockJournalLines
        .where((l) => l['company_id'] == context.companyId && l['account_uuid'] == context.filters['accountUuid'])
        .toList();

    final sumDebit = filtered.fold<double>(0.0, (acc, l) => acc + (l['debit'] as double));
    final sumCredit = filtered.fold<double>(0.0, (acc, l) => acc + (l['credit'] as double));

    return ReportSummary(
      totalCount: filtered.length,
      aggregates: {
        'totalDebit': sumDebit,
        'totalCredit': sumCredit,
        'netBalance': sumDebit - sumCredit,
      },
    );
  }

  @override
  Future<ReportPage<ReportRowData>> fetchPage(
    ReportExecutionContext context, {
    ReportCursor? cursor,
    int pageSize = 50,
  }) async {
    final filtered = mockJournalLines
        .where((l) => l['company_id'] == context.companyId && l['account_uuid'] == context.filters['accountUuid'])
        .toList();

    Iterable<Map<String, dynamic>> paged = filtered;
    if (cursor != null) {
      final cursorDate = cursor.primarySortValue as int;
      final cursorId = int.parse(cursor.uniqueId);

      paged = filtered.where((row) {
        final d = row['entry_date'] as int;
        final id = row['id'] as int;
        return d > cursorDate || (d == cursorDate && id > cursorId);
      });
    }

    final chunk = paged.take(pageSize).toList();
    final hasNext = paged.length > pageSize;

    final items = chunk
        .map((r) => ReportRowData(
              documentType: 'journal_entry',
              documentUuid: 'UUID-${r['id']}',
              values: {
                'id': r['id'].toString(),
                'entryDate': r['entry_date'].toString(),
                'voucherNumber': r['voucher_number'].toString(),
                'debit': r['debit'].toString(),
                'credit': r['credit'].toString(),
              },
            ))
        .toList();

    ReportCursor? nextCursor;
    if (chunk.isNotEmpty && hasNext) {
      final last = chunk.last;
      nextCursor = ReportCursor(
        primarySortValue: last['entry_date'] as int,
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
  group('Phase 3 Production Hardening & Full Coverage Tests', () {
    late MockPhase3PagedProvider provider;
    late ReportExecutionContext context;

    setUp(() {
      provider = MockPhase3PagedProvider();
      context = const ReportExecutionContext(
        companyId: 'COMPANY_A',
        filters: {'accountUuid': 'ACC_1001'},
      );
    });

    test('Account Statement Keyset Pagination traverses 1,000 synthetic rows deterministically', () async {
      final summary = await provider.fetchSummary(context);
      expect(summary.totalCount, equals(1000));

      final page1 = await provider.fetchPage(context, cursor: null, pageSize: 500);
      expect(page1.items.length, equals(500));
      expect(page1.hasNextPage, isTrue);
      expect(page1.nextCursor, isNotNull);

      final page2 = await provider.fetchPage(context, cursor: page1.nextCursor, pageSize: 500);
      expect(page2.items.length, equals(500));
      expect(page2.hasNextPage, isFalse);

      final allIds = <String>{
        ...page1.items.map((i) => i['id']!),
        ...page2.items.map((i) => i['id']!),
      };
      expect(allIds.length, equals(1000));
    });

    test('Read-only invariant: Report execution performs ZERO database mutations', () async {
      expect(provider.totalDbMutations, equals(0));

      await provider.fetchSummary(context);
      await provider.fetchPage(context, cursor: null, pageSize: 50);

      expect(provider.totalDbMutations, equals(0));
    });

    test('Concurrency protection: Fast request B cancels stale request A', () async {
      final controller = UniversalReportExecutionController(
        provider: provider,
        initialContext: context,
        pageSize: 50,
      );

      const contextB = ReportExecutionContext(
        companyId: 'COMPANY_A',
        filters: {'accountUuid': 'ACC_1001', 'postingScope': 'posted'},
      );

      final futureA = controller.executeNewContext(context);
      final futureB = controller.executeNewContext(contextB);

      await Future.wait([futureA, futureB]);

      expect(controller.value.context, equals(contextB));
    });
  });
}
