import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/entities/sale_settlement_type.dart';
import '../../domain/services/device_sale_number.dart';
import 'package:stock_count/core/reporting/arabic_amount_words.dart';

/// Classic Arabic sales invoice PDF (matches traditional credit/cash form).
class SaleInvoicePdfPrinter {
  const SaleInvoicePdfPrinter();

  static const _border = pw.BorderSide(color: PdfColors.black, width: 0.8);

  Future<void> printSale({
    required Sale sale,
    String? logoPath,
    String? headerRightText,
    String? headerLeftText,
    String? currencyNameAr,
    String printedByLabel = 'NexaBiz',
  }) async {
    final prepared = await prepareSale(
      sale: sale,
      logoPath: logoPath,
      headerRightText: headerRightText,
      headerLeftText: headerLeftText,
      currencyNameAr: currencyNameAr,
      printedByLabel: printedByLabel,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => prepared.bytes,
      name: _nameWithoutExtension(prepared.fileName),
    );
  }

  /// Builds PDF + best-effort Downloads save for in-app preview.
  Future<({Uint8List bytes, String fileName})> prepareSale({
    required Sale sale,
    String? logoPath,
    String? headerRightText,
    String? headerLeftText,
    String? currencyNameAr,
    String printedByLabel = 'NexaBiz',
  }) async {
    final bytes = await buildPdf(
      sale: sale,
      logoPath: logoPath,
      headerRightText: headerRightText,
      headerLeftText: headerLeftText,
      currencyNameAr: currencyNameAr,
      printedByLabel: printedByLabel,
    );
    final fileName = buildFileName(sale);
    await trySaveToPublicDownloads(bytes: bytes, fileName: fileName);
    return (bytes: bytes, fileName: fileName);
  }

  /// Builds PDF, best-effort public save, then shares via a temp file
  /// (Android-safe; no storage permission required for share).
  Future<void> shareSale({
    required Sale sale,
    String? logoPath,
    String? headerRightText,
    String? headerLeftText,
    String? currencyNameAr,
    String printedByLabel = 'NexaBiz',
  }) async {
    final prepared = await prepareSale(
      sale: sale,
      logoPath: logoPath,
      headerRightText: headerRightText,
      headerLeftText: headerLeftText,
      currencyNameAr: currencyNameAr,
      printedByLabel: printedByLabel,
    );

    final tempFile = await _writeTempPdf(
      bytes: prepared.bytes,
      fileName: prepared.fileName,
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            tempFile.path,
            mimeType: 'application/pdf',
            name: prepared.fileName,
          ),
        ],
        subject: _nameWithoutExtension(prepared.fileName),
      ),
    );
  }

  /// Tries to save into the public Downloads folder.
  /// Returns the saved path, or `null` if storage is unavailable/denied.
  Future<String?> trySaveToPublicDownloads({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final dir = await _publicDownloadsDirectory();
      if (dir == null) {
        return null;
      }
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      final file = File(p.join(dir.path, fileName));
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<Directory?> _publicDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // Public shared Downloads (not app private /data).
      final publicDownload = Directory('/storage/emulated/0/Download');
      if (publicDownload.existsSync()) {
        return publicDownload;
      }
      final alt = Directory('/sdcard/Download');
      if (alt.existsSync()) {
        return alt;
      }
    }

    try {
      return await getDownloadsDirectory();
    } catch (_) {
      return null;
    }
  }

  Future<File> _writeTempPdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// `{customer}_{saleNumber}_{dd-MM-yyyy}.pdf`
  String buildFileName(Sale sale) {
    final customer = (sale.customerName?.trim().isNotEmpty ?? false)
        ? sale.customerName!.trim()
        : 'عميل_عابر';
    final date = DateFormat('dd-MM-yyyy').format(sale.saleDate.toLocal());
    final raw = '${customer}_${formatSaleNumberPrimary(sale.saleNumber)}_$date.pdf';
    return _sanitizeFileName(raw);
  }

  String _nameWithoutExtension(String fileName) {
    return fileName.toLowerCase().endsWith('.pdf')
        ? fileName.substring(0, fileName.length - 4)
        : fileName;
  }

  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  Future<Uint8List> buildPdf({
    required Sale sale,
    String? logoPath,
    String? headerRightText,
    String? headerLeftText,
    String? currencyNameAr,
    String printedByLabel = 'NexaBiz',
  }) async {
    // Formal Arabic naskh (closest open match to Traditional Arabic / FrankRuehl).
    final regular = await PdfGoogleFonts.amiriRegular();
    final bold = await PdfGoogleFonts.amiriBold();
    final theme = pw.ThemeData.withFont(base: regular, bold: bold);

    final isCredit = sale.settlementType == SaleSettlementType.credit;
    final title = isCredit ? 'فاتورة بيع آجل' : 'فاتورة بيع نقداً';
    final dateText = DateFormat('dd-MM-yyyy').format(sale.saleDate.toLocal());
    final money = NumberFormat('#,##0.##', 'en');
    final customer = (sale.customerName?.trim().isNotEmpty ?? false)
        ? sale.customerName!.trim()
        : 'عميل عابر';
    final currencyLabel = _currencyWord(
      sale.currencyCode,
      overrideAr: currencyNameAr,
    );

    final discount = sale.itemDiscountTotal + sale.discountAmount;
    final gross = sale.subtotal;
    final net = sale.total;
    final remaining = sale.remainingAmount;

    final logoImage = await _loadLogo(logoPath);

    final doc = pw.Document(theme: theme);
    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(20, 16, 20, 20),
          theme: theme,
          textDirection: pw.TextDirection.rtl,
        ),
        maxPages: 40,
        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _brandHeader(
                rightText: headerRightText?.trim() ?? '',
                leftText: headerLeftText?.trim() ?? '',
                logo: logoImage,
              ),
              pw.SizedBox(height: 8),
              pw.Container(height: 2, color: PdfColors.black),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 5,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1),
                  ),
                  child: pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              _metaTable(
                invoiceNumber: formatSaleNumberPrimary(sale.saleNumber),
                invoiceReference: saleNumberView(sale.saleNumber).referenceLabel,
                customerName: customer,
                invoiceDate: dateText,
                currencyLabel: currencyLabel,
              ),
              pw.SizedBox(height: 8),
            ],
          );
        },
        footer: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'طبع بواسطة $printedByLabel',
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.Text(
                  '${context.pageNumber} / ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          );
        },
        build: (context) {
          return [
            ..._itemsSection(
              items: sale.items,
              money: money,
            ),
            pw.SizedBox(height: 8),
            _totalsBlock(
              money: money,
              gross: gross,
              discount: discount,
              net: net,
              remaining: remaining,
              currencyLabel: currencyLabel,
              showBalance: isCredit,
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              'ملاحظة: البضاعة المباعة لاترد بعد خروجها من المحل',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 22),
            // Row flips under RTL: first child on the right.
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _signatureBlock(title: 'توقيع امين المخازن'),
                _signatureBlock(title: 'توقيع المبيعات'),
                _signatureBlock(
                  title: 'توقيع المستلم',
                  subtitle: 'استلمت البضاعة كاملة وسليمة',
                ),
              ],
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  Future<pw.MemoryImage?> _loadLogo(String? logoPath) async {
    final path = logoPath?.trim();
    if (path == null || path.isEmpty) {
      return null;
    }
    final file = File(path);
    if (!file.existsSync()) {
      return null;
    }
    try {
      return pw.MemoryImage(await file.readAsBytes());
    } catch (_) {
      return null;
    }
  }

  /// Three equal columns. Row flips under RTL: right text | logo | left text.
  /// Fixed base height; grows when side text needs more lines (no clipping).
  pw.Widget _brandHeader({
    required String rightText,
    required String leftText,
    required pw.MemoryImage? logo,
  }) {
    const headerHeight = 96.0;

    pw.Widget textCell(String text) {
      return pw.Container(
        constraints: const pw.BoxConstraints(minHeight: headerHeight),
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        alignment: pw.Alignment.center,
        child: pw.Text(
          text.isEmpty ? ' ' : text,
          textAlign: pw.TextAlign.center,
          softWrap: true,
          overflow: pw.TextOverflow.visible,
          style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.5),
        ),
      );
    }

    pw.Widget logoCell() {
      return pw.Container(
        constraints: const pw.BoxConstraints(minHeight: headerHeight),
        alignment: pw.Alignment.center,
        child: logo == null
            ? pw.SizedBox(height: headerHeight - 12)
            : pw.Image(
                logo,
                fit: pw.BoxFit.contain,
                height: headerHeight - 16,
                width: headerHeight - 16,
              ),
      );
    }

    return pw.Table(
      border: null,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          children: [
            // Table is LTR: left → logo → right  ⇒ visual right | logo | left
            textCell(leftText),
            logoCell(),
            textCell(rightText),
          ],
        ),
      ],
    );
  }

  /// Header meta. Row flips under RTL — first child is rightmost:
  /// رقم الفاتورة | إسم العميل | تاريخ الفاتورة | العملة
  pw.Widget _metaTable({
    required String invoiceNumber,
    required String customerName,
    required String invoiceDate,
    required String currencyLabel,
    String? invoiceReference,
  }) {
    final labelStyle = pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold);
    const valueStyle = pw.TextStyle(fontSize: 10);
    final invoiceDisplay = invoiceReference == null ||
            invoiceReference.isEmpty ||
            invoiceReference == invoiceNumber
        ? invoiceNumber
        : '$invoiceNumber\n($invoiceReference)';

    pw.Widget fixedCol(
      String label,
      String value, {
      required double width,
      bool showLeftBorder = true,
      bool wrap = false,
    }) {
      return pw.Container(
        width: width,
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: showLeftBorder
            ? const pw.BoxDecoration(border: pw.Border(left: _border))
            : null,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(label, textAlign: pw.TextAlign.center, style: labelStyle),
            pw.SizedBox(height: 3),
            pw.Text(
              value.isEmpty ? ' ' : value,
              textAlign: pw.TextAlign.center,
              softWrap: wrap,
              overflow: wrap ? pw.TextOverflow.visible : pw.TextOverflow.clip,
              style: valueStyle,
            ),
          ],
        ),
      );
    }

    // Customer column grows with wrapped text height / remaining width.
    final customerCol = pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: const pw.BoxDecoration(border: pw.Border(left: _border)),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(
              'إسم العميل',
              textAlign: pw.TextAlign.center,
              style: labelStyle,
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              customerName.isEmpty ? ' ' : customerName,
              textAlign: pw.TextAlign.center,
              softWrap: true,
              style: valueStyle,
            ),
          ],
        ),
      ),
    );

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.9),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          fixedCol(
            'رقم الفاتورة',
            invoiceDisplay,
            width: 88,
            wrap: invoiceReference != null &&
                invoiceReference.isNotEmpty &&
                invoiceReference != invoiceNumber,
          ),
          customerCol,
          fixedCol('تاريخ الفاتورة', invoiceDate, width: 88),
          fixedCol(
            'العملة',
            currencyLabel,
            width: 92,
            showLeftBorder: false,
            wrap: true,
          ),
        ],
      ),
    );
  }

  /// Products table + qty totals as separate MultiPage children
  /// so the table can still span pages.
  List<pw.Widget> _itemsSection({
    required List<SaleItem> items,
    required NumberFormat money,
  }) {
    var mainQtyTotal = 0.0;
    var subQtyTotal = 0.0;
    for (final item in items) {
      mainQtyTotal += item.mainQuantity;
      subQtyTotal += item.subQuantity;
    }

    return [
      _itemsTable(items: items, money: money),
      pw.SizedBox(height: 2),
      _qtyTotalsRow(
        mainQtyTotal: mainQtyTotal,
        subQtyTotal: subQtyTotal,
      ),
    ];
  }

  /// Borders only under رئيسي / فرعي — no empty bordered cells.
  pw.Widget _qtyTotalsRow({
    required double mainQtyTotal,
    required double subQtyTotal,
  }) {
    pw.Widget qtyTotalBox(String value) {
      return pw.Container(
        width: 38,
        padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.75),
        ),
        alignment: pw.Alignment.center,
        child: pw.Text(
          value,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
      );
    }

    // Match products table physical LTR column widths.
    return pw.Directionality(
      textDirection: pw.TextDirection.ltr,
      child: pw.Row(
        children: [
          pw.SizedBox(width: 58), // الأجمالي
          pw.SizedBox(width: 54), // سعر الفرعي
          pw.SizedBox(width: 54), // سعر الوحدة
          qtyTotalBox(_qty(subQtyTotal)), // فرعي
          qtyTotalBox(_qty(mainQtyTotal)), // رئيسي
          pw.Expanded(child: pw.SizedBox()), // إسم الصنف
          pw.SizedBox(width: 58), // رقم الصنف
          pw.SizedBox(width: 22), // م
        ],
      ),
    );
  }

  /// Products table. pdf Table columns are LTR — reverse so visual RTL is:
  /// م | رقم الصنف | إسم الصنف | رئيسي | فرعي | سعر الوحدة | سعر الفرعي | الأجمالي
  pw.Widget _itemsTable({
    required List<SaleItem> items,
    required NumberFormat money,
  }) {
    // Physical left → right (= visual right ← left).
    final headers = <String>[
      'الأجمالي',
      'سعر الفرعي',
      'سعر الوحدة',
      'فرعي',
      'رئيسي',
      'إسم الصنف',
      'رقم الصنف',
      'م',
    ];

    final widths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(58),
      1: const pw.FixedColumnWidth(54),
      2: const pw.FixedColumnWidth(54),
      3: const pw.FixedColumnWidth(38),
      4: const pw.FixedColumnWidth(38),
      5: const pw.FlexColumnWidth(2.8),
      6: const pw.FixedColumnWidth(58),
      7: const pw.FixedColumnWidth(22),
    };

    pw.Widget headerCell(String text) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 5),
          child: pw.Text(
            text,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        );

    pw.Widget cell(
      String text, {
      pw.TextAlign align = pw.TextAlign.center,
      bool bold = false,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: pw.Text(
          text,
          textAlign: align,
          softWrap: true,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
    }

    final rows = <pw.TableRow>[
      pw.TableRow(
        repeat: true,
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: _border),
        ),
        children: [for (final h in headers) headerCell(h)],
      ),
    ];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final pack = item.packSize <= 0 ? 1 : item.packSize;
      // Same as sale invoice: unitPrice is per main unit.
      final unitPrice = item.unitPrice;
      final subPrice = unitPrice / pack;
      rows.add(
        pw.TableRow(
          children: [
            cell(money.format(item.total), bold: true),
            cell(money.format(subPrice)),
            cell(money.format(unitPrice)),
            cell(_qty(item.subQuantity)),
            cell(_qty(item.mainQuantity)),
            cell(item.productName, align: pw.TextAlign.right),
            cell(item.productCode),
            cell('${i + 1}'),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.75),
      columnWidths: widths,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  pw.Widget _totalsBlock({
    required NumberFormat money,
    required double gross,
    required double discount,
    required double net,
    required double remaining,
    required String currencyLabel,
    required bool showBalance,
  }) {
    pw.Widget cell(
      String text, {
      bool bold = false,
      bool wrap = false,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          softWrap: wrap,
          overflow: wrap ? pw.TextOverflow.visible : pw.TextOverflow.clip,
          style: pw.TextStyle(
            fontSize: wrap ? 8.5 : 9,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            lineSpacing: wrap ? 1.4 : null,
          ),
        ),
      );
    }

    // Row flips under RTL — children listed right→left:
    // الإجمالي | الكلمات | المبلغ
    pw.Widget row(
      String label,
      double amount, {
      bool emphasize = false,
      bool showBottomBorder = true,
    }) {
      final words = amount == 0
          ? 'فقط صفر $currencyLabel'
          : ArabicAmountWords.forAmount(amount, currencyLabel);
      return pw.Container(
        decoration: showBottomBorder
            ? const pw.BoxDecoration(border: pw.Border(bottom: _border))
            : null,
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 86,
              decoration: const pw.BoxDecoration(
                border: pw.Border(left: _border),
              ),
              alignment: pw.Alignment.center,
              child: cell(label, bold: true),
            ),
            pw.Expanded(
              child: pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(left: _border),
                ),
                alignment: pw.Alignment.center,
                child: cell(words, wrap: true),
              ),
            ),
            pw.Container(
              width: 72,
              alignment: pw.Alignment.center,
              child: cell(money.format(amount), bold: emphasize),
            ),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 0.75),
          ),
          child: pw.Column(
            children: [
              row('الإجمالي', gross),
              row('الخصم', discount),
              row(
                'صافي الفاتورة',
                net,
                emphasize: true,
                showBottomBorder: false,
              ),
            ],
          ),
        ),
        if (showBalance) ...[
          pw.SizedBox(height: 6),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.85),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'الرصيد',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  money.format(remaining == 0 ? 0 : -remaining.abs()),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _signatureBlock({required String title, String? subtitle}) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          pw.Text(
            title,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 30),
          if (subtitle != null)
            pw.Text(
              subtitle,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 7.5),
            ),
        ],
      ),
    );
  }

  String _qty(double value) {
    if (value == 0) {
      return '0';
    }
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2);
  }

  /// Prefer [overrideAr] from the presentation/App layer; fall back to code.
  String _currencyWord(String code, {String? overrideAr}) {
    final named = overrideAr?.trim();
    if (named != null && named.isNotEmpty) {
      return named;
    }
    return code.trim().isEmpty ? 'SAR' : code.trim().toUpperCase();
  }
}
