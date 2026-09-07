import 'package:flutter/material.dart';
import 'package:stock_count/core/widgets/app_account_search_picker.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_selection_contract.dart';
import '../../domain/entities/account.dart';

/// Compatibility adapter for legacy [AccountSearchField] delegating to [AppAccountInlineSearchField].
class AccountSearchField extends StatelessWidget {
  const AccountSearchField({
    super.key,
    required this.label,
    required this.accounts,
    required this.selectedUuid,
    required this.onSelected,
    this.hintText,
    this.contract,
  });

  final String label;
  final List<Account> accounts;
  final String? selectedUuid;
  final ValueChanged<Account?> onSelected;
  final String? hintText;
  final AccountSelectionContract? contract;

  @override
  Widget build(BuildContext context) {
    return AppAccountInlineSearchField(
      hintText: hintText ?? label,
      contract:
          contract ?? AccountSelectionContract(selectedUuid: selectedUuid),
      onAccountSelected: (account) => onSelected(account),
    );
  }
}
