import 'package:flutter/material.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import 'app_button.dart';

/// Modal bottom sheet container for multi-criteria search & filtering on mobile devices.
///
/// Keeps filter inputs organized without cluttering main screen top app bars.
class AppFilterSheet extends StatelessWidget {
  const AppFilterSheet({
    super.key,
    required this.title,
    required this.children,
    required this.onApply,
    this.onReset,
    this.applyLabel = 'تطبيق الفلترة',
    this.resetLabel = 'إعادة ضبط',
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onApply;
  final VoidCallback? onReset;
  final String applyLabel;
  final String resetLabel;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    required VoidCallback onApply,
    VoidCallback? onReset,
    String applyLabel = 'تطبيق الفلترة',
    String resetLabel = 'إعادة ضبط',
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppFilterSheet(
        title: title,
        onApply: onApply,
        onReset: onReset,
        applyLabel: applyLabel,
        resetLabel: resetLabel,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    final safeBottom = media.padding.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: media.size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle Bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    color: scheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  if (onReset != null)
                    TextButton(
                      onPressed: () {
                        onReset!();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        resetLabel,
                        style: TextStyle(
                          color: scheme.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Filter Form Fields (Scrollable)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
            // Apply Actions Bar
            Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm + (bottomInset > 0 ? 0 : safeBottom),
              ),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(
                  top: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: AppButton(
                label: applyLabel,
                icon: Icons.check_rounded,
                expand: true,
                onPressed: () {
                  onApply();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
