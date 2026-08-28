import 'package:flutter/material.dart';
import '../../app/constants/app_constants.dart';
import '../../app/theme/app_spacing.dart';
import 'app_responsive.dart';

/// Sticky bottom action bar for form confirm/cancel/delete actions.
///
/// Handles virtual keyboard avoidance and bottom safe areas automatically,
/// ensuring action buttons stay accessible without covering content.
class AppBottomActions extends StatelessWidget {
  const AppBottomActions({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.elevation = 4.0,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    final safeBottom = media.padding.bottom;

    final defaultPadding = padding ??
        EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm + (bottomInset > 0 ? 0 : safeBottom),
        );

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Material(
        color: backgroundColor ?? scheme.surface,
        elevation: elevation,
        shadowColor: scheme.shadow.withValues(alpha: 0.12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: borderColor ?? scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: AppContentConstraint(
            child: Padding(
              padding: defaultPadding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Standardized responsive scaffold container with desktop content constraints
/// and keyboard-aware bottom action bar support.
class AppResponsiveScaffold extends StatelessWidget {
  const AppResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomActions,
    this.floatingActionButton,
    this.maxContentWidth = AppConstants.maxContentWidth,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomActions;
  final Widget? floatingActionButton;
  final double maxContentWidth;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: appBar,
      body: SafeArea(
        top: false,
        bottom: bottomActions == null,
        child: Column(
          children: [
            Expanded(
              child: AppContentConstraint(
                maxWidth: maxContentWidth,
                child: body,
              ),
            ),
            if (bottomActions != null) bottomActions!,
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
