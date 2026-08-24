import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_overview.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../core/sync/sync_request_context.dart';
import '../../../core/widgets/app_button.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_spacing.dart';

/// Modal bottom sheet displaying real-time synchronization or pull progress,
/// keeping results visible upon completion until manually dismissed.
class SyncProgressModal extends ConsumerStatefulWidget {
  const SyncProgressModal({
    super.key,
    required this.isDownloadOnly,
  });

  final bool isDownloadOnly;

  static Future<SyncPassResult?> show(
    BuildContext context,
    WidgetRef ref, {
    required bool isDownloadOnly,
  }) {
    return showModalBottomSheet<SyncPassResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SyncProgressModal(isDownloadOnly: isDownloadOnly),
    );
  }

  @override
  ConsumerState<SyncProgressModal> createState() => _SyncProgressModalState();
}

class _SyncProgressModalState extends ConsumerState<SyncProgressModal> {
  SyncPassResult? _finalResult;
  var _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startOperation();
    });
  }

  Future<void> _startOperation() async {
    if (_started) return;
    _started = true;

    final manager = ref.read(syncManagerProvider);
    if (!manager.isEnabled) {
      await manager.setEnabled(true);
    }

    final result = await manager.syncNow(
      notify: false,
      trigger: SyncPassTrigger.manual,
      upload: !widget.isDownloadOnly,
      download: true,
    );

    if (mounted) {
      setState(() {
        _finalResult = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final overviewAsync = ref.watch(syncOverviewProvider);
    final overview = overviewAsync.asData?.value ?? SyncOverview.initial();
    final isDone = _finalResult != null;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDone
                        ? (_finalResult!.outcome == SyncPassOutcome.failed
                            ? colorScheme.errorContainer
                            : colorScheme.primaryContainer)
                        : colorScheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDone
                        ? (_finalResult!.outcome == SyncPassOutcome.failed
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_rounded)
                        : (widget.isDownloadOnly
                            ? Icons.cloud_download_rounded
                            : Icons.sync_rounded),
                    color: isDone
                        ? (_finalResult!.outcome == SyncPassOutcome.failed
                            ? colorScheme.onErrorContainer
                            : colorScheme.onPrimaryContainer)
                        : colorScheme.onSecondaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDone
                            ? (_finalResult!.outcome == SyncPassOutcome.failed
                                ? l10n.syncServerConnectionFailed
                                : (widget.isDownloadOnly
                                    ? l10n.syncCheckingIncoming
                                    : l10n.syncPassUpToDate))
                            : (widget.isDownloadOnly
                                ? l10n.syncCheckingIncoming
                                : l10n.syncStatusSyncing),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isDone
                            ? (widget.isDownloadOnly
                                ? (_finalResult!.downloaded > 0
                                    ? l10n.syncIncomingCount(_finalResult!.downloaded)
                                    : l10n.syncIncomingNone)
                                : l10n.syncLastPassMetrics(
                                    _finalResult!.uploaded,
                                    _finalResult!.downloaded,
                                    _finalResult!.durationMs,
                                  ))
                            : (overview.progress.phaseName.isNotEmpty
                                ? overview.progress.phaseName
                                : l10n.syncPreparingOperations),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Animated progress section when running
            if (!isDone) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.syncSummaryTitle,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (overview.progress.totalSteps > 0)
                    Text(
                      '${overview.progress.currentStep} / ${overview.progress.totalSteps}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: overview.progress.totalSteps > 0
                      ? overview.progress.fraction
                      : null,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ] else ...[
              // Completion summary overview card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetricColumn(
                      label: l10n.syncSummaryDownloaded,
                      value: '${_finalResult!.downloaded}',
                      icon: Icons.download_rounded,
                      color: Colors.blue,
                    ),
                    _MetricColumn(
                      label: l10n.syncSummaryUploaded,
                      value: '${_finalResult!.uploaded}',
                      icon: Icons.upload_rounded,
                      color: Colors.green,
                    ),
                    _MetricColumn(
                      label: l10n.syncSummaryFailed,
                      value: '${_finalResult!.failed}',
                      icon: Icons.warning_amber_rounded,
                      color: _finalResult!.failed > 0 ? Colors.orange : colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Action button
            AppButton(
              label: isDone ? l10n.close : l10n.cancel,
              expand: true,
              variant: isDone ? AppButtonVariant.filled : AppButtonVariant.outlined,
              onPressed: () => Navigator.pop(context, _finalResult),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
