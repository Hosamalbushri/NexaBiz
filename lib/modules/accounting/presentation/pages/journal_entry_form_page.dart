import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/settings/company/company_profile_providers.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/models/journal_exception.dart';
import '../../domain/services/account_labels.dart';
import '../../domain/services/journal_money.dart';
import '../providers/account_providers.dart';
import '../providers/journal_providers.dart';
import '../widgets/journal_exception_messages.dart';
import 'accounting_routes.dart';

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
  final debitController = TextEditingController();
  final creditController = TextEditingController();

  void dispose() {
    debitController.dispose();
    creditController.dispose();
  }
}

class _JournalEntryFormPageState extends ConsumerState<JournalEntryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _voucherController = TextEditingController();
  final _descriptionController = TextEditingController();
  var _entryDate = DateTime.now();
  var _currencyCode = 'SAR';
  var _isPosted = true;
  var _saving = false;
  var _hydrated = false;
  final _lines = <_LineForm>[_LineForm(), _LineForm()];

  @override
  void dispose() {
    _voucherController.dispose();
    _descriptionController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
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
    _isPosted = entry.isPosted;
    for (final line in _lines) {
      line.dispose();
    }
    _lines
      ..clear()
      ..addAll([
        for (final line in entry.lines)
          _LineForm()
            ..accountUuid = line.accountUuid
            ..debitController.text = line.debit > 0
                ? line.debit.toStringAsFixed(2)
                : ''
            ..creditController.text = line.credit > 0
                ? line.credit.toStringAsFixed(2)
                : '',
      ]);
    if (_lines.length < 2) {
      _lines.add(_LineForm());
    }
    _hydrated = true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(companyProfileProvider).valueOrNull;
    if (!_hydrated && !widget.isEditing) {
      _currencyCode = profile?.defaultCurrencyCode ?? _currencyCode;
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

    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.isEditing
            ? l10n.accountingJournalEdit
            : l10n.accountingJournalAdd,
        showBackButton: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppConstants.pageInsets(context),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.accountingJournalFieldDate),
              subtitle: Text(
                MaterialLocalizations.of(context).formatMediumDate(_entryDate),
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
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _voucherController,
              decoration: InputDecoration(
                labelText: l10n.accountingJournalFieldVoucherNumber,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.accountingJournalFieldVoucherNumber;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.accountingJournalFieldDescription,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              initialValue: _currencyCode,
              decoration: InputDecoration(
                labelText: l10n.accountingJournalFieldCurrency,
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) => _currencyCode = value.trim().toUpperCase(),
              validator: (value) {
                if (value == null || value.trim().length < 3) {
                  return l10n.accountingJournalFieldCurrency;
                }
                return null;
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.accountingJournalPosted),
              value: _isPosted,
              onChanged: (value) => setState(() => _isPosted = value),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.accountingJournalLines,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            accountsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Text(l10n.somethingWentWrong),
              data: (accounts) {
                final posting = [
                  for (final a in accounts)
                    if (a.isPostingAccount && a.isActive && !a.isDeleted) a,
                ];
                return Column(
                  children: [
                    for (var i = 0; i < _lines.length; i++) ...[
                      _buildLineEditor(l10n, posting, i),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                );
              },
            ),
            TextButton.icon(
              onPressed: () => setState(() => _lines.add(_LineForm())),
              icon: const Icon(Icons.add),
              label: Text(l10n.accountingJournalAddLine),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: l10n.accountingJournalSave,
              expand: true,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineEditor(
    AppLocalizations l10n,
    List<Account> posting,
    int index,
  ) {
    final line = _lines[index];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: line.accountUuid,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.accountingJournalAccount,
              ),
              items: [
                for (final account in posting)
                  DropdownMenuItem(
                    value: account.uuid,
                    child: Text(
                      '${account.accountCode} — ${AccountLabels.displayName(l10n, account)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => line.accountUuid = value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.accountingJournalPickAccount;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: line.debitController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.accountingJournalDebit,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: line.creditController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.accountingJournalCredit,
                    ),
                  ),
                ),
                if (_lines.length > 2)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _lines.removeAt(index).dispose();
                      });
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
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
      final debit = JournalMoney.clampNonNegative(
        double.tryParse(line.debitController.text.trim()) ?? 0,
      );
      final credit = JournalMoney.clampNonNegative(
        double.tryParse(line.creditController.text.trim()) ?? 0,
      );
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
      context.go(AccountingRoutes.journalDetails(saved.uuid));
    } on JournalException catch (e) {
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
