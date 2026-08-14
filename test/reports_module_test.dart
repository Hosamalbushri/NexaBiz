import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stock_count/core/reporting/report_exception.dart';
import 'package:stock_count/core/reporting/report_page_format.dart';
import 'package:stock_count/core/reporting/report_table.dart';
import 'package:stock_count/modules/reports/domain/services/report_runner.dart';
import 'package:stock_count/modules/reports/domain/services/sales_period_report_data_port.dart';
import 'package:stock_count/modules/reports/domain/services/sales_period_report_definition.dart';
import 'package:stock_count/core/reporting/report_pdf_theme.dart';
import 'package:pdf/pdf.dart';

void main() {
  group('ReportTable', () {
    test('resolveRtl reverses headers rows and widths', () {
      final resolved = ReportTable.resolveRtl(
        headers: const ['A', 'B', 'C'],
        rows: const [
          ['1', '2', '3'],
        ],
        widths: const {
          0: pw.FixedColumnWidth(10),
          1: pw.FixedColumnWidth(20),
          2: pw.FixedColumnWidth(30),
        },
        isRtl: true,
      );
      expect(resolved.headers, ['C', 'B', 'A']);
      expect(resolved.rows.single, ['3', '2', '1']);
      expect(resolved.widths[0], isA<pw.FixedColumnWidth>());
    });

    test('resolveRtl keeps order for LTR', () {
      final resolved = ReportTable.resolveRtl(
        headers: const ['A', 'B'],
        rows: const [
          ['1', '2'],
        ],
        widths: const {
          0: pw.FixedColumnWidth(10),
          1: pw.FixedColumnWidth(20),
        },
        isRtl: false,
      );
      expect(resolved.headers, ['A', 'B']);
      expect(resolved.rows.single, ['1', '2']);
    });
  });

  group('ReportPageFormat', () {
    test('a4 portrait exposes page format', () {
      expect(ReportPageFormat.a4Portrait.pageFormat, PdfPageFormat.a4);
      expect(ReportPageFormat.a4Portrait.maxPages, greaterThan(0));
    });
  });

  group('SalesPeriodReportDefinition', () {
    test('builds non-empty PDF for sample rows', () async {
      final context = ReportPdfContext(
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        textDirection: pw.TextDirection.ltr,
        pageFormat: ReportPageFormat.a4Landscape,
        isRtl: false,
        localeCode: 'en',
      );
      const definition = SalesPeriodReportDefinition();
      final payload = SalesPeriodReportPayload(
        companyName: 'Demo Co',
        reportTitle: 'Sales by period',
        generatedAtLabel: 'Generated',
        periodLabel: 'All dates',
        totalLabel: 'Grand total',
        rowsLabel: 'Rows',
        columnSaleNumber: 'Number',
        columnDate: 'Date',
        columnCustomer: 'Customer',
        columnSettlement: 'Settlement',
        columnStatus: 'Status',
        columnCurrency: 'Currency',
        columnTotal: 'Total',
        rows: [
          SalesPeriodReportRow(
            saleNumber: '42',
            saleDate: DateTime.utc(2026, 8, 1),
            customerName: 'Acme',
            settlementLabel: 'Cash',
            statusLabel: 'Confirmed',
            currencyCode: 'SAR',
            total: 100,
          ),
        ],
        grandTotal: 100,
      );

      final bytes = await definition.build(context: context, payload: payload);
      expect(bytes.length, greaterThan(100));

      final doc = await const ReportRunner().run(
        definition: definition,
        payload: payload,
        context: context,
        title: 'Sales by period',
        fileName: 'sales.pdf',
      );
      expect(doc.bytes, isNotEmpty);
      expect(doc.fileName, 'sales.pdf');
    });

    test('builds PDF for empty rows', () async {
      final context = ReportPdfContext(
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        textDirection: pw.TextDirection.rtl,
        pageFormat: ReportPageFormat.a4Portrait,
        isRtl: true,
        localeCode: 'ar',
      );
      final bytes = await const SalesPeriodReportDefinition().build(
        context: context,
        payload: const SalesPeriodReportPayload(
          companyName: 'شركة',
          reportTitle: 'تقرير',
          generatedAtLabel: 'تاريخ',
          periodLabel: 'الكل',
          totalLabel: 'الإجمالي',
          rowsLabel: 'الصفوف',
          columnSaleNumber: 'رقم',
          columnDate: 'تاريخ',
          columnCustomer: 'عميل',
          columnSettlement: 'تسوية',
          columnStatus: 'حالة',
          columnCurrency: 'عملة',
          columnTotal: 'مبلغ',
          rows: [],
          grandTotal: 0,
          emptyMessage: 'لا بيانات',
        ),
      );
      expect(bytes, isNotEmpty);
    });
  });

  group('ReportException', () {
    test('toString includes code', () {
      const e = ReportException(ReportException.generationFailed, 'boom');
      expect(e.toString(), contains('generation_failed'));
      expect(e.toString(), contains('boom'));
    });
  });
}
