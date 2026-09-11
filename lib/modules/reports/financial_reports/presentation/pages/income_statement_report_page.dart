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
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/reports/shared/domain/services/income_statement_report_data_port.dart';
import 'package:stock_count/modules/reports/shared/domain/services/income_statement_report_definition.dart';
import 'package:stock_count/modules/reports/shared/presentation/pages/reports_routes.dart';
import 'package:stock_count/modules/reports/shared/presentation/providers/reports_providers.dart';
import 'package:stock_count/modules/reports/shared/presentation/widgets/app_report_query_filter_panel.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

class IncomeStatementReportPage extends ConsumerStatefulWidget {
  const IncomeStatementReportPage({super.key});

  @override
  ConsumerState<IncomeStatementReportPage> createState() =>
      _IncomeStatementReportPageState();
}

class _IncomeStatementReportPageState
    extends ConsumerState<IncomeStatementReportPage> {
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

      const labels = IncomeStatementReportLabels(
        companyName: 'NexaBiz ERP',
        reportTitle: 'قائمة الدخل (الأرباح والخسائر) - Profit & Loss',
        generatedAtLabel: 'تاريخ الاستخراج',
        periodLabel: 'الفترة',
        periodAll: 'جميع التواريخ',
        revenueHeader: 'الإيرادات والمبيعات',
        cogsHeader: 'تكلفة البضاعة المباعة (COGS)',
        grossProfitLabel: 'مجمل الربح (Gross Profit)',
        operatingExpensesHeader: 'المصروفات التشغيلية',
        operatingProfitLabel: 'الربح التشغيلي',
        netProfitLabel: 'صافي الربح (Net Profit)',
        netLossLabel: 'صافي الخسارة (Net Loss)',
        accountCodeLabel: 'رمز الحساب',
        accountNameLabel: 'اسم الحساب',
        amountLabel: 'المبلغ',
        totalsLabel: 'الإجمالي',
        emptyMessage: 'لا توجد حركات إيرادات أو مصروفات خلال الفترة المحددة',
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
                  .read(incomeStatementReportDataPortProvider)
                  .loadFromFilter(filter: filter, labels: labels);
              final contextPdf = await ReportPdfContext.create(
                isRtl: locale.languageCode == 'ar',
                localeCode: locale.toLanguageTag(),
                pageFormat: ReportPageFormat.a4Portrait,
              );
              return ref
                  .read(reportRunnerProvider)
                  .run(
                    definition: const IncomeStatementReportDefinition(),
                    payload: payload,
                    context: contextPdf,
                    title: 'قائمة الدخل',
                    fileName:
                        'income_statement_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'قائمة الدخل (الأرباح والخسائر)',
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          AppReportQueryFilterPanel(
            title: 'تحديد فترة قائمة الدخل',
            subtitle: 'حساب الإيرادات، التكلفة، والمصروفات وصافي الربح',
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
