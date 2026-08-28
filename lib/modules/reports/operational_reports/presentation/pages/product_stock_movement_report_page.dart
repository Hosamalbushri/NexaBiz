import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/reporting/pdf_document_preview_page.dart';
import 'package:stock_count/core/reporting/report_page_format.dart';
import 'package:stock_count/core/reporting/report_pdf_theme.dart';
import 'package:stock_count/core/services/loading_providers.dart';
import 'package:stock_count/core/widgets/app_dynamic_report_table.dart';
import 'package:stock_count/core/widgets/app_report_entity_search_field.dart';
import 'package:stock_count/core/widgets/app_report_query_filter_panel.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/modules/inventory/stock_movements/presentation/pages/stock_issue_form_page.dart';
import 'package:stock_count/modules/inventory/stock_movements/presentation/pages/stock_receipt_form_page.dart';
import 'package:stock_count/modules/inventory/warehouses/presentation/pages/stock_transfer_form_page.dart';
import 'package:stock_count/modules/inventory/warehouses/presentation/providers/warehouse_providers.dart';
import 'package:stock_count/modules/reports/shared/domain/services/product_stock_movement_report_data_port.dart';
import 'package:stock_count/modules/reports/shared/presentation/pages/reports_routes.dart';
import 'package:stock_count/modules/reports/shared/presentation/providers/reports_providers.dart';
import 'package:stock_count/modules/sales/invoices/presentation/pages/sale_form_page.dart';

class ProductStockMovementReportPage extends ConsumerStatefulWidget {
  const ProductStockMovementReportPage({super.key});

  @override
  ConsumerState<ProductStockMovementReportPage> createState() =>
      _ProductStockMovementReportPageState();
}

class _ProductStockMovementReportPageState
    extends ConsumerState<ProductStockMovementReportPage> {
  String? _selectedProductId;
  String? _selectedProductName;
  String? _selectedWarehouseId;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _generating = false;
  ProductStockMovementReportPayload? _payload;



  ProductStockMovementReportLabels _buildLabels(AppLocalizations l10n) {
    final isAr = l10n.localeName == 'ar';
    return ProductStockMovementReportLabels(
      companyName: l10n.appTitle,
      reportTitle: isAr ? 'تقرير حركة صنف' : 'Product Stock Movement Report',
      warehouseLabel: isAr ? 'المخزن' : 'Warehouse',
      productCodeLabel: isAr ? 'رقم السلعة' : 'Item Code',
      productNameLabel: isAr ? 'أسم الصنف' : 'Item Name',
      openingBalanceLabel: isAr ? 'الرصيد السابق' : 'Opening Balance',
      mainCapacityLabel: isAr ? 'العبوة الرئيسية' : 'Main Pack Size',
      subCapacityLabel: isAr ? 'العبوة الفرعية' : 'Sub Pack Size',
      cartonLabel: isAr ? 'كرتون' : 'Carton',
      pieceLabel: isAr ? 'حبة' : 'Piece',
      finalQtyLabel: isAr ? 'نهائي' : 'Total Qty',
      costLabel: isAr ? 'التكلفة' : 'Cost',
      docDateLabel: isAr ? 'تاريخ المستند' : 'Doc Date',
      docTypeLabel: isAr ? 'نوع المستند' : 'Doc Type',
      voucherBookLabel: isAr ? 'الدفتر' : 'Book/Party',
      docNumLabel: isAr ? 'رقم المستند' : 'Doc No.',
      inwardHeaderLabel: isAr ? 'الوارد' : 'Inward',
      outwardHeaderLabel: isAr ? 'المنصرف' : 'Outward',
      endingBalanceHeaderLabel: isAr ? 'رصيد نهاية المدة' : 'Ending Balance',
      totalIncomingCostLabel: isAr ? 'أجمالي تكلفة الوارد' : 'Total Inward Cost',
      totalOutgoingCostLabel: isAr ? 'أجمالي تكلفة المنصرف' : 'Total Outward Cost',
      periodLabel: isAr ? 'من تاريخ' : 'From',
      periodAll: isAr ? 'جميع الفترات' : 'All Period',
      allWarehousesLabel: isAr ? 'جميع المستودعات' : 'All Warehouses',
      emptyMessage: isAr ? 'لا توجد حركات مخزنية لهذا الصنف خلال الفترة المحددة' : 'No movements found for this item in the selected period',
    );
  }

  Future<void> _loadReportData() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedProductId == null) {
      showAppSnackBar(context, message: l10n.localeName == 'ar' ? 'يرجى اختيار صنف أولاً' : 'Please select a product first', isSuccess: false);
      return;
    }

    setState(() => _generating = true);
    try {
      final labels = _buildLabels(l10n);
      final payload = await ref.read(productStockMovementReportDataPortProvider).load(
            productId: _selectedProductId!,
            warehouseId: _selectedWarehouseId,
            fromDate: _fromDate,
            toDate: _toDate,
            labels: labels,
          );
      setState(() {
        _payload = payload;
      });
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: l10n.localeName == 'ar' ? 'حدث خطأ أثناء تحميل التقرير' : 'Error loading report', isSuccess: false);
      }
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

  Future<void> _exportPdf() async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    if (_payload == null) {
      await _loadReportData();
    }
    if (_payload == null) return;

    try {
      final document = await ref.read(loadingControllerProvider).run(
        message: l10n.reportsGenerating,
        action: () async {
          final contextPdf = await ReportPdfContext.create(
            isRtl: locale.languageCode == 'ar',
            localeCode: locale.toLanguageTag(),
            pageFormat: ReportPageFormat.a4Landscape,
          );
          return ref.read(reportRunnerProvider).run(
                definition: ref.read(productStockMovementReportDefinitionProvider),
                payload: _payload!,
                context: contextPdf,
                title: _payload!.labels.reportTitle,
                fileName: 'product_movement_${DateTime.now().millisecondsSinceEpoch}.pdf',
              );
        },
      );

      if (!mounted) return;
      PdfDocumentPreviewArgs.holder = PdfDocumentPreviewArgs(
        bytes: document.bytes,
        title: document.title,
        fileName: document.fileName,
      );
      await context.push(ReportsRoutes.preview);
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: l10n.localeName == 'ar' ? 'حدث خطأ أثناء تصدير PDF' : 'Error exporting PDF', isSuccess: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final warehousesAsync = ref.watch(warehousesListStreamProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.localeName == 'ar' ? 'تقرير حركة صنف' : 'Product Stock Movement Report',
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          AppReportQueryFilterPanel(
            title: l10n.localeName == 'ar' ? 'خيارات التصفية والمعاينة' : 'Filter Options',
            showPostingStatus: false,
            initialFromDate: _fromDate,
            initialToDate: _toDate,
            isLoading: _generating,
            applyButtonLabel: l10n.localeName == 'ar' ? 'عرض التقرير' : 'View Report',
            entitySearchField: AppReportEntitySearchField.product(
              context,
              selectedProductCode: _selectedProductId,
              selectedProductName: _selectedProductName,
              customLabel: l10n.localeName == 'ar' ? 'اختر الصنف / المنتج' : 'Select Product',
              isRequired: true,
              onProductSelected: (product) {
                if (product != null) {
                  setState(() {
                    _selectedProductId = product.itemCode;
                    _selectedProductName = product.name;
                    _payload = null;
                  });
                } else {
                  setState(() {
                    _selectedProductId = null;
                    _selectedProductName = null;
                    _payload = null;
                  });
                }
              },
              onClear: () {
                setState(() {
                  _selectedProductId = null;
                  _selectedProductName = null;
                  _payload = null;
                });
              },
            ),
            extraFilters: [
              warehousesAsync.when(
                data: (warehouses) => DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: _selectedWarehouseId,
                  decoration: InputDecoration(
                    labelText: l10n.localeName == 'ar' ? 'المستودع' : 'Warehouse',
                    prefixIcon: const Icon(Icons.warehouse_outlined),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        l10n.localeName == 'ar' ? 'جميع المستودعات' : 'All Warehouses',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...warehouses.map((w) {
                      return DropdownMenuItem<String?>(
                        value: w.id,
                        child: Text(
                          w.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (val) => setState(() {
                    _selectedWarehouseId = val;
                    _payload = null;
                  }),
                ),
                loading: () => const SizedBox(),
                error: (err, stack) => const SizedBox(),
              ),
            ],
            onApply: (filterData) {
              _fromDate = filterData.fromDate;
              _toDate = filterData.toDate;
              if (_selectedProductId != null && !_generating) {
                _loadReportData();
              } else if (_selectedProductId == null) {
                showAppSnackBar(
                  context,
                  message: l10n.localeName == 'ar'
                      ? 'يرجى اختيار صنف أولاً'
                      : 'Please select a product first',
                  isSuccess: false,
                );
              }
            },
            onViewAsTable: null,
            onPrint: _selectedProductId == null || _generating ? null : _exportPdf,
            onReset: () {
              setState(() {
                _selectedProductId = null;
                _selectedProductName = null;
                _selectedWarehouseId = null;
                _fromDate = null;
                _toDate = null;
                _payload = null;
              });
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Display Report Data if available
          if (_payload != null)
            _buildMovementsTable(context, _payload!),
        ],
      ),
    );
  }

  void _navigateToOriginalVoucher(BuildContext context, ProductStockMovementRow row) {
    final type = row.documentType.toLowerCase();

    Widget targetPage;

    if (type.contains('توريد') || type.contains('استلام') || type.contains('receipt')) {
      targetPage = const StockReceiptFormPage();
    } else if (type.contains('صرف') || type.contains('اخراج') || type.contains('issue')) {
      targetPage = const StockIssueFormPage();
    } else if (type.contains('تحويل') || type.contains('transfer')) {
      targetPage = const StockTransferFormPage();
    } else if (type.contains('مردود') || type.contains('return')) {
      targetPage = const StockReceiptFormPage();
    } else if (type.contains('مبيعات') || type.contains('فاتورة') || type.contains('sale')) {
      targetPage = const SaleFormPage();
    } else {
      targetPage = const StockIssueFormPage();
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => targetPage),
    );
  }

  Widget _buildMovementsTable(BuildContext context, ProductStockMovementReportPayload payload) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFmt = DateFormat('dd-MM-yyyy');
    final op = payload.openingBalance;

    return AppDynamicReportTable<ProductStockMovementRow>(
      title: 'تقرير حركة صنف تفصيلي',
      subtitle: '${payload.productCode} — ${payload.productName}',
      minTableWidth: 1100,
      onExportPdf: _exportPdf,
      onPrint: _exportPdf,
      headerInfoCards: [
        ReportHeaderInfoSpec(
          title: 'المستودع',
          value: payload.warehouseName,
          icon: Icons.warehouse_outlined,
        ),
        ReportHeaderInfoSpec(
          title: 'الصنف / المنتج',
          value: payload.productName,
          subValue: 'كود: ${payload.productCode}',
          icon: Icons.inventory_2_outlined,
          accentColor: colorScheme.primary,
        ),
        ReportHeaderInfoSpec(
          title: 'الرصيد السابق',
          value: '${op.cartons} كرتون / ${op.pieces.toStringAsFixed(0)} حبة',
          subValue: 'إجمالي: ${op.totalQty.toStringAsFixed(0)} (تكلفة: ${op.totalCost.toStringAsFixed(0)})',
          icon: Icons.history_rounded,
          accentColor: const Color(0xFFE65100),
        ),
        ReportHeaderInfoSpec(
          title: 'سعة العبوة',
          value: '${payload.mainUnitCapacity} حبة/كرتون',
          icon: Icons.unfold_more_rounded,
        ),
      ],
      groupHeaders: const [
        ReportGroupHeaderSpec(
          title: 'بيانات المستند',
          startColumnIndex: 0,
          columnSpan: 5,
        ),
        ReportGroupHeaderSpec(
          title: 'الوارد',
          startColumnIndex: 5,
          columnSpan: 3,
        ),
        ReportGroupHeaderSpec(
          title: 'المنصرف',
          startColumnIndex: 8,
          columnSpan: 3,
        ),
        ReportGroupHeaderSpec(
          title: 'رصيد نهاية المدة',
          startColumnIndex: 11,
          columnSpan: 2,
        ),
      ],
      columns: [
        ReportColumnSpec<ProductStockMovementRow>(
          id: 'actions',
          label: 'الإجراء',
          flex: 18,
          alignment: Alignment.center,
          cellBuilder: (context, row) {
            final isDark = theme.brightness == Brightness.dark;
            final actionColor = isDark ? Colors.white : colorScheme.primary;
            final containerBg = isDark
                ? Colors.white.withValues(alpha: 0.12)
                : colorScheme.primaryContainer.withValues(alpha: 0.4);
            final borderColor = isDark
                ? Colors.white.withValues(alpha: 0.25)
                : colorScheme.primary.withValues(alpha: 0.3);

            return InkWell(
              onTap: () => _navigateToOriginalVoucher(context, row),
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: containerBg,
                  borderRadius: BorderRadius.circular(AppRadius.xs + 2),
                  border: Border.all(
                    color: borderColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 13,
                      color: actionColor,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'فتح',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: actionColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        ReportColumnSpec<ProductStockMovementRow>(
          id: 'date',
          label: 'تاريخ المستند',
          flex: 22,
          alignment: Alignment.center,
          cellBuilder: (ctx, row) => Text(
            dateFmt.format(row.documentDate),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        ReportColumnSpec<ProductStockMovementRow>(
          id: 'docType',
          label: 'نوع المستند',
          flex: 20,
          alignment: Alignment.center,
          getValue: (row) => row.documentType,
        ),
        ReportColumnSpec<ProductStockMovementRow>(
          id: 'book',
          label: 'الدفتر / الجهة',
          flex: 25,
          getValue: (row) => row.voucherBook,
        ),
        ReportColumnSpec<ProductStockMovementRow>(
          id: 'docNum',
          label: 'رقم المستند',
          flex: 18,
          alignment: Alignment.center,
          getValue: (row) => row.documentNumber,
        ),
        ReportColumnSpec<ProductStockMovementRow>(
          id: 'inCartons',
          label: 'كرتون',
          flex: 14,
          isNumeric: true,
          alignment: Alignment.center,
          getValue: (row) => '${row.inCartons}',
        ),
        ReportColumnSpec<ProductStockMovementRow>(
          id: 'inPieces',
          label: 'حبة',
          flex: 14,
          isNumeric: true,
          alignment: Alignment.center,
          getValue: (row) => row.inPieces.toStringAsFixed(0),
        ),
        ReportColumnSpec<ProductStockMovementRow>(
          id: 'inCost',
          label: 'التكلفة',
          flex: 22,
          isNumeric: true,
          alignment: Alignment.centerRight,
          getValue: (row) => row.inCost.toStringAsFixed(0),
        ),
        ReportColumnSpec<ProductStockMovementRow>(
          id: 'outCartons',
          label: 'كرتون',
          flex: 14,
          isNumeric: true,
          alignment: Alignment.center,
          getValue: (row) => '${row.outCartons}',
        ),
        ReportColumnSpec<ProductStockMovementRow>(
          id: 'outPieces',
          label: 'حبة',
          flex: 14,
          isNumeric: true,
          alignment: Alignment.center,
          getValue: (row) => row.outPieces.toStringAsFixed(0),
        ),
        ReportColumnSpec<ProductStockMovementRow>(
          id: 'outCost',
          label: 'التكلفة',
          flex: 22,
          isNumeric: true,
          alignment: Alignment.centerRight,
          getValue: (row) => row.outCost.toStringAsFixed(0),
        ),
        ReportColumnSpec<ProductStockMovementRow>(
          id: 'balQty',
          label: 'الرصيد المتبقي',
          flex: 20,
          isNumeric: true,
          alignment: Alignment.center,
          getValue: (row) => row.balanceTotalQty.toStringAsFixed(0),
        ),
        ReportColumnSpec<ProductStockMovementRow>(
          id: 'balCost',
          label: 'رصيد التكلفة',
          flex: 22,
          isNumeric: true,
          alignment: Alignment.centerRight,
          getValue: (row) => row.balanceCost.toStringAsFixed(0),
        ),
      ],
      items: payload.rows,
      footerSummaries: [
        ReportFooterSummarySpec(
          columnId: 'inCost',
          label: 'إجمالي تكلفة الوارد',
          value: payload.totalIncomingCost.toStringAsFixed(0),
          color: const Color(0xFF2E7D32),
          icon: Icons.arrow_downward_rounded,
        ),
        ReportFooterSummarySpec(
          columnId: 'outCost',
          label: 'إجمالي تكلفة المنصرف',
          value: payload.totalOutgoingCost.toStringAsFixed(0),
          color: colorScheme.error,
          icon: Icons.arrow_upward_rounded,
        ),
      ],
    );
  }
}
