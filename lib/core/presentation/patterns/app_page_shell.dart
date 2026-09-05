import 'package:flutter/material.dart';

import '../../theme/tokens/tokens.dart';

/// Canonical responsive page shell pattern for NexaBiz ERP screens.
///
/// Handles screen constraints, safe areas, padding, background color,
/// and bi-directional RTL/LTR alignment.
class AppPageShell extends StatelessWidget {
  const AppPageShell({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.maxWidth = 1400.0,
    this.padding,
    this.backgroundColor,
    this.scrollable = true,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );

    if (scrollable) {
      content = SingleChildScrollView(child: content);
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? theme.colorScheme.surfaceContainerLowest,
      appBar: appBar,
      body: SafeArea(child: content),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
