import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/digit_normalization.dart';
import '../../domain/services/rp_treasury_account_port.dart';
import '../providers/rp_providers.dart';

const _kDebounceMs = 300;
const _kMinQueryLength = 1;
const _kResultLimit = 20;

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

/// Searchable cash/bank account field (treasury accounts).
class RpCashAccountSearchField extends ConsumerStatefulWidget {
  const RpCashAccountSearchField({
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
  ConsumerState<RpCashAccountSearchField> createState() =>
      _RpCashAccountSearchFieldState();
}

class _RpCashAccountSearchFieldState
    extends ConsumerState<RpCashAccountSearchField> {
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
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && mounted) {
        Future<void>.delayed(const Duration(milliseconds: 140), () {
          if (mounted && !_focusNode.hasFocus) {
            setState(() => _showResults = false);
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant RpCashAccountSearchField oldWidget) {
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
      final results = await ref
          .read(rpTreasuryAccountPortProvider)
          .listCashBoxAccounts();
      final normalized = query.toLowerCase();
      final filtered = results
          .where(
            (a) =>
                a.name.toLowerCase().contains(normalized) ||
                a.code.toLowerCase().contains(normalized),
          )
          .take(_kResultLimit)
          .toList(growable: false);
      if (!mounted || !_session.isCurrent(token)) {
        return;
      }
      setState(() {
        _results = filtered;
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
            prefixIcon: Icon(Icons.account_balance_wallet_outlined,
                color: scheme.primary),
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
          onTap: () {
            if (_controller.text.trim().isEmpty) {
              _onChanged(' ');
            }
          },
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
      final results = await ref
          .read(rpTreasuryAccountPortProvider)
          .searchPostingAccounts(query, limit: _kResultLimit);
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
