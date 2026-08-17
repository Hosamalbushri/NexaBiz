import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/settings/company/company_profile_providers.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/business_date.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../domain/entities/accounting_period_status.dart';
import '../../domain/entities/fiscal_year.dart';
import '../../domain/models/fiscal_year_exception.dart';
import '../../domain/services/account_labels.dart';
import '../../domain/services/period_closing_service.dart';
import '../providers/account_providers.dart';
import '../providers/journal_providers.dart';
import '../widgets/account_search_field.dart';
import 'accounting_routes.dart';

/// Multi-step fiscal year creation wizard.
class FiscalYearCreatePage extends ConsumerStatefulWidget {
  const FiscalYearCreatePage({super.key});

  @override
  ConsumerState<FiscalYearCreatePage> createState() =>
      _FiscalYearCreatePageState();
}

class _FiscalYearCreatePageState extends ConsumerState<FiscalYearCreatePage> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  var _step = 0;
  var _periodCount = 12;
  var _fxEnabled = false;
  var _saving = false;
  DateTime? _start;
  DateTime? _end;
  String? _fxGainUuid;
  String? _fxLossUuid;
  List<GeneratedPeriodSpec> _preview = const [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, 1, 1);
    _end = DateTime(now.year, 12, 31);
    _codeController.text = '${now.year}';
    _nameController.text = '${now.year}';
    WidgetsBinding.instance.addPostFrameCallback((_) => _rebuildPreview());
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _rebuildPreview() {
    if (_start == null || _end == null) {
      return;
    }
    try {
      final specs = previewFiscalPeriods(
        startDate: _start!,
        endDate: _end!,
        periodCount: _periodCount,
      );
      setState(() => _preview = specs);
    } on FiscalYearException {
      setState(() => _preview = const []);
    }
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    setState(() => _start = picked);
    _rebuildPreview();
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    setState(() => _end = picked);
    _rebuildPreview();
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    if (_start == null || _end == null || _preview.isEmpty) {
      showAppSnackBar(
        context,
        message: l10n.somethingWentWrong,
        isSuccess: false,
      );
      return;
    }
    final profile = ref.read(companyProfileProvider).valueOrNull;
    final base = profile?.defaultCurrencyCode ?? 'SAR';
    final actor = ref.read(authStateProvider).session?.user.name ?? 'local';

    setState(() => _saving = true);
    try {
      final fy = await ref.read(createFiscalYearUseCaseProvider).call(
            FiscalYearDraft(
              code: _codeController.text.trim(),
              name: _nameController.text.trim(),
              startDate: BusinessDate.utcDay(_start!),
              endDate: BusinessDate.utcDay(_end!),
              baseCurrencyCode: base,
              periodCount: _periodCount,
              periodFrequency: PeriodFrequency.monthly,
              fxRevaluationEnabled: _fxEnabled,
              fxGainAccountUuid: _fxEnabled ? _fxGainUuid : null,
              fxLossAccountUuid: _fxEnabled ? _fxLossUuid : null,
              createdBy: actor,
            ),
          );
      ref.invalidate(fiscalYearSummariesProvider);
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.accountingFiscalYearCreated,
        isSuccess: true,
      );
      context.pushReplacement(AccountingRoutes.fiscalYearDetails(fy.uuid));
    } catch (e) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, message: e.toString(), isSuccess: false);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accountsAsync = ref.watch(accountsProvider);
    final dateFmt = DateFormat.yMMMd();
    final stepTitles = [
      l10n.accountingFiscalWizardStepYear,
      l10n.accountingFiscalWizardStepPeriods,
      l10n.accountingFiscalWizardStepFx,
      l10n.accountingFiscalWizardStepPreview,
    ];

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.accountingFiscalYearCreateTitle,
        showBackButton: true,
      ),
      body: ListView(
        padding: AppConstants.pageInsets(context),
        children: [
          Text(
            stepTitles[_step],
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_step == 0) ...[
            TextField(
              controller: _codeController,
              decoration: InputDecoration(labelText: l10n.accountingFiscalYearCode),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.accountingFiscalYearName),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.accountingFiscalYearStart),
              subtitle: Text(
                _start == null ? '—' : dateFmt.format(_start!),
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickStart,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.accountingFiscalYearEnd),
              subtitle: Text(_end == null ? '—' : dateFmt.format(_end!)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickEnd,
            ),
          ] else if (_step == 1) ...[
            Text(l10n.accountingFiscalYearPeriods),
            Slider(
              value: _periodCount.toDouble(),
              min: 1,
              max: 24,
              divisions: 23,
              label: '$_periodCount',
              onChanged: (v) {
                setState(() => _periodCount = v.round());
                _rebuildPreview();
              },
            ),
            Text('$_periodCount'),
          ] else if (_step == 2) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.accountingFiscalYearFxEnabled),
              value: _fxEnabled,
              onChanged: (v) {
                setState(() {
                  _fxEnabled = v;
                  if (!v) {
                    return;
                  }
                  final accounts =
                      ref.read(accountsProvider).valueOrNull ?? const [];
                  _fxGainUuid ??= accounts
                      .where((a) => AccountLabels.systemKeyOf(a) == 'fx_gain')
                      .map((a) => a.uuid)
                      .firstOrNull;
                  _fxLossUuid ??= accounts
                      .where((a) => AccountLabels.systemKeyOf(a) == 'fx_loss')
                      .map((a) => a.uuid)
                      .firstOrNull;
                });
              },
            ),
            if (_fxEnabled)
              accountsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(e.toString()),
                data: (accounts) {
                  final posting = accounts
                      .where((a) => a.canPost)
                      .toList(growable: false);
                  final defaultGain = accounts
                      .where((a) => AccountLabels.systemKeyOf(a) == 'fx_gain')
                      .map((a) => a.uuid)
                      .firstOrNull;
                  final defaultLoss = accounts
                      .where((a) => AccountLabels.systemKeyOf(a) == 'fx_loss')
                      .map((a) => a.uuid)
                      .firstOrNull;
                  if ((_fxGainUuid == null && defaultGain != null) ||
                      (_fxLossUuid == null && defaultLoss != null)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _fxGainUuid ??= defaultGain;
                        _fxLossUuid ??= defaultLoss;
                      });
                    });
                  }
                  return Column(
                    children: [
                      AccountSearchField(
                        label: l10n.accountingFiscalYearFxGainAccount,
                        hintText: l10n.accountingSearchHint,
                        accounts: posting,
                        selectedUuid: _fxGainUuid,
                        onSelected: (account) => setState(
                          () => _fxGainUuid = account?.uuid,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AccountSearchField(
                        label: l10n.accountingFiscalYearFxLossAccount,
                        hintText: l10n.accountingSearchHint,
                        accounts: posting,
                        selectedUuid: _fxLossUuid,
                        onSelected: (account) => setState(
                          () => _fxLossUuid = account?.uuid,
                        ),
                      ),
                    ],
                  );
                },
              ),
          ] else ...[
            Text(l10n.accountingFiscalYearPreview),
            const SizedBox(height: AppSpacing.sm),
            if (_preview.isEmpty)
              Text(
                l10n.somethingWentWrong,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else
              for (final p in _preview)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text('${p.periodNumber}. ${p.name}'),
                  subtitle: Text(
                    '${dateFmt.format(p.startDate.toLocal())}'
                    ' – ${dateFmt.format(p.endDate.toLocal())}',
                  ),
                  trailing: Text(l10n.accountingPeriodStatusClosed),
                ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: AppButton(
                    label: l10n.accountingFiscalWizardBack,
                    variant: AppButtonVariant.outlined,
                    onPressed: _saving
                        ? null
                        : () => setState(() => _step -= 1),
                  ),
                ),
              if (_step > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: _step == 3
                      ? l10n.accountingFiscalWizardCreate
                      : l10n.accountingFiscalWizardNext,
                  isLoading: _saving,
                  onPressed: _saving
                      ? null
                      : () {
                          if (_step < 3) {
                            setState(() => _step += 1);
                            if (_step == 3) {
                              _rebuildPreview();
                            }
                          } else {
                            _create();
                          }
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
