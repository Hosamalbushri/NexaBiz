import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/presentation/providers/dashboard_services_provider.dart';
import 'package:stock_count/app/settings/widgets/settings_chrome.dart';
import 'package:stock_count/core/widgets/app_snackbar.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import 'package:stock_count/modules/accounting/journals/presentation/providers/journal_providers.dart';

/// Accounting module settings bundle (embedded in the Settings module hub).
class AccountingSettingsPanel extends ConsumerWidget {
  const AccountingSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final closedAsync = ref.watch(accountingFiscalClosedThroughProvider);
    final closed = closedAsync.valueOrNull;
    final dateFormat = DateFormat.yMMMd();

    return Column(
      children: [
        SettingsSubSection(
          title: l10n.accountingChartOfAccounts,
          subtitle: 'إعدادات وإدارة دليل الحسابات الافتراضي',
          child: Consumer(
            builder: (context, ref, _) {
              final accountsAsync = ref.watch(accountsProvider);
              final accounts = accountsAsync.valueOrNull ?? const [];
              final isEmpty = accounts.isEmpty;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('دليل الحسابات الافتراضي'),
                subtitle: Text(
                  isEmpty
                      ? 'دليل الحسابات فارغ حالياً'
                      : 'تم إنشاء دليل الحسابات (إجمالي ${accounts.length} حساب)',
                ),
                trailing: ElevatedButton.icon(
                  onPressed: accountsAsync.isLoading
                      ? null
                      : () async {
                          final repo = ref.read(accountRepositoryProvider);
                          await repo.seedDefaultChart();
                          ref.invalidate(accountsProvider);
                          if (context.mounted) {
                            showAppSnackBar(
                              context,
                              message: 'تم توليد دليل الحسابات الافتراضي بنجاح',
                              isSuccess: true,
                            );
                          }
                        },
                  icon: const Icon(Icons.account_tree_outlined),
                  label: Text(isEmpty ? 'توليد الدليل' : 'إعادة محاذاة الدليل'),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SettingsSubSection(
          title: l10n.accountingFiscalClosedSectionTitle,
          subtitle:
              '${l10n.accountingFiscalClosedSectionSubtitle} '
              '${l10n.accountingFiscalYearsSubtitle}',
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.accountingFiscalClosedThroughLabel),
                subtitle: Text(
                  closed == null
                      ? l10n.accountingFiscalClosedNone
                      : dateFormat.format(closed.toLocal()),
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: closedAsync.isLoading
                    ? null
                    : () => _pickClosedThrough(context, ref, closed),
              ),
              if (closed != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => _saveClosedThrough(context, ref, null),
                    child: Text(l10n.accountingFiscalClosedClear),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickClosedThrough(
    BuildContext context,
    WidgetRef ref,
    DateTime? current,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current?.toLocal() ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !context.mounted) {
      return;
    }
    await _saveClosedThrough(context, ref, picked);
  }

  Future<void> _saveClosedThrough(
    BuildContext context,
    WidgetRef ref,
    DateTime? day,
  ) async {
    final l10n = AppLocalizations.of(context);
    await ref
        .read(settingsRepositoryProvider)
        .saveAccountingFiscalClosedThrough(day);
    ref.invalidate(accountingFiscalClosedThroughProvider);
    if (!context.mounted) {
      return;
    }
    showAppSnackBar(
      context,
      message: l10n.accountingFiscalClosedSavedSuccess,
      isSuccess: true,
    );
  }
}
