import 'package:flutter/material.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/widgets/app_async_autocomplete_field.dart';
import '../../domain/entities/account.dart';
import '../../domain/services/account_labels.dart';

const _kResultLimit = 50;

/// Searchable account picker (code / name), built using [AppAsyncAutocompleteField].
class AccountSearchField extends StatefulWidget {
  const AccountSearchField({
    super.key,
    required this.label,
    required this.accounts,
    required this.selectedUuid,
    required this.onSelected,
    this.hintText,
  });

  final String label;
  final List<Account> accounts;
  final String? selectedUuid;
  final ValueChanged<Account?> onSelected;
  final String? hintText;

  @override
  State<AccountSearchField> createState() => _AccountSearchFieldState();
}

class _AccountSearchFieldState extends State<AccountSearchField> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode(skipTraversal: true);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _display(_selectedAccount()));
  }

  @override
  void didUpdateWidget(covariant AccountSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedUuid != oldWidget.selectedUuid ||
        widget.accounts != oldWidget.accounts) {
      if (!_focusNode.hasFocus) {
        final text = _display(_selectedAccount());
        if (_controller.text != text) {
          _controller.text = text;
        }
      }
    }
  }

  Account? _selectedAccount() {
    final uuid = widget.selectedUuid;
    if (uuid == null) {
      return null;
    }
    for (final account in widget.accounts) {
      if (account.uuid == uuid) {
        return account;
      }
    }
    return null;
  }

  String _display(Account? account) {
    if (account == null) {
      return '';
    }
    final l10n = AppLocalizations.of(context);
    return '${account.accountCode} — ${AccountLabels.displayName(l10n, account)}';
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Account> _fetchOptions(String query) {
    if (query.isEmpty) {
      return const [];
    }
    final l10n = AppLocalizations.of(context);
    final matches = <Account>[];
    for (final account in widget.accounts) {
      if (!AccountLabels.matchesQuery(l10n, account, query)) {
        continue;
      }
      matches.add(account);
      if (matches.length >= _kResultLimit) {
        break;
      }
    }
    return matches;
  }

  void _clear() {
    widget.onSelected(null);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasSelection = widget.selectedUuid != null;

    return AppAsyncAutocompleteField<Account>(
      controller: _controller,
      focusNode: _focusNode,
      label: widget.label,
      showLabelAbove: true,
      hint: widget.hintText ?? l10n.accountingSearchHint,
      minQueryLength: 1,
      debounceDuration: Duration.zero,
      fetchOptions: (query) => _fetchOptions(query),
      itemLabelBuilder: (account) => _display(account),
      onSelected: (account) {
        if (account == null) {
          widget.onSelected(null);
        } else {
          widget.onSelected(account);
        }
      },
      onQueryChanged: (raw) {
        if (raw.isEmpty) {
          widget.onSelected(null);
        }
      },
      suffixIcon: hasSelection || _controller.text.isNotEmpty
          ? IconButton(
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              onPressed: _clear,
              icon: const Icon(Icons.clear),
            )
          : null,
      noResultsText: l10n.accountingNoSearchResults,
      itemBuilder: (context, account) {
        return ListTile(
          dense: true,
          title: Text(
            _display(account),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}

