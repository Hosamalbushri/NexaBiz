import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/settings/widgets/settings_chrome.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/accounting_mode.dart';
import '../providers/accounting_mode_providers.dart';

/// Accounting module settings bundle (embedded in platform Settings).
class AccountingSettingsPanel extends ConsumerWidget {
  const AccountingSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final modeAsync = ref.watch(accountingModeProvider);
    final mode = modeAsync.valueOrNull ?? AccountingMode.standalone;

    return SettingsSubSection(
      title: l10n.accountingModeSectionTitle,
      subtitle: l10n.accountingModeSectionSubtitle,
      child: Column(
        children: [
          RadioListTile<AccountingMode>(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.accountingModeStandalone),
            subtitle: Text(l10n.accountingModeStandaloneDescription),
            value: AccountingMode.standalone,
            groupValue: mode,
            onChanged: modeAsync.isLoading
                ? null
                : (value) => _onChanged(context, ref, value),
          ),
          RadioListTile<AccountingMode>(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.accountingModeIntegrated),
            subtitle: Text(l10n.accountingModeIntegratedDescription),
            value: AccountingMode.integrated,
            groupValue: mode,
            onChanged: modeAsync.isLoading
                ? null
                : (value) => _onChanged(context, ref, value),
          ),
        ],
      ),
    );
  }

  Future<void> _onChanged(
    BuildContext context,
    WidgetRef ref,
    AccountingMode? value,
  ) async {
    if (value == null) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    await ref.read(accountingModeProvider.notifier).setMode(value);
    if (!context.mounted) {
      return;
    }
    showAppSnackBar(
      context,
      message: l10n.accountingModeSavedSuccess,
      isSuccess: true,
    );
  }
}
