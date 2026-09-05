import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stock_count/app/localization/app_localizations.dart';
import 'package:stock_count/app/theme/app_spacing.dart';
import 'package:stock_count/core/presentation/widgets/search_filter_bar.dart';
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
  void _onQueryChanged(String value) {
    widget.onQueryChanged?.call(value);
    final current = ref.read(transactionListFilterProvider);
    ref.read(transactionListFilterProvider.notifier).state =
        current.copyWith(query: value.trim());
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

    final statusChips = [
      _StatusChip(
        label: l10n.rpTypeAll,
        selected: filter.documentStatus == null,
        onTap: () => _setStatus(null),
      ),
      const SizedBox(width: AppSpacing.sm),
      _StatusChip(
        label: l10n.rpStatusUnposted,
        selected: filter.documentStatus == TransactionStatus.unposted,
        onTap: () => _setStatus(TransactionStatus.unposted),
      ),
      const SizedBox(width: AppSpacing.sm),
      _StatusChip(
        label: l10n.rpStatusPosted,
        selected: filter.documentStatus == TransactionStatus.posted,
        onTap: () => _setStatus(TransactionStatus.posted),
      ),
    ];

    return SearchFilterBar(
      searchQuery: widget.initialQuery,
      searchHint: l10n.rpSearchHint,
      onSearchChanged: _onQueryChanged,
      activeFilterChips: statusChips,
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
