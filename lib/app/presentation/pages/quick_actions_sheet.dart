import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_button.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../../modules/authentication/presentation/providers/auth_providers.dart';
import '../models/quick_action_definition.dart';
import '../providers/quick_actions_provider.dart';
import '../quick_action_runner.dart';
import 'quick_actions_customize_sheet.dart';

/// Opens the quick-actions sheet as a modal (fallback / non-shell hosts).
Future<void> showQuickActionsSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);

  return showAppBottomSheet<void>(
    context: context,
    title: l10n.quickActionsTitle,
    child: const QuickActionsSheetBody(),
  );
}

/// Animated panel used by [AppShell] above the bottom navigation.
class QuickActionsPanel extends StatelessWidget {
  const QuickActionsPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.58;

    return Material(
      color: colorScheme.surface,
      elevation: 10,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.25),
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.xl),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Center(
                child: Text(
                  l10n.quickActionsTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              QuickActionsSheetBody(onClose: onClose),
            ],
          ),
        ),
      ),
    );
  }
}

/// Body for the quick-actions bottom sheet / overlay panel.
class QuickActionsSheetBody extends ConsumerWidget {
  const QuickActionsSheetBody({super.key, this.onClose});

  /// Called before running an action (and by the shell when dismissing).
  final VoidCallback? onClose;

  Future<void> _openCustomize(BuildContext context, WidgetRef ref) async {
    // Close the shell panel first — nested bottom sheets fight its scrim/drag.
    onClose?.call();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!context.mounted) {
      return;
    }

    final controller = ref.read(quickActionsProvider.notifier);
    final currentIds =
        ref.read(quickActionsProvider).valueOrNull ?? defaultQuickActionIds();
    final authState = ref.read(authStateProvider);
    final availableCatalog = quickActionCatalog()
        .where((action) => action.hasPermission(authState))
        .toList();

    final result = await showAppBottomSheet<List<String>>(
      context: context,
      child: QuickActionsCustomizeSheet(
        availableActions: availableCatalog,
        initiallySelectedIds: currentIds,
      ),
    );

    if (result != null) {
      await controller.save(result);
    }
  }

  void _dismiss(BuildContext context) {
    if (onClose != null) {
      onClose!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final asyncIds = ref.watch(quickActionsProvider);
    final authState = ref.watch(authStateProvider);
    final runner = const QuickActionRunner();

    return asyncIds.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.somethingWentWrong, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l10n.retry,
            onPressed: () => ref.read(quickActionsProvider.notifier).reload(),
          ),
        ],
      ),
      data: (ids) {
        final actions = [
          for (final id in ids)
            if (findQuickActionById(id) != null &&
                findQuickActionById(id)!.hasPermission(authState))
              findQuickActionById(id)!,
        ];

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.quickActionsSubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (actions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  l10n.quickActionsEmptyPinned,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length + 1,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, index) {
                if (index == actions.length) {
                  return _QuickActionCustomizeTile(
                    label: l10n.quickActionsCustomize,
                    onTap: () => _openCustomize(context, ref),
                  );
                }
                final action = actions[index];
                return _QuickActionTile(
                  icon: action.icon,
                  label: action.title(l10n),
                  onTap: () => runner.run(
                    sheetContext: context,
                    action: action,
                    onClose: () => _dismiss(context),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(icon, size: 18, color: colorScheme.primary),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionCustomizeTile extends StatelessWidget {
  const _QuickActionCustomizeTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = colorScheme.outline.withValues(alpha: 0.55);

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: CustomPaint(
            painter: _DashedRRectPainter(
              color: borderColor,
              radius: AppRadius.md,
            ),
            child: Ink(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dashLength = 6.0;
      const gapLength = 4.0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
