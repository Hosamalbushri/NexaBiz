import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';

import 'package:stock_count/app/exit/app_exit_scope.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/settings/company/functional_currency_providers.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_amount_field.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/models/journal_exception.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/account_labels.dart';
import '../../domain/services/journal_money.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import '../providers/journal_providers.dart';
import '../widgets/journal_exception_messages.dart';
import 'package:stock_count/modules/accounting/shared/presentation/pages/accounting_routes.dart';

/// Create / edit a manual journal entry (business rules via posting service).
class JournalEntryFormPage extends ConsumerStatefulWidget {
  const JournalEntryFormPage({super.key, this.entryUuid});

  final String? entryUuid;

  bool get isEditing => entryUuid != null && entryUuid!.isNotEmpty;

  @override
  ConsumerState<JournalEntryFormPage> createState() =>
      _JournalEntryFormPageState();
}

class _LineForm {
  String? accountUuid;
  double debit = 0;
  double credit = 0;
}

class _JournalEntryFormPageState extends ConsumerState<JournalEntryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _voucherController = TextEditingController();
  final _descriptionController = TextEditingController();
  var _entryDate = DateTime.now();
  var _currencyCode = 'SAR';
  final _currencyController = TextEditingController(text: 'SAR');
  var _isPosted = true;
  var _saving = false;
  var _hydrated = false;
  final _lines = <_LineForm>[_LineForm(), _LineForm()];

  @override
  void dispose() {
    _voucherController.dispose();
    _descriptionController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  void _hydrate(JournalEntry entry) {
    if (_hydrated) {
      return;
    }
    _voucherController.text = entry.voucherNumber;
    _descriptionController.text = entry.description ?? '';
    _entryDate = entry.entryDate.toLocal();
    _currencyCode = entry.currencyCode;
    _currencyController.text = entry.currencyCode;
    _isPosted = entry.isPosted;
    _lines
      ..clear()
      ..addAll([
        for (final line in entry.lines)
          _LineForm()
            ..accountUuid = line.accountUuid
            ..debit = line.debit > 0 ? line.debit : 0
            ..credit = line.credit > 0 ? line.credit : 0,
      ]);
    if (_lines.length < 2) {
      _lines.add(_LineForm());
    }
    _hydrated = true;
  }

  bool _hasUnsavedChanges() {
    if (_saving) return false;
    return _voucherController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _lines.any((l) => l.accountUuid != null || l.debit > 0 || l.credit > 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currencyInfo = ref.watch(functionalCurrencyStateInfoProvider);
    final defaultCurrency = currencyInfo.valueOrNull?.currencyCode;
    if (!_hydrated && !widget.isEditing) {
      if (defaultCurrency != null && defaultCurrency.isNotEmpty) {
        _currencyCode = defaultCurrency;
        _currencyController.text = defaultCurrency;
      }
      _hydrated = true;
    }

    if (widget.isEditing) {
      final async = ref.watch(journalEntryByUuidProvider(widget.entryUuid!));
      async.whenData((entry) {
        if (entry != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _hydrate(entry));
            }
          });
        }
      });
    }

    return UnsavedChangesScope(
      hasUnsavedChanges: _hasUnsavedChanges,
      child: AppFormPage(
        title: widget.isEditing
            ? l10n.accountingJournalEdit
            : l10n.accountingJournalAdd,
        formKey: _formKey,
        onSubmit: _saving ? null : _save,
        submitLabel: l10n.accountingJournalSave,
        isLoading: _saving,
        showBackButton: true,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppResponsiveForm(
              maxColumns: 2,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.accountingJournalFieldDate),
                  subtitle: Text(
                    MaterialLocalizations.of(
                      context,
                    ).formatMediumDate(_entryDate),
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _entryDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _entryDate = picked);
                    }
                  },
                ),
                AppTextField(
                  controller: _voucherController,
                  label: l10n.accountingJournalFieldVoucherNumber,
                  required: true,
                ),
                AppTextField(
                  controller: _descriptionController,
                  label: l10n.accountingJournalFieldDescription,
                  maxLines: 2,
                ),
                AppTextField(
                  controller: _currencyController,
                  label: l10n.accountingJournalFieldCurrency,
                  required: true,
                  onChanged: (value) =>
                      _currencyCode = value.trim().toUpperCase(),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.accountingJournalPosted),
              value: _isPosted,
              onChanged: (value) => setState(() => _isPosted = value),
            ),
            const SizedBox(height: AppSpacing.md),
            _JournalLinesSection(lines: _lines),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final drafts = <JournalLineDraft>[];
    for (final line in _lines) {
      final debit = JournalMoney.clampNonNegative(line.debit);
      final credit = JournalMoney.clampNonNegative(line.credit);
      if (debit == 0 && credit == 0) {
        continue;
      }
      if (line.accountUuid == null) {
        showAppSnackBar(
          context,
          message: l10n.accountingJournalPickAccount,
          isSuccess: false,
        );
        return;
      }
      drafts.add(
        JournalLineDraft(
          accountUuid: line.accountUuid!,
          debit: debit,
          credit: credit,
          currencyCode: _currencyCode,
        ),
      );
    }
    if (drafts.length < 2) {
      showAppSnackBar(
        context,
        message: l10n.accountingJournalErrorLines,
        isSuccess: false,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(postJournalEntryUseCaseProvider)
          .call(
            JournalEntryDraft(
              uuid: widget.isEditing ? widget.entryUuid : null,
              entryDate: _entryDate,
              voucherNumber: _voucherController.text.trim(),
              voucherType: l10n.accountingJournalManualType,
              currencyCode: _currencyCode,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              isPosted: _isPosted,
              lines: drafts,
            ),
          );
      ref.invalidate(journalEntriesProvider);
      ref.invalidate(journalEntryByUuidProvider(saved.uuid));
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: l10n.accountingJournalSavedSuccess,
        isSuccess: true,
      );
      if (widget.isEditing) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AccountingRoutes.journalDetails(saved.uuid));
        }
      } else {
        context.replace(AccountingRoutes.journalDetails(saved.uuid));
      }
    } on JournalException catch (e) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: journalExceptionMessage(l10n, e),
        isSuccess: false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        message: journalExceptionMessage(l10n, e),
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _JournalLinesSection extends ConsumerStatefulWidget {
  const _JournalLinesSection({required this.lines});

  final List<_LineForm> lines;

  @override
  ConsumerState<_JournalLinesSection> createState() =>
      __JournalLinesSectionState();
}

class __JournalLinesSectionState extends ConsumerState<_JournalLinesSection> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accountsAsync = ref.watch(accountsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountingJournalLines,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        accountsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => AppErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(accountsProvider),
          ),
          data: (accounts) {
            final posting = [
              for (final a in accounts)
                if (a.isPostingAccount && a.isActive && !a.isDeleted) a,
            ];
            return Column(
              children: [
                for (var i = 0; i < widget.lines.length; i++) ...[
                  _buildLineEditor(l10n, posting, i),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          label: l10n.accountingJournalAddLine,
          icon: Icons.add,
          variant: AppButtonVariant.outlined,
          onPressed: () => setState(() => widget.lines.add(_LineForm())),
        ),
      ],
    );
  }

  Widget _buildLineEditor(
    AppLocalizations l10n,
    List<Account> posting,
    int index,
  ) {
    final line = widget.lines[index];
    final mediaWidth = MediaQuery.of(context).size.width;
    final isCompact = mediaWidth < 500;

    return AppSurface(
      variant: AppSurfaceVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppSelectField<String?>(
                  value: line.accountUuid,
                  label: l10n.accountingJournalAccount,
                  required: true,
                  items: [
                    for (final account in posting)
                      AppSelectItem<String?>(
                        value: account.id,
                        label:
                            '${account.accountCode} — ${AccountLabels.displayName(l10n, account)}',
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => line.accountUuid = value),
                ),
              ),
              if (widget.lines.length > 2) ...[
                const SizedBox(width: AppSpacing.xs),
                AppIconButton(
                  icon: Icons.delete_outline,
                  color: Colors.red,
                  tooltip: l10n.localeName == 'ar'
                      ? 'حذف السطر'
                      : 'Delete line',
                  onPressed: () {
                    setState(() {
                      widget.lines.removeAt(index);
                    });
                  },
                ),
              ],
            ],
          ),
            const SizedBox(height: AppSpacing.sm),
            if (isCompact) ...[
              AppAmountField(
                value: line.debit,
                label: l10n.accountingJournalDebit,
                emptyWhenZero: true,
                onChanged: (value) => setState(() {
                  line.debit = value;
                  if (value > 0) {
                    line.credit = 0;
                  }
                }),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppAmountField(
                value: line.credit,
                label: l10n.accountingJournalCredit,
                emptyWhenZero: true,
                onChanged: (value) => setState(() {
                  line.credit = value;
                  if (value > 0) {
                    line.debit = 0;
                  }
                }),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: AppAmountField(
                      value: line.debit,
                      label: l10n.accountingJournalDebit,
                      emptyWhenZero: true,
                      onChanged: (value) => setState(() {
                        line.debit = value;
                        if (value > 0) {
                          line.credit = 0;
                        }
                      }),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppAmountField(
                      value: line.credit,
                      label: l10n.accountingJournalCredit,
                      emptyWhenZero: true,
                      onChanged: (value) => setState(() {
                        line.credit = value;
                        if (value > 0) {
                          line.debit = 0;
                        }
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
  }
}
