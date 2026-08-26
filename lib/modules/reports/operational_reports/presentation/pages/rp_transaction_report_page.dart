import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/company/company_profile.dart';
import 'package:stock_count/app/settings/company/company_profile_providers.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/reporting/pdf_document_preview_page.dart';
import 'package:stock_count/core/reporting/report_exception.dart';
import 'package:stock_count/core/reporting/report_page_format.dart';
import 'package:stock_count/core/reporting/report_pdf_theme.dart';
import 'package:stock_count/core/widgets/app_button.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/core/widgets/custom_app_bar.dart';
import 'package:stock_count/modules/reports/shared/domain/services/rp_report_data_port.dart';
import 'package:stock_count/modules/reports/shared/presentation/providers/reports_providers.dart';
import 'package:stock_count/modules/reports/shared/presentation/pages/reports_routes.dart';

class RpTransactionReportPage extends ConsumerStatefulWidget {
  const RpTransactionReportPage({required this.kind, super.key});

  final RpReportKind kind;

  @override
  ConsumerState<RpTransactionReportPage> createState() =>
      _RpTransactionReportPageState();
}

class _RpTransactionReportPageState
    extends ConsumerState<RpTransactionReportPage> {
  DateTime? _from;
  DateTime? _to;
  var _generating = false;

  String _title(AppLocalizations l10n) {
    return switch (widget.kind) {
      RpReportKind.receipts => l10n.reportsRpReceiptsTitle,
      RpReportKind.payments => l10n.reportsRpPaymentsTitle,
      RpReportKind.cashMovement => l10n.reportsRpCashMovementTitle,
      RpReportKind.bankMovement => l10n.reportsRpBankMovementTitle,
      RpReportKind.customerReceipts => l10n.reportsRpCustomerReceiptsTitle,
      RpReportKind.dailySummary => l10n.reportsRpDailySummaryTitle,
      RpReportKind.periodSummary => l10n.reportsRpPeriodSummaryTitle,
    };
  }

  String _typeLabel(AppLocalizations l10n, String storage) {
    return storage == 'payment' ? l10n.rpTypePayment : l10n.rpTypeReceipt;
  }

  String _statusLabel(AppLocalizations l10n, String storage) {
    return storage == 'posted' ? l10n.rpStatusPosted : l10n.rpStatusUnposted;
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _from = picked);
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _to = picked);
  }

  Future<void> _generate() async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final from = _from ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
    final to = _to ?? DateTime.now();
    setState(() => _generating = true);
    try {
      final profile =
          ref.read(companyProfileProvider).valueOrNull ??
          const CompanyProfile();
      const rowLimit = 5000;
      final data = await ref.read(rpReportDataPortProvider).load(
            RpReportQuery(
              kind: widget.kind,
              from: from,
              to: to,
              rowLimit: rowLimit,
            ),
          );
      final dateFmt = DateFormat.yMMMd(locale.toString());
      final localizedRows = [
        for (final row in data.rows)
          RpReportRow(
            transactionNumber: row.transactionNumber,
            transactionDate: row.transactionDate,
            typeLabel: _typeLabel(l10n, row.typeLabel),
            partyLabel: row.partyLabel.trim().isEmpty
                ? l10n.rpNoParty
                : row.partyLabel,
            amount: row.amount,
            currencyCode: row.currencyCode,
            statusLabel: _statusLabel(l10n, row.statusLabel),
          ),
      ];
      final payload = RpReportPayload(
        companyName: profile.name.trim().isEmpty
            ? l10n.appTitle
            : profile.name.trim(),
        reportTitle: _title(l10n),
        periodLabel:
            '${l10n.reportsPeriod}: ${dateFmt.format(from)} – ${dateFmt.format(to)}',
        generatedAtLabel: l10n.reportsGeneratedAt,
        totalLabel: l10n.reportsRpTotal,
        countLabel: l10n.reportsRpCount,
        totalAmount: data.totalAmount,
        totalCount: data.totalCount,
        columnNumber: l10n.reportsRpColNumber,
        columnDate: l10n.reportsRpColDate,
        columnType: l10n.reportsRpColType,
        columnParty: l10n.reportsRpColParty,
        columnAmount: l10n.reportsRpColAmount,
        columnStatus: l10n.reportsRpColStatus,
        truncatedNote: data.totalCount > rowLimit
            ? 'Showing first $rowLimit of ${data.totalCount} rows'
            : null,
        rows: localizedRows,
      );

      final contextPdf = await ReportPdfContext.create(
        isRtl: locale.languageCode == 'ar',
        localeCode: locale.toLanguageTag(),
        pageFormat: ReportPageFormat.a4Portrait,
      );
      final document = await ref.read(reportRunnerProvider).run(
            definition: ref.read(rpTransactionReportDefinitionProvider),
            payload: payload,
            context: contextPdf,
            title: _title(l10n),
            fileName:
                'rp_${widget.kind.name}_${DateTime.now().millisecondsSinceEpoch}.pdf',
          );
      if (!mounted) return;
      PdfDocumentPreviewArgs.holder = PdfDocumentPreviewArgs(
        bytes: document.bytes,
        title: document.title,
        fileName: document.fileName,
      );
      await context.push(ReportsRoutes.preview);
    } on ReportException {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: l10n.reportsErrorGeneric,
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
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFmt = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return Scaffold(
      appBar: CustomAppBar(title: _title(l10n), showBackButton: true),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          ListTile(
            title: Text(l10n.reportsAccountStatementFromDate),
            subtitle: Text(_from == null ? '—' : dateFmt.format(_from!)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _pickFrom,
          ),
          ListTile(
            title: Text(l10n.reportsAccountStatementToDate),
            subtitle: Text(_to == null ? '—' : dateFmt.format(_to!)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _pickTo,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: _generating
                ? l10n.rpLoading
                : l10n.reportsGeneratePreview,
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
