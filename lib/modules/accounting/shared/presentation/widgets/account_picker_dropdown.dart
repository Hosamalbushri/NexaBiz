import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/presentation/providers/account_providers.dart';
import '../../domain/services/account_mapping_resolver.dart';

class AccountPickerDropdown extends ConsumerWidget {
  const AccountPickerDropdown({
    super.key,
    required this.label,
    required this.role,
    this.selectedUuid,
    this.onChanged,
  });

  final String label;
  final AccountRole role;
  final String? selectedUuid;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final theme = Theme.of(context);

    return accountsAsync.when(
      data: (accounts) {
        final leafAccounts = accounts
            .where((a) => a.isPostingAccount && a.isActive && !a.isDeleted)
            .toList();

        final currentSelection = leafAccounts.any((a) => a.uuid == selectedUuid)
            ? selectedUuid
            : null;

        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: currentSelection,
              hint: const Text('اختر حساباً من الدليل...'),
              items: leafAccounts.map((account) {
                return DropdownMenuItem<String>(
                  value: account.uuid,
                  child: Text(
                    '${account.accountCode} - ${account.name}',
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
        'خطأ في تحميل الحسابات: $err',
        style: TextStyle(color: theme.colorScheme.error),
      ),
    );
  }
}
