import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/digit_normalization.dart';
import '../../domain/services/rp_customer_lookup_port.dart';
import '../providers/rp_providers.dart';

const _kDebounceMs = 300;
const _kMinQueryLength = 2;
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

class RpCustomerSearchField extends ConsumerStatefulWidget {
  const RpCustomerSearchField({
    super.key,
    required this.onCustomerSelected,
    this.initialQuery = '',
    this.hintText,
  });

  final ValueChanged<RpCustomerRef> onCustomerSelected;
  final String initialQuery;
  final String? hintText;

  @override
  ConsumerState<RpCustomerSearchField> createState() =>
      _RpCustomerSearchFieldState();
}

class _RpCustomerSearchFieldState extends ConsumerState<RpCustomerSearchField> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode(skipTraversal: true);
  final _session = _SearchSession();
  var _loading = false;
  var _showResults = false;
  var _searchFailed = false;
  List<RpCustomerRef> _results = const [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void didUpdateWidget(covariant RpCustomerSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery &&
        widget.initialQuery != _controller.text) {
      _controller.text = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    _session.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _normalizedQuery =>
      normalizeDigitsToWestern(_controller.text).trim();

  void _onChanged(String value) {
    final query = normalizeDigitsToWestern(value).trim();
    if (query.length < _kMinQueryLength) {
      _session.invalidate();
      setState(() {
        _results = const [];
        _loading = false;
        _showResults = false;
        _searchFailed = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _showResults = true;
      _searchFailed = false;
    });
    _session.schedule((token) => _search(query, token));
  }

  Future<void> _search(String query, int token) async {
    try {
      final results = await ref
          .read(rpCustomerLookupPortProvider)
          .search(query, limit: _kResultLimit);
      if (!mounted || !_session.isCurrent(token)) {
        return;
      }
      setState(() {
        _results = results;
        _loading = false;
        _showResults = true;
        _searchFailed = false;
      });
    } catch (_) {
      if (!mounted || !_session.isCurrent(token)) {
        return;
      }
      setState(() {
        _results = const [];
        _loading = false;
        _showResults = true;
        _searchFailed = true;
      });
    }
  }

  void _select(RpCustomerRef customer) {
    widget.onCustomerSelected(customer);
    _controller.text = customer.name;
    setState(() {
      _results = const [];
      _loading = false;
      _showResults = false;
      _searchFailed = false;
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final query = _normalizedQuery;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.rpCustomer,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          inputFormatters: const [WesternDigitsInputFormatter()],
          textInputAction: TextInputAction.done,
          onChanged: _onChanged,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: scheme.surface,
            hintText: widget.hintText ?? l10n.rpSearchCustomerHint,
            prefixIcon: Icon(Icons.search_rounded, color: scheme.primary),
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
        ),
        if (_showResults && query.length >= _kMinQueryLength) ...[
          const SizedBox(height: AppSpacing.xs),
          Material(
            color: scheme.surface,
            elevation: 2,
            borderRadius: BorderRadius.circular(AppRadius.md),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : _searchFailed
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        l10n.rpAutocompleteSearchFailed,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    )
                  : _results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        l10n.rpCustomerNotFound,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: scheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                      itemBuilder: (context, index) {
                        final customer = _results[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.person_outline_rounded,
                            color: scheme.primary,
                          ),
                          title: Text(customer.name),
                          subtitle: customer.phone?.trim().isNotEmpty ?? false
                              ? Text(customer.phone!.trim())
                              : null,
                          onTap: () => _select(customer),
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
