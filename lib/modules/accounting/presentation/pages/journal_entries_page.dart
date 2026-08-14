import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/constants/app_constants.dart';
import '../../../../app/localization/app_localizations.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/journal_entry.dart';
import '../providers/journal_providers.dart';
import 'accounting_routes.dart';

/// Paginated-friendly list of journal entry headers.
class JournalEntriesPage extends ConsumerStatefulWidget {
  const JournalEntriesPage({super.key});

  @override
  ConsumerState<JournalEntriesPage> createState() => _JournalEntriesPageState();
}

class _JournalEntriesPageState extends ConsumerState<JournalEntriesPage> {
  static const _debounce = Duration(milliseconds: 300);

  final _searchController = TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      ref.read(journalListQueryProvider.notifier).state = value.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final entriesAsync = ref.watch(journalEntriesProvider);
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: l10n.accountingJournalsTitle,
        showBackButton: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AccountingRoutes.pushJournalCreate(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.accountingJournalAdd),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppConstants.pageInsets(context).copyWith(bottom: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.accountingJournalsSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: l10n.accountingJournalsSearchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: entriesAsync.when(
              loading: () => const AppLoading(),
              error: (e, _) => AppErrorState(message: e.toString()),
              data: (entries) {
                if (entries.isEmpty) {
                  return AppEmptyState(
                    title: l10n.accountingJournalsEmptyTitle,
                    subtitle: l10n.accountingJournalsEmptyMessage,
                    icon: Icons.receipt_long_outlined,
                  );
                }
                return ListView.separated(
                  padding: AppConstants.pageInsets(context).copyWith(bottom: 96),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _JournalHeaderTile(
                      entry: entry,
                      dateLabel: dateFormat.format(entry.entryDate.toLocal()),
                      onTap: () => AccountingRoutes.pushJournalDetails(
                        context,
                        entry.uuid,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalHeaderTile extends StatelessWidget {
  const _JournalHeaderTile({
    required this.entry,
    required this.dateLabel,
    required this.onTap,
  });

  final JournalEntryHeader entry;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.voucherNumber,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    AppStatusBadge(
                      label: entry.isPosted
                          ? l10n.accountingJournalPosted
                          : l10n.accountingJournalUnposted,
                      tone: entry.isPosted
                          ? AppStatusTone.success
                          : AppStatusTone.warning,
                      animate: false,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateLabel · ${entry.voucherType}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (entry.description != null &&
                    entry.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text(
                      '${l10n.accountingJournalDebit}: ${entry.totalDebit.toStringAsFixed(2)}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '${l10n.accountingJournalCredit}: ${entry.totalCredit.toStringAsFixed(2)}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      entry.currencyCode,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
