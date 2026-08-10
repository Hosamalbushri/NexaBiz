import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Visual configuration for [CustomAppBar].
///
/// Use [CustomAppBarStyle.adaptive] for theme-aware defaults, or
/// [CustomAppBarStyle.light] / [CustomAppBarStyle.dark] for explicit modes.
@immutable
class CustomAppBarStyle {
  const CustomAppBarStyle({
    this.height = kToolbarHeight + 8,
    this.borderRadius = 24,
    this.elevation = 8,
    this.backgroundColor,
    this.gradient,
    this.foregroundColor,
    this.centerTitle = true,
    this.useGradient = false,
    this.actionButtonSize = 42,
    this.horizontalPadding = 16,
    this.shadowColor,
    this.scrolledUnderElevation,
  });

  /// Toolbar body height excluding [PreferredSizeWidget] bottom content.
  final double height;

  /// Bottom corner radius applied to the bar surface.
  final double borderRadius;

  /// Soft shadow strength beneath the bar.
  final double elevation;

  /// Solid background when [gradient] is null or [useGradient] is false.
  final Color? backgroundColor;

  /// Optional gradient overlay. Falls back to an adaptive premium gradient.
  final Gradient? gradient;

  /// Primary content color for title, icons, and controls.
  final Color? foregroundColor;

  /// Whether the title block is centered horizontally.
  final bool centerTitle;

  /// When true, renders [gradient] (or adaptive default) instead of [backgroundColor].
  final bool useGradient;

  /// Square dimension for icon action buttons.
  final double actionButtonSize;

  /// Horizontal inset for leading, title, and trailing clusters.
  final double horizontalPadding;

  /// Shadow tint. Defaults to a subtle primary-tinted shadow.
  final Color? shadowColor;

  /// Elevation applied when content scrolls under the bar.
  final double? scrolledUnderElevation;

  /// Creates a style that adapts to the current [ThemeData].
  factory CustomAppBarStyle.adaptive(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return CustomAppBarStyle(
      useGradient: false,
      centerTitle: true,
      backgroundColor: isDark
          ? colorScheme.surfaceContainerHigh
          : colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      shadowColor: colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.12),
    );
  }

  /// Light-mode preset with airy surface tones.
  static const CustomAppBarStyle light = CustomAppBarStyle(
    useGradient: false,
    backgroundColor: Color(0xFFF8FAFC),
    foregroundColor: Color(0xFF0F172A),
    shadowColor: Color(0x1A1565C0),
  );

  /// Dark-mode preset with deep, refined contrast.
  static const CustomAppBarStyle dark = CustomAppBarStyle(
    useGradient: false,
    backgroundColor: Color(0xFF111827),
    foregroundColor: Color(0xFFF8FAFC),
    shadowColor: Color(0x33000000),
  );

  CustomAppBarStyle merge(CustomAppBarStyle? other) {
    if (other == null) {
      return this;
    }

    return CustomAppBarStyle(
      height: other.height,
      borderRadius: other.borderRadius,
      elevation: other.elevation,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      gradient: other.gradient ?? gradient,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      centerTitle: other.centerTitle,
      useGradient: other.useGradient,
      actionButtonSize: other.actionButtonSize,
      horizontalPadding: other.horizontalPadding,
      shadowColor: other.shadowColor ?? shadowColor,
      scrolledUnderElevation:
          other.scrolledUnderElevation ?? scrolledUnderElevation,
    );
  }
}

/// Premium Material 3 app bar with adaptive theming, rounded geometry,
/// optional actions, and configurable layout.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.style,
    this.bottom,
    this.actions,
    this.showBackButton = false,
    this.onBack,
    this.showMenuButton = false,
    this.onMenu,
    this.menuIcon = Icons.menu_rounded,
    this.showSearch = false,
    this.onSearch,
    this.searchIcon = Icons.search_rounded,
    this.showNotifications = false,
    this.notificationCount = 0,
    this.onNotifications,
    this.notificationIcon = Icons.notifications_none_rounded,
    this.profileImage,
    this.profileInitials,
    this.onProfileTap,
    this.automaticSystemOverlay = true,
    this.animateContent = true,
  });

  /// Primary title text.
  final String title;

  /// Visual overrides. Falls back to [CustomAppBarStyle.adaptive].
  final CustomAppBarStyle? style;

  /// Optional bottom content such as a [TabBar].
  final PreferredSizeWidget? bottom;

  /// Additional trailing widgets rendered before built-in actions.
  final List<Widget>? actions;

  /// Shows a leading back affordance.
  final bool showBackButton;

  /// Back button callback. Defaults to [Navigator.maybePop].
  final VoidCallback? onBack;

  /// Shows a leading menu affordance when [showBackButton] is false.
  final bool showMenuButton;

  /// Menu button callback.
  final VoidCallback? onMenu;

  /// Leading icon when [showMenuButton] is true.
  final IconData menuIcon;

  /// Shows a search action on the trailing edge.
  final bool showSearch;

  /// Search action callback.
  final VoidCallback? onSearch;

  /// Search icon override.
  final IconData searchIcon;

  /// Shows a notifications action on the trailing edge.
  final bool showNotifications;

  /// Badge count for notifications. Hidden when zero.
  final int notificationCount;

  /// Notifications action callback.
  final VoidCallback? onNotifications;

  /// Notifications icon override.
  final IconData notificationIcon;

  /// Optional profile image shown as a trailing avatar.
  final ImageProvider<Object>? profileImage;

  /// Initials fallback when [profileImage] is null.
  final String? profileInitials;

  /// Profile avatar tap callback.
  final VoidCallback? onProfileTap;

  /// Applies a [SystemUiOverlayStyle] derived from bar luminance.
  final bool automaticSystemOverlay;

  /// Enables subtle entrance animation for title and actions.
  final bool animateContent;

  @override
  Size get preferredSize {
    final resolvedStyle = style ?? const CustomAppBarStyle();
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(resolvedStyle.height + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resolvedStyle = style ?? CustomAppBarStyle.adaptive(context);
    final foreground =
        resolvedStyle.foregroundColor ?? colorScheme.onSurface;
    final mediaWidth = MediaQuery.sizeOf(context).width;
    final isCompact = mediaWidth < 360;
    final horizontalPadding =
        isCompact ? 12.0 : resolvedStyle.horizontalPadding;

    final background = resolvedStyle.useGradient
        ? null
        : (resolvedStyle.backgroundColor ??
            (theme.brightness == Brightness.dark
                ? colorScheme.surfaceContainerHigh
                : colorScheme.surface));

    final gradient = resolvedStyle.useGradient
        ? (resolvedStyle.gradient ??
            CustomAppBarStyle.adaptive(context).gradient)
        : null;

    final overlayStyle = _systemOverlayStyle(
      context: context,
      foreground: foreground,
      background: background,
      gradient: gradient,
    );

    final content = _CustomAppBarSurface(
      style: resolvedStyle,
      backgroundColor: background,
      gradient: gradient,
      foregroundColor: foreground,
      horizontalPadding: horizontalPadding,
      title: title,
      bottom: bottom,
      leading: _buildLeading(context, foreground, resolvedStyle),
      titleWidget: _CustomAppBarTitle(
        title: title,
        foregroundColor: foreground,
        centerTitle: resolvedStyle.centerTitle,
        animate: animateContent,
      ),
      trailing: _buildTrailing(context, foreground, resolvedStyle),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: automaticSystemOverlay
          ? overlayStyle
          : const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
      child: PreferredSize(
        preferredSize: preferredSize,
        child: Material(
          type: MaterialType.transparency,
          elevation: resolvedStyle.scrolledUnderElevation ?? 0,
          shadowColor: resolvedStyle.shadowColor ??
              colorScheme.primary.withValues(alpha: 0.12),
          child: content,
        ),
      ),
    );
  }

  Widget? _buildLeading(
    BuildContext context,
    Color foreground,
    CustomAppBarStyle resolvedStyle,
  ) {
    if (showBackButton) {
      return _CustomAppBarIconButton(
        icon: Icons.arrow_back_rounded,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onBack ?? () => _defaultBack(context),
        foregroundColor: foreground,
        size: resolvedStyle.actionButtonSize,
      );
    }

    if (showMenuButton) {
      return _CustomAppBarIconButton(
        icon: menuIcon,
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        onPressed: onMenu,
        foregroundColor: foreground,
        size: resolvedStyle.actionButtonSize,
      );
    }

    return null;
  }

  /// Pops when possible; otherwise navigates to the platform home route.
  ///
  /// Module roots are often opened with `context.go`, which leaves nothing to pop.
  static void _defaultBack(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      if (router.canPop()) {
        router.pop();
        return;
      }
      router.go('/');
      return;
    }

    Navigator.of(context).maybePop();
  }

  List<Widget> _buildTrailing(
    BuildContext context,
    Color foreground,
    CustomAppBarStyle resolvedStyle,
  ) {
    final widgets = <Widget>[];

    if (actions != null) {
      widgets.addAll(actions!);
    }

    if (showSearch) {
      widgets.add(
        _CustomAppBarIconButton(
          icon: searchIcon,
          tooltip: MaterialLocalizations.of(context).searchFieldLabel,
          onPressed: onSearch,
          foregroundColor: foreground,
          size: resolvedStyle.actionButtonSize,
        ),
      );
    }

    if (showNotifications) {
      widgets.add(
        _CustomAppBarNotificationButton(
          icon: notificationIcon,
          count: notificationCount,
          onPressed: onNotifications,
          foregroundColor: foreground,
          size: resolvedStyle.actionButtonSize,
        ),
      );
    }

    if (profileImage != null || (profileInitials?.isNotEmpty ?? false)) {
      widgets.add(
        _CustomAppBarAvatar(
          image: profileImage,
          initials: profileInitials,
          onTap: onProfileTap,
          size: resolvedStyle.actionButtonSize,
        ),
      );
    }

    return widgets;
  }

  SystemUiOverlayStyle _systemOverlayStyle({
    required BuildContext context,
    required Color foreground,
    Color? background,
    Gradient? gradient,
  }) {
    final brightness = Theme.of(context).brightness;
    Color sample = background ?? foreground;

    if (gradient is LinearGradient && gradient.colors.isNotEmpty) {
      sample = gradient.colors.first;
    }

    final luminance = sample.computeLuminance();
    final isLightBackground = luminance > 0.55;

    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          isLightBackground ? Brightness.dark : Brightness.light,
      statusBarBrightness:
          brightness == Brightness.dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          brightness == Brightness.dark ? Brightness.light : Brightness.dark,
    );
  }
}

class _CustomAppBarSurface extends StatelessWidget {
  const _CustomAppBarSurface({
    required this.style,
    required this.backgroundColor,
    required this.gradient,
    required this.foregroundColor,
    required this.horizontalPadding,
    required this.title,
    required this.bottom,
    required this.leading,
    required this.titleWidget,
    required this.trailing,
  });

  final CustomAppBarStyle style;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color foregroundColor;
  final double horizontalPadding;
  final String title;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final Widget titleWidget;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(style.borderRadius),
        bottomRight: Radius.circular(style.borderRadius),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: style.shadowColor ??
                  Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
              blurRadius: style.elevation * 2.4,
              offset: Offset(0, style.elevation * 0.45),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: style.height,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: horizontalPadding,
                    end: horizontalPadding,
                  ),
                  child: style.centerTitle
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            Row(
                              children: [
                                if (leading != null) leading!,
                                const Spacer(),
                                if (trailing.isNotEmpty)
                                  _CustomAppBarTrailingRow(items: trailing),
                              ],
                            ),
                            IgnorePointer(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: style.actionButtonSize + 12,
                                ),
                                child: titleWidget,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            if (leading != null) ...[
                              leading!,
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: titleWidget,
                              ),
                            ),
                            if (trailing.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              _CustomAppBarTrailingRow(items: trailing),
                            ],
                          ],
                        ),
                ),
              ),
              if (bottom != null) bottom!,
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomAppBarTitle extends StatelessWidget {
  const _CustomAppBarTitle({
    required this.title,
    required this.foregroundColor,
    required this.centerTitle,
    required this.animate,
  });

  final String title;
  final Color foregroundColor;
  final bool centerTitle;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      height: 1.05,
      color: foregroundColor,
      fontSize: 22,
    );

    final content = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: centerTitle ? TextAlign.center : TextAlign.start,
      style: titleStyle,
    );

    if (!animate) {
      return content;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 8),
            child: child,
          ),
        );
      },
      child: content,
    );
  }
}

class _CustomAppBarTrailingRow extends StatelessWidget {
  const _CustomAppBarTrailingRow({required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          items[i],
        ],
      ],
    );
  }
}

/// Reusable premium action button for [CustomAppBar].
class CustomAppBarAction extends StatelessWidget {
  const CustomAppBarAction({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.isLoading = false,
    this.foregroundColor,
    this.size = 42,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? foregroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = foregroundColor ?? Theme.of(context).colorScheme.onSurface;

    return _CustomAppBarIconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
      isLoading: isLoading,
      foregroundColor: color,
      size: size,
    );
  }
}

class _CustomAppBarIconButton extends StatefulWidget {
  const _CustomAppBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.foregroundColor,
    required this.size,
    this.onPressed,
    this.isLoading = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color foregroundColor;
  final double size;

  @override
  State<_CustomAppBarIconButton> createState() =>
      _CustomAppBarIconButtonState();
}

class _CustomAppBarIconButtonState extends State<_CustomAppBarIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null && !widget.isLoading;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Material(
            color: colorScheme.primary.withValues(alpha: enabled ? 0.08 : 0.04),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: enabled ? widget.onPressed : null,
              onHighlightChanged: (value) => setState(() => _pressed = value),
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: widget.isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : Icon(
                        widget.icon,
                        size: 22,
                        color: enabled
                            ? colorScheme.primary
                            : widget.foregroundColor.withValues(alpha: 0.38),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomAppBarNotificationButton extends StatelessWidget {
  const _CustomAppBarNotificationButton({
    required this.icon,
    required this.count,
    required this.onPressed,
    required this.foregroundColor,
    required this.size,
  });

  final IconData icon;
  final int count;
  final VoidCallback? onPressed;
  final Color foregroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badgeText = count > 99 ? '99+' : '$count';

    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).alertDialogLabel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _CustomAppBarIconButton(
            icon: icon,
            tooltip: MaterialLocalizations.of(context).alertDialogLabel,
            onPressed: onPressed,
            foregroundColor: foregroundColor,
            size: size,
          ),
          if (count > 0)
            PositionedDirectional(
              top: 6,
              end: 6,
              child: AnimatedScale(
                scale: 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    child: Text(
                      badgeText,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onError,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            height: 1,
                          ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomAppBarAvatar extends StatelessWidget {
  const _CustomAppBarAvatar({
    required this.image,
    required this.initials,
    required this.onTap,
    required this.size,
  });

  final ImageProvider<Object>? image;
  final String? initials;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: onTap != null,
      child: Material(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: image != null
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: image!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      (initials ?? '').trim().isEmpty
                          ? '?'
                          : initials!.trim().substring(0, 1).toUpperCase(),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
