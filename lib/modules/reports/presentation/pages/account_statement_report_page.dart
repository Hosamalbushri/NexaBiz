import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/reports/account_statement_display.dart';
import '../../../../app/settings/company/company_profile.dart';
import '../../../../app/settings/company/company_profile_providers.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/reporting/pdf_document_preview_page.dart';
import '../../../../core/reporting/report_exception.dart';
import '../../../../core/reporting/report_page_format.dart';
import '../../../../core/reporting/report_pdf_theme.dart';
import '../../../../core/services/loading_providers.dart';
import '../../../../core/utils/async_search_token.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/services/account_statement_report_data_port.dart';
import '../providers/reports_providers.dart';
import 'reports_routes.dart';

/// Filter form + PDF preview for Chart of Accounts account statement.
class AccountStatementReportPage extends ConsumerStatefulWidget {
  const AccountStatementReportPage({super.key});

  @override
  ConsumerState<AccountStatementReportPage> createState() =>
      _AccountStatementReportPageState();
}

class _AccountStatementReportPageState
    extends ConsumerState<AccountStatementReportPage> {
  AccountStatementAccountRef? _account;
  String? _currencyCode;
  DateTime? _from;
  DateTime? _to;
  var _statementType = AccountStatementType.cumulativeAccountCurrency;
  var _postingFilter = AccountStatementPostingFilter.all;
  var _generating = false;
  List<AccountStatementCurrencyRef> _currencies = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrencies());
  }

  Future<void> _loadCurrencies() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final list = await ref
        .read(accountStatementReportDataPortProvider)
        .listCurrencies(isArabic: isArabic);
    if (!mounted) {
      return;
    }
    setState(() => _currencies = list);
  }

  String _accountLabel(
    AppLocalizations l10n,
    AccountStatementAccountRef account,
  ) {
    final name = _displayAccountName(l10n, account);
    return '${account.accountCode} — $name';
  }

  String _displayAccountName(
    AppLocalizations l10n,
    AccountStatementAccountRef account,
  ) {
    return resolveAccountStatementDisplayName(l10n, account);
  }

  Future<void> _pickAccount() async {
    final selected = await showModalBottomSheet<AccountStatementAccountRef>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AccountPickerSheet(),
    );
    if (selected != null && mounted) {
      setState(() => _account = selected);
    }
  }

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
    if (_account == null) {
      showAppSnackBar(
        context,
        message: l10n.reportsAccountStatementAccountRequired,
        isSuccess: false,
      );
      return;
    }

    setState(() => _generating = true);
    try {
      final profile =
          ref.read(companyProfileProvider).valueOrNull ??
          const CompanyProfile();
      final labels = AccountStatementReportLabels(
        companyName: profile.name.trim().isEmpty
            ? l10n.appTitle
            : profile.name.trim(),
        reportTitle: l10n.reportsAccountStatementTitle,
        printedByLabel: l10n.reportsAccountStatementPrintedBy,
        fromDateLabel: l10n.reportsAccountStatementFromDate,
        toDateLabel: l10n.reportsAccountStatementToDate,
        accountNameLabel: l10n.reportsAccountStatementAccountName,
        accountNumberLabel: l10n.reportsAccountStatementAccountNumber,
        currencyAll: l10n.reportsAccountStatementCurrencyAll,
        columnSide: l10n.reportsAccountStatementColSide,
        columnDescription: l10n.reportsAccountStatementColDescription,
        columnVoucherType: l10n.reportsAccountStatementColVoucherType,
        columnVoucherNumber: l10n.reportsAccountStatementColVoucherNumber,
        columnDate: l10n.reportsColDate,
        columnDebit: l10n.reportsAccountStatementColDebit,
        columnCredit: l10n.reportsAccountStatementColCredit,
        columnBalance: l10n.reportsAccountStatementColBalance,
        columnCurrency: l10n.reportsAccountStatementColCurrency,
        columnInCurrency: l10n.reportsAccountStatementColInCurrency,
        totalsDebitLabel: l10n.reportsAccountStatementTotalsDebit,
        totalsCreditLabel: l10n.reportsAccountStatementTotalsCredit,
        finalBalanceByCurrencyLabel:
            l10n.reportsAccountStatementFinalBalanceByCurrency,
        disclaimer: l10n.reportsAccountStatementDisclaimer,
        accountantLabel: l10n.reportsAccountStatementAccountant,
        reviewerLabel: l10n.reportsAccountStatementReviewer,
        financeManagerLabel: l10n.reportsAccountStatementFinanceManager,
        emptyMessage: l10n.reportsAccountStatementEmpty,
        statementTypeLabelOf: (type) => _statementTypeLabel(l10n, type),
        postingFilterLabelOf: (filter) => _postingFilterLabel(l10n, filter),
        accountDisplayNameOf: (account) => _displayAccountName(l10n, account),
      );

      final document = await ref.read(loadingControllerProvider).run(
        message: l10n.reportsGenerating,
        action: () async {
          final payload = await ref
              .read(accountStatementReportDataPortProvider)
              .load(
                accountUuid: _account!.accountUuid,
                currencyCode: _currencyCode,
                fromDate: _from,
                toDate: _to,
                statementType: _statementType,
                postingFilter: _postingFilter,
                labels: labels,
              );
          final contextPdf = await ReportPdfContext.create(
            isRtl: true,
            localeCode: 'ar',
            pageFormat: const ReportPageFormat(
              pageFormat: PdfPageFormat.a4,
              margin: pw.EdgeInsets.fromLTRB(16, 14, 16, 16),
            ),
          );
          return ref
              .read(reportRunnerProvider)
              .run(
                definition: ref.read(accountStatementReportDefinitionProvider),
                payload: payload,
                context: contextPdf,
                title: l10n.reportsAccountStatementTitle,
                fileName:
                    'account_statement_${DateTime.now().millisecondsSinceEpoch}.pdf',
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

  String _statementTypeLabel(
    AppLocalizations l10n,
    AccountStatementType type,
  ) {
    return switch (type) {
      AccountStatementType.cumulativeAccountCurrency =>
        l10n.reportsAccountStatementTypeCumulative,
      AccountStatementType.detailed =>
        l10n.reportsAccountStatementTypeDetailed,
      AccountStatementType.summary => l10n.reportsAccountStatementTypeSummary,
    };
  }

  String _postingFilterLabel(
    AppLocalizations l10n,
    AccountStatementPostingFilter filter,
  ) {
    return switch (filter) {
      AccountStatementPostingFilter.all =>
        l10n.reportsAccountStatementPostingAll,
      AccountStatementPostingFilter.posted =>
        l10n.reportsAccountStatementPostingPosted,
      AccountStatementPostingFilter.unposted =>
        l10n.reportsAccountStatementPostingUnposted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateFmt = DateFormat.yMMMd(Localizations.localeOf(context).toString());

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.reportsAccountStatementTitle,
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          Text(
            l10n.reportsAccountStatementSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Material(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.reportsAccountStatementFilters,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.reportsAccountStatementAccount,
                        border: const OutlineInputBorder(),
                      ),
                      child: InkWell(
                        onTap: _pickAccount,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _account == null
                                    ? l10n.reportsAccountStatementAccountHint
                                    : _accountLabel(l10n, _account!),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: _account == null
                                      ? scheme.onSurfaceVariant
                                      : null,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.account_tree_outlined,
                              color: scheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String?>(
                      // ignore: deprecated_member_use
                      value: _currencyCode,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.reportsAccountStatementCurrency,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            l10n.reportsAccountStatementCurrencyAll,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        for (final c in _currencies)
                          DropdownMenuItem<String?>(
                            value: c.code,
                            child: Text(
                              '${c.code} — ${c.displayName}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _currencyCode = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: l10n.reportsAccountStatementFromDate,
                            value: _from == null
                                ? l10n.reportsDateAny
                                : dateFmt.format(_from!),
                            onClear: _from == null
                                ? null
                                : () => setState(() => _from = null),
                            onPick: _pickFrom,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _DateField(
                            label: l10n.reportsAccountStatementToDate,
                            value: _to == null
                                ? l10n.reportsDateAny
                                : dateFmt.format(_to!),
                            onClear: _to == null
                                ? null
                                : () => setState(() => _to = null),
                            onPick: _pickTo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<AccountStatementType>(
                      // ignore: deprecated_member_use
                      value: _statementType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.reportsAccountStatementType,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final type in AccountStatementType.values)
                          DropdownMenuItem(
                            value: type,
                            child: Text(
                              _statementTypeLabel(l10n, type),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      selectedItemBuilder: (context) => [
                        for (final type in AccountStatementType.values)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              _statementTypeLabel(l10n, type),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _statementType = value);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<AccountStatementPostingFilter>(
                      // ignore: deprecated_member_use
                      value: _postingFilter,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.reportsAccountStatementPostingStatus,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final filter
                            in AccountStatementPostingFilter.values)
                          DropdownMenuItem(
                            value: filter,
                            child: Text(
                              _postingFilterLabel(l10n, filter),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _postingFilter = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(child: Text(value)),
          if (onClear != null)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.clear, size: 18),
              visualDensity: VisualDensity.compact,
            ),
          IconButton(
            onPressed: onPick,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _AccountPickerSheet extends ConsumerStatefulWidget {
  const _AccountPickerSheet();

  @override
  ConsumerState<_AccountPickerSheet> createState() =>
      _AccountPickerSheetState();
}

class _AccountPickerSheetState extends ConsumerState<_AccountPickerSheet> {
  static const _searchDebounce = Duration(milliseconds: 300);

  final _controller = TextEditingController();
  var _loading = true;
  final _searchToken = AsyncSearchToken();
  Timer? _debounce;
  List<AccountStatementAccountRef> _accounts = const [];

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () => _search(query));
  }

  Future<void> _search(String query) async {
    final token = _searchToken.next();
    setState(() => _loading = true);
    final list = await ref
        .read(accountStatementReportDataPortProvider)
        .searchAccounts(query);
    if (!mounted || !_searchToken.isCurrent(token)) {
      return;
    }
    setState(() {
      _accounts = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.reportsAccountStatementAccount,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: l10n.reportsAccountStatementAccountSearch,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: _onQueryChanged,
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _accounts.isEmpty
                ? Center(child: Text(l10n.reportsAccountStatementAccountEmpty))
                : ListView.separated(
                    itemCount: _accounts.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final account = _accounts[index];
                      return ListTile(
                        title: Text(
                          '${account.accountCode} — ${resolveAccountStatementDisplayName(l10n, account)}',
                        ),
                        onTap: () => Navigator.of(context).pop(account),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
