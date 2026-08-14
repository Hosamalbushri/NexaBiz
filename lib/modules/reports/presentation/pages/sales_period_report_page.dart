import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/settings/company/company_profile.dart';
import '../../../../app/settings/company/company_profile_providers.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/reporting/pdf_document_preview_page.dart';
import '../../../../core/reporting/report_exception.dart';
import '../../../../core/reporting/report_page_format.dart';
import '../../../../core/reporting/report_pdf_theme.dart';
import '../../../../core/services/loading_providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/services/sales_period_report_data_port.dart';
import '../providers/reports_providers.dart';
import 'reports_routes.dart';

/// Filter + generate UI for the sales-period PDF report.
class SalesPeriodReportPage extends ConsumerStatefulWidget {
  const SalesPeriodReportPage({super.key});

  @override
  ConsumerState<SalesPeriodReportPage> createState() =>
      _SalesPeriodReportPageState();
}

class _SalesPeriodReportPageState extends ConsumerState<SalesPeriodReportPage> {
  DateTime? _from;
  DateTime? _to;
  String? _status; // storage value or null = all
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
      final labels = SalesPeriodReportLabels(
        companyName: profile.name.trim().isEmpty
            ? l10n.appTitle
            : profile.name.trim(),
        reportTitle: l10n.reportsSalesPeriodTitle,
        generatedAtLabel: l10n.reportsGeneratedAt,
        periodLabel: l10n.reportsPeriod,
        totalLabel: l10n.reportsGrandTotal,
        rowsLabel: l10n.reportsRowCount,
        columnSaleNumber: l10n.reportsColSaleNumber,
        columnDate: l10n.reportsColDate,
        columnCustomer: l10n.reportsColCustomer,
        columnSettlement: l10n.reportsColSettlement,
        columnStatus: l10n.reportsColStatus,
        columnCurrency: l10n.reportsColCurrency,
        columnTotal: l10n.reportsColTotal,
        emptyMessage: l10n.reportsEmptySales,
        settlementCash: l10n.salesSettlementCash,
        settlementCredit: l10n.salesSettlementCredit,
        statusLabelOf: (value) => _statusLabel(l10n, value),
        allStatuses: l10n.reportsStatusAll,
        periodAll: l10n.reportsPeriodAll,
      );

      final document = await ref.read(loadingControllerProvider).run(
        message: l10n.reportsGenerating,
        action: () async {
          final payload = await ref
              .read(salesPeriodReportDataPortProvider)
              .load(
                fromDate: _from,
                toDate: _to,
                statusStorageValue: _status,
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
                definition: ref.read(salesPeriodReportDefinitionProvider),
                payload: payload,
                context: contextPdf,
                title: l10n.reportsSalesPeriodTitle,
                fileName:
                    'sales_period_${DateTime.now().millisecondsSinceEpoch}.pdf',
              );
        },
      );

      if (!mounted) {
        return;
      }
          PdfDocumentPreviewArgs.holder = PdfDocumentPreviewArgs(
            bytes: document.bytes,
            title: document.title,
            fileName: document.fileName,
          );
          await context.push(ReportsRoutes.preview);
    } on ReportException catch (e) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: _mapError(l10n, e),
        isSuccess: false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
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

  String _statusLabel(AppLocalizations l10n, String value) {
    return switch (value) {
      'unposted' ||
      'draft' ||
      'pending' ||
      'cancelled' ||
      'rejected' => l10n.salesStatusUnposted,
      'posted' || 'confirmed' || 'completed' => l10n.salesStatusPosted,
      _ => value,
    };
  }

  String _mapError(AppLocalizations l10n, ReportException e) {
    return switch (e.code) {
      ReportException.emptyReport => l10n.reportsEmptySales,
      ReportException.fontLoadFailed => l10n.reportsErrorFont,
      ReportException.generationFailed => l10n.reportsErrorGeneric,
      _ => l10n.reportsErrorGeneric,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dateFmt = DateFormat.yMMMd(Localizations.localeOf(context).toString());

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.reportsSalesPeriodTitle,
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          Text(
            l10n.reportsSalesPeriodSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.reportsFromDate),
            subtitle: Text(
              _from == null ? l10n.reportsDateAny : dateFmt.format(_from!),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_from != null)
                  IconButton(
                    onPressed: () => setState(() => _from = null),
                    icon: const Icon(Icons.clear),
                  ),
                IconButton(
                  onPressed: _pickFrom,
                  icon: const Icon(Icons.calendar_today_outlined),
                ),
              ],
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.reportsToDate),
            subtitle: Text(
              _to == null ? l10n.reportsDateAny : dateFmt.format(_to!),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_to != null)
                  IconButton(
                    onPressed: () => setState(() => _to = null),
                    icon: const Icon(Icons.clear),
                  ),
                IconButton(
                  onPressed: _pickTo,
                  icon: const Icon(Icons.calendar_today_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String?>(
            // ignore: deprecated_member_use
            value: _status,
            decoration: InputDecoration(labelText: l10n.reportsColStatus),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(l10n.reportsStatusAll),
              ),
              DropdownMenuItem(
                value: 'unposted',
                child: Text(l10n.salesStatusUnposted),
              ),
              DropdownMenuItem(
                value: 'posted',
                child: Text(l10n.salesStatusPosted),
              ),
            ],
            onChanged: (value) => setState(() => _status = value),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: l10n.reportsGeneratePreview,
            icon: Icons.picture_as_pdf_outlined,
            expand: true,
            isLoading: _generating,
            onPressed: _generating ? null : _generate,
          ),
        ],
      ),
    );
  }
}
