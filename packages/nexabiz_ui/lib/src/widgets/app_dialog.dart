import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../theme/tokens/tokens.dart';
import 'app_button.dart';

/// Predefined canonical width variants for NexaBiz dialogs.
enum AppDialogSize {
  /// Small dialog (max-width: 400px). Ideal for simple alerts, confirmations, or small prompts.
  small(400),

  /// Medium dialog (max-width: 560px). Ideal for standard forms, quick detail cards, or selectors.
  medium(560),

  /// Large dialog (max-width: 720px). Ideal for multi-section forms, detailed tables, or trees.
  large(720),

  /// Fullscreen dialog (fills available viewport width & height).
  fullscreen(double.infinity);

  const AppDialogSize(this.maxWidth);
  final double maxWidth;
}

/// Canonical NexaBiz Central Dialog Component (`NexaBizDialog<T>`).
///
/// Centralizes application dialog presentation, responsive sizing, scrolling content bounds,
/// title/description header layout, loading/error UI presentation, and action bar area.
///
/// Completely domain-independent and form-independent.
class AppDialog<T> extends StatelessWidget {
  const AppDialog({
    super.key,
    this.title,
    this.description,
    this.icon,
    this.leading,
    this.trailing,
    this.errorMessage,
    this.isLoading = false,
    this.size = AppDialogSize.medium,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    required this.child,
    this.actions,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.showCloseButton = true,
  });

  /// Optional dialog title string or custom widget.
  final String? title;

  /// Optional subtitle or detailed description.
  final String? description;

  /// Optional leading icon data.
  final IconData? icon;

  /// Optional custom leading widget.
  final Widget? leading;

  /// Optional trailing widget in the header.
  final Widget? trailing;

  /// Optional global error message to display in an error banner.
  final String? errorMessage;

  /// Whether the dialog is currently processing an async operation.
  final bool isLoading;

  /// Predefined dialog max-width sizing variant.
  final AppDialogSize size;

  /// Padding for the dialog container header & wrapper.
  final EdgeInsetsGeometry padding;

  /// Padding surrounding the main scrollable content area.
  final EdgeInsetsGeometry contentPadding;

  /// Main dialog content widget.
  final Widget child;

  /// Custom list of action widgets for the bottom action bar.
  /// If provided, overrides default confirm/cancel buttons.
  final List<Widget>? actions;

  /// Label for the primary confirm button (default: 'Confirm').
  final String confirmLabel;

  /// Label for the secondary cancel button (default: 'Cancel').
  final String cancelLabel;

  /// Callback executed when primary confirm action is pressed.
  final VoidCallback? onConfirm;

  /// Callback executed when cancel action is pressed.
  final VoidCallback? onCancel;

  /// Whether the confirm button represents a destructive action (styled red).
  final bool isDestructive;

  /// Whether to display a close button in the header trailing area.
  final bool showCloseButton;

  /// Static helper to display the canonical dialog and return a typed result `T?`.
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? description,
    IconData? icon,
    Widget? leading,
    Widget? trailing,
    String? errorMessage,
    bool isLoading = false,
    AppDialogSize size = AppDialogSize.medium,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.lg),
    EdgeInsetsGeometry contentPadding = const EdgeInsets.all(AppSpacing.lg),
    required Widget child,
    List<Widget>? actions,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
    bool showCloseButton = true,
    bool barrierDismissible = true,
    bool useRootNavigator = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible && !isLoading,
      useRootNavigator: useRootNavigator,
      builder: (dialogContext) {
        return AppDialog<T>(
          title: title,
          description: description,
          icon: icon,
          leading: leading,
          trailing: trailing,
          errorMessage: errorMessage,
          isLoading: isLoading,
          size: size,
          padding: padding,
          contentPadding: contentPadding,
          actions: actions,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          onConfirm: onConfirm,
          onCancel: onCancel,
          isDestructive: isDestructive,
          showCloseButton: showCloseButton,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasShadcnTheme =
        context.dependOnInheritedWidgetOfExactType<shadcn.Theme>() != null;
    if (!hasShadcnTheme) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return shadcn.Theme(
        data: isDark
            ? const shadcn.ThemeData.dark()
            : const shadcn.ThemeData(),
        child: Builder(
          builder: (context) => _buildDialog(context),
        ),
      );
    }
    return _buildDialog(context);
  }

  Widget _buildDialog(BuildContext context) {
    final theme = shadcn.Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);

    final isFullscreen = size == AppDialogSize.fullscreen;
    final hasHeader = title != null || description != null || icon != null || leading != null || trailing != null || showCloseButton;
    final hasActions = actions != null || onConfirm != null || onCancel != null || isLoading;

    final resolvedLeading = leading ?? (icon != null
        ? Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDestructive
                    ? [
                        colorScheme.destructive.withValues(alpha: 0.18),
                        colorScheme.destructive.withValues(alpha: 0.08),
                      ]
                    : [
                        colorScheme.primary.withValues(alpha: 0.18),
                        colorScheme.primary.withValues(alpha: 0.08),
                      ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isDestructive
                    ? colorScheme.destructive.withValues(alpha: 0.3)
                    : colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isDestructive ? colorScheme.destructive : colorScheme.primary,
            ),
          )
        : null);

    Widget headerWidget = const SizedBox.shrink();
    if (hasHeader) {
      headerWidget = Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (resolvedLeading != null) ...[
                  resolvedLeading,
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: colorScheme.foreground,
                          ),
                        ),
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          description!,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: colorScheme.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing case final Widget body) body,
                if (showCloseButton && trailing == null)
                  Material(
                    color: colorScheme.mutedForeground.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: colorScheme.mutedForeground,
                      ),
                      onPressed: isLoading
                          ? null
                          : () {
                              final nav = Navigator.of(context);
                              onCancel?.call();
                              if (context.mounted && nav.canPop()) {
                                nav.pop(null);
                              }
                            },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.border.withValues(alpha: 0.5),
            ),
          ],
        ),
      );
    }

    Widget errorBannerWidget = const SizedBox.shrink();
    if (errorMessage case final String msg when msg.trim().isNotEmpty) {
      errorBannerWidget = Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.destructive.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(theme.radiusMd),
          border: Border.all(
            color: colorScheme.destructive.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: colorScheme.destructive,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                errorMessage!,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.destructive,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget actionsWidget = const SizedBox.shrink();
    if (hasActions) {
      final defaultActionButtons = actions ??
          [
            Expanded(
              child: AppButton(
                label: cancelLabel,
                variant: AppButtonVariant.outlined,
                expand: true,
                onPressed: isLoading
                    ? null
                    : () {
                        final nav = Navigator.of(context);
                        onCancel?.call();
                        if (context.mounted && nav.canPop()) {
                          nav.pop(false);
                        }
                      },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: confirmLabel,
                variant: isDestructive ? AppButtonVariant.destructive : AppButtonVariant.filled,
                isLoading: isLoading,
                expand: true,
                onPressed: isLoading
                    ? null
                    : () {
                        final nav = Navigator.of(context);
                        onConfirm?.call();
                        if (context.mounted && nav.canPop()) {
                          nav.pop(true);
                        }
                      },
              ),
            ),
          ];

      actionsWidget = Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.card,
          border: Border(
            top: BorderSide(
              color: colorScheme.border.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: defaultActionButtons,
        ),
      );
    }

    // Responsive Constraints setup
    final maxDialogWidth = size.maxWidth;
    final viewportHeight = mediaQuery.size.height;
    final maxDialogHeight = isFullscreen ? viewportHeight : viewportHeight * 0.88;

    final dialogSurface = Material(
      color: colorScheme.card,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isFullscreen ? 0 : AppRadius.lg),
        side: BorderSide(
          color: colorScheme.border.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxDialogWidth,
          maxHeight: maxDialogHeight,
        ),
        child: Column(
          mainAxisSize: isFullscreen ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            headerWidget,
            errorBannerWidget,
            Flexible(
              child: SingleChildScrollView(
                padding: contentPadding,
                child: child,
              ),
            ),
            actionsWidget,
          ],
        ),
      ),
    );

    if (isFullscreen) {
      return Dialog.fullscreen(child: dialogSurface);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: dialogSurface,
    );
  }
}
