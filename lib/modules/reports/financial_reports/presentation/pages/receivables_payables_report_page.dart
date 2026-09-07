import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/app/settings/company/company_profile_providers.dart';
import 'package:stock_count/core/report_engine/domain/models/report_execution_context.dart';
import 'package:stock_count/core/report_engine/domain/models/report_query_filter.dart';
import 'package:stock_count/core/reporting/pdf_document_preview_page.dart';
import 'package:stock_count/core/reporting/report_exception.dart';
import 'package:stock_count/core/reporting/report_page_format.dart';
import 'package:stock_count/core/reporting/report_pdf_theme.dart';
import 'package:stock_count/core/services/loading_providers.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/reports/shared/domain/services/receivables_payables_report_data_port.dart';
import 'package:stock_count/modules/reports/shared/domain/services/receivables_payables_report_definition.dart';
import 'package:stock_count/modules/reports/shared/presentation/pages/reports_routes.dart';
import 'package:stock_count/modules/reports/shared/presentation/providers/reports_providers.dart';
import 'package:stock_count/modules/reports/shared/presentation/widgets/app_report_query_filter_panel.dart';

class ReceivablesPayablesReportPage extends ConsumerStatefulWidget {
  const ReceivablesPayablesReportPage({
    super.key,
    this.type = ReceivablesPayablesType.receivables,
  });

  final ReceivablesPayablesType type;

  @override
  ConsumerState<ReceivablesPayablesReportPage> createState() =>
      _ReceivablesPayablesReportPageState();
}

class _ReceivablesPayablesReportPageState
    extends ConsumerState<ReceivablesPayablesReportPage> {
  DateTime? _from;
  DateTime? _to;
  var _postedOnly = true;
  var _generating = false;

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _from = picked);
    }
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _to = picked);
    }
  }

  Future<void> _generate() async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    setState(() => _generating = true);
    try {
      final profile =
          ref.read(companyProfileProvider).valueOrNull ??
          const CompanyProfile();

      final isReceivables = widget.type == ReceivablesPayablesType.receivables;

      final labels = ReceivablesPayablesReportLabels(
        companyName: 'NexaBiz ERP',
        reportTitle: isReceivables
            ? 'تقرير ذمم العملاء (Customer Receivables)'
            : 'تقرير ذمم الموردين (Supplier Payables)',
        generatedAtLabel: 'تاريخ الاستخراج',
        periodLabel: 'الفترة',
        periodAll: 'جميع التواريخ',
        columnEntityCode: 'الرمز',
        columnEntityName: isReceivables
            ? 'اسم العميل/الحساب'
            : 'اسم المورد/الحساب',
        columnOpeningBalance: 'رصيد البداية',
        columnInvoices: isReceivables
            ? 'الفواتير/المديونية'
            : 'الفواتير/المطالبات',
        columnPayments: isReceivables ? 'المقبوضات' : 'المدفوعات',
        columnAdjustments: 'التسويات',
        columnEndingBalance: 'الرصيد المتبقي',
        totalsLabel: 'الإجمالي',
        emptyMessage: isReceivables
            ? 'لا توجد ذمم عملاء خلال الفترة المحددة'
            : 'لا توجد ذمم موردين خلال الفترة المحددة',
      );

      final filter = ReportQueryFilter(
        companyId: profile.name.isEmpty ? 'default' : profile.name,
        fromDate: _from,
        toDate: _to,
        postingScope: _postedOnly ? PostingScope.postedOnly : PostingScope.all,
      );

      final document = await ref
          .read(loadingControllerProvider)
          .run(
            message: l10n.reportsGenerating,
            action: () async {
              final payload = await ref
                  .read(receivablesPayablesReportDataPortProvider)
                  .loadFromFilter(
                    filter: filter,
                    type: widget.type,
                    labels: labels,
                  );
              final contextPdf = await ReportPdfContext.create(
                isRtl: locale.languageCode == 'ar',
                localeCode: locale.toLanguageTag(),
                pageFormat: ReportPageFormat.a4Landscape,
              );
              return ref
                  .read(reportRunnerProvider)
                  .run(
                    definition: const ReceivablesPayablesReportDefinition(),
                    payload: payload,
                    context: contextPdf,
                    title: isReceivables ? 'ذمم العملاء' : 'ذمم الموردين',
                    fileName:
                        '${isReceivables ? "receivables" : "payables"}_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
    } on ReportException catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: e.code == ReportException.fontLoadFailed
            ? l10n.reportsErrorFont
            : l10n.reportsErrorGeneric,
        isSuccess: false,
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: l10n.reportsErrorGeneric,
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReceivables = widget.type == ReceivablesPayablesType.receivables;

    return Scaffold(
      appBar: CustomAppBar(
        title: isReceivables ? 'تقرير ذمم العملاء' : 'تقرير ذمم الموردين',
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          AppReportQueryFilterPanel(
            title: isReceivables
                ? 'كشف أركان مديونية العملاء'
                : 'كشف مستحقات الموردين',
            subtitle:
                'تتبع رصيد البداية، الفواتير، المقبوضات/المدفوعات والرصيد المتبقي',
            fromDate: _from,
            toDate: _to,
            onPickFromDate: _pickFrom,
            onPickToDate: _pickTo,
            onClearDates: () => setState(() {
              _from = null;
              _to = null;
            }),
            additionalFilters: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('العمليات المرحلة فقط (Posted Only)'),
                value: _postedOnly,
                onChanged: (val) => setState(() => _postedOnly = val),
              ),
            ],
            isGenerating: _generating,
            onGenerate: _generate,
          ),
        ],
      ),
    );
  }
}
