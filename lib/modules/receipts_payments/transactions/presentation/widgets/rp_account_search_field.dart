import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/widgets/app_async_autocomplete_field.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_treasury_account_port.dart';
import '../providers/rp_providers.dart';

const _kDebounceMs = 300;
const _kMinQueryLength = 1;
const _kResultLimit = 50;

String rpCashAccountDisplayName(AppLocalizations l10n, RpAccountRef account) {
  final key = account.systemKey?.trim();
  return switch (key) {
    'cash' => l10n.accountingAccountCash,
    'bank' => l10n.accountingAccountBank,
    'petty_cash' => l10n.accountingAccountPettyCash,
    _ => account.name,
  };
}

String rpCashAccountLabel(AppLocalizations l10n, RpAccountRef account) {
  final name = rpCashAccountDisplayName(l10n, account);
  final code = account.code.trim();
  if (code.isEmpty) {
    return name;
  }
  return '$code — $name';
}

String _cashAccountLabel(AppLocalizations l10n, RpAccountRef account) =>
    rpCashAccountLabel(l10n, account);

/// Dropdown of cash/bank treasury accounts (صناديق).
class RpCashAccountDropdown extends ConsumerStatefulWidget {
  const RpCashAccountDropdown({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.hintText,
    this.showSelectedNameBelow = false,
  });

  final String label;
  final RpAccountRef? selected;
  final ValueChanged<RpAccountRef?> onSelected;
  final String? hintText;

  /// When true, the field shows the account code and the localized name
  /// appears as helper text underneath.
  final bool showSelectedNameBelow;

  @override
  ConsumerState<RpCashAccountDropdown> createState() =>
      _RpCashAccountDropdownState();
}

class _RpCashAccountDropdownState
    extends ConsumerState<RpCashAccountDropdown> {
  var _loading = true;
  List<RpAccountRef> _accounts = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    try {
      final languageCode = Localizations.localeOf(context).languageCode;
      final accounts = await ref
          .read(rpTreasuryAccountPortProvider)
          .listCashBoxAccounts(languageCode: languageCode);
      if (!mounted) {
        return;
      }
      setState(() {
        _accounts = accounts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _accounts = const [];
        _loading = false;
      });
    }
  }

  List<RpAccountRef> _itemsForDropdown() {
    final selected = widget.selected;
    if (selected == null) {
      return _accounts;
    }
    final exists = _accounts.any((a) => a.accountId == selected.accountId);
    if (exists) {
      return _accounts;
    }
    return [selected, ..._accounts];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final items = _itemsForDropdown();
    final selectedId = widget.selected?.accountId;
    RpAccountRef? value;
    if (selectedId != null) {
      for (final account in items) {
        if (account.accountId == selectedId) {
          value = account;
          break;
        }
      }
    }

    if (_loading) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(
            Icons.account_balance_wallet_outlined,
            color: scheme.primary,
          ),
        ),
        child: const SizedBox(
          height: 24,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(
            Icons.account_balance_wallet_outlined,
            color: scheme.primary,
          ),
        ),
        child: Text(
          l10n.salesCashAccountEmpty,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      );
    }

    final field = DropdownButtonFormField<RpAccountRef>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        prefixIcon: Icon(
          Icons.account_balance_wallet_outlined,
          color: scheme.primary,
        ),
      ),
      items: [
        for (final account in items)
          DropdownMenuItem<RpAccountRef>(
            value: account,
            child: Text(
              _cashAccountLabel(l10n, account),
              softWrap: true,
            ),
          ),
      ],
      selectedItemBuilder: (context) {
        return [
          for (final account in items)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                widget.showSelectedNameBelow
                    ? (account.code.trim().isEmpty
                        ? rpCashAccountDisplayName(l10n, account)
                        : account.code.trim())
                    : _cashAccountLabel(l10n, account),
                softWrap: true,
              ),
            ),
        ];
      },
      onChanged: widget.onSelected,
    );

    if (!widget.showSelectedNameBelow || value == null) {
      return field;
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field,
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 12),
          child: Text(
            rpCashAccountDisplayName(l10n, value),
            softWrap: true,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Searchable posting account field (counter account), built using [AppAsyncAutocompleteField].
class RpCounterAccountSearchField extends ConsumerStatefulWidget {
  const RpCounterAccountSearchField({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.hintText,
  });

  final String label;
  final RpAccountRef? selected;
  final ValueChanged<RpAccountRef?> onSelected;
  final String? hintText;

  @override
  ConsumerState<RpCounterAccountSearchField> createState() =>
      _RpCounterAccountSearchFieldState();
}

class _RpCounterAccountSearchFieldState
    extends ConsumerState<RpCounterAccountSearchField> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode(skipTraversal: true);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _display(widget.selected));
  }

  @override
  void didUpdateWidget(covariant RpCounterAccountSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected?.accountId != oldWidget.selected?.accountId) {
      _controller.text = _display(widget.selected);
    }
  }

  String _display(RpAccountRef? account) {
    if (account == null) {
      return '';
    }
    final code = account.code.trim();
    if (code.isNotEmpty) {
      return '$code — ${account.name}';
    }
    return account.name;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<List<RpAccountRef>> _search(String query) async {
    final languageCode = Localizations.localeOf(context).languageCode;
    return ref.read(rpTreasuryAccountPortProvider).searchPostingAccounts(
          query,
          limit: _kResultLimit,
          languageCode: languageCode,
        );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppAsyncAutocompleteField<RpAccountRef>(
      controller: _controller,
      focusNode: _focusNode,
      label: widget.label,
      showLabelAbove: true,
      hint: widget.hintText,
      minQueryLength: _kMinQueryLength,
      debounceDuration: const Duration(milliseconds: _kDebounceMs),
      prefixIcon: Icon(Icons.account_tree_outlined, color: scheme.primary),
      fetchOptions: _search,
      itemLabelBuilder: _display,
      onSelected: (account) => widget.onSelected(account),
      onQueryChanged: (raw) {
        if (raw.trim().length < _kMinQueryLength) {
          widget.onSelected(null);
        }
      },
      itemBuilder: (context, account) {
        return ListTile(
          dense: true,
          title: Text(_display(account)),
        );
      },
    );
  }
}

