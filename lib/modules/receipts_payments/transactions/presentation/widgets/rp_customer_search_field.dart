import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/core/widgets/app_async_autocomplete_field.dart';
import 'package:stock_count/modules/receipts_payments/shared/domain/services/rp_customer_lookup_port.dart';
import '../providers/rp_providers.dart';

const _kDebounceMs = 300;
const _kMinQueryLength = 2;
const _kResultLimit = 20;

/// Searchable customer field for R&P transactions, built using [AppAsyncAutocompleteField].
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

class _RpCustomerSearchFieldState
    extends ConsumerState<RpCustomerSearchField> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode(skipTraversal: true);

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
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<List<RpCustomerRef>> _search(String query) async {
    return ref
        .read(rpCustomerLookupPortProvider)
        .search(query, limit: _kResultLimit);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return AppAsyncAutocompleteField<RpCustomerRef>(
      controller: _controller,
      focusNode: _focusNode,
      label: l10n.rpCustomer,
      showLabelAbove: true,
      hint: widget.hintText ?? l10n.rpSearchCustomerHint,
      minQueryLength: _kMinQueryLength,
      debounceDuration: const Duration(milliseconds: _kDebounceMs),
      fetchOptions: _search,
      itemLabelBuilder: (c) => c.name,
      onSelected: (customer) {
        if (customer != null) {
          widget.onCustomerSelected(customer);
        }
      },
      noResultsText: l10n.rpCustomerNotFound,
      errorText: l10n.rpAutocompleteSearchFailed,
      itemBuilder: (context, customer) {
        final phone = customer.phone?.trim();
        final hasPhone = phone != null && phone.isNotEmpty;
        return ListTile(
          dense: true,
          leading: Icon(
            Icons.person_outline_rounded,
            color: scheme.primary,
          ),
          title: Text(customer.name),
          subtitle: hasPhone ? Text(phone) : null,
        );
      },
    );
  }
}

