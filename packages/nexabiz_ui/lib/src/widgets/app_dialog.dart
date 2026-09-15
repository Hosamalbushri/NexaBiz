import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

import '../theme/tokens/tokens.dart';
import 'app_button.dart';
import 'app_icon_avatar.dart';

/// Predefined canonical width variants for NexaBiz dialogs with enhanced breathing room.
enum AppDialogSize {
  /// Small dialog (max-width: 460px). Ideal for simple alerts, confirmations, or small prompts.
  small(460),

  /// Medium dialog (max-width: 640px). Ideal for standard forms, quick detail cards, or selectors.
  medium(640),

  /// Large dialog (max-width: 880px). Ideal for multi-section forms, detailed tables, or trees.
  large(880),

  /// Fullscreen dialog (fills available viewport width & height).
  fullscreen(double.infinity);

  const AppDialogSize(this.maxWidth);
  final double maxWidth;
}

/// Semantic tones for confirmation and alert dialogs.
enum AppDialogTone { primary, info, warning, danger }

/// Canonical NexaBiz Central Dialog Component (`NexaBizDialog<T>`).
///
/// Next-generation, world-class UI design inspired by Linear & Vercel design systems.
/// Features a 24px squircle rounded surface, crisp dark contrast, subtle top highlight,
/// glowing compact avatar pill, centered layout, and minimalist glassmorphic close controls.
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
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 18,
    ),
    required this.child,
    this.actions,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.showCloseButton = true,
    this.showActions = true,
    this.showCancelButton = true,
    this.showConfirmButton = true,
    this.centerHeader = true,
    this.centerContent = true,
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

  /// Whether to show the bottom action bar.
  final bool showActions;

  /// Whether to include the cancel button when using default actions.
  final bool showCancelButton;

  /// Whether to include the confirm button when using default actions.
  final bool showConfirmButton;

  /// Whether to center-align the header title and description text inside the middle column.
  final bool centerHeader;

  /// Whether to center-align the main dialog body content.
  final bool centerContent;

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
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.xl),
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 18,
    ),
    required Widget child,
    List<Widget>? actions,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
    bool showCloseButton = true,
    bool showActions = true,
    bool showCancelButton = true,
    bool showConfirmButton = true,
    bool centerHeader = true,
    bool centerContent = true,
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
          showActions: showActions,
          showCancelButton: showCancelButton,
          showConfirmButton: showConfirmButton,
          centerHeader: centerHeader,
          centerContent: centerContent,
          child: child,
        );
      },
    );
  }

  /// Unified static helper to show a confirmation dialog directly using the single `AppDialog` component.
  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    AppDialogTone tone = AppDialogTone.warning,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    Widget? customBody,
    bool barrierDismissible = true,
  }) {
    final avatarTone = switch (tone) {
      AppDialogTone.primary => AppIconAvatarTone.primary,
      AppDialogTone.info => AppIconAvatarTone.info,
      AppDialogTone.warning => AppIconAvatarTone.warning,
      AppDialogTone.danger => AppIconAvatarTone.error,
    };

    final iconData = switch (tone) {
      AppDialogTone.primary => Icons.help_outline_rounded,
      AppDialogTone.info => Icons.info_outline_rounded,
      AppDialogTone.warning => Icons.warning_amber_rounded,
      AppDialogTone.danger => Icons.error_outline_rounded,
    };

    return show<bool>(
      context: context,
      title: title,
      size: AppDialogSize.small,
      isDestructive: tone == AppDialogTone.danger,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: onConfirm,
      onCancel: onCancel,
      barrierDismissible: barrierDismissible,
      centerHeader: true,
      centerContent: true,
      leading: AppIconAvatar(
        icon: iconData,
        tone: avatarTone,
        size: AppIconAvatarSize.md,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (customBody != null) ...[
              const SizedBox(height: 14),
              customBody,
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildDialog(context);
  }

  Widget _buildDialog(BuildContext context) {
    final theme = shadcn.Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isFullscreen = size == AppDialogSize.fullscreen;
    final hasHeader = title != null || description != null || icon != null || leading != null || trailing != null || showCloseButton;
    final renderActions = showActions && (actions == null || actions!.isNotEmpty);

    final dialogBgColor = colorScheme.popover;
    final borderColor = colorScheme.border;
    final footerBgColor = colorScheme.muted.withValues(alpha: 0.3);

    final rawAvatar = leading ?? (icon != null
        ? AppIconAvatar(
            icon: icon!,
            tone: isDestructive ? AppIconAvatarTone.error : AppIconAvatarTone.primary,
            size: AppIconAvatarSize.sm,
          )
        : null);

    final resolvedLeading = rawAvatar != null
        ? Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isDestructive ? colorScheme.destructive : colorScheme.primary).withValues(alpha: isDark ? 0.3 : 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDestructive ? colorScheme.destructive : colorScheme.primary).withValues(alpha: isDark ? 0.15 : 0.08),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: rawAvatar,
          )
        : null;

    final closeButtonWidget = showCloseButton && trailing == null
        ? Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: isLoading
                  ? null
                  : () {
                      final nav = Navigator.of(context);
                      onCancel?.call();
                      if (context.mounted && nav.canPop()) {
                        nav.pop(null);
                      }
                    },
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.border.withValues(alpha: isDark ? 0.3 : 0.6),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: colorScheme.mutedForeground,
                ),
              ),
            ),
          )
        : null;

    Widget headerWidget = const SizedBox.shrink();
    if (hasHeader) {
      final Widget leftSlotWidget = resolvedLeading ?? (showCloseButton && trailing == null ? const SizedBox(width: 28) : const SizedBox.shrink());
      final Widget rightSlotWidget = trailing ?? (closeButtonWidget ?? (resolvedLeading != null ? const SizedBox(width: 28) : const SizedBox.shrink()));

      headerWidget = Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
        decoration: BoxDecoration(
          color: dialogBgColor,
          border: Border(
            bottom: BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Slot 1: Leading Icon Avatar
            leftSlotWidget,
            if (resolvedLeading != null) const SizedBox(width: 14),

            // Slot 2: Title & Description Column
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: centerHeader ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      textAlign: centerHeader ? TextAlign.center : TextAlign.start,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: colorScheme.foreground,
                      ),
                    ),
                  if (description != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      description!,
                      textAlign: centerHeader ? TextAlign.center : TextAlign.start,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Slot 3: Close Control / Trailing Action
            if (rightSlotWidget is! SizedBox || rightSlotWidget.width != 0)
              const SizedBox(width: 12),
            rightSlotWidget,
          ],
        ),
      );
    }

    Widget errorBannerWidget = const SizedBox.shrink();
    if (errorMessage case final String msg when msg.trim().isNotEmpty) {
      errorBannerWidget = Container(
        margin: const EdgeInsets.fromLTRB(24, 12, 24, 4),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.destructive.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.destructive.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: colorScheme.destructive,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                errorMessage!,
                textAlign: centerHeader ? TextAlign.center : TextAlign.start,
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
    if (renderActions) {
      List<Widget> defaultActionButtons;
      if (actions != null) {
        defaultActionButtons = actions!;
      } else {
        final buttons = <Widget>[];

        if (showCancelButton && confirmLabel != cancelLabel) {
          buttons.add(
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
          );
        }

        if (showConfirmButton) {
          if (buttons.isNotEmpty) {
            buttons.add(const SizedBox(width: 12));
          }

          buttons.add(
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
          );
        }

        defaultActionButtons = buttons;
      }

      actionsWidget = Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
        decoration: BoxDecoration(
          color: footerBgColor,
          border: Border(
            top: BorderSide(
              color: borderColor,
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

    final maxDialogWidth = size.maxWidth;
    final viewportHeight = mediaQuery.size.height;
    final maxDialogHeight = isFullscreen ? viewportHeight : viewportHeight * 0.88;

    final dialogSurface = Material(
      color: dialogBgColor,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isFullscreen ? 0 : 24.0),
        side: BorderSide(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isFullscreen ? 0 : 24.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
              blurRadius: 36,
              spreadRadius: -4,
              offset: const Offset(0, 16),
            ),
          ],
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
                  child: centerContent
                      ? Center(
                          child: DefaultTextStyle.merge(
                            textAlign: TextAlign.center,
                            child: child,
                          ),
                        )
                      : child,
                ),
              ),
              actionsWidget,
            ],
          ),
        ),
      ),
    ).animate().scale(
          duration: 200.ms,
          curve: Curves.easeOutCubic,
          begin: const Offset(0.96, 0.96),
          end: const Offset(1.0, 1.0),
        ).fadeIn(duration: 180.ms);

    if (isFullscreen) {
      return Dialog.fullscreen(child: dialogSurface);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      child: dialogSurface,
    );
  }
}
