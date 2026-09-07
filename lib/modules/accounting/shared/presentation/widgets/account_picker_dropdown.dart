import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/services/account_labels.dart';
import '../../domain/services/account_mapping_resolver.dart';
import '../../domain/services/account_selection_contract.dart';
import '../providers/account_selection_providers.dart';

/// Canonical Dropdown presentation surface for Account selection.
class AccountPickerDropdown extends ConsumerWidget {
  const AccountPickerDropdown({
    super.key,
    required this.label,
    this.role,
    this.contract,
    this.selectedUuid,
    this.onChanged,
  });

  final String label;
  final AccountRole? role;
  final AccountSelectionContract? contract;
  final String? selectedUuid;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final effectiveContract =
        contract ??
        AccountSelectionContract(postingOnly: true, selectedUuid: selectedUuid);

    final accountsAsync = ref.watch(
      filteredAccountsProvider((
        contract: effectiveContract,
        query: '',
        activeTypeFilter: null,
        activePostingOnly: null,
      )),
    );

    return accountsAsync.when(
      data: (eligibleAccounts) {
        final currentSelection =
            eligibleAccounts.any((a) => a.uuid == selectedUuid)
            ? selectedUuid
            : null;

        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: currentSelection,
              hint: Text(l10n.accountingSearchHint),
              items: eligibleAccounts.map((account) {
                return DropdownMenuItem<String>(
                  value: account.uuid,
                  child: Text(
                    '${account.accountCode} - ${AccountLabels.displayName(l10n, account)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Text(
        '${l10n.accountSearchNotAvailable}: $err',
        style: TextStyle(color: theme.colorScheme.error),
      ),
    );
  }
}
