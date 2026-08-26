import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../core/sync/sync_status.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Modal bottom sheet or page for inspecting synchronization outbox operations.
class SyncInspectorSheet extends ConsumerStatefulWidget {
  const SyncInspectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const SyncInspectorSheet(),
    );
  }

  @override
  ConsumerState<SyncInspectorSheet> createState() => _SyncInspectorSheetState();
}

class _SyncInspectorSheetState extends ConsumerState<SyncInspectorSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<SyncOperation> _allOperations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOperations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOperations() async {
    setState(() => _loading = true);
    final queue = ref.read(syncQueueProvider);
    final list = await queue.peekAll();
    if (!mounted) return;
    setState(() {
      _allOperations = list;
      _loading = false;
    });
  }

  List<SyncOperation> _filterOperations(int tabIndex) {
    if (tabIndex == 1) {
      return _allOperations
          .where((op) =>
              op.status == SyncStatus.failed ||
              op.status == SyncStatus.conflict ||
              op.status == SyncStatus.rejected)
          .toList();
    }
    if (tabIndex == 2) {
      return _allOperations
          .where((op) =>
              op.status == SyncStatus.pending ||
              op.status == SyncStatus.syncing)
          .toList();
    }
    return _allOperations;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final issuesCount = _allOperations.where((o) =>
        o.status == SyncStatus.failed ||
        o.status == SyncStatus.conflict ||
        o.status == SyncStatus.rejected).length;
    final pendingCount = _allOperations.where((o) =>
        o.status == SyncStatus.pending ||
        o.status == SyncStatus.syncing).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CustomAppBar(
            title: l10n.syncOutboxTitle(_allOperations.length),
            showBackButton: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_outlined),
                onPressed: _loadOperations,
                tooltip: l10n.adminDevicesRefresh,
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: Column(
            children: [
              TabBar(
                controller: _tabController,
                onTap: (_) => setState(() {}),
                tabs: [
                  Tab(text: l10n.syncOutboxTabAll(_allOperations.length)),
                  Tab(text: l10n.syncOutboxTabIssues(issuesCount)),
                  Tab(text: l10n.syncOutboxTabPending(pendingCount)),
                ],
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildList(scrollController, l10n),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(ScrollController scrollController, AppLocalizations l10n) {
    final items = _filterOperations(_tabController.index);
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.done_all_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.syncOutboxEmpty,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final op = items[index];
        return _OperationTile(
          operation: op,
          onTap: () => _showDetailDialog(op),
        );
      },
    );
  }

  Future<void> _showDetailDialog(SyncOperation op) async {
    final dialogContext = context;
    await showDialog<void>(
      context: dialogContext,
      builder: (context) => _OperationDetailDialog(
        operation: op,
        onRetry: () async {
          final resetOp = op.copyWith(
            status: SyncStatus.pending,
            clearNextRetryAt: true,
          );
          await ref.read(syncQueueProvider).update(resetOp);
          if (!mounted || !dialogContext.mounted) return;
          Navigator.of(dialogContext).pop();
          _loadOperations();
          ref.read(syncManagerProvider).syncNow();
        },
        onPurge: () async {
          await ref.read(syncQueueProvider).remove(op.id);
          if (!mounted || !dialogContext.mounted) return;
          Navigator.of(dialogContext).pop();
          _loadOperations();
        },
      ),
    );
  }
}

class _OperationTile extends StatelessWidget {
  const _OperationTile({
    required this.operation,
    required this.onTap,
  });

  final SyncOperation operation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (statusLabel, statusColor) = switch (operation.status) {
      SyncStatus.synced => ('Synced', colorScheme.primary),
      SyncStatus.pending => ('Pending', colorScheme.tertiary),
      SyncStatus.syncing => ('Syncing', colorScheme.primary),
      SyncStatus.failed => ('Failed', colorScheme.error),
      SyncStatus.conflict => ('Conflict', colorScheme.error),
      SyncStatus.rejected => ('Rejected', colorScheme.error),
      SyncStatus.quarantined => ('Quarantined', colorScheme.error),
    };

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        title: Row(
          children: [
            Text(
              operation.entityType.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                operation.type.name.toUpperCase(),
                style: theme.textTheme.labelSmall,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                statusLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Entity ID: ${operation.entityId}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            if (operation.lastError != null && operation.lastError!.isNotEmpty)
              Text(
                'Error: ${operation.lastError}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _OperationDetailDialog extends StatelessWidget {
  const _OperationDetailDialog({
    required this.operation,
    required this.onRetry,
    required this.onPurge,
  });

  final SyncOperation operation;
  final VoidCallback onRetry;
  final VoidCallback onPurge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final jsonPretty = const JsonEncoder.withIndent('  ').convert(operation.payload);

    return AlertDialog(
      title: Text(l10n.syncOutboxDetailsTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _detailRow(context, 'Op ID', operation.id),
            _detailRow(context, 'Entity Type', operation.entityType),
            _detailRow(context, 'Entity ID', operation.entityId),
            _detailRow(context, 'Type', operation.type.name),
            _detailRow(context, 'Status', operation.status.name),
            _detailRow(context, 'Base Version', '${operation.baseVersion}'),
            _detailRow(context, 'Attempts', '${operation.attemptCount}'),
            if (operation.nextRetryAt != null)
              _detailRow(
                context,
                'Next Retry',
                operation.nextRetryAt!.isAfter(DateTime.now())
                    ? 'In ${operation.nextRetryAt!.difference(DateTime.now()).inSeconds}s'
                    : 'Ready for retry',
              ),
            if (operation.lastError != null)
              _detailRow(context, 'Last Error', operation.lastError!, isError: true),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Payload Preview:',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                jsonPretty,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.delete_outline_rounded),
          label: Text(l10n.syncOutboxPurge),
          style: TextButton.styleFrom(foregroundColor: colorScheme.error),
          onPressed: onPurge,
        ),
        AppButton(
          label: l10n.syncOutboxRetryNow,
          icon: Icons.refresh_outlined,
          onPressed: onRetry,
        ),
      ],
    );
  }

  Widget _detailRow(BuildContext context, String label, String value, {bool isError = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isError ? theme.colorScheme.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
