import 'package:flutter/material.dart';

/// Standardized loading state indicator.
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    super.key,
    this.message = 'جاري التحميل...',
    this.progress,
  });

  final String message;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: message,
        container: true,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(value: progress),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Standardized error state widget with retry action.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.title = 'حدث خطأ غير متوقع',
    this.message,
    this.error,
    this.onRetry,
    this.retryLabel = 'إعادة المحاولة',
  });

  final String title;
  final String? message;
  final Object? error;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayMessage = message ?? error?.toString() ?? 'تعذر إكمال العملية المطلوب';

    return Center(
      child: Semantics(
        label: '$title: $displayMessage',
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 36,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                displayMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48, minWidth: 120),
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: Text(retryLabel),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Standardized empty state widget for lists, grids, and search results.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.title = 'لا توجد بيانات',
    this.message = 'لم يتم العثور على أي عناصر هنا بعد',
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Semantics(
        label: '$title: $message',
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: colorScheme.outline,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48, minWidth: 140),
                  child: ElevatedButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
