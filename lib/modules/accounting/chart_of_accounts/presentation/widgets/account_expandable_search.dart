import 'package:flutter/material.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/widgets/app_expandable_search_bar.dart';

/// In-page expandable search for Chart of Accounts, built on [AppExpandableSearchBar].
class AccountExpandableSearch extends StatelessWidget {
  const AccountExpandableSearch({
    super.key,
    required this.expanded,
    required this.onExpandedChanged,
    required this.onQueryChanged,
    this.controller,
    this.focusNode,
  });

  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final ValueChanged<String> onQueryChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppExpandableSearchBar(
      expanded: expanded,
      onExpandedChanged: onExpandedChanged,
      onChanged: onQueryChanged,
      controller: controller,
      focusNode: focusNode,
      hint: l10n.accountingSearchHint,
    );
  }
}
