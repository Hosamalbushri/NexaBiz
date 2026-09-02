import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/constants/app_constants.dart';
import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/widgets/app_search_bar.dart';
import '../../domain/entities/transaction_status.dart';
import '../providers/transaction_list_provider.dart';

class TransactionFilterBar extends ConsumerStatefulWidget {
  const TransactionFilterBar({
    super.key,
    this.initialQuery = '',
    this.onQueryChanged,
  });

  final String initialQuery;
  final ValueChanged<String>? onQueryChanged;

  @override
  ConsumerState<TransactionFilterBar> createState() =>
      _TransactionFilterBarState();
}

class _TransactionFilterBarState extends ConsumerState<TransactionFilterBar> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    widget.onQueryChanged?.call(value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      final current = ref.read(transactionListFilterProvider);
      ref.read(transactionListFilterProvider.notifier).state =
          current.copyWith(query: value.trim());
    });
  }

  void _setStatus(TransactionStatus? status) {
    final current = ref.read(transactionListFilterProvider);
    ref.read(transactionListFilterProvider.notifier).state = current.copyWith(
      documentStatus: status,
      clearDocumentStatus: status == null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(transactionListFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.pagePadding,
            AppSpacing.md,
            AppConstants.pagePadding,
            AppSpacing.sm,
          ),
          child: AppSearchBar(
            controller: _searchController,
            hint: l10n.rpSearchHint,
            onChanged: (value) {
              setState(() {});
              _onQueryChanged(value);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.pagePadding,
            0,
            AppConstants.pagePadding,
            AppSpacing.sm,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatusChip(
                  label: l10n.rpTypeAll,
                  selected: filter.documentStatus == null,
                  onTap: () => _setStatus(null),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatusChip(
                  label: l10n.rpStatusUnposted,
                  selected:
                      filter.documentStatus == TransactionStatus.unposted,
                  onTap: () => _setStatus(TransactionStatus.unposted),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatusChip(
                  label: l10n.rpStatusPosted,
                  selected: filter.documentStatus == TransactionStatus.posted,
                  onTap: () => _setStatus(TransactionStatus.posted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: scheme.primaryContainer,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
      ),
      side: BorderSide(
        color: selected
            ? scheme.primary.withValues(alpha: 0.3)
            : scheme.outlineVariant.withValues(alpha: 0.5),
      ),
    );
  }
}
