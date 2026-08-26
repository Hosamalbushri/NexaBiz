import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/utils/digit_normalization.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_treasury_account_port.dart';
import '../providers/rp_providers.dart';

const _kDebounceMs = 300;
const _kMinQueryLength = 1;
const _kResultLimit = 50;

final class _SearchSession {
  Timer? _debounce;
  var _token = 0;

  void schedule(void Function(int token) run) {
    _debounce?.cancel();
    final token = ++_token;
    _debounce = Timer(const Duration(milliseconds: _kDebounceMs), () {
      run(token);
    });
  }

  void invalidate() {
    _debounce?.cancel();
    _token++;
  }

  bool isCurrent(int token) => token == _token;

  void dispose() {
    _debounce?.cancel();
  }
}

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
      value: value,
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

/// Searchable posting account field (counter account).
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
  final _session = _SearchSession();
  var _loading = false;
  var _showResults = false;
  List<RpAccountRef> _results = const [];

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
    _session.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String query, int token) async {
    try {
      final languageCode = Localizations.localeOf(context).languageCode;
      final results = await ref
          .read(rpTreasuryAccountPortProvider)
          .searchPostingAccounts(
            query,
            limit: _kResultLimit,
            languageCode: languageCode,
          );
      if (!mounted || !_session.isCurrent(token)) {
        return;
      }
      setState(() {
        _results = results;
        _loading = false;
        _showResults = true;
      });
    } catch (_) {
      if (!mounted || !_session.isCurrent(token)) {
        return;
      }
      setState(() {
        _results = const [];
        _loading = false;
        _showResults = true;
      });
    }
  }

  void _onChanged(String value) {
    widget.onSelected(null);
    final query = normalizeDigitsToWestern(value).trim();
    if (query.length < _kMinQueryLength) {
      _session.invalidate();
      setState(() {
        _results = const [];
        _loading = false;
        _showResults = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _showResults = true;
    });
    _session.schedule((token) => _search(query, token));
  }

  void _select(RpAccountRef account) {
    widget.onSelected(account);
    _controller.text = _display(account);
    setState(() {
      _results = const [];
      _loading = false;
      _showResults = false;
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          inputFormatters: const [WesternDigitsInputFormatter()],
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: scheme.surface,
            hintText: widget.hintText,
            prefixIcon:
                Icon(Icons.account_tree_outlined, color: scheme.primary),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          onChanged: _onChanged,
        ),
        if (_showResults && _results.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          _ResultsList(
            results: _results,
            onSelect: _select,
            labelBuilder: _display,
          ),
        ],
      ],
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.results,
    required this.onSelect,
    required this.labelBuilder,
  });

  final List<RpAccountRef> results;
  final ValueChanged<RpAccountRef> onSelect;
  final String Function(RpAccountRef) labelBuilder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 180),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: results.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
          itemBuilder: (context, index) {
            final account = results[index];
            return ListTile(
              dense: true,
              title: Text(labelBuilder(account)),
              onTap: () => onSelect(account),
            );
          },
        ),
      ),
    );
  }
}
