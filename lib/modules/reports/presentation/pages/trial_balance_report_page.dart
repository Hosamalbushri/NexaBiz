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
import '../../domain/services/trial_balance_report_data_port.dart';
import '../providers/reports_providers.dart';
import 'reports_routes.dart';

/// Filter + generate UI for the trial-balance PDF report.
class TrialBalanceReportPage extends ConsumerStatefulWidget {
  const TrialBalanceReportPage({super.key});

  @override
  ConsumerState<TrialBalanceReportPage> createState() =>
      _TrialBalanceReportPageState();
}

class _TrialBalanceReportPageState
    extends ConsumerState<TrialBalanceReportPage> {
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
      final labels = TrialBalanceReportLabels(
        companyName: profile.name.trim().isEmpty
            ? l10n.appTitle
            : profile.name.trim(),
        reportTitle: l10n.reportsTrialBalanceTitle,
        generatedAtLabel: l10n.reportsGeneratedAt,
        periodLabel: l10n.reportsPeriod,
        periodAll: l10n.reportsPeriodAll,
        columnCode: l10n.reportsTrialBalanceColCode,
        columnName: l10n.reportsTrialBalanceColName,
        columnDebit: l10n.reportsTrialBalanceColDebit,
        columnCredit: l10n.reportsTrialBalanceColCredit,
        totalsLabel: l10n.reportsTrialBalanceTotals,
        balancedLabel: l10n.reportsTrialBalanceBalanced,
        unbalancedLabel: l10n.reportsTrialBalanceUnbalanced,
        emptyMessage: l10n.reportsTrialBalanceEmpty,
      );

      final document = await ref.read(loadingControllerProvider).run(
        message: l10n.reportsGenerating,
        action: () async {
          final payload = await ref
              .read(trialBalanceReportDataPortProvider)
              .load(
                fromDate: _from,
                toDate: _to,
                postedOnly: _postedOnly,
                labels: labels,
              );
          final contextPdf = await ReportPdfContext.create(
            isRtl: locale.languageCode == 'ar',
            localeCode: locale.toLanguageTag(),
            pageFormat: ReportPageFormat.a4Portrait,
          );
          return ref
              .read(reportRunnerProvider)
              .run(
                definition: ref.read(trialBalanceReportDefinitionProvider),
                payload: payload,
                context: contextPdf,
                title: l10n.reportsTrialBalanceTitle,
                fileName:
                    'trial_balance_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
        message: e.code == ReportException.fontLoadFailed
            ? l10n.reportsErrorFont
            : l10n.reportsErrorGeneric,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dateFmt = DateFormat.yMMMd(Localizations.localeOf(context).toString());

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.reportsTrialBalanceTitle,
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          Text(
            l10n.reportsTrialBalanceSubtitle,
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.reportsTrialBalancePostedOnly),
            value: _postedOnly,
            onChanged: (value) => setState(() => _postedOnly = value),
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
