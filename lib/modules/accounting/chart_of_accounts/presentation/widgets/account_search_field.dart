import 'package:flutter/material.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_radius.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/utils/digit_normalization.dart';
import '../../domain/entities/account.dart';
import '../../domain/services/account_labels.dart';

const _kResultLimit = 50;

/// Searchable account picker (code / name), similar to R&P counter search.
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
  var _showResults = false;
  List<Account> _results = const [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncControllerFromSelection();
    });
  }

  @override
  void didUpdateWidget(covariant AccountSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedUuid != oldWidget.selectedUuid ||
        widget.accounts != oldWidget.accounts) {
      if (!_focusNode.hasFocus) {
        _syncControllerFromSelection();
      }
    }
  }

  void _syncControllerFromSelection() {
    final next = _display(_selectedAccount());
    if (_controller.text != next) {
      _controller.text = next;
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

  void _onChanged(String value) {
    widget.onSelected(null);
    final query = normalizeDigitsToWestern(value).trim();
    final l10n = AppLocalizations.of(context);
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _showResults = false;
      });
      return;
    }
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
    setState(() {
      _results = matches;
      _showResults = true;
    });
  }

  void _select(Account account) {
    widget.onSelected(account);
    _controller.text = _display(account);
    setState(() {
      _results = const [];
      _showResults = false;
    });
    _focusNode.unfocus();
  }

  void _clear() {
    widget.onSelected(null);
    _controller.clear();
    setState(() {
      _results = const [];
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final hasSelection = widget.selectedUuid != null;

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
            hintText: widget.hintText ?? l10n.accountingSearchHint,
            prefixIcon: Icon(
              Icons.search,
              color: scheme.primary,
            ),
            suffixIcon: hasSelection || _controller.text.isNotEmpty
                ? IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).deleteButtonTooltip,
                    onPressed: _clear,
                    icon: const Icon(Icons.clear),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          onChanged: _onChanged,
          onTap: () {
            if (_controller.text.trim().isNotEmpty &&
                widget.selectedUuid == null) {
              _onChanged(_controller.text);
            }
          },
        ),
        if (_showResults) ...[
          const SizedBox(height: AppSpacing.xs),
          if (_results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                l10n.accountingNoSearchResults,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Material(
              color: scheme.surface,
              elevation: 2,
              borderRadius: BorderRadius.circular(AppRadius.md),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                  itemBuilder: (context, index) {
                    final account = _results[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        _display(account),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _select(account),
                    );
                  },
                ),
              ),
            ),
        ],
      ],
    );
  }
}
