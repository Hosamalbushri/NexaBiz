import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/reporting/arabic_amount_words.dart';
import '../../../../core/reporting/report_pdf_theme.dart';
import '../services/account_statement_report_data_port.dart';
import '../services/report_definition.dart';

/// Soft2 cumulative account statement — matches sample layout:
/// title + period → account strip → per-currency movement grids →
/// Soft2 totals table (بالعملة / مدين / دائن + amount in words) →
/// disclaimer → signatures → print footer.
class AccountStatementReportDefinition
    implements ReportDefinition<AccountStatementReportPayload> {
  const AccountStatementReportDefinition();

  static const _line = pw.BorderSide(color: PdfColors.black, width: 0.65);
  static final _headerFill = PdfColors.grey300;
  static final _numberFill = PdfColors.green100;
  static const _currencyGap = 20.0;

  @override
  String get id => 'account_statement';

  @override
  Future<Uint8List> build({
    required ReportPdfContext context,
    required AccountStatementReportPayload payload,
  }) async {
    final doc = pw.Document(theme: context.theme);
    final dateFmt = DateFormat('dd-MM-yyyy');
    final generated = DateFormat(
      'dd-MM-yyyy hh:mm:ss a',
    ).format(DateTime.now());
    final money = NumberFormat('#,##0.00', 'en');

    String fmtDate(DateTime? d) =>
        d == null ? '—' : dateFmt.format(d.toLocal());

    doc.addPage(
      pw.MultiPage(
        maxPages: context.pageFormat.maxPages,
        pageTheme: context.pageFormat.toPageTheme(
          theme: context.theme,
          textDirection: pw.TextDirection.rtl,
        ),
        header: (ctx) {
          final pageMark = '${ctx.pagesCount}-${ctx.pagesCount}';
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(pageMark, style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(pageMark, style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  payload.reportTitle,
                  textAlign: pw.TextAlign.center,
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Divider(thickness: 1.1, color: PdfColors.black),
                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      '${payload.fromDateLabel} ${fmtDate(payload.fromDate)}',
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(width: 28),
                    pw.Text(
                      '${payload.toDateLabel} ${fmtDate(payload.toDate)}',
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                _accountInfoRow(
                  accountNumberLabel: payload.accountNumberLabel,
                  accountNumber: payload.accountCode,
                  accountNameLabel: payload.accountNameLabel,
                  accountName: payload.accountName,
                ),
                pw.SizedBox(height: 6),
              ],
            ),
          );
        },
        footer: (ctx) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 1.0, color: PdfColors.black),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      generated,
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      '${ctx.pageNumber}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      payload.printedByLabel,
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        build: (ctx) {
          final balances = _balances(payload);
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: _buildCurrencySections(
                payload: payload,
                money: money,
                dateFmt: dateFmt,
              ),
            ),
            if (payload.lines.isEmpty && balances.isEmpty) ...[
              pw.SizedBox(height: 14),
              pw.Text(
                payload.emptyMessage ?? '—',
                textAlign: pw.TextAlign.center,
                textDirection: pw.TextDirection.rtl,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
            pw.SizedBox(height: 14),
            pw.Text(
              payload.disclaimer,
              textAlign: pw.TextAlign.center,
              textDirection: pw.TextDirection.rtl,
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 22),
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _signSlot(payload.accountantLabel),
                  _signSlot(payload.reviewerLabel),
                  _signSlot(payload.financeManagerLabel),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  List<AccountStatementCurrencyBalance> _balances(
    AccountStatementReportPayload payload,
  ) {
    if (payload.balancesByCurrency.isNotEmpty) {
      return payload.balancesByCurrency;
    }
    final code = (payload.currencyCode ?? '').trim();
    if (code.isEmpty && payload.lines.isEmpty) {
      return const [];
    }
    final resolved = code.isEmpty
        ? (payload.lines.isNotEmpty
              ? (payload.lines.first.currencyCode ?? '—')
              : payload.currencyLabel)
        : code;
    return [
      AccountStatementCurrencyBalance(
        currencyCode: resolved,
        openingBalance: payload.openingBalance,
        totalDebit: payload.totalDebit,
        totalCredit: payload.totalCredit,
        closingBalance: payload.closingBalance,
        displayCurrencyCode: resolved,
        amountInWords: ArabicAmountWords.forAmount(
          payload.closingBalance.abs(),
          resolved,
        ),
      ),
    ];
  }

  pw.Widget _accountInfoRow({
    required String accountNumberLabel,
    required String accountNumber,
    required String accountNameLabel,
    required String accountName,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.75),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          _metaBox(
            label: accountNumberLabel,
            value: accountNumber,
            width: 130,
            showLeftBorder: true,
          ),
          _metaBox(
            label: accountNameLabel,
            value: accountName,
            flex: true,
            showLeftBorder: true,
          ),
          pw.Container(
            width: 28,
            height: 30,
            decoration: const pw.BoxDecoration(
              border: pw.Border(left: _line),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _metaBox({
    required String label,
    required String value,
    double? width,
    bool flex = false,
    bool showLeftBorder = false,
  }) {
    final child = pw.Container(
      width: width,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: showLeftBorder
          ? const pw.BoxDecoration(border: pw.Border(left: _line))
          : null,
      child: pw.Row(
        children: [
          pw.Text(
            label,
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.center,
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (flex) {
      return pw.Expanded(child: child);
    }
    return child;
  }

  /// Soft2 columns (RTL visual):
  /// الرقم | تاريخ السند | نوع السند | العملة | التفاصيل | المدين | الدائن | الرصيد | م/د
  ///
  /// Each currency: movements table + its own full-width final-balance table.
  pw.Widget _buildCurrencySections({
    required AccountStatementReportPayload payload,
    required NumberFormat money,
    required DateFormat dateFmt,
  }) {
    final visualHeaders = <String>[
      payload.columnVoucherNumber,
      payload.columnDate,
      payload.columnVoucherType,
      payload.columnCurrency,
      payload.columnDescription,
      payload.columnDebit,
      payload.columnCredit,
      payload.columnBalance,
      payload.columnSide,
    ];
    final visualWidths = <pw.TableColumnWidth>[
      const pw.FixedColumnWidth(40),
      const pw.FixedColumnWidth(56),
      const pw.FixedColumnWidth(68),
      const pw.FixedColumnWidth(34),
      const pw.FlexColumnWidth(2.6),
      const pw.FixedColumnWidth(56),
      const pw.FixedColumnWidth(56),
      const pw.FixedColumnWidth(60),
      const pw.FixedColumnWidth(18),
    ];
    final paintHeaders = visualHeaders.reversed.toList(growable: false);
    final paintWidths = <int, pw.TableColumnWidth>{
      for (var i = 0; i < visualWidths.length; i++)
        i: visualWidths[visualWidths.length - 1 - i],
    };

    final balances = _balances(payload);
    final linesByCurrency = <String, List<AccountStatementLine>>{};
    for (final line in payload.lines) {
      final key = (line.currencyCode ?? '').trim().toUpperCase();
      final code = key.isEmpty ? '—' : key;
      (linesByCurrency[code] ??= <AccountStatementLine>[]).add(line);
    }

    final order = <String>[
      for (final b in balances) b.currencyCode.trim().toUpperCase(),
    ];
    for (final code in linesByCurrency.keys) {
      if (!order.contains(code)) {
        order.add(code);
      }
    }
    final base = (payload.baseCurrencyCode ?? '').trim().toUpperCase();
    if (base.isNotEmpty && order.contains(base) && order.first != base) {
      order
        ..remove(base)
        ..insert(0, base);
    }

    AccountStatementCurrencyBalance balanceFor(String code) {
      for (final b in balances) {
        if (b.currencyCode.toUpperCase() == code) {
          return b;
        }
      }
      return AccountStatementCurrencyBalance(
        currencyCode: code,
        openingBalance: 0,
        totalDebit: 0,
        totalCredit: 0,
        closingBalance: 0,
        displayCurrencyCode: code,
        amountInWords: ArabicAmountWords.forAmount(0, code),
      );
    }

    if (order.isEmpty) {
      return _movementsTable(
        paintHeaders: paintHeaders,
        paintWidths: paintWidths,
        rows: const [],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < order.length; i++) ...[
          if (i > 0) pw.SizedBox(height: _currencyGap),
          _movementsTable(
            paintHeaders: paintHeaders,
            paintWidths: paintWidths,
            rows: [
              for (final line in linesByCurrency[order[i]] ?? const [])
                _movementPaintRow(
                  line: line,
                  money: money,
                  dateFmt: dateFmt,
                  fallbackCurrency: order[i],
                ),
            ],
          ),
          pw.SizedBox(height: 6),
          _soft2FinalBalanceTableForCurrency(
            payload: payload,
            balance: balanceFor(order[i]),
            money: money,
          ),
        ],
      ],
    );
  }

  List<pw.Widget> _movementPaintRow({
    required AccountStatementLine line,
    required NumberFormat money,
    required DateFormat dateFmt,
    required String fallbackCurrency,
  }) {
    final code =
        (line.displayCurrencyCode ?? line.currencyCode ?? fallbackCurrency)
            .trim();
    final visual = <pw.Widget>[
      _dataCell(
        line.voucherNumber,
        fill: line.isPosted ? null : _numberFill,
        bold: true,
      ),
      _dataCell(dateFmt.format(line.entryDate.toLocal())),
      _dataCell(line.voucherType),
      _dataCell(code.isEmpty ? fallbackCurrency : code, bold: true),
      _dataCell(line.description, align: pw.TextAlign.right),
      _dataCell(line.debit == 0 ? '.00' : money.format(line.debit)),
      _dataCell(line.credit == 0 ? '.00' : money.format(line.credit)),
      _dataCell(money.format(line.balance)),
      _dataCell(line.sideLabel, bold: true),
    ];
    return visual.reversed.toList(growable: false);
  }

  pw.Widget _movementsTable({
    required List<String> paintHeaders,
    required Map<int, pw.TableColumnWidth> paintWidths,
    required List<List<pw.Widget>> rows,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.55),
      columnWidths: paintWidths,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _headerFill),
          children: [for (final h in paintHeaders) _headerCell(h)],
        ),
        for (final row in rows) pw.TableRow(children: row),
      ],
    );
  }

  /// One Soft2 final-balance table for a single currency (full page width).
  /// Title → بالعملة | مدين | دائن → values → amount in words.
  pw.Widget _soft2FinalBalanceTableForCurrency({
    required AccountStatementReportPayload payload,
    required AccountStatementCurrencyBalance balance,
    required NumberFormat money,
  }) {
    final colHeaders = <String>[
      payload.columnInCurrency,
      payload.totalsDebitLabel,
      payload.totalsCreditLabel,
    ];
    final widths = <pw.TableColumnWidth>[
      const pw.FlexColumnWidth(1),
      const pw.FlexColumnWidth(1.2),
      const pw.FlexColumnWidth(1.2),
    ];
    final paintHeaders = colHeaders.reversed.toList(growable: false);
    final paintWidths = <int, pw.TableColumnWidth>{
      for (var i = 0; i < widths.length; i++) i: widths[widths.length - 1 - i],
    };

    final code =
        (balance.displayCurrencyCode ?? balance.currencyCode).trim();
    final words = (balance.amountInWords ?? '').trim();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            color: _headerFill,
            border: pw.Border.all(color: PdfColors.black, width: 0.7),
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(
            payload.finalBalanceByCurrencyLabel,
            textAlign: pw.TextAlign.center,
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.7),
          columnWidths: paintWidths,
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _headerFill),
              children: [for (final h in paintHeaders) _headerCell(h)],
            ),
            pw.TableRow(
              children: <pw.Widget>[
                _dataCell(code, bold: true),
                _dataCell(
                  balance.closingDebitSide == 0
                      ? '.00'
                      : money.format(balance.closingDebitSide),
                  bold: true,
                ),
                _dataCell(
                  balance.closingCreditSide == 0
                      ? '.00'
                      : money.format(balance.closingCreditSide),
                  bold: true,
                ),
              ].reversed.toList(growable: false),
            ),
          ],
        ),
        if (words.isNotEmpty)
          pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.7),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: pw.Text(
              words,
              textAlign: pw.TextAlign.center,
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
      ],
    );
  }

  pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _dataCell(
    String text, {
    PdfColor? fill,
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Container(
      color: fill,
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      child: pw.Text(
        text,
        textAlign: align,
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _signSlot(String label) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 28),
      ],
    );
  }
}
