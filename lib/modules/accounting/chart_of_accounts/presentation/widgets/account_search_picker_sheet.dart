import 'package:flutter/material.dart';
import 'package:stock_count/core/widgets/app_account_search_picker.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account.dart';
import 'package:stock_count/modules/accounting/chart_of_accounts/domain/entities/account_type.dart';
import 'package:stock_count/modules/accounting/shared/domain/services/account_selection_contract.dart';

/// Compatibility function delegating to canonical [showAppAccountPicker].
Future<Account?> showAccountSearchPicker(
  BuildContext context, {
  String? title,
  AccountType? initialTypeFilter,
  bool postingOnlyDefault = true,
  String? selectedUuid,
  AccountSelectionContract? contract,
}) {
  return showAppAccountPicker(
    context,
    title: title,
    initialTypeFilter: initialTypeFilter,
    postingOnlyDefault: postingOnlyDefault,
    selectedUuid: selectedUuid,
    contract: contract,
  );
}

/// Compatibility adapter delegating to canonical [AppAccountSearchPickerSheet].
class AccountSearchPickerSheet extends StatelessWidget {
  const AccountSearchPickerSheet({
    super.key,
    this.title,
    this.initialTypeFilter,
    this.postingOnlyDefault = true,
    this.selectedUuid,
    this.contract,
  });

  final String? title;
  final AccountType? initialTypeFilter;
  final bool postingOnlyDefault;
  final String? selectedUuid;
  final AccountSelectionContract? contract;

  @override
  Widget build(BuildContext context) {
    return AppAccountSearchPickerSheet(
      title: title,
      initialTypeFilter: initialTypeFilter,
      postingOnlyDefault: postingOnlyDefault,
      selectedUuid: selectedUuid,
      contract: contract,
    );
  }
}

/// Compatibility adapter delegating to canonical [AppAccountSearchPicker].
class AccountSearchPicker extends StatelessWidget {
  const AccountSearchPicker({
    super.key,
    this.initialTypeFilter,
    this.postingOnlyDefault = false,
    this.selectedUuid,
    this.onAccountSelected,
    this.contract,
  });

  final AccountType? initialTypeFilter;
  final bool postingOnlyDefault;
  final String? selectedUuid;
  final ValueChanged<Account>? onAccountSelected;
  final AccountSelectionContract? contract;

  @override
  Widget build(BuildContext context) {
    return AppAccountSearchPicker(
      initialTypeFilter: initialTypeFilter,
      postingOnlyDefault: postingOnlyDefault,
      selectedUuid: selectedUuid,
      onAccountSelected: onAccountSelected,
      contract: contract,
    );
  }
}
