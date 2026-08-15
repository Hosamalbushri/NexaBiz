import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/presentation/providers/dashboard_services_provider.dart';
import '../../../../app/settings/widgets/settings_chrome.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../providers/journal_providers.dart';

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
          title: l10n.accountingFiscalClosedSectionTitle,
          subtitle: l10n.accountingFiscalClosedSectionSubtitle,
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
